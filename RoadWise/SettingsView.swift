//
//  SettingsView.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        NavigationView {
            Form {
                // Theme Section
                Section(header: Label("Theme", systemImage: "paintbrush.fill")) {
                    Picker("App Theme", selection: $settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Audio Controls Section
                Section(header: Label("Audio", systemImage: "speaker.wave.3.fill")) {
                    Toggle("Mute", isOn: $settings.isMuted)

                    VStack(alignment: .leading) {
                        Text("Volume: \(Int(settings.volume * 100))%")
                        Slider(value: $settings.volume, in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        Text("Speech Rate: \(String(format: "%.1fx", settings.speechRate))")
                        Slider(value: $settings.speechRate, in: 0.5...2.0, step: 0.1)
                    }
                }

                // Narration Settings Section
                Section(header: Label("Narration", systemImage: "text.bubble.fill")) {
                    Picker("Frequency", selection: $settings.narrationFrequency) {
                        ForEach(NarrationFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Discovery Distance: \(String(format: "%.1f mi", settings.discoveryDistance))")
                        Slider(value: $settings.discoveryDistance, in: 0.1...1.0, step: 0.1)
                    }

                    VStack(alignment: .leading) {
                        Text("Narration Distance: \(String(format: "%.1f mi", settings.narrationDistance))")
                        Slider(value: $settings.narrationDistance, in: 0.1...1.0, step: 0.1)
                    }

                    Toggle("Fallback Narration", isOn: $settings.fallbackNarration)
                }

                // POI Categories Section
                Section(header: Label("POI Categories", systemImage: "mappin.and.ellipse")) {
                    Toggle("Historical", isOn: $settings.poiCategories.historical)
                    Toggle("Business", isOn: $settings.poiCategories.business)
                    Toggle("Natural", isOn: $settings.poiCategories.natural)
                    Toggle("Quirky", isOn: $settings.poiCategories.quirky)
                    Toggle("Food", isOn: $settings.poiCategories.food)
                }

                // Auto-Fact Section
                Section(header: Label("Auto-Fact Triggering", systemImage: "timer")) {
                    Toggle("Enable Auto-Facts", isOn: $settings.autoFactEnabled)

                    if settings.autoFactEnabled {
                        VStack(alignment: .leading) {
                            Text("Interval: \(Int(settings.autoFactInterval)) seconds")
                            Slider(value: $settings.autoFactInterval, in: 10...120, step: 5)
                        }
                    }
                }

                // Distance-Based Facts Section
                Section(header: Label("Distance-Based Facts", systemImage: "road.lanes")) {
                    Toggle("Enable Distance Facts", isOn: $settings.distanceFactsEnabled)

                    if settings.distanceFactsEnabled {
                        VStack(alignment: .leading) {
                            Text("Every \(Int(settings.distanceFactsMiles)) miles")
                            Slider(value: $settings.distanceFactsMiles, in: 5...50, step: 5)
                        }
                    }
                }

                // Map Display Section
                Section(header: Label("Map Display", systemImage: "map.fill")) {
                    Toggle("Auto-Center Map", isOn: $settings.autoCenter)
                    Toggle("Show POI Markers", isOn: $settings.showPOIMarkers)
                    Toggle("Show AI-Discovered POIs", isOn: $settings.showAIPOIs)
                    Toggle("Show Static POIs", isOn: $settings.showStaticPOIs)
                }

                // Advanced Section
                Section(header: Label("Advanced", systemImage: "slider.horizontal.3")) {
                    VStack(alignment: .leading) {
                        Text("Re-narration Reset: \(String(format: "%.1f mi", settings.reNarrationDistance))")
                        Slider(value: $settings.reNarrationDistance, in: 0.5...3.0, step: 0.5)
                    }

                    VStack(alignment: .leading) {
                        Text("Max Validation Distance: \(Int(settings.maxValidationDistance)) mi")
                        Slider(value: $settings.maxValidationDistance, in: 1...10, step: 1)
                    }

                    VStack(alignment: .leading) {
                        Text("Discovery Interval: \(String(format: "%.2f mi", settings.discoveryInterval))")
                        Slider(value: $settings.discoveryInterval, in: 0.05...0.5, step: 0.05)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
