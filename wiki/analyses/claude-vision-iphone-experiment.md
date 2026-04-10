---
title: Claude Code Vision + WDA iPhone Testing Experiment
type: analysis
created: 2026-04-10
updated: 2026-04-10
tags: [experiment, claude-code, vision, wda, ios, real-device]
sources: [drizz-clone-spec, midscene-js]
---

# Claude Code Vision + WDA iPhone Testing Experiment

Hands-on experiment using Claude Code's native image reading as the "VLM" to drive E2E testing on a real iPhone 17 Pro Max (iOS 26.3) via WebDriverAgent.

## Setup

| Component | Details |
|-----------|---------|
| Device | iPhone 17 Pro Max (iOS 26.3), USB connected |
| WDA | Appium xcuitest-driver 10.43.0, built with `xcodebuild build-for-testing` |
| Port forwarding | `iproxy 8100 8100` |
| Vision engine | Claude Code (Opus 4.6) reading PNG screenshots via `Read` tool |
| Actions | WDA W3C Actions API over HTTP |
| Window size | 440x956 points |

## Test Flow Executed

```
Home screen → Spotlight search → Open Settings → General → About
```

| Step | Action | Method | Result |
|------|--------|--------|--------|
| 1 | Open 抖音 from home screen | Vision estimated (169,141) | ✅ App opened |
| 2 | Tap "我" (Profile) tab | Vision guessed (400,930) — wrong | ❌ Off by 33 points in Y |
| 3 | Tap "我" again | WDA element find → (396,897) | ✅ Profile loaded |
| 4 | Go home | WDA `pressButton: home` | ✅ |
| 5 | Swipe left to App Library | Vision: swipe (350,500)→(50,500) | ✅ |
| 6 | Swipe down for Spotlight | Vision: swipe (220,400)→(220,600) | ✅ |
| 7 | Type "Settings" | WDA active element → `value` | ✅ Search results shown |
| 8 | Tap Settings icon | Vision estimated (152,120) | ✅ Settings opened |
| 9 | Tap "通用" (General) | Vision guessed (220,530) — wrong | ❌ Off by 205 points in Y |
| 10 | Tap "通用" again | WDA element find → (220,735) | ✅ General page loaded |
| 11 | Tap "关于本机" (About) | Vision guessed (220,250) — wrong | ❌ Off by 156 points in Y |
| 12 | Tap "关于本机" again | WDA element find → (220,406) | ✅ About page loaded |
| 13 | Read device info | Vision reads screenshot | ✅ iPhone 17 Pro Max, iOS 26.3, 2TB |

## Key Findings

### 1. Pure Vision Coordinate Estimation Is Unreliable

Claude's vision correctly identifies WHAT is on screen (app names, buttons, text) but **consistently misjudges WHERE elements are** in point coordinates. Errors were 100-200 points in Y axis.

**Root cause:** The screenshot image is scaled down when presented to Claude. The mapping from pixel position in the scaled image to actual device points is imprecise. iOS 26 also has significantly more padding/spacing than the visual appearance suggests.

| Attempt | Vision estimate | Actual position | Error |
|---------|----------------|-----------------|-------|
| "我" tab | (400, 930) | (396, 897) | 33 pts Y |
| "通用" | (220, 530) | (220, 735) | 205 pts Y |
| "关于本机" | (220, 250) | (220, 406) | 156 pts Y |

### 2. WDA Element Finding Is Fast and Precise

WDA's `elements` API with predicate strings returns exact coordinates instantly. No VLM call needed. This is effectively the same as what [[appium]] and [[xcuitest]] do — using the accessibility tree.

```bash
# Find element by label — instant, exact
curl -X POST "http://localhost:8100/session/$SESSION/elements" \
  -d '{"using": "predicate string", "value": "label == \"通用\""}'
# Returns: x=20 y=708 w=400 h=55
```

### 3. Vision Excels at Understanding, Not Locating

| Task | Vision accuracy |
|------|----------------|
| What app is this? | Excellent |
| What text is on screen? | Excellent |
| Is the user logged in? | Excellent |
| Read structured data (device info table) | Excellent |
| Tap the "Login" button at coordinates (?,?) | Poor (100-200pt error) |

### 4. The Optimal Hybrid Approach

The best results came from combining both:

```
Claude Vision (understanding)  +  WDA Elements (locating)
─────────────────────────────     ─────────────────────────
"What's on screen?"               "Where exactly is it?"
"Did the action succeed?"         "Tap at (x, y)"
"What data is displayed?"         "Find element by label"
"Is there an error?"              "Get element rect"
```

This is essentially **what Midscene.js does wrong** (pure vision for locating) and **what Appium does right** (accessibility tree for locating) — but both miss the other's strength.

## How This Relates to Midscene.js

### Midscene's approach: Pure Vision
Midscene sends screenshots to a VLM and asks it to return pixel coordinates. This has the same fundamental problem we observed — VLMs are imprecise at coordinate estimation (3-10 seconds per step, non-deterministic, sometimes wrong).

### What we discovered works better: Hybrid

