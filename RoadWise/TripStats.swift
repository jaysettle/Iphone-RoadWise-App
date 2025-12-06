//
//  TripStats.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import Foundation
import CoreLocation

class TripStats: ObservableObject {
    @Published var factsHeard: Int = 0
    @Published var distanceTraveled: Double = 0.0 // miles
    @Published var tripDuration: TimeInterval = 0
    @Published var averageSpeed: Double = 0.0
    @Published var maxSpeed: Double = 0.0
    @Published var factHistory: [FactHistoryItem] = []

    private var tripStartTime: Date?
    private var lastLocation: CLLocationCoordinate2D?
    private var speedReadings: [Double] = []

    var formattedDuration: String {
        let hours = Int(tripDuration) / 3600
        let minutes = (Int(tripDuration) % 3600) / 60
        let seconds = Int(tripDuration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var formattedDistance: String {
        return String(format: "%.1f mi", distanceTraveled)
    }

    func startTrip() {
        tripStartTime = Date()
        factsHeard = 0
        distanceTraveled = 0
        tripDuration = 0
        averageSpeed = 0
        maxSpeed = 0
        lastLocation = nil
        speedReadings = []
        factHistory = []
    }

    func updateLocation(_ location: CLLocationCoordinate2D, speed: Double) {
        // Update duration
        if let start = tripStartTime {
            tripDuration = Date().timeIntervalSince(start)
        }

        // Update distance
        if let last = lastLocation {
            let distance = calculateDistance(from: last, to: location)
            distanceTraveled += distance
        }
        lastLocation = location

        // Update speed stats
        if speed > 0 {
            speedReadings.append(speed)
            if speed > maxSpeed {
                maxSpeed = speed
            }
            averageSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)
        }
    }

    func addFact(_ fact: RoadWiseFact) {
        factsHeard += 1
        let historyItem = FactHistoryItem(
            timestamp: Date(),
            fact: fact
        )
        factHistory.insert(historyItem, at: 0)

        // Keep last 50 facts
        if factHistory.count > 50 {
            factHistory.removeLast()
        }
    }

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let earthRadius = 3958.8 // miles

        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1) * cos(lat2) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))

        return earthRadius * c
    }
}

struct FactHistoryItem: Identifiable {
    let id = UUID()
    let timestamp: Date
    let fact: RoadWiseFact
}
