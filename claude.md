# CLAUDE.md - Roadwise Project

**Read this file before making changes to understand the server environment.**

This project runs on jasLinux alongside other critical services. Be careful not to disrupt them.

---

## Project Overview

**Roadwise** is a real-time narrated road trip web app that tells you interesting facts about your surroundings as you drive. It uses GPS tracking with heading detection to only narrate points of interest (POIs) that are **ahead of you**, creating a smooth, hands-free tour guide experience.

## Tech Stack

- **Tailwind CSS** - Utility-first CSS framework (via CDN)
- **Leaflet.js v1.9.4** - Interactive map library
- **OpenStreetMap** - Map tile provider

## File Structure

```
/home/jay/projects/number one test/
├── index.html        # Main application file (single-page app)
├── maps-app.service  # Systemd service file (copy at /etc/systemd/system/)
├── debug.html        # Simple debug page for testing map initialization
├── test-logging.html # Test page with log forwarding (not used in production)
└── CLAUDE.md         # Project documentation
```

## Features

### Core Roadwise Functionality
- **Continuous GPS Tracking** - `watchPosition` with high accuracy
- **Heading Detection** - Calculates direction from GPS position changes
- **Speed Calculation** - Real-time speed in MPH from position changes
- **Directional Filtering** - Only narrates POIs ahead of you (60° cone)
- **Text-to-Speech Narration** - Web Speech API reads facts automatically
- **Smart Re-narration** - Clears narrated POIs after 1 mile to allow re-hearing
- **Auto-centering Map** - Follows your position as you drive

### POI System
**Dynamic AI Discovery** - Uses OpenAI GPT-4o-mini to discover POIs:
- Requests 10-15 coordinate-based facts within 3 miles
- JSON format: `{fact: "text", lat: 39.1234, lon: -86.5678}`
- Sends current position, heading, and speed to OpenAI for context
- Searches 0.2 miles ahead based on your heading
- Discovers every 0.1 miles traveled
- Validates coordinates (rejects POIs >5 miles away)
- Extracts location names from fact text using pattern matching
- Finds historical sites, local businesses, landmarks, quirky facts
- Narrates when within 0.5 miles and in your direction
- **Orange markers** on map for AI-discovered POIs

**Static POIs** (10 hardcoded for Plainfield, Indiana):
- Downtown Plainfield Historic District, Western Yearly Meeting House
- Indianapolis International Airport, Warehouse District
- Hummel Park, Perry Crossing, Oasis Diner, Prewitt Restaurant
- White Lick Creek Bridge, Historic US Route 40
- **Blue markers** on map for static POIs

**Fallback Narration**:
- If no POIs narrated in 30 seconds, shares Plainfield history facts
- Cycles through 5 interesting local history snippets
- Prevents long silent periods during drives

### UI Features
- **Collapsible Sidebar** - Click X to hide, hamburger menu to show
- **Tab Navigation** - Map, Dashboard, Settings, About sections
- **Touch-friendly** - No zoom buttons, use pinch-to-zoom
- **Draggable Speed Display** - Shows speed (MPH) and heading (degrees), drag to reposition
- **Theme System** - Light, Dark, Fun, Retro Road Trip themes (localStorage persisted)

### Settings System (localStorage persisted)
**Audio Controls:**
- Mute toggle, Volume slider (0-100%), Speech rate (0.5x-2x), Test voice button

**Narration Settings:**
- Frequency modes: Frequent / Normal / Minimal
- Discovery distance (0.1-1.0 mi ahead)
- Narration trigger distance (0.1-1.0 mi)
- POI category toggles (Historical, Business, Natural, Quirky, Food)
- Fallback narration toggle

**Map Display:**
- Auto-center map toggle
- Show/hide POI markers
- Show/hide AI-discovered POIs
- Show/hide static POIs

**Advanced:**
- Re-narration reset distance (0.5-3.0 mi)
- Max AI POI validation distance (1-10 mi)
- Discovery interval (0.05-0.5 mi)

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
```

### Architecture Overview
```
Internet/iPhone
    |
    v
Tailscale Funnel (HTTPS)
    |
    ├── /      → Open WebUI (3001) → Claude Bridge (8000) → Claude CLI
    |                                                            ↓
    |                                                       MCP Servers
    |                                                       (hass-mcp, google-drive)
    |
    └── /maps  → Maps App (8001)
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

### Check Status
```bash
# Is the server running?
ss -tlnp | grep 8001

# Check Tailscale routing
tailscale serve status
```

---

## Related Projects

### Claude CLI Bridge (`/home/jay/claude-cli-bridge/`)
- OpenAI-compatible API server proxying to Claude Code CLI
- Runs on port 8000 via systemd
- Enables Open WebUI to communicate with Claude
- **Reference**: See `/home/jay/claude-cli-bridge/CLAUDE.md` for full server documentation

### Common Commands
```bash
# Check all services
sudo systemctl status claude-bridge.service --no-pager
docker ps | grep open-webui
ss -tlnp | grep -E ':(3001|8000|8001)'
tailscale funnel status

# Restart Claude Bridge (if needed)
sudo systemctl restart claude-bridge.service

# Restart Open WebUI (if needed)
docker restart open-webui-claude
```

---

## Important Notes

