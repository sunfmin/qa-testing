---
title: Drizz Clone — Local macOS App Specification
type: analysis
created: 2026-04-10
updated: 2026-04-10
tags: [spec, macos, vision-ai, mobile-testing, drizz-clone]
sources: [ios-e2e-testing-research-2026, drizz]
---

# Drizz Clone — Local macOS App Specification

A local, open-source macOS application that uses Vision AI to automate mobile E2E testing. Tests are written in plain English and executed on iOS Simulators and Android Emulators by "seeing" the screen — no selectors, no accessibility IDs, no source code required.

**Codename:** Iris

## 1. Goals

### What we're building
A native macOS desktop app that:
1. Connects to iOS Simulators (via `simctl`) and Android Emulators (via `adb`)
2. Captures device screenshots in real-time
3. Sends screenshots to a Vision Language Model (VLM) to identify UI elements
4. Executes plain-English test steps by mapping instructions to screen coordinates
5. Caches visual states to avoid redundant AI calls
6. Reports results with step-level screenshots and pass/fail status

### What we're NOT building (MVP)
- Cloud execution platform
- Real physical device support
- CI/CD integration APIs
- Multi-user collaboration
- Test generation AI (Fathom equivalent)

### Key differentiators vs Drizz
- **Fully local** — no cloud dependency for execution, your own API keys
- **Open source** — transparent, extensible, no vendor lock-in
- **BYO-LLM** — use any VLM provider (OpenAI, Anthropic, Google, Ollama for local models)
- **Free** — no per-run pricing

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  Iris macOS App                  │
│                                                  │
│  ┌──────────┐  ┌───────────┐  ┌──────────────┐  │
│  │  Editor   │  │  Runner   │  │   Results    │  │
│  │  (Test    │  │  (Exec    │  │   (Report    │  │
│  │  Author)  │  │  Engine)  │  │   Viewer)    │  │
│  └────┬─────┘  └─────┬─────┘  └──────┬───────┘  │
│       │              │               │           │
│  ┌────┴──────────────┴───────────────┴────────┐  │
│  │              Core Engine                    │  │
│  │                                             │  │
│  │  ┌─────────┐ ┌──────────┐ ┌─────────────┐  │  │
│  │  │ Device  │ │ Vision   │ │   Visual    │  │  │
│  │  │ Bridge  │ │ AI       │ │   Cache     │  │  │
│  │  │         │ │ Pipeline │ │             │  │  │
│  │  └────┬────┘ └────┬─────┘ └──────┬──────┘  │  │
│  └───────┼───────────┼──────────────┼──────────┘  │
│          │           │              │              │
└──────────┼───────────┼──────────────┼──────────────┘
           │           │              │
    ┌──────┴──────┐ ┌──┴───┐   ┌─────┴─────┐
    │  simctl /   │ │ VLM  │   │  SQLite   │
    │  adb        │ │ API  │   │  Cache DB │
    └─────────────┘ └──────┘   └───────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **Editor** | Write/edit test files, syntax highlighting, step preview |
| **Runner** | Execute test steps sequentially, manage device lifecycle |
| **Results** | Display step-by-step results with screenshots, timings, pass/fail |
| **Device Bridge** | Abstract iOS Simulator (`simctl`) and Android Emulator (`adb`) interaction |
| **Vision AI Pipeline** | Screenshot → VLM analysis → element identification → coordinate mapping |
| **Visual Cache** | Store screen state embeddings, match against cache before calling VLM |

## 3. Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **App framework** | Swift + SwiftUI | Native macOS, best performance, first-class Xcode integration |
| **Device control (iOS)** | `xcrun simctl` CLI | Standard Apple tool, no dependencies |
| **Device control (Android)** | `adb` CLI | Standard Android tool |
| **Screenshot capture (iOS)** | `simctl io booted screenshot` | Native, fast, reliable |
| **Screenshot capture (Android)** | `adb exec-out screencap -p` | Standard approach |
| **Input injection (iOS)** | `simctl io booted input` (touch/keyboard) | Native simulator input |
| **Input injection (Android)** | `adb shell input tap/text/swipe` | Standard approach |
| **VLM integration** | HTTP REST calls to provider APIs | OpenAI (GPT-4o), Anthropic (Claude), Google (Gemini), Ollama (local) |
| **Visual cache** | SQLite + perceptual hashing (pHash) | Fast local lookup, no external dependency |
| **Image processing** | CoreImage / Vision.framework | Native macOS frameworks for image analysis |
| **Test file format** | YAML | Simple, human-readable, Git-friendly |
| **Data persistence** | SQLite (via GRDB.swift) | Lightweight, embedded |

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

## 5. Vision AI Pipeline

### Per-Step Execution Flow

