---
title: Drizz Clone — Local macOS App Specification
type: analysis
created: 2026-04-10
updated: 2026-04-10
tags: [spec, macos, vision-ai, mobile-testing, drizz-clone]
sources: [ios-e2e-testing-research-2026, drizz]
---

# Drizz Clone — Local macOS App Specification

A local, open-source macOS application that uses Vision AI to automate mobile E2E testing. Tests are written in plain English and executed on iOS/Android simulators AND real physical devices by "seeing" the screen — no selectors, no accessibility IDs, no source code required. Includes a headless CLI runner for CI/CD pipelines.

**Codename:** Iris

## 1. Goals

### What we're building

**Two deliverables:**

1. **Iris.app** — Native macOS desktop app (SwiftUI GUI) for authoring and running tests interactively
2. **iris** CLI — Headless command-line runner for CI/CD pipelines, sharing the same core engine

Both support:
1. iOS Simulators (`simctl`) + **real iOS devices** (via WebDriverAgent over USB/network)
2. Android Emulators + **real Android devices** (via `adb` — works identically)
3. Vision AI screenshot analysis → element identification → coordinate-based execution
4. Visual cache to avoid redundant VLM calls
5. Step-level screenshots, timing, and pass/fail reporting

### What we're NOT building (MVP)
- Cloud execution platform (managed device farm)
- Multi-user collaboration / team features
- Test generation AI (Fathom equivalent)
- Web dashboard

### Key differentiators vs Drizz
- **Fully local** — no cloud dependency for execution
- **Open source** — transparent, extensible, no vendor lock-in
- **Claude Code integration** — uses Claude's native vision capabilities via Claude Code (tool use + screenshot reading) as the primary VLM engine. No separate API key management needed.
- **Free** — no per-run pricing beyond existing Claude Code subscription

## 2. Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                        Iris                                    │
│                                                                │
│  ┌────────────────────────┐    ┌───────────────────────────┐   │
│  │     Iris.app (GUI)     │    │      iris CLI             │   │
│  │                        │    │                           │   │
│  │  Editor │ Runner │ Res │    │  $ iris run test.yaml     │   │
│  └────────┬───────────────┘    │  $ iris run tests/ --junit│   │
│           │                    └─────────┬─────────────────┘   │
│           └──────────┬──────────────────┘                      │
│                      │                                         │
│  ┌───────────────────┴──────────────────────────────────────┐  │
│  │                    Core Engine                            │  │
│  │                  (shared library)                         │  │
│  │                                                           │  │
│  │  ┌──────────┐ ┌──────────┐ ┌───────┐ ┌───────────────┐   │  │
│  │  │ Device   │ │ Vision   │ │ Visual│ │   Reporter    │   │  │
│  │  │ Bridge   │ │ AI       │ │ Cache │ │ (JSON/JUnit/  │   │  │
│  │  │          │ │ Pipeline │ │       │ │  HTML)        │   │  │
│  │  └────┬─────┘ └────┬─────┘ └───┬───┘ └───────────────┘   │  │
│  └───────┼────────────┼────────────┼─────────────────────────┘  │
│          │            │            │                             │
└──────────┼────────────┼────────────┼─────────────────────────────┘
           │            │            │
  ┌────────┴────────┐ ┌─┴──┐  ┌─────┴─────┐
  │ simctl / adb /  │ │VLM │  │  SQLite   │
  │ WDA (real iOS)  │ │API │  │  Cache DB │
  └─────────────────┘ └────┘  └───────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **Iris.app (GUI)** | Interactive test authoring, device preview, visual results |
| **iris CLI** | Headless test execution for CI/CD, JUnit/JSON output, exit codes |
| **Core Engine** | Shared library: test parsing, step execution, VLM calls, caching |
| **Device Bridge** | Abstract simulators, emulators, and **real physical devices** |
| **Vision AI Pipeline** | Screenshot → VLM analysis → element identification → coordinate mapping |
| **Visual Cache** | Store screen state embeddings, match against cache before calling VLM |
| **Reporter** | Generate results in JSON, JUnit XML, and HTML formats |

## 3. Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **App framework** | Swift + SwiftUI | Native macOS, best performance, first-class Xcode integration |
| **CLI framework** | Swift ArgumentParser | Same language as GUI, shares core engine |
| **Device control (iOS sim)** | `xcrun simctl` CLI | Standard Apple tool, no dependencies |
| **Device control (iOS real)** | WebDriverAgent (WDA) over USB/Wi-Fi | Proven approach (same as Appium uses), XCTest-based |
| **Device control (Android)** | `adb` CLI | Works identically for emulators and real devices |
| **Screenshot (iOS sim)** | `simctl io booted screenshot` | Native, fast, reliable |
| **Screenshot (iOS real)** | WDA screenshot endpoint | HTTP GET to WDA server |
| **Screenshot (Android)** | `adb exec-out screencap -p` | Works for emulators and real devices |
| **Input (iOS sim)** | `simctl io booted input` | Native simulator input |
| **Input (iOS real)** | WDA touch/type endpoints | HTTP POST to WDA server |
| **Input (Android)** | `adb shell input tap/text/swipe` | Works for emulators and real devices |
| **Vision AI** | Claude Code integration (Read tool for screenshots) | Native vision capabilities, no separate API keys, leverages existing Claude Code session |
| **Visual cache** | SQLite + perceptual hashing (pHash) | Fast local lookup, no external dependency |
| **Image processing** | CoreImage / Vision.framework | Native macOS frameworks for image analysis |
| **Test file format** | YAML | Simple, human-readable, Git-friendly |
| **Data persistence** | SQLite (via GRDB.swift) | Lightweight, embedded |
| **Report formats** | JUnit XML, JSON, HTML | JUnit for CI integration, JSON for programmatic access, HTML for humans |

## 4. Test File Format

Tests are YAML files with plain-English steps:

```yaml
# login-test.yaml
name: Login Flow
app:
  platform: ios
  bundleId: com.example.myapp  # or apk path for Android
  # device: "iPhone 16 Pro"    # optional, uses booted device by default

steps:
  - tap: "Login"
  - tap: "Email field"
  - type: "test@example.com"
  - tap: "Password field"
  - type: "secret123"
  - tap: "Sign In"
  - wait: 3                     # seconds
  - assert: "Welcome back"      # verify text is visible
  - screenshot: "login-success" # save named screenshot
```

### Step Types

| Step | Syntax | Description |
|------|--------|-------------|
| **tap** | `tap: "Login button"` | Tap on element matching description |
| **type** | `type: "hello world"` | Type text into the currently focused field |
| **swipe** | `swipe: "up"` / `swipe: "left on product list"` | Swipe in a direction, optionally on a specific element |
| **assert** | `assert: "Welcome"` | Verify text or element is visible on screen |
| **wait** | `wait: 3` | Wait N seconds |
| **screenshot** | `screenshot: "step-name"` | Save a named screenshot |
| **back** | `back` | Press back / navigate back |
| **launch** | `launch` | (Re)launch the app |
| **clear** | `clear` | Clear app state |
| **scroll** | `scroll: "down until 'Load More' is visible"` | Scroll with a condition |
| **long_press** | `long_press: "Delete button"` | Long press on element |
| **set_location** | `set_location: { lat: 37.7749, lon: -122.4194 }` | Mock GPS location |

### Advanced Features (Post-MVP)

```yaml
# Reusable flows
include: flows/login.yaml

# Variables
env:
  EMAIL: ${TEST_EMAIL}
  PASSWORD: ${TEST_PASSWORD}

# Conditional
steps:
  - if_visible: "Cookie Banner"
    then:
      - tap: "Accept"

# Repeat
steps:
  - repeat: 3
    steps:
      - swipe: "left on card"
```

## 5. Vision AI Pipeline — Claude Code Integration

Instead of managing separate VLM API keys and HTTP clients, Iris leverages **Claude Code's native vision capabilities**. Claude Code can read screenshot images directly via its `Read` tool. The iris CLI is designed to run **as a Claude Code tool or sub-process**, passing screenshots to Claude for analysis within the existing session.

### How It Works

```
1. Capture screenshot from device → save to temp file
         │
2. Check visual cache (pHash similarity)
         │
    ┌─────┴─────┐
    │ Cache HIT  │──→ Use cached element coordinates → Execute action
    └─────┬─────┘
          │ Cache MISS
          ▼
3. Claude Code reads the screenshot (via Read tool — native image support)
   and processes a structured prompt:

   "Analyze this mobile app screenshot at /tmp/iris_step3.png.
    Find the UI element: 'Login button'.
    Return JSON: { found, element, x, y, width, height, confidence }"
         │
4. Parse Claude's response → extract coordinates
         │
5. Store in visual cache (screenshot hash → coordinates)
         │
6. Execute action at coordinates via simctl/adb/WDA
         │
7. Wait for UI to settle (screen-diff stability check)
         │
8. Capture post-action screenshot for results
```

### Integration Approach

The iris CLI acts as a **Claude Code skill or hook** — Claude Code orchestrates the test execution by:

1. Reading the YAML test file
2. For each step, calling `iris` CLI commands to capture screenshots and execute actions
3. Using its own vision to analyze screenshots and determine element coordinates
4. Passing coordinates back to `iris` for action execution

```bash
# Claude Code runs iris as a tool:
$ iris screenshot --device "iPhone 16 Pro" --output /tmp/current.png
# → Claude reads /tmp/current.png with its native vision
# → Claude determines: "Login button is at (187, 423)"
$ iris tap --device "iPhone 16 Pro" --x 187 --y 423
$ iris screenshot --device "iPhone 16 Pro" --output /tmp/after_tap.png
# → Claude reads the result screenshot to verify
```

### Alternative: Standalone Mode with Direct API

For running without Claude Code (e.g., in CI with a plain API key), iris also supports direct Anthropic API calls:

```swift
protocol VisionAnalyzer {
    func findElement(screenshot: URL, description: String) async throws -> ElementResult
    func assertVisible(screenshot: URL, description: String) async throws -> AssertResult
}

struct ElementResult {
    let found: Bool
    let element: String
    let x: Int, y: Int
    let width: Int, height: Int
    let confidence: Double
}

// Primary: Claude Code integration (uses Claude's built-in vision)
class ClaudeCodeAnalyzer: VisionAnalyzer {
    // Outputs structured prompts that Claude Code processes
    // Screenshots are read by Claude natively via Read tool
}

// Fallback: Direct Anthropic API (for CI/CD without Claude Code)
class AnthropicAPIAnalyzer: VisionAnalyzer {
    // POST to messages API with base64 image + structured prompt
    let apiKey: String  // from ANTHROPIC_API_KEY env var
}
```

### Prompt Design

**For `tap` steps:**
```
Analyze this mobile app screenshot. Find the UI element that best matches: "{description}".
Return a JSON object with: found (bool), element (what you found), x (center x coordinate), 
y (center y coordinate), width, height, confidence (0-1).
The screenshot dimensions are {width}x{height} pixels.
If multiple elements match, return the most prominent/likely one.
If no element matches, set found=false and explain in element field.
```

**For `assert` steps:**
```
Analyze this mobile app screenshot. Is the following visible on screen: "{description}"?
Return JSON: { "visible": true/false, "evidence": "what you see", "confidence": 0-1 }
```

## 6. Visual Cache System

### Design

Each screenshot is hashed using perceptual hashing (pHash). Before calling the VLM, the current screenshot's hash is compared against cached entries.

```
┌─────────────────────────────────────┐
│           Visual Cache DB           │
│          (SQLite table)             │
├─────────┬──────────┬────────┬───────┤
│ phash   │ step_desc│ result │ ts    │
│ (uint64)│ (text)   │ (json) │ (int) │
├─────────┼──────────┼────────┼───────┤
│ 0xA3F...│ "Login"  │ {x,y} │ 17...│
└─────────┴──────────┴────────┴───────┘
```