- **Do not use ports 3001, 8000, or 8080** - reserved for other services
- **Geolocation requires HTTPS** - Tailscale Funnel provides this
- **Maps server auto-starts on boot** via systemd (maps-app.service)
- **UFW firewall is active** - ports restricted to LAN/Tailscale

---

*Last Updated: 2025-11-27*

---

## Debugging & Development

### Browser Console Logging

The app includes comprehensive console logging for debugging:

- 🚀 `[PAGE]` - Page initialization logs
- 🗺️ `[MAP]` - Map setup and operations
- 🚗 `[TRACKING]` - GPS tracking logs
- ✅ - Success messages
- ❌ - Error messages
- 📍 - Position updates (lat, lng, heading, speed)

**To view logs:** Press F12 in browser → Console tab

### Debugging Map Issues with Firefox Headless

When the browser console isn't accessible (e.g., HTTPS/HTTP mixed content blocking log forwarding), use Firefox in headless mode to capture JavaScript errors:

```bash
# Run Firefox headless and capture console errors
timeout 15 firefox --headless --new-instance http://localhost:8001/index.html 2>&1 | grep -E "(JavaScript error|Error:|console)"

# More comprehensive capture with Node.js
cat > /tmp/test_page.js << 'JSEOF'
const { spawn } = require('child_process');

const firefox = spawn('firefox', [
    '--headless',
    '--new-instance',
    'http://localhost:8001/index.html'
], {
    stdio: ['ignore', 'pipe', 'pipe']
});

let hasErrors = false;

firefox.stderr.on('data', (data) => {
    const output = data.toString();
    if (output.includes('JavaScript error') || output.includes('Error:')) {
        console.log('ERROR:', output.trim());
        hasErrors = true;
    }
});

setTimeout(() => {
    firefox.kill();
    console.log(hasErrors ? '\n❌ Errors detected' : '\n✅ No errors');
    process.exit(hasErrors ? 1 : 0);
}, 8000);
JSEOF

node /tmp/test_page.js
```

This technique was used to discover the critical "settings before initialization" bug that wasn't visible in browser console due to HTTPS/HTTP mixed content blocking.

### Common Issues Found & Fixed

1. **Map Container Height Issue**
   - Problem: Map div had `height: 100%` but parent chain broke
   - Fix: Added `html, body { height: 100% }` and `h-full` to `<main>` element
   - Line 11: CSS fix
   - Line 171: Layout fix

2. **Settings Initialization Order**
   - Problem: `loadSettings()` called before `let settings = {...}` declaration
   - Error: `ReferenceError: can't access lexical declaration 'settings' before initialization`
   - Fix: Moved `loadSettings()` call to after settings declaration (line 716)
   - Discovered via Firefox headless execution

3. **HTTPS/HTTP Mixed Content**
   - Problem: Log forwarding to `http://192.168.3.142:9999/log` blocked on HTTPS page
   - Solution: Use Firefox headless for debugging instead of browser log forwarding

### Debug Pages

**debug.html** - Minimal test page:
- Pink background on map div (visual height indicator)
- White debug box showing initialization steps
- Simple map with marker at Plainfield, IN
- URL: `http://192.168.3.142:8001/debug.html`

**test-logging.html** - Log forwarding test:
- Intercepts console.log/error/warn
- Forwards to HTTP endpoint (blocked by HTTPS in production)
- Not used in production due to mixed content security

### Verification Commands

```bash
# Check if service is running
ss -tlnp | grep 8001

# Test page accessibility
curl -I http://localhost:8001/index.html

# Check for JavaScript errors
firefox --headless --new-instance http://localhost:8001/index.html 2>&1 | grep -i error

# Check Leaflet CDN
curl -I https://unpkg.com/leaflet@1.9.4/dist/leaflet.js

# Verify CSS structure
curl -s http://localhost:8001/index.html | grep -E "(html, body|#map.*height)"
```

---

## Recent Updates (November 2025)

### 🎯 AI-Generated Fact Summaries (v1.11.0)

**Problem:** Claude/OpenAI was repeating similar topics (bridges, buildings, historical facts) during the same drive.

**Solution:** Implemented AI-generated summary tags that are tracked and fed back to prevent repetition.

**How It Works:**
1. AI now returns **4 metadata lines** instead of 3:
   ```
   Nearest city: Indianapolis, Indiana
   Reference place: Indianapolis Motor Speedway
   Reference coordinates: 39.7939, -86.2347
   Summary: Indy 500 music festival    <-- NEW!
   ```

2. Summary is a **2-5 word phrase** describing the topic (e.g., "covered bridge history", "limestone cave formation", "wildlife migration patterns")

3. Summaries are extracted from AI response:
   ```javascript
   const summaryMatch = fact.match(/Summary:\s*(.+)/i);
   factSummary = summaryMatch ? summaryMatch[1].trim() : fallback;
   ```

4. **30 summaries tracked** per session (increased from 10 full facts)

5. Summaries fed back to AI in next request:
   ```
   Previously used topics in this drive (AVOID these):
   covered bridge history | limestone cave | wildlife migration | ...
   ```

6. Summaries saved in chase-log.json:
   ```json
   {
     "timestamp": "2025-11-28T20:00:00.000Z",
     "coords": "39.704200, -86.399400",
     "speed": "45.5 mph",
     "heading": "180",
     "fact": "The covered bridge at Hummel Park...",
     "summary": "covered bridge history"
   }
   ```

