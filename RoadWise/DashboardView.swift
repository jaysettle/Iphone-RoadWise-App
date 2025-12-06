//
//  DashboardView.swift
//  RoadWise
//
//  Created by Jay on 12/5/25.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var tripStats: TripStats

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Trip Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Facts Heard",
                            value: "\(tripStats.factsHeard)",
                            icon: "sparkles",
                            color: .blue
                        )

                        StatCard(
                            title: "Distance",
                            value: tripStats.formattedDistance,
                            icon: "road.lanes",
                            color: .green
                        )

                        StatCard(
                            title: "Duration",
                            value: tripStats.formattedDuration,
                            icon: "clock.fill",
                            color: .orange
                        )

                        StatCard(
                            title: "Avg Speed",
                            value: String(format: "%.0f mph", tripStats.averageSpeed),
                            icon: "gauge.medium",
                            color: .purple
                        )

                        StatCard(
                            title: "Max Speed",
                            value: String(format: "%.0f mph", tripStats.maxSpeed),
                            icon: "speedometer",
                            color: .red
                        )
                    }
                    .padding(.horizontal)

                    // Start/Reset Trip Button
                    Button(action: {
                        tripStats.startTrip()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Trip Stats")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Recent Facts History
                    if !tripStats.factHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Facts")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(tripStats.factHistory.prefix(10)) { item in
                                FactHistoryCard(item: item)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No facts yet!")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Start driving and tap 'Get Fun Fact' to hear interesting facts about your surroundings.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FactHistoryCard: View {
    let item: FactHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let place = item.fact.referencePlace {
                    Text(place)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text(item.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(item.fact.text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let summary = item.fact.summary {
                Text(summary)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView(tripStats: TripStats())
}
