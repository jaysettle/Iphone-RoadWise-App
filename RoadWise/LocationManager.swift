//
//  LocationManager.swift
//  RoadWise
//
//  Created by Jay on 12/4/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    // Current location
    @Published var location: CLLocationCoordinate2D?

    // Speed in MPH (converted from m/s)
    @Published var speedMPH: Double = 0.0

    // Heading in degrees (0-360, where 0 = North)
    @Published var heading: Double = 0.0

    // Status message for UI
    @Published var statusMessage: String = "Initializing GPS..."

    // Has received first fix
    @Published var hasFirstFix: Bool = false

    // Authorization status
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Previous location for heading calculation (like web app)
    private var previousLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.activityType = .automotiveNavigation
    }

    func requestPermission() {
        authorizationStatus = locationManager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        case .denied, .restricted:
            statusMessage = "Location permission denied"
        @unknown default:
            break
        }
    }

    func startTracking() {
        statusMessage = "Initializing GPS..."
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        case .denied, .restricted:
            statusMessage = "Location permission denied"
        case .notDetermined:
            statusMessage = "Waiting for permission..."
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Update location
        location = newLocation.coordinate

        // First fix notification (like web app)
        if !hasFirstFix {
            hasFirstFix = true
            statusMessage = "GPS Ready"
            // Clear status after 3 seconds (like web app)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.hasFirstFix == true {
                    self?.statusMessage = ""
                }
            }
        }

        // Speed calculation (convert m/s to MPH)
        // GPS speed is more accurate than calculating from distance
        if newLocation.speed >= 0 {
            speedMPH = newLocation.speed * 2.23694 // m/s to MPH
        } else {
            speedMPH = 0
        }

        // Heading from GPS course (direction of travel)
        // This matches web app behavior - calculated from movement, not compass
        if newLocation.course >= 0 {
            heading = newLocation.course
        } else if let prev = previousLocation {
            // Calculate heading from previous position if course unavailable
            heading = calculateBearing(from: prev.coordinate, to: newLocation.coordinate)
        }

        previousLocation = newLocation
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // We use GPS course (direction of travel) instead of compass heading
        // This matches web app behavior
        // Compass heading available in newHeading.trueHeading if needed later
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError

        switch clError?.code {
        case .denied:
            statusMessage = "Location permission denied"
        case .locationUnknown:
            statusMessage = "GPS unavailable - searching..."
        case .network:
            statusMessage = "Network error - retrying..."
        default:
            statusMessage = "GPS error - retrying..."
        }

        // Fallback to Plainfield, IN (like web app)
        if location == nil {
            location = CLLocationCoordinate2D(latitude: 39.7042, longitude: -86.3994)
            statusMessage = "Using default location"
        }
    }

    // Calculate bearing between two coordinates (like web app)
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 {
            bearing += 360
        }

        return bearing
    }
}