| Aspect | Midscene.js | Our Experiment | Winner |
|--------|-------------|----------------|--------|
| Element locating | VLM coordinates (slow, imprecise) | WDA element find (instant, exact) | WDA |
| Screen understanding | VLM (good) | Claude vision (good) | Tie |
| Assertions | VLM evaluates screenshot | Claude reads screenshot | Tie |
| Data extraction | VLM extracts from screenshot | Claude reads screenshot | Tie |
| Speed per step | 3-10 seconds (VLM API call) | <1 second (WDA) + 0 for cached assertions | WDA |
| Cost per step | VLM API charges | $0 for WDA, Claude session for assertions | Hybrid cheaper |
| Canvas/no-DOM | VLM works (pure vision) | WDA fails (needs accessibility tree) | Midscene |
| Determinism | Non-deterministic | Deterministic (WDA element find) | WDA |

### When Pure Vision (Midscene) Still Wins

1. **Canvas/WebGL** — no accessibility tree exists, vision is the only option
2. **Cross-platform same test** — vision sees the same "Login" button on iOS and Android
3. **No source code access** — app without accessibility labels, vision still works
4. **Fuzzy matching** — "tap the red button near the cart icon" (spatial/visual reasoning)

### When Hybrid (WDA + Vision) Wins

1. **Speed** — WDA element find is instant vs 3-10s per VLM call
2. **Accuracy** — exact coordinates, no guessing
3. **Cost** — no per-step VLM charges for actions
4. **Determinism** — same result every time
5. **CI/CD** — fast, reliable, predictable execution time

### Recommended Architecture for Iris

```
┌─────────────────────────────────────────────┐
│              Test Runner                     │
│                                              │
│  For ACTIONS (tap, type, swipe):             │
│  → WDA element find by label (fast, exact)   │
│  → Fallback: Claude vision coordinates       │
│    (for canvas, no-label, visual matching)   │
│                                              │
│  For ASSERTIONS (verify, read data):         │
│  → Claude vision reads screenshot            │
│  → Natural language: "is login successful?"  │
│                                              │
│  For PLANNING (complex multi-step):          │
│  → Claude breaks down intent into steps      │
│  → Each step uses the action/assert split    │
└─────────────────────────────────────────────┘
```

This hybrid approach would be:
- **Faster** than Midscene (no VLM call for actions)
- **Cheaper** than Midscene (only VLM for assertions)
- **More accurate** than pure vision (exact coordinates)
- **Still flexible** (falls back to vision when accessibility tree fails)

## WDA Helper Script

Created `wda.sh` at `/Users/sunfmin/Developments/midscene-tryout/wda.sh` with commands: `session`, `screenshot`, `tap`, `type`, `swipe`, `find`, `rect`, `home`, `status`.

## See Also

- [[midscene-js]] — pure vision approach, works but slow and imprecise for locating
- [[drizz-clone-spec]] — Iris spec that should adopt the hybrid approach
- [[drizz]] — commercial tool using pure vision
- [[appium]] — uses WDA under the hood, same element-finding capability
- [[xcuitest]] — Apple's native framework, same accessibility tree

---

# 中文翻译

# Claude Code 视觉 + WDA iPhone 测试实验

在真实 iPhone 17 Pro Max（iOS 26.3）上进行的动手实验，使用 Claude Code 的原生图像读取作为"VLM"，通过 WebDriverAgent 驱动 E2E 测试。

## 测试流程

```
主屏幕 → Spotlight 搜索 → 打开设置 → 通用 → 关于本机
```

## 关键发现

### 1. 纯视觉坐标估算不可靠

Claude 视觉能正确识别屏幕上**有什么**（应用名、按钮、文字），但**一致性地误判元素位置**。Y 轴误差 100-200 点。

根本原因：截图在展示给 Claude 时被缩放，缩放图像中的像素位置到实际设备点坐标的映射不精确。iOS 26 的间距也比视觉外观暗示的大得多。

### 2. WDA 元素查找快速且精确

WDA 的元素 API 使用谓词字符串立即返回精确坐标。不需要 VLM 调用。

### 3. 视觉擅长理解，不擅长定位

- 理解屏幕内容 → 优秀
- 读取结构化数据 → 优秀
- 估算点击坐标 → 差（100-200点误差）

### 4. 最优混合方案

- **操作**（点击、输入、滑动）→ WDA 元素查找（快速、精确）
- **断言**（验证、读取数据）→ Claude 视觉读取截图
- **规划**（复杂多步骤）→ Claude 将意图分解为步骤

## 与 Midscene.js 的关系

Midscene 使用纯视觉定位（VLM 返回坐标），有我们观察到的同样问题——VLM 坐标估算不精确（每步 3-10 秒，非确定性，有时出错）。

**混合方案优于 Midscene：**
- 更快（操作不需要 VLM 调用）
- 更便宜（只在断言时使用 VLM）
- 更准确（精确坐标）
- 仍然灵活（在无障碍树失效时回退到视觉）

**Midscene 仍然在以下场景更优：**
- Canvas/WebGL（无无障碍树）
- 跨平台同一测试（视觉在 iOS 和 Android 上看到相同的按钮）
- 无源码应用（没有无障碍标签）

## 参见

- [[midscene-js]] — 纯视觉方案
- [[drizz-clone-spec]] — 应采用混合方案的 Iris 规格
- [[appium]] — 底层使用同样的 WDA 元素查找
