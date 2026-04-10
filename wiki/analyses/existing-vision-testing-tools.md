---
title: Existing Vision-Based UI Testing Tools & Claude Integrations
type: analysis
created: 2026-04-10
updated: 2026-04-10
tags: [vision-ai, testing, claude, mcp, open-source, landscape]
sources: [ios-e2e-testing-research-2026, drizz-clone-spec]
---

# Existing Vision-Based UI Testing Tools & Claude Integrations

Research into what already exists before building Iris. The landscape is more mature than expected.

## Key Finding

**We don't need to build from scratch.** Several mature tools already do what Iris was designed to do — especially Midscene.js and the MCP servers for Claude Code. The opportunity is in **composition and integration**, not greenfield development.

## 1. MCP Servers for Mobile Device Control (Claude Code)

These plug directly into Claude Code and provide mobile device control:

| Project | Stars | Platforms | Key Features |
|---------|-------|-----------|-------------|
| [**ios-simulator-mcp**](https://github.com/joshuayoes/ios-simulator-mcp) | **1,800** | iOS Simulator | `ui_tap`, `ui_type`, `ui_swipe`, `ui_describe_all`, `ui_view` (screenshot). Install: `claude mcp add ios-sim-server -- npx -y ios-simulator-mcp@latest` |
| [**claude-in-mobile**](https://github.com/AlexGladkov/claude-in-mobile) | **197** | Android + iOS Sim + Desktop | 30+ commands, annotated screenshots with bounding boxes, WebView inspection via CDP |
| [**appium-mcp**](https://github.com/appium/appium-mcp) | **303** | Android + iOS | Official Appium. 40+ MCP tools. AI-powered element finding with vision models (Qwen3-VL, Gemini-3-Flash). Test code generation |
| [**XcodeBuildMCP**](https://www.xcodebuildmcp.com/) | ~1k | iOS/macOS | Full Xcode control: build, test, debug, deploy from Claude Code |

> [!note] ios-simulator-mcp (1.8k stars) is the most directly relevant. It already does screenshot + tap/type/swipe on iOS Simulator from Claude Code. This is essentially the iOS half of what Iris was designed to do.

## 2. Vision-Based UI Testing Frameworks (Open Source)

| Tool | Stars | Mobile? | Approach | License |
|------|-------|---------|----------|---------|
| [**Midscene.js**](https://github.com/web-infra-dev/midscene) (ByteDance) | **12,600** | **Yes: Android (adb) + iOS (WDA)** + Web | Pure vision element localization. `aiAct()`, `aiQuery()`, `aiAssert()`, `aiTap()`. Multiple VLMs. | MIT |
| [**Skyvern**](https://github.com/Skyvern-AI/skyvern) | **15,000+** | Web only | Vision LLM + Playwright. Screenshot → VLM → click | AGPL-3.0 |
| [**Shortest**](https://github.com/antiwork/shortest) | **~4,000** | Web only | Natural language E2E tests + Claude Computer Use + Playwright | Open source |
| [**UI-TARS**](https://github.com/bytedance/UI-TARS) (ByteDance) | **~5,000** | Cross-platform | Open-source VLM (2B/7B/72B) trained specifically for UI automation | Open source |
| [**Magnitude**](https://github.com/magnitudedev/magnitude) | ~1,000 | Web only | Dual-agent: Planner (Claude/GPT-4o) + Executor (Moondream, self-hostable) | MIT |
| [**Stark Vision**](https://github.com/AppiumTestDistribution/stark-vision) | 19 | **Android + iOS** | Appium-based, natural language commands, vision element finding | Open source |
| [**Factif-AI**](https://github.com/presidio-oss/factif-ai) | 57 | Desktop + mobile (via Docker VNC) | Supports Claude, GPT-4o, Gemini, OmniParser. Puppeteer + Docker VNC modes | MIT |

### Midscene.js — The Most Relevant

Midscene.js by ByteDance is the closest existing tool to what we planned for Iris:

- **Pure vision** — no selectors, no accessibility IDs, just screenshots
- **iOS support** via WebDriverAgent (same approach as our spec)
- **Android support** via adb (same approach)
- **Natural language** API: `aiAct("tap Login")`, `aiAssert("shows Welcome")`
- **Multiple VLMs**: Qwen3-VL, Gemini-3-pro, Doubao, self-hosted UI-TARS
- **12.6k GitHub stars** — well-maintained, active community
- **MIT license**

iOS setup: macOS + Xcode + WebDriverAgent >= 7.0.0
Docs: [midscenejs.com/ios-getting-started](https://midscenejs.com/ios-getting-started)

## 3. Anthropic Computer Use API

Claude has a built-in **Computer Use tool** (beta) that does screenshot → analyze → click/type:

- **Actions**: screenshot, click, type, key, mouse_move, scroll, drag, zoom
- **Models**: Claude Opus 4.6, Sonnet 4.6
- **Benchmark**: Sonnet 4.6 reached 72.5% on OSWorld (up from 42.0%)
- **Limitation**: Designed for desktop Linux (Docker + Xvfb), not mobile devices natively
- **Can be adapted**: Point screenshot/action at mobile simulator → works indirectly
- **Reference**: [anthropic-quickstarts/computer-use-demo](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo)

## 4. Claude Code Skills for Mobile Testing

| Skill | Description |
|-------|-------------|
| **autocraft** (installed) | Screenshot-verified testing workflows |
| **iterative-dev-macos** (installed) | XCUITest, screenshot capture, visual review |
| [**ios-simulator-skill**](https://github.com/conorluddy/ios-simulator-skill) | Xcodebuild wrapper with screenshot capture + accessibility trees |
| **claude-mobile-ios-testing** | Combines expo-mcp + xc-mcp for React Native testing |

## 5. Real-World Examples

- **Christopher Meiklejohn's Zabriskie QA** — Claude sweeps 25 mobile screens daily, analyzes screenshots for visual issues, auto-files bug reports. Uses `ios-simulator-mcp`.
- **Pocketworks** — Goal-driven mobile testing using Claude's vision capabilities.
- **Drizz** — Commercial SaaS doing exactly this (our original research subject).

## Impact on Iris Spec

### What we should NOT build (already exists)

| Planned Iris Feature | Already Exists In |
|---------------------|-------------------|
| iOS Simulator bridge (simctl) | ios-simulator-mcp (1.8k stars), claude-in-mobile |
| Android bridge (adb) | claude-in-mobile, appium-mcp |
| Vision AI element finding | Midscene.js (12.6k stars), Claude Computer Use API |
| Screenshot → VLM → coordinates pipeline | Midscene.js, Skyvern, Shortest |
| WebDriverAgent integration for real iOS | Midscene.js (already supports WDA) |
| Natural language test steps | Midscene.js (`aiAct`, `aiAssert`), Shortest |

### What we CAN build (gaps in the market)

1. **Claude Code native skill/MCP** that wraps Midscene.js or ios-simulator-mcp with YAML test file support
2. **Real iOS device support in Claude Code** — ios-simulator-mcp only does simulators, not real devices via WDA
3. **CI/CD runner** with JUnit output that uses existing MCP tools under the hood
4. **Unified mobile testing skill** — combine ios-simulator-mcp + claude-in-mobile + visual cache into one cohesive experience
5. **YAML test format** — none of the existing tools use a declarative YAML test format; they're all programmatic (JS/Python)

### Recommended Pivot

Instead of building Iris from scratch, consider:

1. **Use Midscene.js** as the execution engine (it already has iOS WDA + Android adb + vision)
2. **Build a Claude Code skill** that reads YAML test files and calls Midscene.js
3. **Add a CLI wrapper** that runs Midscene.js tests with JUnit output for CI/CD
4. **Or** build an MCP server that extends ios-simulator-mcp with real device support (WDA) and YAML test execution

This approach gets us to a working product in 2-3 weeks instead of 12.

## See Also

- [[drizz-clone-spec]] — original Iris specification
- [[drizz]] — commercial tool this research was inspired by
- [[e2e-testing-strategy]] — testing best practices

---

# 中文翻译

# 现有视觉 UI 测试工具和 Claude 集成

在构建 Iris 之前对现有工具的调研。生态系统比预期成熟得多。

## 关键发现

**不需要从零构建。** 多个成熟工具已经实现了 Iris 设计的功能——特别是 Midscene.js 和 Claude Code 的 MCP 服务器。机会在于**组合和集成**，而非从头开发。

## 1. 移动设备控制的 MCP 服务器（Claude Code）

| 项目 | Stars | 平台 | 安装方式 |
|------|-------|------|----------|
| **ios-simulator-mcp** | 1,800 | iOS 模拟器 | `claude mcp add ios-sim-server -- npx -y ios-simulator-mcp@latest` |
| **claude-in-mobile** | 197 | Android + iOS + 桌面 | 30+ 命令，带标注的截图 |
| **appium-mcp** | 303 | Android + iOS | 官方 Appium，40+ 工具，视觉元素查找 |

## 2. 视觉 UI 测试框架

**Midscene.js**（字节跳动，12.6k stars）是最相关的：
- 纯视觉定位，无需选择器
- 支持 iOS（WDA）+ Android（adb）+ Web
- 自然语言 API：`aiAct("点击登录")`
- 多 VLM 支持：Qwen3-VL、Gemini、UI-TARS
- MIT 许可证

## 3. 对 Iris 规格的影响

### 不需要构建的（已存在）
- iOS 模拟器桥（simctl）→ ios-simulator-mcp
- Android 桥（adb）→ claude-in-mobile、appium-mcp
- 视觉 AI 元素查找 → Midscene.js
- 截图 → VLM → 坐标管道 → Midscene.js

### 可以构建的（市场空白）
1. 包装 Midscene.js 或 ios-simulator-mcp 的 Claude Code 技能，支持 YAML 测试文件
2. Claude Code 中的真实 iOS 设备支持（现有 MCP 只支持模拟器）
3. 带 JUnit 输出的 CI/CD 运行器
4. **YAML 声明式测试格式** — 现有工具都是编程式的（JS/Python）

### 建议调整方向

不从零构建 Iris，而是：
1. 使用 **Midscene.js** 作为执行引擎
2. 构建一个读取 YAML 测试文件并调用 Midscene.js 的 **Claude Code 技能**
3. 添加 JUnit 输出的 **CLI 包装器**用于 CI/CD

这种方式可以在 2-3 周内而非 12 周得到可用产品。

## 参见

- [[drizz-clone-spec]] — 原始 Iris 规格
- [[drizz]] — 本调研的灵感来源
- [[e2e-testing-strategy]] — 测试最佳实践