**Benefits:**
- ✅ AI knows exactly what topics to avoid
- ✅ Short & consistent (2-5 words vs 80-char fragments)
- ✅ Tracks 3x more variety (30 vs 10)
- ✅ Cleaner prompts (more tokens for fact generation)
- ✅ Persistent across sessions (saved in JSON)

**Code Changes:**
- `index.html` lines 2593-2602: Added Summary to output format
- `index.html` lines 2784-2804: Extract and track summaries
- `index.html` line 2257: Added summary field to chase log
- `index.html` lines 2501-2509: Stronger variety instructions

---

### 📝 Chase Log System (JSON Format)

**Purpose:** Track all fun facts with GPS coordinates, speed, heading, and summaries for post-drive analysis.

**Implementation:**
- **File:** `/home/jay/projects/number one test/chase-log.json`
- **Server:** `chase-log-server.js` (Node.js, port 9998)
- **Service:** `chase-log.service` (systemd, auto-start)

**Log Entry Format:**
```json
[
  {
    "timestamp": "2025-11-28T20:00:00.000Z",
    "coords": "39.704200, -86.399400",
    "speed": "45.5 mph",
    "heading": "180",
    "fact": "The historic covered bridge at Hummel Park spans White Lick Creek...",
    "summary": "covered bridge history"
  }
]
```

**Endpoints:**
- `POST http://192.168.3.142:9998/chaselog` - Add fact to log
- `GET http://192.168.3.142:9998/chaselog` - Retrieve all facts

**Service Management:**
```bash
# Check status
sudo systemctl status chase-log.service

# View logs
sudo journalctl -u chase-log.service -f

# View chase log file
cat "/home/jay/projects/number one test/chase-log.json" | jq .
```

**Firewall Rule:**
```bash
sudo ufw allow from 192.168.3.0/24 to any port 9998 comment 'Chase Log Server'
```

---

### 🔒 Claude API Proxy (Fixed Mixed Content)

**Problem:** HTTPS pages (Tailscale Funnel) couldn't fetch from HTTP proxy (mixed content error).

**Solution:** Added Claude proxy to Tailscale Funnel with path-based routing.

**Configuration:**
```bash
# Tailscale Funnel paths
https://jaslinux.tail23d264.ts.net/claude-proxy → http://127.0.0.1:3002
https://jaslinux.tail23d264.ts.net/maps → http://127.0.0.1:8001
```

**Smart URL Selection (index.html:2703-2705):**
```javascript
const proxyUrl = window.location.protocol === 'https:'
    ? 'https://jaslinux.tail23d264.ts.net/claude-proxy/v1/messages'
    : 'http://192.168.3.142:3002/v1/messages';
```

**Enhanced Logging (claude-proxy.js):**
- 📥 Incoming request with model and message length
- 📤 Response status and content length
- ❌ Full error stack traces

**Proxy Logs:**
```bash
# Monitor Claude proxy
sudo journalctl -u claude-proxy.service -f

# Example output
📥 Proxying Claude API request...
📊 Request model: claude-3-haiku-20240307
📊 Request message length: 2456 chars
📤 Claude API response: 200
✅ Response content length: 567 chars
```

---

### 🎨 UI Improvements

#### Removed Heading Display (v1.10.0)
**Why:** App doesn't have access to device compass. "Heading" was calculated from GPS movement (only works when moving).

**Changes:**
- Removed triangle/arrow icon
- Removed heading number
- Speed display now single row: `⚡ 45 mph`
- Simplified `updateSpeedDisplay()` function

**Note:** Heading calculation still used internally for:
- Discovering POIs ahead
- AI context (direction of travel)
- 60-degree cone filtering

#### Removed Degree Symbols
- Speed display: No "degrees" label
- Heading (when it existed): No ° symbol
- Cleaner, simpler UI

#### Fixed "Fetching Fact" Button
**Problem:** Button text wrapping incorrectly (showed "Fetching..." only).

**Fix:** Added proper flex container:
```html
<div class="flex items-center justify-center gap-2">
  <svg>...</svg>
  <span>Fetching Fact...</span>
</div>
```

---

### 🗺️ Map Marker System

**Current Fact Marker:**
- Red marker (30x30px)
- Visible and prominent

**Previous Fact Markers:**
- Gray markers (24x24px, 70% opacity)
- Automatically changed when new fact is added

**Code (index.html:2173-2212):**
```javascript
function addFactMarker(coords, factText) {
    // Change all previous markers to gray
    factMarkers.forEach(markerData => {
        markerData.marker.setIcon(L.divIcon({
            className: 'fact-marker-previous',
            html: '<div style="background: #9CA3AF; ...">📍</div>',
            iconSize: [24, 24]
        }));
    });

    // Create new red marker
    const marker = L.marker([coords.lat, coords.lon], {
        icon: L.divIcon({
            className: 'fact-marker-current',
            html: '<div style="background: #DC2626; ...">📍</div>',
            iconSize: [30, 30]
        })
    }).addTo(map);
}
```

---

### 🗣️ Voice Randomization

**Feature:** Each fun fact uses a random Azure neural voice for variety.

**Voices (17 total):**
- JennyNeural, GuyNeural, AriaNeural, DavisNeural, AmberNeural, AnaNeural
- ChristopherNeural, BrandonNeural, EmmaNeural, AndrewNeural, AvaNeural
- EricNeural, JacobNeural, MichelleNeural, RogerNeural, SaraNeural, TonyNeural