### Cache Lookup Logic

```
1. Capture screenshot → compute pHash
2. Query: SELECT * FROM cache WHERE hamming_distance(phash, ?) < threshold AND step_desc = ?
3. If match found (distance < 8 bits):
   → Return cached coordinates
   → Log: "Cache HIT (distance=3)"
4. If no match:
   → Call VLM
   → Store result: INSERT INTO cache (phash, step_desc, result, ts)
   → Log: "Cache MISS → VLM call"
```

### Cache Invalidation
- TTL-based: entries older than N days auto-expire (configurable, default 7 days)
- Manual: user can clear cache per test or globally
- Threshold tuning: hamming distance threshold configurable (default 8 out of 64 bits)

## 7. Device Bridge

### Device Type Matrix

| | iOS Simulator | iOS Real Device | Android Emulator | Android Real Device |
|--|---------------|-----------------|------------------|---------------------|
| **Screenshot** | `simctl io screenshot` | WDA `/screenshot` | `adb screencap` | `adb screencap` |
| **Tap** | `simctl io input tap` | WDA `/wda/tap` | `adb input tap` | `adb input tap` |
| **Type** | `simctl io input text` | WDA `/wda/keys` | `adb input text` | `adb input text` |
| **Swipe** | `simctl io input swipe` | WDA `/wda/dragfromtoforduration` | `adb input swipe` | `adb input swipe` |
| **Install app** | `simctl install` | `devicectl install` | `adb install` | `adb install` |
| **Launch app** | `simctl launch` | WDA `/wda/apps/launch` | `adb shell am start` | `adb shell am start` |
| **Setup** | Xcode only | Xcode + provisioning profile + WDA build | Android SDK | USB debugging on |
| **CI/CD friendly** | Yes (headless) | Yes (USB connected Mac) | Yes (headless) | Yes (USB or network) |

### iOS Simulator Bridge

```swift
struct iOSSimulatorBridge: DeviceBridge {
    func listDevices() -> [Device] {
        // xcrun simctl list devices --json
    }
    
    func bootDevice(_ udid: String) {
        // xcrun simctl boot {udid}
    }
    
    func installApp(_ path: String, on udid: String) {
        // xcrun simctl install {udid} {path}
    }
    
    func launchApp(_ bundleId: String, on udid: String) {
        // xcrun simctl launch {udid} {bundleId}
    }
    
    func screenshot() -> CGImage {
        // xcrun simctl io booted screenshot --type=png /tmp/iris_screenshot.png
    }
    
    func tap(x: Int, y: Int) {
        // xcrun simctl io booted input tap {x} {y}
        // Note: simctl input requires Xcode 16+
        // Fallback: use AppleScript + Accessibility to click on simulator window
    }
    
    func typeText(_ text: String) {
        // xcrun simctl io booted input text "{text}"
    }
    
    func swipe(from: CGPoint, to: CGPoint, duration: Double) {
        // xcrun simctl io booted input swipe {x1} {y1} {x2} {y2} {duration}
    }
    
    func setLocation(lat: Double, lon: Double) {
        // xcrun simctl location booted set {lat},{lon}
    }
    
    func terminateApp(_ bundleId: String) {
        // xcrun simctl terminate booted {bundleId}
    }
    
    func clearAppData(_ bundleId: String) {
        // xcrun simctl privacy booted reset all {bundleId}
        // + delete app container
    }
}
```

### Android Emulator Bridge

```swift
struct AndroidEmulatorBridge: DeviceBridge {
    func listDevices() -> [Device] {
        // adb devices -l
    }
    
    func screenshot() -> CGImage {
        // adb exec-out screencap -p > /tmp/iris_screenshot.png
    }
    
    func tap(x: Int, y: Int) {
        // adb shell input tap {x} {y}
    }
    
    func typeText(_ text: String) {
        // adb shell input text "{escaped_text}"
    }
    
    func swipe(from: CGPoint, to: CGPoint, duration: Int) {
        // adb shell input swipe {x1} {y1} {x2} {y2} {duration_ms}
    }
    
    func pressBack() {
        // adb shell input keyevent KEYCODE_BACK
    }
    
    func installApp(_ path: String) {
        // adb install {path}
    }
    
    func launchApp(_ packageName: String) {
        // adb shell monkey -p {packageName} -c android.intent.category.LAUNCHER 1
    }
}
```

### iOS Real Device Bridge (via WebDriverAgent)

The key technical challenge for real iOS devices is input injection. Unlike simulators (`simctl io input`), Apple provides no public API to send touches to a physical device. The proven solution is **WebDriverAgent (WDA)** — the same approach Appium uses.

**How WDA works:**
1. WDA is an XCTest bundle that runs on the physical device
2. It starts an HTTP server (default port 8100) on the device
3. The host machine communicates with WDA over USB (via `iproxy` port forwarding) or Wi-Fi
4. WDA translates HTTP requests into XCUITest actions (taps, types, swipes, screenshots)

