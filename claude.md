# CLAUDE.md - RoadWise iOS App

## Project Overview

**RoadWise** is a native iOS app that tells you interesting facts about your surroundings as you drive. It uses GPS tracking to fetch AI-generated facts about nearby points of interest, with text-to-speech narration for a hands-free experience.

**Repository**: https://github.com/jaysettle/Iphone-RoadWise-App

---

## iOS App Architecture

### Tech Stack
- **SwiftUI** - iOS 16+ compatible UI framework
- **MapKit** - Apple Maps integration
- **CoreLocation** - GPS tracking with speed/heading
- **AVFoundation** - Text-to-speech (AVSpeechSynthesizer)
- **Claude API** - AI fact generation via Tailscale proxy

### File Structure
```
RoadWise/
├── RoadWiseApp.swift       # App entry point
├── MainTabView.swift       # Tab navigation (Map, Dashboard, Settings, About)
├── MapTabView.swift        # Main map view with GPS and fact fetching
├── DashboardView.swift     # Trip statistics and fact history
├── SettingsView.swift      # App settings UI
├── AboutView.swift         # App info and credits
├── LocationManager.swift   # CoreLocation GPS tracking
├── ClaudeService.swift     # Claude API integration
├── AppSettings.swift       # Settings model with UserDefaults persistence
├── TripStats.swift         # Trip statistics tracking
└── Info.plist              # Location permission description
```

### Key Components

#### MainTabView.swift
Tab-based navigation with 4 tabs:
- **Map** - Full-screen map with GPS, speed display, fact markers
- **Dashboard** - Trip stats (facts heard, distance, duration, speeds)
- **Settings** - Theme, audio, narration controls
- **About** - App info and credits

#### MapTabView.swift
- Full-screen Apple Maps with user location
- Speed display overlay (top-left)
- "Get Fun Fact" button
- Fact markers (red = current, gray = previous)
- Auto-center toggle
- Auto-fact timer support

#### LocationManager.swift
```swift
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    @Published var speedMPH: Double = 0.0
    @Published var heading: Double = 0.0
    @Published var statusMessage: String = "Initializing GPS..."
}
```

#### ClaudeService.swift
- Connects to Claude API via Tailscale proxy
- Anti-repetition: tracks last 10 facts
- Extracts metadata: nearest city, reference place, coordinates, summary
- Model: `claude-sonnet-4-20250514`

#### AppSettings.swift
Persisted settings via UserDefaults:
- **Theme**: Light, Dark, Fun, Retro
- **Audio**: Mute, volume, speech rate
- **Narration**: Auto-fact enabled, interval
- **Map**: Auto-center toggle

---

## Building & Running

### Requirements
- Xcode 15+
- iOS 16.0+ deployment target
- Apple Developer account (for device testing)

### Build Commands
```bash
# Navigate to project
cd "/Users/jaysettle/Library/CloudStorage/GoogleDrive-jaysettle@gmail.com/My Drive/Projects/40RoadWise/RoadWise"

# Clean build
xcodebuild -scheme RoadWise -destination 'generic/platform=iOS' clean build

# Check for errors
xcodebuild -scheme RoadWise -destination 'generic/platform=iOS' build 2>&1 | grep -E "(error:|warning:)"
```

### Running on Device
1. Open `RoadWise.xcodeproj` in Xcode
2. Select your iPhone as the run destination
3. Press Cmd+R to build and run
4. Grant location permission when prompted

### Location Permission
The app requires location permission. Add to Xcode build settings:
- Key: `NSLocationWhenInUseUsageDescription`
- Value: "RoadWise needs your location to find interesting facts about your surroundings"

---

## API Configuration

### Claude Proxy
The app connects to Claude via a Tailscale proxy:
```swift
private let proxyURL = "https://jaslinux.tail23d264.ts.net/claude-proxy/v1/messages"
```

### Prompt Format
The AI returns facts with metadata:
```
Nearest city: Indianapolis, Indiana
Reference place: Indianapolis Motor Speedway
Reference coordinates: 39.7939, -86.2347
Summary: Indy 500 racing history

[Interesting fact about the location...]
```

---

## iOS 16 Compatibility Notes

This app targets iOS 16 to support older devices. Key compatibility considerations:

1. **ObservableObject** instead of `@Observable` (iOS 17+)
2. **Map(coordinateRegion:)** instead of new Map API (iOS 17+)
3. **onChange(of:) { _ in }** instead of `onChange(of:) { _, newValue in }` (iOS 17+)
4. **No SwiftData** - requires iOS 17+

---

## Version History

- **v1.0** (Dec 2025) - Initial iOS app with tabbed interface, GPS tracking, Claude AI integration

---

*Last Updated: 2025-12-05*

---
---

# Web App Reference (jasLinux Server)

The iOS app is based on the RoadWise web app running on jasLinux. Below is the original web app documentation for reference.

---

## Web App Overview