**Implementation (index.html:1591-1616):**
```javascript
const standardNeuralVoices = ['en-US-JennyNeural', ...];
function getRandomVoice() {
    return standardNeuralVoices[Math.floor(Math.random() * standardNeuralVoices.length)];
}

// Facts use random voice
await speak(fact, pendingAudioElement, true); // true = random
```

**User's manually selected voice still used for:**
- Error messages
- Status announcements
- Non-fact speech

---

### 📍 Coordinate Validation (100-Mile Check)

**Problem:** Facts sometimes returned European coordinates (>100 miles away).

**Solution:** Validate all coordinates; fallback to state capital if too far.

**State Capitals Lookup (index.html:2283-2293):**
```javascript
const stateCapitals = {
    'Indiana': { lat: 39.7684, lon: -86.1581, name: 'Indianapolis' },
    'Illinois': { lat: 39.7817, lon: -89.6501, name: 'Springfield' },
    'Ohio': { lat: 39.9612, lon: -82.9988, name: 'Columbus' },
    // ... 10 states total
};
```

**Validation Logic (index.html:2249-2290):**
1. Calculate distance from user to fact coordinates
2. If ≤100 miles: Use fact coordinates
3. If >100 miles:
   - Extract state from "Nearest city" line
   - Look up state capital
   - Use capital coordinates
   - Default to Indianapolis if no match

**All 4 coordinate extraction patterns updated** to call validation.

---

### 🐛 Android GPS Fixes

**Problem:** GPS stuck on "Checking GPS..." even after location granted.

**Root Cause:**
- No status indicator during GPS initialization
- Timeout too short (30s) for Android cold start
- Confusing status messages

**Solutions:**
1. **Status Indicators:**
   - "🛰️ Initializing GPS..." on page load
   - "✅ GPS Ready" when first fix acquired (clears after 3s)
   - Specific error messages by code

2. **Increased Timeout:** 30s → 60s for Android GPS cold start

3. **Removed Confusing Message:** No more "Checking GPS..." on button click when GPS already working

**Error Messages (index.html:2131-2137):**
```javascript
if (error.code === 1) updateStatus('❌ Location permission denied');
if (error.code === 2) updateStatus('⚠️ GPS unavailable - searching for signal...');
if (error.code === 3) updateStatus('⏱️ GPS timeout - still trying...');
```

---

### 🔧 Technical Improvements

#### Audio Pool for iOS
**Problem:** iOS Safari requires user gesture for audio playback.

**Solution:** Pre-create audio elements during user interaction:
- 3-element audio pool
- Initialized on first button click
- Used for distance-triggered facts
- Button-triggered facts create new audio with gesture

#### Session Tracking
**Added:** `sessionId = Date.now()` - Unique ID per drive
**Purpose:**
- Helps AI distinguish between different trips
- Allows topic repetition across different sessions
- Included in AI prompt for context

---

### 📊 Service Ports & URLs

| Service | LAN | Public (Tailscale) |
|---------|-----|-------------------|
| RoadWise App | http://192.168.3.142:8001 | https://jaslinux.tail23d264.ts.net/maps |
| Claude Proxy | http://192.168.3.142:3002 | https://jaslinux.tail23d264.ts.net/claude-proxy |
| Chase Log Server | http://192.168.3.142:9998 | - |

---

### 🔍 Debugging Commands

```bash
# Monitor all RoadWise services
sudo journalctl -f -u maps-app.service -u claude-proxy.service -u chase-log.service

# Check Claude proxy requests
sudo journalctl -u claude-proxy.service -n 20 | grep "📥"

# View chase log
curl http://192.168.3.142:9998/chaselog | jq .

# Test Claude proxy
curl -X POST https://jaslinux.tail23d264.ts.net/claude-proxy/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-haiku-20240307","max_tokens":100,"messages":[{"role":"user","content":"Test"}]}'

# Check Tailscale Funnel status
sudo tailscale funnel status
```

---

### 📝 Version History

- **v1.11.0** (2025-11-28): AI-generated fact summaries, 30-topic tracking
- **v1.10.0** (2025-11-28): Removed heading display, Android GPS fixes
- **v1.9.0** (2025-11-28): Chase log JSON format, summaries in logs
- **v1.8.0** (2025-11-28): Claude proxy via Tailscale Funnel, mixed content fix
- **v1.7.0** (2025-11-28): Voice randomization, marker colors, coordinate validation
- **v1.6.0** (2025-11-27): Audio pool for iOS, button text fix

---

*Last Updated: 2025-11-28 - AI-Generated Fact Summaries & Chase Log System*


## Recent Updates (November 28, 2025)

### 1. Chase Log System (JSON Format)

**Purpose**: Track all fun facts with timestamps, GPS coordinates, speed, and AI-generated summaries.

**Files Created**:
- `chase-log-server.js` - Node.js server on port 9998
- `chase-log.service` - Systemd service for auto-start
- `chase-log.json` - JSON array of all logged facts

**Service Management**:
```bash
# Check status
sudo systemctl status chase-log.service

# View logs
sudo journalctl -u chase-log.service -f

# View JSON log
cat "/home/jay/projects/number one test/chase-log.json" | jq .

# Retrieve via HTTP
curl http://192.168.3.142:9998/chaselog
```