```swift
struct iOSRealDeviceBridge: DeviceBridge {
    let deviceUDID: String
    let wdaBaseURL: URL  // e.g. http://localhost:8100 (port-forwarded via iproxy)

    func setup() async throws {
        // 1. Start iproxy to forward WDA port over USB
        //    iproxy 8100 8100 --udid {deviceUDID}
        //
        // 2. Build and install WDA onto the device (one-time setup)
        //    xcodebuild build-for-testing \
        //      -project WebDriverAgent.xcodeproj \
        //      -scheme WebDriverAgentRunner \
        //      -destination "id={deviceUDID}" \
        //      -allowProvisioningUpdates
        //
        // 3. Launch WDA test runner on device
        //    xcodebuild test-without-building \
        //      -project WebDriverAgent.xcodeproj \
        //      -scheme WebDriverAgentRunner \
        //      -destination "id={deviceUDID}"
    }

    func screenshot() async throws -> CGImage {
        // GET {wdaBaseURL}/screenshot
        // Returns base64-encoded PNG
    }

    func tap(x: Int, y: Int) async throws {
        // POST {wdaBaseURL}/wda/tap/0
        // Body: { "x": x, "y": y }
    }

    func typeText(_ text: String) async throws {
        // POST {wdaBaseURL}/wda/keys
        // Body: { "value": [characters] }
    }

    func swipe(from: CGPoint, to: CGPoint, duration: Double) async throws {
        // POST {wdaBaseURL}/wda/dragfromtoforduration
        // Body: { "fromX": .., "fromY": .., "toX": .., "toY": .., "duration": .. }
    }

    func launchApp(_ bundleId: String) async throws {
        // POST {wdaBaseURL}/wda/apps/launch
        // Body: { "bundleId": bundleId }
    }

    func installApp(_ path: String) async throws {
        // xcrun devicectl device install app --device {deviceUDID} {path}
        // (Xcode 15+) or ios-deploy --id {deviceUDID} --bundle {path}
    }

    func listDevices() async -> [Device] {
        // xcrun devicectl list devices --json-output /dev/stdout
        // or: system_profiler SPUSBDataType | grep iPhone
    }
}
```

**WDA setup requirements:**
- Apple Developer account (free or paid) for code signing
- Xcode with the device's iOS version SDK
- First-time provisioning profile trust on the device (Settings → General → Device Management)
- USB cable or same Wi-Fi network for network-based testing

**WDA source:** Appium maintains WDA as open source at `github.com/appium/WebDriverAgent`. We bundle a pre-built version or build from source during `iris setup`.

**Simplifying the setup — `iris setup` command:**
```bash
# One-time setup for real iOS device testing
$ iris setup ios-device
  → Detecting connected devices...
  → Found: iPhone 16 Pro (UDID: 00008110-...)
  → Building WebDriverAgent...
  → Signing with team: XXXXXXXXXX
  → Installing WDA on device...
  → Trust the developer profile on your device (Settings → General → Device Management)
  → Press Enter when done...
  → Starting WDA... ✅ Ready at http://localhost:8100
  → Device "iPhone 16 Pro" is ready for testing.
```

### DeviceBridge Protocol

```swift
protocol DeviceBridge {
    var deviceInfo: Device { get }
    func screenshot() async throws -> CGImage
    func tap(x: Int, y: Int) async throws
    func typeText(_ text: String) async throws
    func swipe(from: CGPoint, to: CGPoint, duration: Double) async throws
    func launchApp(_ identifier: String) async throws
    func terminateApp(_ identifier: String) async throws
    func installApp(_ path: String) async throws
}

struct Device {
    let id: String              // UDID or serial
    let name: String            // "iPhone 16 Pro" or "Pixel 8"
    let platform: Platform      // .ios or .android
    let osVersion: String       // "18.4" or "15"
    let state: DeviceState      // .booted, .shutdown, .connected
    let isPhysical: Bool        // true for real devices, false for simulators/emulators
    let connectionType: ConnectionType  // .usb, .wifi, .local (simulator)
}

enum ConnectionType { case usb, wifi, local }
```

### DeviceManager — Unified Discovery

```swift
class DeviceManager {
    /// Discovers all available devices across all bridges
    func discoverDevices() async -> [Device] {
        async let simulators = iOSSimulatorBridge.listDevices()
        async let realIOS = iOSRealDeviceBridge.listDevices()
        async let android = AndroidBridge.listDevices()  // covers both emulator + real
        return await simulators + realIOS + android
    }

    /// Returns the appropriate bridge for a given device
    func bridge(for device: Device) -> DeviceBridge {
        switch (device.platform, device.isPhysical) {
        case (.ios, false):  return iOSSimulatorBridge(deviceUDID: device.id)
        case (.ios, true):   return iOSRealDeviceBridge(deviceUDID: device.id)
        case (.android, _):  return AndroidBridge(serial: device.id)  // adb works for both
        }
    }
}
```

## 8. UI Design

