//
//  MainTabView.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var settings = AppSettings()
    @StateObject private var tripStats = TripStats()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab
            MapTabView(settings: settings, tripStats: tripStats)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(0)

            // Dashboard Tab
            DashboardView(tripStats: tripStats)
                .tabItem {
                    Image(systemName: "gauge.medium")
                    Text("Dashboard")
                }
                .tag(1)

            // Settings Tab
            SettingsView(settings: settings)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)

            // About Tab
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("About")
                }
                .tag(3)
        }
        .accentColor(settings.themeColor)
    }
}

#Preview {
    MainTabView()
}