**Log Entry Format**:
```json
{
  "timestamp": "2025-11-28T20:00:00.000Z",
  "coords": "39.704200, -86.399400",
  "speed": "45.5 mph",
  "heading": "180",
  "fact": "The Indianapolis Motor Speedway hosts...",
  "summary": "Indy 500 music festival"
}
```

**Features**:
- POST endpoint: Appends new facts to JSON array
- GET endpoint: Retrieves entire log
- Pretty-printed JSON (2-space indentation)
- Firewall: Port 9998 allowed for LAN (192.168.3.0/24)

---

### 2. Claude API Integration (Fixed HTTPS Mixed Content)

**Problem**: App accessed via HTTPS couldn't fetch from HTTP proxy (browser security).

**Solution**: Added Tailscale Funnel path for HTTPS access.

**Claude Proxy Configuration**:
```bash
# Service: claude-proxy.service (port 3002)
# Location: /home/jay/projects/number one test/claude-proxy.js
# Model: claude-3-haiku-20240307
```

**Tailscale Funnel Setup**:
```bash
# Added proxy path
sudo tailscale funnel --bg --https=443 --set-path=/claude-proxy http://127.0.0.1:3002

# Current configuration:
# https://jaslinux.tail23d264.ts.net/claude-proxy → http://127.0.0.1:3002
```

**Smart URL Selection** (index.html ~line 2703):
```javascript
// Automatically detects protocol
const proxyUrl = window.location.protocol === 'https:'
    ? 'https://jaslinux.tail23d264.ts.net/claude-proxy/v1/messages'
    : 'http://192.168.3.142:3002/v1/messages';
```

**Enhanced Logging**:
- Proxy logs: Request model, message length, response status, content length
- Frontend logs: Protocol detection, proxy URL, response headers, content preview
- Emoji-based log levels: 📥 (incoming), 📤 (outgoing), ❌ (errors)

**Monitor Logs**:
```bash
# Proxy logs
sudo journalctl -u claude-proxy.service -f

# Look for:
# 📥 Proxying Claude API request...
# 📊 Request model: claude-3-haiku-20240307
# 📊 Request message length: 1234 chars
# 📤 Claude API response: 200
# ✅ Response content length: 567 chars
```

---

### 3. AI-Generated Fact Summaries (Anti-Repetition System)

**Purpose**: Prevent Claude/OpenAI from repeating similar topics by tracking AI-generated summary tags.

**How It Works**:

**Step 1: AI generates 4 metadata lines** (added "Summary" line):
```
Nearest city: Indianapolis, Indiana
Reference place: Indianapolis Motor Speedway
Reference coordinates: 39.7939, -86.2347
Summary: Indy 500 music festival    <-- NEW!
```

**Step 2: Summary extracted from response** (index.html ~line 2785):
```javascript
const summaryMatch = fact.match(/Summary:\s*(.+)/i);
factSummary = summaryMatch ? summaryMatch[1].trim() : fallback;
```

**Step 3: Summaries tracked in history** (30 max):
```javascript
factHistory.push(factSummary);  // "Indy 500 music festival"
if (factHistory.length > 30) factHistory.shift();
```

**Step 4: Fed back to AI in next request** (index.html ~line 2602):
```
Previously used topics in this drive (AVOID these):
Indy 500 music festival | deer migration patterns | limestone geology | ...
```

**Step 5: Saved to chase log**:
```json
{
  "summary": "Indy 500 music festival"
}
```

**Prompt Instructions** (index.html ~line 2501):
```
CRITICAL: Check the "Previously used topics" list carefully.
DO NOT repeat or closely resemble ANY of those summaries.

Rules for variety:
- Each summary represents a fact already told in this drive
- You MUST pick something completely different from ALL previous summaries
- Different category, different type of location, different subject matter
- Rotate categories aggressively - no two facts in a row from same category
```

**Output Format Requirements** (index.html ~line 2593):
```
Summary: <2-5 words describing this fact's topic>

Examples:
- "covered bridge history"
- "limestone cave formation"
- "wildlife migration patterns"
- "abandoned railroad"
```

**Console Logs**:
```
📝 [FACT-SUMMARY] AI provided summary: "covered bridge history"
📚 [FACT-HISTORY] Added summary to history: "covered bridge history"
📚 [FACT-HISTORY] Total summaries tracked: 5
```

**Benefits**:
- AI generates its own topic tags (2-5 words)
- Tracks 30 summaries vs 20 text fragments
- Cleaner, more consistent than extracting topics ourselves
- Persistent across sessions via chase log
- Dramatically reduces repetition

---

### 4. UI Improvements

**Removed Heading Display** (index.html ~line 269):
- App doesn't have access to device compass
- "Heading" was calculated from GPS movement (only worked while moving)
- Showed "---" when stationary (confusing)
- Removed triangle/arrow icon and heading number
- Speed display now single row: `⚡ 45 mph`
- Heading calculation still used internally for POI discovery

**Fixed "Fetching Fact" Button** (index.html ~line 2653):
- Added proper flex container to prevent text wrapping
- Changed "Loading..." to "Fetching Fact..." for clarity
- Now displays: `[spinner] Fetching Fact...`

**Removed Degree Symbols**:
- No more "°" or "degrees" text labels
- Cleaner display (e.g., "180" instead of "180°")

---