### Main Window Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Iris                                          ⚙️  ▶️ Run   │
├──────────────┬──────────────────────┬───────────────────────┤
│              │                      │                       │
│  📁 Tests    │   Test Editor        │   Device Preview      │
│              │                      │                       │
│  ▸ login.yml │   name: Login Flow   │  ┌─────────────────┐  │
│  ▸ cart.yml  │   app:               │  │                 │  │
│  ▸ search.yml│     platform: ios    │  │   [Simulator    │  │
│              │     bundleId: ...    │  │    Mirror]      │  │
│              │                      │  │                 │  │
│  📱 Devices  │   steps:             │  │                 │  │
│              │     - tap: "Login"   │  │                 │  │
│  ● iPhone 16 │     - type: "email"  │  │                 │  │
│  ○ Pixel 8   │     - tap: "Submit"  │  │                 │  │
│              │     - assert: "Hi"   │  └─────────────────┘  │
│              │                      │                       │
│  🔧 Settings │                      │  Step: 2/4  ⏱ 12.3s  │
│              │                      │  Status: ● Running    │
├──────────────┴──────────────────────┴───────────────────────┤
│  Run Log                                                    │
│  ✅ Step 1: tap "Login" (0.8s, cache HIT)                   │
│  ✅ Step 2: type "email" (0.3s)                             │
│  ⏳ Step 3: tap "Submit" (calling VLM...)                   │
│  ○ Step 4: assert "Welcome"                                 │
└─────────────────────────────────────────────────────────────┘
```

### Settings Panel

```
┌─────────────────────────────────────┐
│  Settings                           │
├─────────────────────────────────────┤
│                                     │
│  Vision Provider                    │
│  ┌─────────────────────────────┐    │
│  │ ● Claude Code (integrated)  │    │
│  │ ○ Anthropic API (direct)    │    │
│  └─────────────────────────────┘    │
│                                     │
│  API Key: sk-••••••••••••••••       │
│  (only for direct API mode)         │
│  Model:   claude-sonnet-4-6  ▼     │
│                                     │
│  ── Cache ──                        │
│  Cache TTL:     [7] days            │
│  Hash threshold: [8] bits           │
│  [Clear Cache]                      │
│                                     │
│  ── Execution ──                    │
│  Step delay:    [1.0] sec           │
│  VLM timeout:   [30] sec           │
│  Screenshot scale: [2x] ▼          │
│                                     │
│  ── Paths ──                        │
│  Tests dir:  ~/iris-tests           │
│  Results dir: ~/iris-results        │
│                                     │
└─────────────────────────────────────┘
```

### Results View

```
┌─────────────────────────────────────────────────────────────┐
│  Results: login-test.yaml                    📅 2026-04-10  │
│  Duration: 18.4s  |  Steps: 4/4  |  Status: ✅ PASSED      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: tap "Login"                          ✅ 2.1s      │
│  ┌────────────────────┐  ┌────────────────────┐            │
│  │ Before             │  │ After              │            │
│  │ [screenshot]       │  │ [screenshot]       │            │
│  └────────────────────┘  └────────────────────┘            │
│  VLM: Found "Login" button at (187, 423), confidence 0.97  │
│  Source: Cache HIT (distance=2)                             │
│                                                             │
│  Step 2: type "test@example.com"              ✅ 0.5s      │
│  ...                                                        │
│                                                             │
│  Step 3: tap "Sign In"                        ✅ 8.2s      │
│  ┌────────────────────┐  ┌────────────────────┐            │
│  │ Before             │  │ After              │            │
│  │ [screenshot]       │  │ [screenshot]       │            │
│  └────────────────────┘  └────────────────────┘            │
│  VLM: Found "Sign In" button at (200, 580), confidence 0.94│
│  Source: Cache MISS → VLM call (model: claude-sonnet-4-6)  │
│                                                             │
│  Step 4: assert "Welcome back"                ✅ 1.6s      │
│  VLM: Text "Welcome back" found at (160, 120), conf 0.99   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 9. CLI Runner (iris)

A headless command-line tool that shares the Core Engine with Iris.app, designed for CI/CD pipelines.

### Commands

```bash
# Run a single test
$ iris run login-test.yaml

# Run a directory of tests
$ iris run tests/

# Specify device
$ iris run login-test.yaml --device "iPhone 16 Pro"
$ iris run login-test.yaml --device "00008110-XXXX"  # by UDID

# Output formats
$ iris run tests/ --junit results/junit.xml        # JUnit XML for CI
$ iris run tests/ --json results/report.json        # JSON for programmatic use
$ iris run tests/ --html results/report.html        # HTML for humans
$ iris run tests/ --screenshots results/screenshots/ # Save all step screenshots

# VLM configuration
$ iris run tests/ --provider anthropic --model claude-sonnet-4-6
$ iris run tests/ --provider ollama --model qwen2.5-vl
$ IRIS_API_KEY=sk-... iris run tests/               # API key via env var

# Device setup
$ iris devices                                       # List all available devices
$ iris setup ios-device                              # One-time WDA setup for real iOS
$ iris setup android-device                          # Verify adb connectivity

# Cache management
$ iris cache clear                                   # Clear visual cache
$ iris cache stats                                   # Show cache hit rate stats
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tests passed |
| 1 | One or more tests failed |
| 2 | Configuration error (missing API key, no device, bad YAML) |
| 3 | Device error (device disconnected, WDA not running) |
| 4 | VLM error (API timeout, auth failure) |

### Configuration File (`.iris.yaml`)

Project-level config that the CLI reads automatically:

```yaml
# .iris.yaml (in project root)
vision:
  provider: claude-code       # "claude-code" (default) or "anthropic-api" (for standalone CI)
  model: claude-sonnet-4-6    # only used in anthropic-api mode
  # api_key: via ANTHROPIC_API_KEY env var (never in file, only for anthropic-api mode)

device:
  platform: ios
  name: "iPhone 16 Pro"     # or "any" for first available
  physical: false            # true = real device, false = simulator

cache:
  enabled: true
  ttl_days: 7
  threshold: 8

execution:
  step_delay: 1.0           # seconds between steps
  vlm_timeout: 30           # seconds
  retry_on_failure: 1       # retry failed steps N times
  screenshot_scale: 2       # @2x

output:
  dir: ./iris-results
  junit: true
  json: true
  html: false
  screenshots: true
```

### JUnit XML Output

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Iris" tests="4" failures="1" time="23.5">
  <testsuite name="login-test.yaml" tests="4" failures="1" time="23.5">
    <testcase name="tap: Login" time="2.1" classname="login-test">
    </testcase>
    <testcase name="type: test@example.com" time="0.5" classname="login-test">
    </testcase>
    <testcase name="tap: Sign In" time="8.2" classname="login-test">
    </testcase>
    <testcase name="assert: Welcome back" time="12.7" classname="login-test">
      <failure message="Text 'Welcome back' not found on screen">
        VLM response: visible=false, confidence=0.12
        Screenshot: iris-results/screenshots/login-test_step4_after.png
      </failure>
    </testcase>
  </testsuite>
</testsuites>
```

### GitHub Actions Integration

