---
title: macOS Desktop Automation Landscape (2026)
type: analysis
created: 2026-04-22
updated: 2026-04-22
tags: [macos, desktop, automation, testing, landscape, research]
sources: [web-research]
---

# macOS Desktop Automation Landscape (2026)

Parallel to [[webdriveragent|WDA]] for iOS, what's available for **macOS desktop apps**? This page catalogs the options by layer — from XCTest-based drivers (Mac2) down through the native AX API and up into vision-based AI agents — so we can pick the right tool when Iris or the [[auto-bug-fix-workflow]] expands to desktop.

## TL;DR

**Direct WDA analog: [[appium-mac2-driver]].** It literally contains a `WebDriverAgentMac` Xcode project forked from Facebook's WDA, exposes a WebDriver HTTP API on port 10100, and uses the same `accessibility id` / predicate / class chain locators. Everything we know about WDA transfers.

Below Mac2 is the raw Accessibility (AX) API, which powers most lightweight tools (Hammerspoon, atomacos, Fazm, macos-use). Above Mac2 are vision/LLM agents (Claude Computer Use, UI-TARS). The same WDA-plus-vision hybrid we validated on iPhone ([[claude-vision-iphone-experiment]]) should port 1:1 to macOS by swapping WDA for Mac2.

## Layer 1: XCTest-Based (the WDA equivalent)

### Appium Mac2 Driver — **the answer to "is there a WDA for macOS?"**

- XCTest bundle named `WebDriverAgentMac` runs on the host Mac on port 10100
- W3C WebDriver + `macos:` extensions: `click`, `keys`, `appleScript`, `screenshots`, `deepLink`, `performAccessibilityAudit`
- Locator strategies identical to WDA: `accessibility id`, `class name`, `-ios predicate string`, `-ios class chain`, `xpath`
- **Only macOS automation tool that is XCTest-backed** — everyone else is at the AX API level or above
- One session per Mac (no parallelism), cold-start 10-20s
- Full reference: [[appium-mac2-driver]]

### Raw XCUITest for macOS (no Appium)

Apple's XCTest framework natively supports macOS app UI testing — `XCUIApplication`, `XCUIElement`, the same API as iOS. If you have Xcode project access to the app under test, you can write XCTest cases directly with no Appium/Mac2 wrapper. [[xcuitest]]

**Trade-off**: loses the HTTP/language-agnostic surface. Your tests must be Swift/Obj-C inside Xcode. Mac2 exists precisely because teams want WebDriver's decoupling.

## Layer 2: Accessibility API (AX)