**RoadWise Web** is a real-time narrated road trip web app that tells you interesting facts about your surroundings as you drive. It uses GPS tracking with heading detection to only narrate points of interest (POIs) that are **ahead of you**, creating a smooth, hands-free tour guide experience.

**This project runs on jasLinux alongside other critical services. Be careful not to disrupt them.**

## Web Tech Stack

- **Tailwind CSS** - Utility-first CSS framework (via CDN)
- **Leaflet.js v1.9.4** - Interactive map library
- **OpenStreetMap** - Map tile provider

## Web File Structure

```
/home/jay/projects/number one test/
├── index.html        # Main application file (single-page app)
├── maps-app.service  # Systemd service file (copy at /etc/systemd/system/)
├── debug.html        # Simple debug page for testing map initialization
├── test-logging.html # Test page with log forwarding (not used in production)
└── CLAUDE.md         # Project documentation
```

## Web Features

### Core Roadwise Functionality
- **Continuous GPS Tracking** - `watchPosition` with high accuracy
- **Heading Detection** - Calculates direction from GPS position changes
- **Speed Calculation** - Real-time speed in MPH from position changes
- **Directional Filtering** - Only narrates POIs ahead of you (60° cone)
- **Text-to-Speech Narration** - Web Speech API reads facts automatically
- **Smart Re-narration** - Clears narrated POIs after 1 mile to allow re-hearing
- **Auto-centering Map** - Follows your position as you drive

### POI System
**Dynamic AI Discovery** - Uses Claude to discover POIs:
- Requests coordinate-based facts within 3 miles
- Sends current position, heading, and speed for context
- Validates coordinates (rejects POIs >100 miles away)
- **Red markers** on map for current fact, gray for previous

### UI Features
- **Collapsible Sidebar** - Click X to hide, hamburger menu to show
- **Tab Navigation** - Map, Dashboard, Settings, About sections
- **Touch-friendly** - No zoom buttons, use pinch-to-zoom
- **Theme System** - Light, Dark, Fun, Retro Road Trip themes (localStorage persisted)

### Settings System (localStorage persisted)
**Audio Controls:**
- Mute toggle, Volume slider (0-100%), Speech rate (0.5x-2x), Test voice button

**Narration Settings:**
- Frequency modes: Frequent / Normal / Minimal
- Discovery distance (0.1-1.0 mi ahead)
- Narration trigger distance (0.1-1.0 mi)
- POI category toggles (Historical, Business, Natural, Quirky, Food)

**Map Display:**
- Auto-center map toggle
- Show/hide POI markers

---

## Server Environment

### Server Identity
- **Hostname**: jasLinux
- **IP Address**: 192.168.3.142
- **User**: jay
- **OS**: Ubuntu Linux
- **Tailscale IP**: 100.85.48.107
- **Public URL**: https://jaslinux.tail23d264.ts.net

### Critical Services - DO NOT DISRUPT

| Port | Service | Managed By | Notes |
|------|---------|------------|-------|
| 3001 | Open WebUI | Docker (open-webui-claude) | Web chat interface |
| 8000 | Claude CLI Bridge | systemd (claude-bridge.service) | OpenAI-compatible API |
| 8080 | Other service | - | Reserved |
| **8001** | **Maps App** | **systemd (maps-app.service)** | **This project** |

### Tailscale Funnel Configuration
```
https://jaslinux.tail23d264.ts.net/      → http://localhost:3001 (Open WebUI)
https://jaslinux.tail23d264.ts.net/maps  → http://localhost:8001 (Maps App)
https://jaslinux.tail23d264.ts.net/claude-proxy → http://localhost:3002 (Claude Proxy)
```

---

## Running the Maps App

The Maps App runs as a **systemd service** and starts automatically on boot.

### Service Commands
```bash
# Check status
sudo systemctl status maps-app.service

# Start/Stop/Restart
sudo systemctl start maps-app.service
sudo systemctl stop maps-app.service
sudo systemctl restart maps-app.service

# View logs
sudo journalctl -u maps-app.service -f
```

### Manual Start (if needed)
```bash
cd "/home/jay/projects/number one test"
python3 -m http.server 8001
```

---

## Access URLs

**Production (Tailscale Funnel)**:
- App: https://jaslinux.tail23d264.ts.net/maps
- Claude Proxy: https://jaslinux.tail23d264.ts.net/claude-proxy

**Local Network**:
- App: http://192.168.3.142:8001
- Claude Proxy: http://192.168.3.142:3002
- Chase Log: http://192.168.3.142:9998/chaselog

---

## Important Notes

- **Do not use ports 3001, 8000, or 8080** - reserved for other services
- **Geolocation requires HTTPS** - Tailscale Funnel provides this
- **Maps server auto-starts on boot** via systemd (maps-app.service)
- **UFW firewall is active** - ports restricted to LAN/Tailscale

---

*Web App Last Updated: 2025-11-28*
