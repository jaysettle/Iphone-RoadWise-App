//
//  MapTabView.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import SwiftUI
import MapKit
import AVFoundation

struct MapTabView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var tripStats: TripStats

    // Location manager for GPS tracking
    @StateObject private var locationManager = LocationManager()

    // Claude API service
    @State private var claudeService = ClaudeService()

    // Azure Speech TTS
    @StateObject private var azureSpeech = AzureSpeechService()

    // Audio player for Azure TTS
    @State private var audioPlayer: AVAudioPlayer?

    // Map region - will follow user
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.7042, longitude: -86.3994),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    // Fetching state
    @State private var isFetching: Bool = false

    // Current fact being displayed
    @State private var currentFact: RoadWiseFact?

    // Fact markers on map
    @State private var factMarkers: [FactMarker] = []

    // Show fact sheet
    @State private var showFactSheet: Bool = false

    // Error message
    @State private var errorMessage: String?

    // Auto-fact timer
    @State private var autoFactTimer: Timer?

    var body: some View {
        ZStack {
            // Full-screen map (iOS 16 compatible)
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: factMarkers) { marker in
                MapAnnotation(coordinate: marker.coordinate) {
                    ZStack {
                        Circle()
                            .fill(marker.isCurrent ? .red : .gray.opacity(0.7))
                            .frame(width: marker.isCurrent ? 30 : 24, height: marker.isCurrent ? 30 : 24)
                        Text("📍")
                            .font(.system(size: marker.isCurrent ? 16 : 12))
                    }
                    .onTapGesture {
                        if let fact = marker.fact {
                            currentFact = fact
                            showFactSheet = true
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)

            // Speed display overlay (top-left, like web app)
            VStack {
                HStack {
                    SpeedDisplayView(speed: locationManager.speedMPH)
                        .padding(.leading, 16)
                        .padding(.top, 60)
                    Spacer()

                    // Auto-center toggle
                    Button(action: { settings.autoCenter.toggle() }) {
                        Image(systemName: settings.autoCenter ? "location.fill" : "location")
                            .font(.system(size: 20))
                            .foregroundColor(settings.autoCenter ? .blue : .gray)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 60)
                }
                Spacer()
            }

            // Status bar and button at bottom
            VStack {
                Spacer()

                // Error message (if any)
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 4)
                }

                // Status message
                if !locationManager.statusMessage.isEmpty {
                    Text(locationManager.statusMessage)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 8)
                }

                // Get Fact button
                Button(action: getFact) {
                    HStack {
                        if isFetching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Fetching Fact...")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Get Fun Fact")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(isFetching ? .gray : settings.themeColor)
                    .cornerRadius(25)
                }
                .disabled(isFetching)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            tripStats.startTrip()
            setupAutoFact()
        }
        .onDisappear {
            autoFactTimer?.invalidate()
        }
        .onReceive(locationManager.$location) { newLocation in
            // Update trip stats
            if let location = newLocation {
                tripStats.updateLocation(location, speed: locationManager.speedMPH)
            }

            // Auto-center map on user location
            if settings.autoCenter, let location = newLocation {
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapRegion = MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                }
            }
        }
        .onChange(of: settings.autoFactEnabled) { _ in
            setupAutoFact()
        }
        .onChange(of: settings.autoFactInterval) { _ in
            setupAutoFact()
        }
        .sheet(isPresented: $showFactSheet) {
            FactSheetView(fact: currentFact)
        }
    }

    private func setupAutoFact() {
        autoFactTimer?.invalidate()

        if settings.autoFactEnabled {
            autoFactTimer = Timer.scheduledTimer(withTimeInterval: settings.autoFactInterval, repeats: true) { _ in
                if !isFetching {
                    getFact()
                }
            }
        }
    }

    private func getFact() {
        guard let location = locationManager.location else {
            errorMessage = "Waiting for GPS..."
            return
        }

        isFetching = true
        errorMessage = nil

        // Show GPS coords in status (like web app)
        locationManager.statusMessage = String(format: "GPS: %.4f, %.4f", location.latitude, location.longitude)

        Task {
            do {
                let fact = try await claudeService.getFact(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    heading: locationManager.heading,
                    speed: locationManager.speedMPH
                )

                await MainActor.run {
                    currentFact = fact

                    // Add marker to map
                    addFactMarker(fact: fact, userLocation: location)

                    // Add to trip stats
                    tripStats.addFact(fact)

                    // Speak the fact (if not muted) - no popup, just speak
                    if !settings.isMuted {
                        speakFact(fact.text)
                    }

                    isFetching = false
                    locationManager.statusMessage = fact.summary ?? "Fact loaded!"
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isFetching = false
                    locationManager.statusMessage = "Error - tap to retry"
                }
            }
        }
    }

    private func addFactMarker(fact: RoadWiseFact, userLocation: CLLocationCoordinate2D) {
        // Mark all existing markers as not current
        for i in factMarkers.indices {
            factMarkers[i].isCurrent = false
        }

        // Use fact coordinates if available, otherwise use user location
        let coordinate = fact.coordinates ?? userLocation

        // Add new marker
        let marker = FactMarker(
            coordinate: coordinate,
            fact: fact,
            isCurrent: true
        )
        factMarkers.append(marker)

        // Keep only last 20 markers
        if factMarkers.count > 20 {
            factMarkers.removeFirst()
        }
    }

    private func speakFact(_ text: String) {
        Task {
            do {
                let audioData = try await azureSpeech.synthesizeSpeech(text: text)

                await MainActor.run {
                    // Configure audio session for playback
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        print("Audio session error: \(error)")
                    }

                    // Play the audio
                    do {
                        audioPlayer = try AVAudioPlayer(data: audioData)
                        audioPlayer?.volume = Float(settings.volume)
                        audioPlayer?.play()
                    } catch {
                        print("Audio player error: \(error)")
                    }
                }
            } catch {
                print("Azure Speech error: \(error)")
            }
        }
    }
}

// Fact marker for map
struct FactMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let fact: RoadWiseFact?
    var isCurrent: Bool
}

// Speed display component (matches web app style)
struct SpeedDisplayView: View {
    let speed: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .foregroundColor(.yellow)
            Text("\(Int(speed))")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text("mph")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// Fact sheet view
struct FactSheetView: View {
    let fact: RoadWiseFact?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let fact = fact {
                        // Location info
                        if let place = fact.referencePlace {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                Text(place)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let city = fact.nearestCity {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.gray)
                                Text(city)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // The fact
                        Text(fact.text)
                            .font(.body)
                            .lineSpacing(4)

                        Spacer(minLength: 20)

                        // Summary tag
                        if let summary = fact.summary {
                            HStack {
                                Spacer()
                                Text(summary)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            }
                        }
                    } else {
                        Text("No fact available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Fun Fact")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MapTabView(settings: AppSettings(), tripStats: TripStats())
}