macOS exposes every UI element — `AXButton`, `AXTextField`, `AXMenu`, with labels, roles, geometry, and available actions — via the `AXUIElement` C API. Every higher-level tool on macOS (including XCTest's macOS implementation) ultimately calls this API.

### Key tools at the AX layer

| Tool | Language | Position | Notes |
|------|----------|----------|-------|
| `atomacos` / `atomac` | Python | Testing-focused AX wrapper | Maintained fork of older `atomac` |
| **Hammerspoon** | Lua | Power-user automation + hotkeys | Staggering breadth of macOS integrations — window mgmt, Spotlight, menus, apps; not test-oriented, no assertions |
| **cliclick** | CLI | Coordinate clicks/keystrokes | No element finding; pure (x,y). Useful for shell scripts |
| AppleScript / JXA | Apple-native | Built-in system scripting | App-by-app scriptability varies; `System Events` exposes generic UI |
| `mb-dev/macos-ui-automation` (MCP) | Node | AX-tree MCP server for LLMs | Feeds structured UI tree to Claude/Cursor |

### AX vs. screenshots for AI agents — 2026 consensus

Industry reporting this year has settled on **accessibility-first for desktop LLM agents**, not vision-first:

> "Every UI element in every macOS app — buttons, text fields, menus, lists — is exposed through Accessibility APIs as structured, hierarchical data, allowing AI to read `AXButton, label='Send', enabled=true` instead of analyzing images."

Measured on a 25-task suite (Fazm blog):
- **Fazm** (AX-tree based): **8.2s/task, 84% success**
- **UI-TARS** (vision model): **11.4s/task, 72% success**

This validates our iOS finding from [[claude-vision-iphone-experiment]] in desktop form: structured element data beats raw pixels for both speed and reliability. Vision remains useful for assertions ("does the screen look right?") but coordinate inference is best left to the structured layer.

## Layer 3: Vision / AI Agents

### Apple-ecosystem vision agents

- **Claude Computer Use** — general screen-control tool use, works on any desktop OS; slow and expensive per action, best for exploratory tasks
- **UI-TARS (Alibaba)** — the only purpose-built vision model for computer use, no external API; 72% task success in the study above
- **Fazm** — Swift-native macOS agent, `ScreenCaptureKit` + AX API hybrid, supports local LLMs; leader on desktop automation per the 2026 Fazm comparison

### Legacy image-matching

- **SikuliX** — image-template matching; breaks on theme/resolution/OS updates; useful as a last resort for apps with no AX tree (rare on macOS — even Electron exposes AX)

## Layer 4: End-User / Scripting Automation (not testing)

Listed for completeness; these are not QA testing tools:

- **Apple Shortcuts** — basic user-visible actions; no UI scripting depth
- **Automator** — effectively deprecated by Apple
- **Keyboard Maestro** — commercial; the closest macOS equivalent of Power Automate Desktop for end-user macros
- **Raycast / Alfred** — launcher-style automation, hotkey-triggered

## Mapping to Our Existing Work

### If Iris expands to macOS

Swap WDA with Mac2 in [[drizz-clone-spec|Iris]]. The architecture carries over:

```
Test (English) ──▶ LLM plan ──▶ Mac2 HTTP (:10100) ──▶ WebDriverAgentMac ──▶ macOS app
                         └────▶ Claude vision on screenshots (assertions)
```

No Iris concept needs to change. The only platform-specific code is the HTTP client base URL and the locator extensions (`macos:` vs. none on iOS).

### If [[auto-bug-fix-workflow]] expands to desktop

Action vocabulary covered by Mac2:
- **Reproduce** → `macos: launchApp` + `macos: keys` + `macos: click` driven by bug steps
- **Record** → `macos: startRecordingScreen` (FFMPEG) or `macos: startNativeScreenRecording` (XCTest native, Xcode 15+)
- **Screenshot-for-vision** → `macos: screenshots` (all displays) or standard `GET /screenshot`
- **Gaps** → `macos: appleScript` covers Finder, System Settings, menu bar, Mission Control

The iOS-only bits of the workflow (`idb install`, Simulator vs. real device selection, WDA code signing) drop out entirely — macOS is always "the local machine," no device management layer.

## Decision Matrix

| Goal | Recommendation |
|------|---------------|
| WebDriver-style macOS automation, matches our WDA mental model | **Mac2 Driver** |
| Lightweight Python/Swift desktop scripting | atomacos or native `AXUIElement` |
| LLM agent reading structured UI | Fazm / macos-use MCP servers (AX tree) |
| Apps with no AX tree (truly rare) | SikuliX / vision |
| End-user macros, hotkeys | Hammerspoon or Keyboard Maestro |
| Inside an Xcode project already | XCUITest directly, skip Appium |

## Key References

- [Appium Mac2 Driver GitHub](https://github.com/appium/appium-mac2-driver) — 172 stars, v3.3.1 (2026-04-15)
- [Mac2 driver docs](https://appium.github.io/appium.io/docs/en/drivers/mac2/)
- [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) — Lua desktop automation
- [Fazm blog: macOS accessibility tree for desktop control](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control)
- [MacPaw Research: Parsing macOS application UI](https://research.macpaw.com/publications/how-to-parse-macos-app-ui)

## See Also

- [[appium-mac2-driver]] — Full entity page on the Mac2 driver (WDA's sibling)
- [[webdriveragent]] — iOS counterpart
- [[claude-vision-iphone-experiment]] — iPhone experiment validating WDA+vision hybrid (analogy holds on macOS)
- [[existing-vision-testing-tools]] — Landscape of vision-based testing tools (mobile-focused)

---

# 中文翻译

# macOS 桌面自动化生态（2026）

与 iOS 的 [[webdriveragent|WDA]] 平行，**macOS 桌面应用**有哪些自动化方案？本页按层级整理选项——从基于 XCTest 的 driver（Mac2）向下到原生 AX API，再向上到基于视觉的 AI agent——便于未来 Iris 或 [[auto-bug-fix-workflow]] 扩展到桌面时选型。

## 结论速览

**WDA 的直接对等物：[[appium-mac2-driver]]。** 它字面上就包含一个从 Facebook WDA fork 来的 `WebDriverAgentMac` Xcode 工程，在 10100 端口暴露 WebDriver HTTP API，使用相同的 `accessibility id` / predicate / class chain 定位策略。我们对 WDA 的所有认知都能平移。

Mac2 之下是原生 AX API，为大多数轻量工具（Hammerspoon、atomacos、Fazm、macos-use）提供支持。Mac2 之上是视觉/LLM agent（Claude Computer Use、UI-TARS）。我们在 iPhone 上验证的 WDA+视觉混合方案（[[claude-vision-iphone-experiment]]）可以通过把 WDA 换成 Mac2 1:1 移植到 macOS。

## 第 1 层：基于 XCTest（WDA 等价物）

### Appium Mac2 Driver —— "macOS 有没有 WDA？"的答案

- 名为 `WebDriverAgentMac` 的 XCTest bundle 运行在主机 Mac 上，端口 10100
- W3C WebDriver + `macos:` 扩展：`click`、`keys`、`appleScript`、`screenshots`、`deepLink`、`performAccessibilityAudit`
- 定位策略与 WDA 一致：`accessibility id`、`class name`、`-ios predicate string`、`-ios class chain`、`xpath`
- **唯一由 XCTest 支撑的 macOS 自动化工具** —— 其他所有工具都在 AX API 层或更上层
- 每台 Mac 单会话（无并行），冷启动 10-20 秒
- 完整参考：[[appium-mac2-driver]]

### 裸 XCUITest for macOS（无 Appium）

Apple 的 XCTest 框架原生支持 macOS 应用 UI 测试——`XCUIApplication`、`XCUIElement`，与 iOS 同一套 API。如果你有被测应用的 Xcode 工程访问权，可以直接在 Xcode 内用 Swift/Obj-C 写 XCTest case，无需 Appium/Mac2 封装。[[xcuitest]]

**取舍**：失去 HTTP/语言无关的接口。你的测试必须在 Xcode 内用 Swift/Obj-C 写。Mac2 存在的理由正是团队需要 WebDriver 带来的解耦。

## 第 2 层：可访问性 API（AX）

macOS 通过 `AXUIElement` C API 暴露每个 UI 元素——`AXButton`、`AXTextField`、`AXMenu`，带标签、角色、几何信息和可用动作。macOS 上所有更高层的工具（包括 XCTest 的 macOS 实现）最终都调用这个 API。

### AX 层的关键工具

| 工具 | 语言 | 定位 | 备注 |
|------|------|------|------|
| `atomacos` / `atomac` | Python | 面向测试的 AX 封装 | 老 `atomac` 的维护分叉 |
| **Hammerspoon** | Lua | 高级用户自动化 + 热键 | 惊人的 macOS 集成广度——窗口管理、Spotlight、菜单、应用；非测试导向，无断言 |
| **cliclick** | CLI | 坐标点击/按键 | 无元素查找；纯 (x,y)。适合 shell 脚本 |
| AppleScript / JXA | Apple 原生 | 内置系统脚本 | 各应用可脚本化程度不一；`System Events` 暴露通用 UI |
| `mb-dev/macos-ui-automation`（MCP） | Node | 面向 LLM 的 AX 树 MCP 服务器 | 向 Claude/Cursor 喂结构化 UI 树 |

### AX vs. 截图——2026 年共识

今年业界报告已经在桌面 LLM agent 上定论为**可访问性优先**，而非视觉优先：

> "macOS 每个应用的每个 UI 元素——按钮、文本框、菜单、列表——都通过 Accessibility API 以结构化、层级化数据的形式暴露，让 AI 可以读取 `AXButton, label='Send', enabled=true` 而非分析图像。"

25 任务测试集上的实测（Fazm 博客）：
- **Fazm**（基于 AX 树）：**平均 8.2 秒/任务，84% 成功率**
- **UI-TARS**（视觉模型）：**平均 11.4 秒/任务，72% 成功率**

这在桌面端验证了我们在 [[claude-vision-iphone-experiment]] 中得到的 iOS 结论：结构化元素数据在速度和可靠性上都优于原始像素。视觉对断言仍有用（"屏幕看起来对吗？"），但坐标推断最好留给结构化层。

## 第 3 层：视觉 / AI Agent

### Apple 生态视觉 agent

- **Claude Computer Use** — 通用屏幕控制工具使用，适用任何桌面 OS；每动作慢且贵，适合探索式任务
- **UI-TARS（阿里巴巴）** — 唯一专为 computer use 构建的视觉模型，无需外部 API；上述研究中 72% 任务成功率
- **Fazm** — Swift 原生 macOS agent，`ScreenCaptureKit` + AX API 混合，支持本地 LLM；2026 Fazm 对比中桌面自动化领跑

### 传统图像匹配

- **SikuliX** — 图像模板匹配；对主题/分辨率/OS 更新脆弱；仅作为没有 AX 树应用的最后手段（macOS 上罕见——连 Electron 都暴露 AX）

## 第 4 层：终端用户 / 脚本自动化（非测试）

列出以作完整；这些不是 QA 测试工具：

- **Apple Shortcuts** — 基本用户可见动作；无 UI 脚本深度
- **Automator** — 实际上已被 Apple 弃用
- **Keyboard Maestro** — 商业软件；macOS 上最接近 Power Automate Desktop 的终端用户宏工具
- **Raycast / Alfred** — 启动器式自动化，热键触发

## 对我们现有工作的映射

### 如果 Iris 扩展到 macOS

在 [[drizz-clone-spec|Iris]] 中把 WDA 换成 Mac2。架构原封不动：

```
测试（英文） ──▶ LLM 规划 ──▶ Mac2 HTTP (:10100) ──▶ WebDriverAgentMac ──▶ macOS 应用
                         └────▶ 截图上的 Claude 视觉（断言）
```

Iris 的任何概念都不需要改。唯一平台相关的代码是 HTTP 客户端的 base URL 和定位扩展（`macos:` vs. iOS 上的无）。

### 如果 [[auto-bug-fix-workflow]] 扩展到桌面

Mac2 覆盖的动作词汇：
- **复现** → 由 bug 步骤驱动的 `macos: launchApp` + `macos: keys` + `macos: click`
- **录制** → `macos: startRecordingScreen`（FFMPEG）或 `macos: startNativeScreenRecording`（XCTest 原生，Xcode 15+）
- **供视觉的截图** → `macos: screenshots`（所有显示器）或标准 `GET /screenshot`
- **空白** → `macos: appleScript` 覆盖 Finder、系统设置、菜单栏、Mission Control

工作流里 iOS 专属的部分（`idb install`、模拟器 vs. 真机选择、WDA 代码签名）完全退场——macOS 永远就是"本地机器"，没有设备管理层。

## 决策矩阵

| 目标 | 推荐 |
|------|------|
| WebDriver 风格的 macOS 自动化，匹配我们的 WDA 心智模型 | **Mac2 Driver** |
| 轻量 Python/Swift 桌面脚本 | atomacos 或原生 `AXUIElement` |
| LLM agent 读取结构化 UI | Fazm / macos-use MCP（AX 树） |
| 没有 AX 树的应用（真的罕见） | SikuliX / 视觉 |
| 终端用户宏、热键 | Hammerspoon 或 Keyboard Maestro |
| 已在 Xcode 工程内 | 直接 XCUITest，跳过 Appium |

## 关键参考

- [Appium Mac2 Driver GitHub](https://github.com/appium/appium-mac2-driver) — 172 stars，v3.3.1（2026-04-15）
- [Mac2 driver 文档](https://appium.github.io/appium.io/docs/en/drivers/mac2/)
- [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) — Lua 桌面自动化
- [Fazm 博客：用于桌面控制的 macOS 可访问性树](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control)
- [MacPaw Research：解析 macOS 应用 UI](https://research.macpaw.com/publications/how-to-parse-macos-app-ui)

## 参见

- [[appium-mac2-driver]] — Mac2 driver 完整实体页（WDA 的兄弟）
- [[webdriveragent]] — iOS 对等物
- [[claude-vision-iphone-experiment]] — iPhone 实验验证了 WDA+ 视觉混合（类比在 macOS 上成立）
- [[existing-vision-testing-tools]] — 视觉测试工具生态（聚焦移动端）
