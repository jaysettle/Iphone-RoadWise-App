//
//  AppSettings.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import SwiftUI

// Theme options matching web app
enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case fun = "Fun"
    case retro = "Retro Road Trip"

    var color: Color {
        switch self {
        case .light: return .blue
        case .dark: return .indigo
        case .fun: return .orange
        case .retro: return .brown
        }
    }
}

// Narration frequency matching web app
enum NarrationFrequency: String, CaseIterable {
    case frequent = "Frequent"
    case normal = "Normal"
    case minimal = "Minimal"

    var intervalMultiplier: Double {
        switch self {
        case .frequent: return 0.5
        case .normal: return 1.0
        case .minimal: return 2.0
        }
    }
}

// POI Categories matching web app
struct POICategories {
    var historical: Bool = true
    var business: Bool = true
    var natural: Bool = true
    var quirky: Bool = true
    var food: Bool = true
}

class AppSettings: ObservableObject {
    // Theme
    @Published var theme: AppTheme {
        didSet { save() }
    }

    // Audio Controls
    @Published var isMuted: Bool {
        didSet { save() }
    }
    @Published var volume: Double {
        didSet { save() }
    }
    @Published var speechRate: Double {
        didSet { save() }
    }

    // Narration Settings
    @Published var narrationFrequency: NarrationFrequency {
        didSet { save() }
    }
    @Published var discoveryDistance: Double {
        didSet { save() }
    }
    @Published var narrationDistance: Double {
        didSet { save() }
    }
    @Published var poiCategories: POICategories {
        didSet { save() }
    }
    @Published var fallbackNarration: Bool {
        didSet { save() }
    }

    // Auto-Fact Triggering
    @Published var autoFactEnabled: Bool {
        didSet { save() }
    }
    @Published var autoFactInterval: Double {
        didSet { save() }
    }

    // Distance-Based Facts
    @Published var distanceFactsEnabled: Bool {
        didSet { save() }
    }
    @Published var distanceFactsMiles: Double {
        didSet { save() }
    }

    // Map Display
    @Published var autoCenter: Bool {
        didSet { save() }
    }
    @Published var showPOIMarkers: Bool {
        didSet { save() }
    }
    @Published var showAIPOIs: Bool {
        didSet { save() }
    }
    @Published var showStaticPOIs: Bool {
        didSet { save() }
    }

    // Advanced
    @Published var reNarrationDistance: Double {
        didSet { save() }
    }
    @Published var maxValidationDistance: Double {
        didSet { save() }
    }
    @Published var discoveryInterval: Double {
        didSet { save() }
    }

    var themeColor: Color {
        theme.color
    }

    init() {
        // Load from UserDefaults or use defaults matching web app
        let defaults = UserDefaults.standard

        self.theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "light") ?? .light
        self.isMuted = defaults.bool(forKey: "isMuted")
        self.volume = defaults.object(forKey: "volume") as? Double ?? 1.0
        self.speechRate = defaults.object(forKey: "speechRate") as? Double ?? 1.0
        self.narrationFrequency = NarrationFrequency(rawValue: defaults.string(forKey: "narrationFrequency") ?? "normal") ?? .normal
        self.discoveryDistance = defaults.object(forKey: "discoveryDistance") as? Double ?? 0.2
        self.narrationDistance = defaults.object(forKey: "narrationDistance") as? Double ?? 0.5
        self.fallbackNarration = defaults.object(forKey: "fallbackNarration") as? Bool ?? true
        self.autoFactEnabled = defaults.bool(forKey: "autoFactEnabled")
        self.autoFactInterval = defaults.object(forKey: "autoFactInterval") as? Double ?? 30.0
        self.distanceFactsEnabled = defaults.bool(forKey: "distanceFactsEnabled")
        self.distanceFactsMiles = defaults.object(forKey: "distanceFactsMiles") as? Double ?? 5.0
        self.autoCenter = defaults.object(forKey: "autoCenter") as? Bool ?? true
        self.showPOIMarkers = defaults.object(forKey: "showPOIMarkers") as? Bool ?? true
        self.showAIPOIs = defaults.object(forKey: "showAIPOIs") as? Bool ?? true
        self.showStaticPOIs = defaults.object(forKey: "showStaticPOIs") as? Bool ?? true
        self.reNarrationDistance = defaults.object(forKey: "reNarrationDistance") as? Double ?? 1.0
        self.maxValidationDistance = defaults.object(forKey: "maxValidationDistance") as? Double ?? 100.0
        self.discoveryInterval = defaults.object(forKey: "discoveryInterval") as? Double ?? 0.1

        // POI Categories
        self.poiCategories = POICategories(
            historical: defaults.object(forKey: "poi_historical") as? Bool ?? true,
            business: defaults.object(forKey: "poi_business") as? Bool ?? true,
            natural: defaults.object(forKey: "poi_natural") as? Bool ?? true,
            quirky: defaults.object(forKey: "poi_quirky") as? Bool ?? true,
            food: defaults.object(forKey: "poi_food") as? Bool ?? true
        )
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(theme.rawValue, forKey: "theme")
        defaults.set(isMuted, forKey: "isMuted")
        defaults.set(volume, forKey: "volume")
        defaults.set(speechRate, forKey: "speechRate")
        defaults.set(narrationFrequency.rawValue, forKey: "narrationFrequency")
        defaults.set(discoveryDistance, forKey: "discoveryDistance")
        defaults.set(narrationDistance, forKey: "narrationDistance")
        defaults.set(fallbackNarration, forKey: "fallbackNarration")
        defaults.set(autoFactEnabled, forKey: "autoFactEnabled")
        defaults.set(autoFactInterval, forKey: "autoFactInterval")
        defaults.set(distanceFactsEnabled, forKey: "distanceFactsEnabled")
        defaults.set(distanceFactsMiles, forKey: "distanceFactsMiles")
        defaults.set(autoCenter, forKey: "autoCenter")
        defaults.set(showPOIMarkers, forKey: "showPOIMarkers")
        defaults.set(showAIPOIs, forKey: "showAIPOIs")
        defaults.set(showStaticPOIs, forKey: "showStaticPOIs")
        defaults.set(reNarrationDistance, forKey: "reNarrationDistance")
        defaults.set(maxValidationDistance, forKey: "maxValidationDistance")
        defaults.set(discoveryInterval, forKey: "discoveryInterval")
        defaults.set(poiCategories.historical, forKey: "poi_historical")
        defaults.set(poiCategories.business, forKey: "poi_business")
        defaults.set(poiCategories.natural, forKey: "poi_natural")
        defaults.set(poiCategories.quirky, forKey: "poi_quirky")
        defaults.set(poiCategories.food, forKey: "poi_food")
    }
}