```
1. Capture screenshot from device
         │
2. Check visual cache (pHash similarity)
         │
    ┌─────┴─────┐
    │ Cache HIT  │──→ Use cached element coordinates → Execute action
    └─────┬─────┘
          │ Cache MISS
          ▼
3. Send to VLM with structured prompt:
   ┌──────────────────────────────────────────┐
   │ System: You are a mobile UI analyzer.    │
   │ Analyze this screenshot and find the     │
   │ element described by the user.           │
   │                                          │
   │ Return JSON:                             │
   │ {                                        │
   │   "found": true/false,                   │
   │   "element": "description",              │
   │   "x": 187,                              │
   │   "y": 423,                              │
   │   "width": 120,                          │
   │   "height": 44,                          │
   │   "confidence": 0.95                     │
   │ }                                        │
   │                                          │
   │ User: Find the element: "Login button"   │
   │ [attached: screenshot.png]               │
   └──────────────────────────────────────────┘
         │
4. Parse VLM response → extract coordinates
         │
5. Store in visual cache (screenshot hash → coordinates)
         │
6. Execute action at coordinates via simctl/adb
         │
7. Wait for UI to settle (configurable delay or screen-diff stability check)
         │
8. Capture post-action screenshot for results
```

### VLM Prompt Design

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

**For `swipe` steps with target:**
```
Analyze this mobile app screenshot. Find the element or area described by: "{description}".
Return the bounding box as JSON: { "found": true/false, "x": ..., "y": ..., "width": ..., "height": ... }
I need to perform a swipe {direction} gesture on this element.
```

### VLM Provider Abstraction

```swift
protocol VLMProvider {
    var name: String { get }
    func analyze(screenshot: CGImage, prompt: String) async throws -> VLMResponse
}

struct VLMResponse {
    let found: Bool
    let element: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let confidence: Double
    let rawJSON: String
}

// Implementations
class OpenAIProvider: VLMProvider { ... }    // GPT-4o
class AnthropicProvider: VLMProvider { ... } // Claude
class GeminiProvider: VLMProvider { ... }    // Gemini
class OllamaProvider: VLMProvider { ... }    // Local models (Qwen-VL, LLaVA, etc.)
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

### DeviceBridge Protocol

```swift
protocol DeviceBridge {
    func listDevices() async -> [Device]
    func screenshot() async throws -> CGImage
    func tap(x: Int, y: Int) async throws
    func typeText(_ text: String) async throws
    func swipe(from: CGPoint, to: CGPoint, duration: Double) async throws
    func launchApp(_ identifier: String) async throws
    func terminateApp(_ identifier: String) async throws
}