```yaml
name: E2E Tests (Iris)
on:
  push:
    branches: [main]
  pull_request:

jobs:
  e2e-ios-simulator:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-xcode@v1
        with:
          xcode-version: '16.2'

      - name: Install Iris CLI
        run: brew install iris  # or: swift build -c release && cp .build/release/iris /usr/local/bin/

      - name: Boot iOS Simulator
        run: |
          xcrun simctl boot "iPhone 16 Pro"
          xcrun simctl list | grep Booted

      - name: Install app on simulator
        run: xcrun simctl install booted ./build/MyApp.app

      - name: Run E2E tests
        env:
          IRIS_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          iris run tests/ \
            --device "iPhone 16 Pro" \
            --provider anthropic \
            --model claude-sonnet-4-6 \
            --junit results/junit.xml \
            --screenshots results/screenshots/

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-results
          path: results/

      - name: Publish JUnit results
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: Iris E2E Results
          path: results/junit.xml
          reporter: java-junit

  e2e-ios-real-device:
    runs-on: [self-hosted, macOS, has-iphone]  # self-hosted runner with USB-connected iPhone
    steps:
      - uses: actions/checkout@v4

      - name: Start WDA on device
        run: iris setup ios-device --non-interactive

      - name: Install app on device
        run: xcrun devicectl device install app --device "$DEVICE_UDID" ./build/MyApp.ipa

      - name: Run E2E tests on real device
        env:
          IRIS_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          iris run tests/ \
            --device "$DEVICE_UDID" \
            --provider anthropic \
            --junit results/junit.xml

      - name: Upload results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-real-device-results
          path: results/
```

### JSON Output Schema

```json
{
  "version": "1.0",
  "runner": "iris",
  "timestamp": "2026-04-10T14:30:00Z",
  "device": {
    "id": "XXXX-XXXX",
    "name": "iPhone 16 Pro",
    "platform": "ios",
    "osVersion": "18.4",
    "isPhysical": true
  },
  "provider": { "name": "anthropic", "model": "claude-sonnet-4-6" },
  "summary": {
    "total": 4,
    "passed": 3,
    "failed": 1,
    "duration": 23.5,
    "cacheHitRate": 0.75
  },
  "tests": [
    {
      "file": "login-test.yaml",
      "name": "Login Flow",
      "status": "failed",
      "duration": 23.5,
      "steps": [
        {
          "index": 0,
          "type": "tap",
          "description": "Login",
          "status": "passed",
          "duration": 2.1,
          "cacheHit": true,
          "vlm": { "x": 187, "y": 423, "confidence": 0.97 },
          "screenshots": {
            "before": "screenshots/login-test_step0_before.png",
            "after": "screenshots/login-test_step0_after.png"
          }
        }
      ]
    }
  ]
}
```

## 10. Project Structure

```
iris/
├── Package.swift                       # SPM: shared core + CLI executable
├── Iris.xcodeproj                      # Xcode project for GUI app
│
├── Sources/
│   ├── IrisCore/                       # Shared library (used by both GUI and CLI)
│   │   ├── TestRunner.swift            # Orchestrates test execution
│   │   ├── TestParser.swift            # YAML → [TestStep] parsing
│   │   ├── StepExecutor.swift          # Executes individual steps
│   │   ├── Models.swift                # TestFile, TestStep, TestResult, etc.
│   │   ├── Config.swift                # .iris.yaml parsing + env vars
│   │   │
│   │   ├── Vision/
│   │   │   ├── VisionAnalyzer.swift    # Protocol
│   │   │   ├── ClaudeCodeAnalyzer.swift # Primary: Claude Code vision integration
│   │   │   ├── AnthropicAPIAnalyzer.swift # Fallback: direct API for CI/CD
│   │   │   └── PromptBuilder.swift     # Constructs prompts per step type
│   │   │
│   │   ├── Device/
│   │   │   ├── DeviceBridge.swift      # Protocol
│   │   │   ├── DeviceManager.swift     # Unified discovery across all bridges
│   │   │   ├── iOSSimulatorBridge.swift    # simctl wrapper
│   │   │   ├── iOSRealDeviceBridge.swift   # WDA HTTP client
│   │   │   ├── WDAManager.swift            # Build, install, launch WDA
│   │   │   └── AndroidBridge.swift         # adb wrapper (emulator + real)
│   │   │
│   │   ├── Cache/
│   │   │   ├── VisualCache.swift       # Cache lookup + storage
│   │   │   ├── PerceptualHash.swift    # pHash implementation
│   │   │   └── CacheDB.swift          # SQLite operations
│   │   │
│   │   ├── Reporter/
│   │   │   ├── Reporter.swift          # Protocol
│   │   │   ├── JUnitReporter.swift     # JUnit XML output
│   │   │   ├── JSONReporter.swift      # JSON output
│   │   │   └── HTMLReporter.swift      # HTML report with screenshots
│   │   │
│   │   └── Util/
│   │       ├── Shell.swift             # Run CLI commands
│   │       ├── ImageUtil.swift         # Screenshot processing
│   │       └── Logger.swift            # Structured logging
│   │
│   └── IrisCLI/                        # CLI executable
│       ├── main.swift                  # Entry point
│       ├── RunCommand.swift            # iris run <test>
│       ├── DevicesCommand.swift        # iris devices
│       ├── SetupCommand.swift          # iris setup ios-device / android-device
│       └── CacheCommand.swift          # iris cache clear / stats
│
├── IrisApp/                            # macOS GUI app
│   ├── IrisApp.swift                   # App entry point
│   ├── ContentView.swift               # Main window layout
│   ├── Views/
│   │   ├── TestEditorView.swift        # YAML test editor
│   │   ├── DevicePreviewView.swift     # Live device mirror
│   │   ├── RunLogView.swift            # Step-by-step execution log
│   │   ├── ResultsView.swift           # Test results with screenshots
│   │   ├── SettingsView.swift          # Configuration panel
│   │   └── SidebarView.swift           # File tree + device list
│   └── Helpers/
│       └── AppSettings.swift           # GUI-specific settings (UserDefaults)
│
├── WebDriverAgent/                     # Bundled WDA (git submodule from appium/WebDriverAgent)
│   └── ...
│
├── Tests/
│   ├── IrisCoreTests/
│   │   ├── TestParserTests.swift
│   │   ├── PerceptualHashTests.swift
│   │   ├── VLMProviderTests.swift
│   │   ├── CacheTests.swift
│   │   └── ReporterTests.swift
│   └── IrisCLITests/
│       └── CommandTests.swift
│
└── README.md
```