### 5. Coordinate Validation (100-Mile Limit)

**Purpose**: Prevent facts with European or far-away coordinates from appearing.

**Implementation** (index.html ~line 2293):
```javascript
const stateCapitals = {
    'Indiana': { lat: 39.7684, lon: -86.1581, name: 'Indianapolis' },
    'Illinois': { lat: 39.7817, lon: -89.6501, name: 'Springfield' },
    'Ohio': { lat: 39.9612, lon: -82.9988, name: 'Columbus' },
    'Kentucky': { lat: 38.2009, lon: -84.8733, name: 'Frankfort' },
    'Michigan': { lat: 42.7325, lon: -84.5555, name: 'Lansing' },
    'Wisconsin': { lat: 43.0731, lon: -89.4012, name: 'Madison' },
    'Missouri': { lat: 38.5767, lon: -92.1735, name: 'Jefferson City' },
    'Tennessee': { lat: 36.1627, lon: -86.7816, name: 'Nashville' },
    'Alabama': { lat: 32.3617, lon: -86.2792, name: 'Montgomery' },
    'Georgia': { lat: 33.7490, lon: -84.3880, name: 'Atlanta' }
};

function validateFactCoordinates(lat, lon, factText) {
    const distance = getDistance(userLat, userLon, lat, lon);

    if (distance <= 100) {
        return { lat, lon };  // Use fact coordinates
    }

    // Extract state from "Nearest city: City, State"
    const cityMatch = factText.match(/Nearest city:\s*([^,]+),\s*([^\n]+)/i);
    const stateName = cityMatch ? cityMatch[2].trim() : null;

    // Fallback to state capital
    return stateCapitals[stateName] || { lat: 39.7684, lon: -86.1581 };
}
```

**Applied to all coordinate patterns**: refCoordsMatch, refLocMatch, namedMatch, simpleMatch

**Console Logs**:
```
📏 [COORD-VALIDATE] Fact coordinates are 45.2 miles from user
✅ [COORD-VALIDATE] Distance OK (45.2 mi), using fact coordinates

OR

📏 [COORD-VALIDATE] Fact coordinates are 250.7 miles from user
⚠️ [COORD-VALIDATE] Coordinates too far (250.7 mi > 100 mi), looking for fallback
🏛️ [COORD-VALIDATE] Using Indiana capital (Indianapolis) coordinates instead
```

---

### 6. Android GPS Initialization Fix

**Problem**: GPS stuck on "Checking GPS..." despite location permission granted.

**Root Cause**:
- Android GPS cold start takes 30-60+ seconds
- Old timeout was only 30 seconds
- No status indicator showed initialization progress
- Confusing "Checking GPS..." message appeared when GPS already working

**Solution** (index.html ~line 2077):
```javascript
function startTracking() {
    updateStatus('🛰️ Initializing GPS...');  // Immediate feedback

    navigator.geolocation.watchPosition(
        (position) => {
            if (!currentPosition) {  // First fix
                console.log('✅ [TRACKING] First GPS fix acquired!');
                updateStatus('✅ GPS Ready');
                setTimeout(() => {
                    if (currentPosition) updateStatus('');
                }, 3000);  // Clear after 3s
            }
            currentPosition = position.coords;
            // ... rest of tracking
        },
        (error) => {
            // Specific error messages
            if (error.code === 1) updateStatus('❌ Location permission denied');
            if (error.code === 2) updateStatus('⚠️ GPS unavailable - searching for signal...');
            if (error.code === 3) updateStatus('⏱️ GPS timeout - still trying...');

            // Fallback location if error
            if (!currentPosition) {
                updateStatus('Using test GPS location');
                currentPosition = { latitude: 39.7042, longitude: -86.3994 };
            }
        },
        {
            enableHighAccuracy: true,
            timeout: 60000,  // Increased from 30s to 60s
            maximumAge: 0
        }
    );
}
```

**Removed confusing message** (index.html ~line 2635):
- Old: `updateStatus('Checking GPS...')` shown even when GPS ready
- New: Only shows status if actually needed, otherwise displays coordinates

**User Experience**:
1. Page load: "🛰️ Initializing GPS..."
2. GPS fix acquired: "✅ GPS Ready" (clears after 3 seconds)
3. Button click: "GPS: 39.7042, -86.3994" → "Fetching Fact..." → Fact plays
4. Error handling: Specific messages for permission/unavailable/timeout

---

### 7. Voice & Audio Improvements

**Random Voice Selection** (index.html ~line 1591):
- Each fun fact uses a random Azure neural voice (17 total)
- Adds variety and keeps facts interesting
- User's selected voice still used for errors/status messages

**Voices Array**:
```javascript
const standardNeuralVoices = [
    'en-US-JennyNeural', 'en-US-GuyNeural', 'en-US-AriaNeural',
    'en-US-DavisNeural', 'en-US-AmberNeural', 'en-US-AnaNeural',
    'en-US-ChristopherNeural', 'en-US-BrandonNeural', 'en-US-EmmaNeural',
    'en-US-AndrewNeural', 'en-US-AvaNeural', 'en-US-EricNeural',
    'en-US-JacobNeural', 'en-US-MichelleNeural', 'en-US-RogerNeural',
    'en-US-SaraNeural', 'en-US-TonyNeural'
];

function getRandomVoice() {
    const randomIndex = Math.floor(Math.random() * standardNeuralVoices.length);
    return standardNeuralVoices[randomIndex];
}

// Usage in speak() function:
const voiceToUse = useRandomVoice ? getRandomVoice() : settings.azureVoice;
```