struct Device {
    let id: String          // UDID or serial
    let name: String        // "iPhone 16 Pro" or "Pixel 8"
    let platform: Platform  // .ios or .android
    let osVersion: String   // "18.4" or "15"
    let state: DeviceState  // .booted, .shutdown
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
│  VLM Provider                       │
│  ┌─────────────────────────────┐    │
│  │ ○ OpenAI (GPT-4o)          │    │
│  │ ● Anthropic (Claude)       │    │
│  │ ○ Google (Gemini)          │    │
│  │ ○ Ollama (Local)           │    │
│  └─────────────────────────────┘    │
│                                     │
│  API Key: sk-••••••••••••••••       │
│  Model:   claude-sonnet-4-6  ▼     │
│                                     │
│  Ollama URL: http://localhost:11434 │
│  Ollama Model: qwen2.5-vl ▼        │
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

## 9. Project Structure

```
iris/
├── Iris.xcodeproj
├── Iris/
│   ├── App/
│   │   ├── IrisApp.swift              # App entry point
│   │   └── ContentView.swift          # Main window layout
│   ├── Views/
│   │   ├── TestEditorView.swift       # YAML test editor
│   │   ├── DevicePreviewView.swift    # Live simulator mirror
│   │   ├── RunLogView.swift           # Step-by-step execution log
│   │   ├── ResultsView.swift          # Test results with screenshots
│   │   ├── SettingsView.swift         # Configuration panel
│   │   └── SidebarView.swift          # File tree + device list
│   ├── Core/
│   │   ├── TestRunner.swift           # Orchestrates test execution
│   │   ├── TestParser.swift           # YAML → [TestStep] parsing
│   │   ├── StepExecutor.swift         # Executes individual steps
│   │   └── Models.swift               # TestFile, TestStep, TestResult, etc.
│   ├── Vision/
│   │   ├── VLMProvider.swift          # Protocol + factory
│   │   ├── OpenAIProvider.swift       # GPT-4o integration
│   │   ├── AnthropicProvider.swift    # Claude integration
│   │   ├── GeminiProvider.swift       # Gemini integration
│   │   ├── OllamaProvider.swift       # Local model integration
│   │   └── PromptBuilder.swift        # Constructs VLM prompts per step type
│   ├── Device/
│   │   ├── DeviceBridge.swift         # Protocol
│   │   ├── iOSSimulatorBridge.swift   # simctl wrapper
│   │   ├── AndroidEmulatorBridge.swift# adb wrapper
│   │   └── DeviceManager.swift        # Detect, boot, manage devices
│   ├── Cache/
│   │   ├── VisualCache.swift          # Cache lookup + storage
│   │   ├── PerceptualHash.swift       # pHash implementation
│   │   └── CacheDB.swift             # SQLite operations
│   └── Util/
│       ├── Shell.swift                # Run CLI commands
│       ├── ImageUtil.swift            # Screenshot processing
│       └── Settings.swift             # App configuration
├── IrisTests/
│   ├── TestParserTests.swift
│   ├── PerceptualHashTests.swift
│   ├── VLMProviderTests.swift
│   └── CacheTests.swift
└── README.md
```

## 10. Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] macOS app scaffold (SwiftUI, single window)
- [ ] `Shell.swift` — async CLI command runner
- [ ] `iOSSimulatorBridge` — list devices, boot, screenshot, tap, type
- [ ] `TestParser` — YAML → `[TestStep]` (basic steps only: tap, type, assert, wait)
- [ ] Basic UI: sidebar (test files), editor (read-only YAML view), device list
- **Milestone:** Can list simulators, boot one, take a screenshot, tap at hardcoded coordinates

### Phase 2: Vision AI (Week 3-4)
- [ ] `VLMProvider` protocol + `AnthropicProvider` implementation (start with Claude)
- [ ] `PromptBuilder` — construct prompts for tap, assert, swipe
- [ ] `StepExecutor` — screenshot → VLM → parse response → execute action
- [ ] `TestRunner` — run all steps sequentially, collect results
- [ ] Results view: step list with before/after screenshots
- **Milestone:** Can run a 3-step test (tap, type, assert) end-to-end on iOS Simulator

### Phase 3: Cache + Polish (Week 5-6)
- [ ] `PerceptualHash` — pHash implementation using CoreImage
- [ ] `VisualCache` — SQLite-backed cache with hamming distance lookup
- [ ] Cache HIT/MISS indicators in run log
- [ ] Settings panel: VLM provider selection, API key, cache config
- [ ] `OpenAIProvider` + `OllamaProvider` implementations
- [ ] Live device preview (stream screenshots)
- **Milestone:** Second run of same test hits cache, runs 2x faster

### Phase 4: Android + Advanced (Week 7-8)
- [ ] `AndroidEmulatorBridge` — adb wrapper
- [ ] Platform detection in test files
- [ ] Additional step types: swipe, scroll, long_press, back, set_location
- [ ] YAML syntax: variables, includes, conditionals
- [ ] Export results as HTML report
- [ ] Error handling: VLM failures, device disconnects, timeout recovery
- **Milestone:** Full test suite running on both iOS and Android

### Phase 5: Quality of Life (Week 9-10)
- [ ] Test recording: click on device preview → auto-generate YAML steps
- [ ] Element inspector: hover on device preview → show VLM-identified elements
- [ ] Batch execution: run multiple test files
- [ ] CLI mode: `iris run login-test.yaml` (for CI integration)
- [ ] Keyboard shortcuts and Xcode-like UX polish
- **Milestone:** Usable for daily testing workflows

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
| VLM latency makes tests too slow | Low | Medium | Visual cache, parallel VLM calls for look-ahead, local models via Ollama |
| pHash too coarse for similar screens | Medium | Low | Add structural comparison layer (element count, layout hash) |
| API costs for heavy VLM usage | Medium | Low | Cache reduces calls by ~90%; Ollama for free local inference |
| SwiftUI complexity for custom editor | Low | Medium | Use TextEditor for MVP, consider SourceEditor framework later |

## 13. Success Criteria

**MVP is successful when:**
1. A user can write a 5-step YAML test and run it on an iOS Simulator
2. Vision AI correctly identifies and taps UI elements >90% of the time
3. Second run of the same test is >2x faster due to cache hits
4. Results show clear before/after screenshots for each step
5. Setup takes <5 minutes (clone repo, build, add API key, run)

## See Also

- [[drizz]] — the product this is inspired by
- [[maestro]] — YAML-based alternative (uses accessibility layer, not vision AI)
- [[e2e-testing-strategy]] — testing best practices

---

# 中文翻译

# Drizz 克隆 — 本地 macOS 应用规格说明

一个本地的、开源的 macOS 应用，使用 Vision AI 自动化移动端 E2E 测试。用纯英文编写测试，在 iOS 模拟器和 Android 模拟器上执行——无需选择器、无需无障碍 ID、无需源代码。

**代号：** Iris

## 1. 目标

### 我们在构建什么
一个原生 macOS 桌面应用：
1. 连接 iOS 模拟器（通过 `simctl`）和 Android 模拟器（通过 `adb`）
2. 实时截取设备屏幕截图
3. 将截图发送给视觉语言模型（VLM）识别 UI 元素
4. 通过将英文指令映射到屏幕坐标来执行测试步骤
5. 缓存视觉状态以避免冗余 AI 调用
6. 生成带有逐步截图和通过/失败状态的报告

### MVP 不包含什么
- 云执行平台
- 真实物理设备支持
- CI/CD 集成 API
- 多用户协作
- 测试生成 AI（Fathom 等价功能）

### 与 Drizz 的关键差异
- **完全本地** — 执行不依赖云，使用自己的 API 密钥
- **开源** — 透明、可扩展、无供应商锁定
- **自带 LLM** — 可用任何 VLM 提供商（OpenAI、Anthropic、Google、Ollama 本地模型）
- **免费** — 无按次运行计费

## 2. 架构概览

应用分为三个 UI 层（编辑器、运行器、结果查看器）和三个核心引擎（设备桥、Vision AI 管道、视觉缓存），底层依赖 simctl/adb、VLM API 和 SQLite 缓存数据库。

## 3. 技术栈

| 层 | 技术 | 原因 |
|----|------|------|
| 应用框架 | Swift + SwiftUI | 原生 macOS，最佳性能 |
| iOS 设备控制 | `xcrun simctl` | Apple 标准工具 |
| Android 设备控制 | `adb` | Android 标准工具 |
| VLM 集成 | HTTP REST 调用 | 支持 OpenAI、Anthropic、Google、Ollama |
| 视觉缓存 | SQLite + 感知哈希（pHash） | 快速本地查找 |
| 图像处理 | CoreImage / Vision.framework | macOS 原生框架 |
| 测试文件格式 | YAML | 简单、可读、Git 友好 |

## 4. 测试文件格式

```yaml
name: Login Flow
app:
  platform: ios
  bundleId: com.example.myapp
steps:
  - tap: "Login"
  - type: "test@example.com"
  - tap: "Sign In"
  - assert: "Welcome back"
```

支持的步骤类型：tap、type、swipe、assert、wait、screenshot、back、launch、clear、scroll、long_press、set_location。

## 5. Vision AI 管道

每步执行流程：
1. 从设备截屏
2. 检查视觉缓存（pHash 相似度）
3. 缓存命中 → 使用缓存的坐标
4. 缓存未命中 → 发送到 VLM，附带结构化提示词
5. 解析 VLM 响应，提取坐标
6. 存入缓存
7. 通过 simctl/adb 在坐标处执行操作
8. 截取操作后截图

VLM 提供商抽象为协议，支持 OpenAI、Anthropic、Google 和 Ollama。

## 6. 视觉缓存系统

使用感知哈希（pHash）进行截图指纹识别。缓存条目存储在 SQLite 中。查找时计算当前截图与缓存的汉明距离，低于阈值（默认 8 位）视为命中。

缓存失效：基于 TTL（默认7天）、手动清除、阈值可调。

## 7. 设备桥

iOS 模拟器通过 `xcrun simctl` 控制（截图、点击、输入、滑动、定位）。
Android 模拟器通过 `adb` 控制（相同功能集）。
统一的 `DeviceBridge` 协议抽象两个平台。

## 8. 实现阶段

| 阶段 | 时间 | 里程碑 |
|------|------|--------|
| 1. 基础 | 1-2周 | 能列出模拟器、启动、截图、在硬编码坐标点击 |
| 2. Vision AI | 3-4周 | 能在 iOS 模拟器上端到端运行3步测试 |
| 3. 缓存 + 打磨 | 5-6周 | 第二次运行命中缓存，速度提升2倍 |
| 4. Android + 高级 | 7-8周 | iOS 和 Android 都能运行完整测试套件 |
| 5. 体验优化 | 9-10周 | 测试录制、元素检查器、批量执行、CLI 模式 |

## 9. 成功标准

MVP 成功的标志：
1. 用户可以编写5步 YAML 测试并在 iOS 模拟器上运行
2. Vision AI 正确识别和点击 UI 元素的准确率 >90%
3. 同一测试的第二次运行因缓存命中而快 >2 倍
4. 结果展示每步清晰的前/后截图
5. 设置时间 <5 分钟（克隆仓库、构建、添加 API 密钥、运行）

## 参见

- [[drizz]] — 本项目的灵感来源
- [[maestro]] — 基于 YAML 的替代方案（使用无障碍层而非视觉 AI）
- [[e2e-testing-strategy]] — 测试最佳实践