## 10. Implementation Phases

### Phase 1: Core Engine + CLI (Week 1-2)
- [ ] Swift Package (SPM) with `IrisCore` library + `IrisCLI` executable
- [ ] `Shell.swift` — async CLI command runner
- [ ] `iOSSimulatorBridge` — list devices, boot, screenshot, tap, type
- [ ] `TestParser` — YAML → `[TestStep]` (basic steps: tap, type, assert, wait)
- [ ] `iris devices` and `iris screenshot` CLI commands
- [ ] `.iris.yaml` config file parsing
- **Milestone:** `iris devices` lists simulators, `iris screenshot` captures a PNG

### Phase 2: Vision AI + End-to-End (Week 3-4)
- [ ] `ClaudeCodeAnalyzer` — integration with Claude Code's vision (primary)
- [ ] `AnthropicAPIAnalyzer` — direct API fallback for CI/CD
- [ ] `PromptBuilder` — construct prompts for tap, assert, swipe
- [ ] `StepExecutor` — screenshot → vision analysis → parse response → execute action
- [ ] `TestRunner` — run all steps sequentially, collect results
- [ ] `iris run test.yaml` working end-to-end
- [ ] JUnit XML + JSON reporters
- **Milestone:** `iris run login-test.yaml` runs a 3-step test on iOS Simulator, outputs JUnit XML

### Phase 3: Real Device Support (Week 5-6)
- [ ] Bundle WebDriverAgent (git submodule from appium/WebDriverAgent)
- [ ] `WDAManager` — build, sign, install, launch WDA on real iOS device
- [ ] `iOSRealDeviceBridge` — WDA HTTP client (screenshot, tap, type, swipe)
- [ ] `iris setup ios-device` — guided one-time WDA setup
- [ ] `AndroidBridge` — adb wrapper (works for emulator + real device)
- [ ] `DeviceManager` — unified discovery across all device types
- [ ] `iris setup android-device` — verify adb connectivity
- **Milestone:** Same test runs on both iOS Simulator and real iPhone via `--device`

### Phase 4: Cache + CI/CD (Week 7-8)
- [ ] `PerceptualHash` — pHash implementation using CoreImage
- [ ] `VisualCache` — SQLite-backed cache with hamming distance lookup
- [ ] Cache HIT/MISS indicators in CLI output
- [ ] `iris cache clear` and `iris cache stats` commands
- [ ] HTML reporter with embedded screenshots
- [ ] GitHub Actions workflow example (simulator + real device jobs)
- [ ] `iris run tests/` — batch execution of test directory
- [ ] Exit codes, `--junit`, `--json`, `--html`, `--screenshots` flags
- **Milestone:** Full CI/CD pipeline running on GitHub Actions with JUnit reporting

### Phase 5: GUI App + Polish (Week 9-10)
- [ ] macOS app scaffold (SwiftUI) importing `IrisCore`
- [ ] Sidebar: test file tree + device list (simulators + real devices)
- [ ] Test editor with YAML syntax highlighting
- [ ] Live device preview (stream screenshots from any device type)
- [ ] Run log with step-by-step progress
- [ ] Results view with before/after screenshots
- [ ] Settings panel: vision provider, cache config, device preferences
- [ ] Additional step types: swipe, scroll, long_press, back, set_location
- [ ] YAML syntax: variables, includes, conditionals
- **Milestone:** Full GUI app usable for interactive test authoring and execution

### Phase 6: Advanced (Week 11-12)
- [ ] Test recording: click on device preview → auto-generate YAML steps
- [ ] Element inspector: hover on device preview → show identified elements
- [ ] Parallel test execution across multiple devices
- [ ] Homebrew formula: `brew install iris`
- [ ] Error recovery: VLM failures, device disconnects, WDA crashes
- [ ] Keyboard shortcuts and Xcode-like UX polish
- **Milestone:** Production-ready for daily testing workflows

## 11. Data Models

```swift
// Test file representation
struct TestFile {
    let path: URL
    let name: String
    let app: AppConfig
    let steps: [TestStep]
}

struct AppConfig {
    let platform: Platform      // .ios, .android
    let bundleId: String?       // iOS
    let packageName: String?    // Android
    let appPath: String?        // .app or .apk path
    let device: String?         // specific device name
}

enum Platform { case ios, android }

// Test step types
enum TestStep {
    case tap(description: String)
    case type(text: String)
    case swipe(direction: String, target: String?)
    case assert(description: String)
    case wait(seconds: Double)
    case screenshot(name: String)
    case back
    case launch
    case clear
    case scroll(description: String)
    case longPress(description: String)
    case setLocation(lat: Double, lon: Double)
}

// Execution results
struct TestResult {
    let testFile: String
    let startedAt: Date
    let duration: TimeInterval
    let steps: [StepResult]
    var passed: Bool { steps.allSatisfy { $0.status == .passed } }
}

struct StepResult {
    let step: TestStep
    let status: StepStatus       // .passed, .failed, .skipped
    let duration: TimeInterval
    let screenshotBefore: URL?
    let screenshotAfter: URL?
    let vlmResponse: VLMResponse?
    let cacheHit: Bool
    let error: String?
}

enum StepStatus { case passed, failed, skipped, running }
```

## 12. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| VLM accuracy too low for reliable testing | Medium | High | Tunable prompts, confidence thresholds, fallback to user confirmation |
| `simctl io input` not available on older Xcode | Medium | Medium | Fallback to AppleScript or CGEvent-based input |
| VLM latency makes tests too slow | Low | Medium | Visual cache reduces calls by ~90%, look-ahead prefetch |
| WDA code signing complexity for real iOS devices | High | High | `iris setup` automates the process, clear error messages, docs |
| WDA crashes or disconnects mid-test | Medium | Medium | Auto-restart WDA, retry step, graceful failure with screenshots |
| pHash too coarse for similar screens | Medium | Low | Add structural comparison layer (element count, layout hash) |
| GitHub Actions macOS runners expensive for real device CI | Medium | Medium | Support self-hosted runners, document cost-effective patterns |
| SwiftUI complexity for custom editor | Low | Medium | CLI-first approach; GUI is Phase 5, not blocking |