**Audio Pool for iOS** (index.html ~line 1480):
- Pre-initializes 3 audio elements during user gesture
- Unlocks audio for non-gesture triggers (distance/timer)
- Works around iOS Safari audio restrictions

```javascript
const audioPool = [];
const AUDIO_POOL_SIZE = 3;

async function initializeAudioPool() {
    const silentUrl = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10...';

    for (let i = 0; i < AUDIO_POOL_SIZE; i++) {
        const audio = new Audio();
        audio.src = silentUrl;
        await audio.play();
        audio.pause();
        audioPool.push(audio);
    }
}
```

**Console Logs**:
```
🎲 [VOICE] Using random voice: en-US-BrandonNeural
✅ [AUDIO-POOL] Audio pool initialized (3 elements)
```

**Note**: Audio ducking for background music doesn't work on iOS Safari - browser limitation prevents mixing web audio with external apps (Apple Music, Spotify). This is an OS-level restriction.

---

### 8. Map Marker Improvements

**Color-Coded Markers** (index.html ~line 2173):
- Current fact: RED (#DC2626), 30x30px (prominent)
- Previous facts: GRAY (#9CA3AF), 24x24px, 70% opacity (subtle)
- Automatically updates when new fact is added

```javascript
function addFactMarker(coords, factText) {
    // Change all previous markers to gray
    factMarkers.forEach(markerData => {
        markerData.marker.setIcon(L.divIcon({
            className: 'fact-marker-previous',
            html: '<div style="background: #9CA3AF; ..." >📍</div>',
            iconSize: [24, 24]
        }));
    });

    // Add new red marker
    const marker = L.marker([coords.lat, coords.lon], {
        icon: L.divIcon({
            className: 'fact-marker-current',
            html: '<div style="background: #DC2626; ..." >📍</div>',
            iconSize: [30, 30]
        })
    }).addTo(map);

    factMarkers.push({ marker, coords, text: factText });
}
```

**Console Logs**:
```
🔄 [FACT-MARKER] Changed 3 previous marker(s) to gray
📍 [FACT-MARKER] Added red marker at 39.7939, -86.2347 (current fact)
```

---

## File Locations Summary

### Production Files
```
/home/jay/projects/number one test/
├── index.html              # Main app (all RoadWise code)
├── claude-proxy.js         # Claude API proxy (port 3002)
├── claude-proxy.service    # Systemd service
├── chase-log-server.js     # Chase log server (port 9998)
├── chase-log.service       # Systemd service
├── chase-log.json          # JSON log of all facts
├── maps-app.service        # Main app systemd service
└── CLAUDE.md               # This documentation
```

### Systemd Services
```
/etc/systemd/system/
├── maps-app.service         # Port 8001
├── claude-proxy.service     # Port 3002
└── chase-log.service        # Port 9998
```

### Key Code Sections (index.html)
```
Line ~269:   Speed display (removed heading)
Line ~1223:  factHistory array (AI summaries)
Line ~1480:  Audio pool for iOS
Line ~1591:  Random voice selection
Line ~2077:  GPS tracking with Android fixes
Line ~2173:  Map markers (color-coded)
Line ~2241:  Chase log function
Line ~2293:  State capitals lookup
Line ~2311:  Coordinate validation
Line ~2470:  generateRoadWisePrompt()
Line ~2501:  Anti-repetition instructions
Line ~2593:  Summary output format
Line ~2703:  Claude proxy URL selection
Line ~2785:  Summary extraction
```

### Logs & Monitoring
```bash
# App logs
sudo journalctl -u maps-app.service -f

# Claude proxy logs (detailed)
sudo journalctl -u claude-proxy.service -f

# Chase log server logs
sudo journalctl -u chase-log.service -f

# Browser console (F12)
# Look for emoji-prefixed logs:
# 📝 [FACT-SUMMARY]
# 📚 [FACT-HISTORY]
# 🌐 [CLAUDE]
# 📏 [COORD-VALIDATE]
# 🛰️ [TRACKING]
```

---

## Access URLs

**Production (Tailscale Funnel)**:
- App: https://jaslinux.tail23d264.ts.net/maps
- Claude Proxy: https://jaslinux.tail23d264.ts.net/claude-proxy
- Chase Log API: Not exposed (LAN only)

**Local Network**:
- App: http://192.168.3.142:8001
- Claude Proxy: http://192.168.3.142:3002
- Chase Log: http://192.168.3.142:9998/chaselog

---

## Troubleshooting Guide

### Claude API Not Working

**Symptoms**: Button click shows "Load failed" error

**Diagnosis**:
```bash
# Check proxy status
sudo systemctl status claude-proxy.service

# Test proxy directly (HTTP)
curl -X POST http://192.168.3.142:3002/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-haiku-20240307","max_tokens":100,"messages":[{"role":"user","content":"test"}]}'

# Test proxy via Tailscale Funnel (HTTPS)
curl -X POST https://jaslinux.tail23d264.ts.net/claude-proxy/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model":"claude-3-haiku-20240307","max_tokens":100,"messages":[{"role":"user","content":"test"}]}'

# Check Tailscale Funnel
sudo tailscale funnel status

# View proxy logs
sudo journalctl -u claude-proxy.service -n 50
```

**Common Fixes**:
- Restart proxy: `sudo systemctl restart claude-proxy.service`
- Hard refresh browser: Ctrl+Shift+R (clear cache)
- Check browser console for detailed error logs

---

### Facts Repeating

**Symptoms**: Same or similar topics despite anti-repetition system

**Diagnosis**:
```bash
# Check browser console (F12) for:
📝 [FACT-SUMMARY] AI provided summary: "..."
📚 [FACT-HISTORY] Total summaries tracked: N

# If summaries not being extracted:
⚠️ [FACT-SUMMARY] No Summary line found, using fallback
```

**Fixes**:
- Check AI response includes `Summary: ...` line
- Verify summary extraction regex: `/Summary:\s*(.+)/i`
- Check factHistory array length (should track up to 30)
- Clear history and restart session (refresh page)

**Verify Prompt**:
- Should show: `Previously used topics in this drive (AVOID these): summary1 | summary2 | ...`
- Check prompt instructions emphasize variety (line ~2501)

---

### Chase Log Not Saving

**Symptoms**: No facts appearing in chase-log.json

**Diagnosis**:
```bash
# Check service
sudo systemctl status chase-log.service

# Check file exists and permissions
ls -la "/home/jay/projects/number one test/chase-log.json"

# View recent logs
sudo journalctl -u chase-log.service -n 20

# Test endpoint directly
curl http://192.168.3.142:9998/chaselog

# Try manual POST
curl -X POST http://192.168.3.142:9998/chaselog \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2025-11-28T20:00:00.000Z","coords":"39.7,-86.4","speed":"45 mph","heading":"180","fact":"Test fact","summary":"test"}'
```

**Common Fixes**:
- Restart service: `sudo systemctl restart chase-log.service`
- Check firewall: `sudo ufw status | grep 9998`
- Create file manually: `echo "[]" > "/home/jay/projects/number one test/chase-log.json"`
- Check browser console for `📝 [CHASE-LOG]` messages

---

### GPS Issues (Android)

**Symptoms**: Stuck on "🛰️ Initializing GPS..." or "⏱️ GPS timeout"

**Diagnosis**:
- Wait 60 seconds for cold start (especially indoors)
- Check browser console for GPS error codes
- Look for `✅ [TRACKING] First GPS fix acquired!`

**Error Codes**:
- Code 1: Permission denied (need to grant location permission)
- Code 2: Position unavailable (GPS hardware issue or indoors)
- Code 3: Timeout (need to wait longer or move outdoors)

**Fixes**:
- Grant location permission in browser settings
- Move outdoors for better GPS signal
- Enable "High Accuracy" mode in Android location settings
- Wait full 60 seconds before giving up
- Check for fallback location: "Using test GPS location"

---

### Map Markers Not Appearing

**Symptoms**: Facts play but no markers on map

**Diagnosis**:
```bash
# Check browser console for:
🔍 [FACT-MARKER] Attempting to extract coordinates...
📍 [FACT-MARKER] Added red marker at 39.7939, -86.2347

# If no coordinates:
⚠️ [FACT-MARKER] No coordinates found in fact
```

**Fixes**:
- Verify fact includes coordinate metadata lines
- Check coordinate extraction regex patterns (line ~2331)
- Verify coordinates pass validation (<100 miles)
- Check Leaflet.js loaded: `typeof L !== 'undefined'`

---

### Voice Not Working (iOS)

**Symptoms**: Facts appear but no audio

**Diagnosis**:
- Check audio pool initialization
- Look for `✅ [AUDIO-POOL] Audio pool initialized`
- Check for iOS audio gesture errors

**Fixes**:
- Tap screen before using (initialize audio pool)
- Check iOS silent switch is OFF
- Increase device volume
- Grant microphone/audio permissions if prompted
- Try different voice in settings

---

## Performance & Optimization

**Token Usage**:
- factHistory summaries: ~5 words × 30 = ~150 tokens
- Old approach: ~50 chars × 20 = ~1000 tokens
- **Savings**: 850 tokens per request for more facts!

**Session Management**:
- Each page load = new sessionId (Date.now())
- factHistory cleared on refresh
- Chase log persists across sessions
- Can review past topics via chase-log.json

**Best Practices**:
- Keep summaries 2-5 words
- Track 30 max summaries (balance variety vs prompt size)
- Use state capitals for >100mi coordinates
- Random voices for variety
- Hard refresh browser after updates (Ctrl+Shift+R)

---

## Version History

**v1.0** (Oct 2025) - Initial RoadWise with OpenAI POI discovery  
**v1.1** (Nov 2025) - Added Azure TTS, distance-based triggering  
**v1.2** (Nov 2025) - Claude API integration, session persistence  
**v1.3** (Nov 2025) - Chase log system (JSON format)  
**v1.4** (Nov 2025) - AI-generated fact summaries, anti-repetition  
**v1.5** (Nov 2025) - Coordinate validation, Android GPS fixes  
**v1.6** (Nov 2025) - UI improvements, voice randomization, marker colors  
**v1.7** (Nov 28, 2025) - Claude HTTPS proxy via Tailscale Funnel (current)  

---

*Last Updated: 2025-11-28 23:00 EST - Comprehensive v1.7 Documentation*
