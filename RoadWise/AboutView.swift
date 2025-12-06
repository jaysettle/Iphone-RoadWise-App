//
//  AboutView.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Logo
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [.blue, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)

                            Text("RW")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Text("RoadWise")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About RoadWise")
                            .font(.headline)

                        Text("RoadWise is a real-time narrated road trip app that tells you interesting facts about your surroundings as you drive. It uses GPS tracking with heading detection to only narrate points of interest that are ahead of you, creating a smooth, hands-free tour guide experience.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                    .padding(.horizontal)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .padding(.horizontal)

                        FeatureRow(icon: "location.fill", title: "GPS Tracking", description: "Continuous high-accuracy location tracking")
                        FeatureRow(icon: "sparkles", title: "AI-Powered Facts", description: "Claude AI discovers interesting nearby locations")
                        FeatureRow(icon: "speaker.wave.3.fill", title: "Text-to-Speech", description: "Facts are read aloud hands-free")
                        FeatureRow(icon: "arrow.up.circle.fill", title: "Directional", description: "Only narrates POIs ahead of you")
                        FeatureRow(icon: "map.fill", title: "Live Map", description: "See your location and fact markers")
                    }

                    // Credits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Credits")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            CreditRow(label: "Developer", value: "Jay")
                            CreditRow(label: "AI", value: "Claude by Anthropic")
                            CreditRow(label: "Maps", value: "Apple MapKit")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("About")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct CreditRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AboutView()
}