## 13. Success Criteria

**MVP is successful when:**
1. `iris run test.yaml` executes a 5-step test on an iOS Simulator end-to-end
2. `iris run test.yaml --device <iPhone UDID>` runs the same test on a real iPhone
3. Vision AI correctly identifies and taps UI elements >90% of the time
4. Second run of the same test is >2x faster due to cache hits
5. JUnit XML output integrates with GitHub Actions test reporter
6. `iris setup ios-device` gets a real iPhone ready in <10 minutes
7. Same test runs on Android emulator/device with only `platform: android` change

## See Also

- [[drizz]] — the product this is inspired by
- [[maestro]] — YAML-based alternative (uses accessibility layer, not vision AI)
- [[e2e-testing-strategy]] — testing best practices

---

# 中文翻译

# Drizz 克隆 — 本地 macOS 应用规格说明

一个本地的、开源的 macOS 应用，使用 Vision AI 自动化移动端 E2E 测试。用纯英文编写测试，在 iOS/Android 模拟器和**真实物理设备**上执行——无需选择器、无需无障碍 ID、无需源代码。包含无头 CLI 运行器，用于 CI/CD 流水线。

**代号：** Iris

## 1. 目标

### 两个交付物：

1. **Iris.app** — 原生 macOS 桌面应用（SwiftUI GUI），用于交互式编写和运行测试
2. **iris CLI** — 无头命令行运行器，用于 CI/CD 流水线，共享相同的核心引擎

两者都支持：
- iOS 模拟器 + **真实 iOS 设备**（通过 WebDriverAgent over USB/网络）
- Android 模拟器 + **真实 Android 设备**（通过 adb）
- Claude Code 集成的视觉分析（主要方式）或直接 Anthropic API 调用（CI/CD 备选）
- 视觉缓存、逐步截图、JUnit/JSON/HTML 报告

### 与 Drizz 的关键差异
- **完全本地** — 执行不依赖云
- **开源** — 透明、可扩展、无供应商锁定
- **Claude Code 集成** — 使用 Claude 原生视觉能力，无需单独管理 API 密钥
- **免费** — 无按次运行计费

## 2. 真实设备支持

### iOS 真机

通过 **WebDriverAgent (WDA)** 实现 — 与 Appium 使用的方案相同：
1. WDA 是一个运行在真机上的 XCTest bundle
2. 在设备上启动 HTTP 服务器（端口 8100）
3. 主机通过 USB（iproxy 端口转发）或 Wi-Fi 与 WDA 通信
4. WDA 将 HTTP 请求转换为 XCUITest 操作（点击、输入、滑动、截图）

设置要求：Apple 开发者账号、Xcode、首次在设备上信任开发者证书。

`iris setup ios-device` 命令自动化整个设置过程。

### Android 真机

`adb` 对模拟器和真机的工作方式完全相同 — 这是最简单的部分。只需打开 USB 调试。

## 3. CLI 运行器

```bash
# 运行单个测试
$ iris run login-test.yaml

# 指定设备（模拟器或真机）
$ iris run login-test.yaml --device "iPhone 16 Pro"

# CI/CD 输出
$ iris run tests/ --junit results/junit.xml --screenshots results/

# 设备管理
$ iris devices                    # 列出所有可用设备
$ iris setup ios-device          # 一次性 WDA 设置
```

退出码：0=全部通过，1=有失败，2=配置错误，3=设备错误，4=VLM 错误。

### GitHub Actions 集成

支持两种 CI 场景：
- **模拟器作业**：`runs-on: macos-14`，启动模拟器，运行测试
- **真机作业**：`runs-on: [self-hosted, macOS, has-iphone]`，USB 连接的自托管运行器

## 4. Vision AI — Claude Code 集成

主要方式是通过 Claude Code 的原生视觉能力分析截图，而非管理单独的 VLM API。iris CLI 作为 Claude Code 的工具或子进程运行，截图由 Claude 原生读取。

备选方式：直接 Anthropic API 调用（适用于没有 Claude Code 的 CI/CD 环境）。

## 5. 实现阶段

| 阶段 | 时间 | 里程碑 |
|------|------|--------|
| 1. 核心引擎 + CLI | 1-2周 | `iris devices` 和 `iris screenshot` 可用 |
| 2. Vision AI + 端到端 | 3-4周 | `iris run test.yaml` 在 iOS 模拟器上运行，输出 JUnit XML |
| 3. 真机支持 | 5-6周 | 同一测试在模拟器和真实 iPhone 上都能运行 |
| 4. 缓存 + CI/CD | 7-8周 | GitHub Actions 完整流水线 + JUnit 报告 |
| 5. GUI 应用 | 9-10周 | macOS GUI 应用可用于交互式编写和执行 |
| 6. 高级功能 | 11-12周 | 测试录制、并行执行、Homebrew 发布 |

## 6. 成功标准

1. `iris run test.yaml` 在 iOS 模拟器上端到端执行5步测试
2. `iris run test.yaml --device <iPhone UDID>` 在真实 iPhone 上运行同一测试
3. Vision AI 正确识别 UI 元素的准确率 >90%
4. 缓存命中使第二次运行快 >2 倍
5. JUnit XML 输出可与 GitHub Actions 测试报告集成
6. `iris setup ios-device` 在 <10 分钟内完成真机准备
7. 同一测试改 `platform: android` 即可在 Android 上运行

## 参见

- [[drizz]] — 本项目的灵感来源
- [[maestro]] — 基于 YAML 的替代方案（使用无障碍层而非视觉 AI）
- [[e2e-testing-strategy]] — 测试最佳实践
