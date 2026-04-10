---
title: Maestro
type: entity
created: 2026-04-09
updated: 2026-04-10
tags: [testing, ios, android, e2e, yaml, black-box]
sources: [ios-e2e-testing-research-2026]
---

# Maestro

Black-box, YAML-declarative mobile E2E testing framework. [[ios-e2e-testing-research-2026]]

## Key Facts

| Attribute | Value |
|-----------|-------|
| Type | Black-box, accessibility layer |
| Language | YAML (+ JavaScript via `evalScript`) |
| iOS Support | Simulator only (no local real device) |
| License | Apache 2.0 (open source) |
| GitHub Stars | 13,479 |
| Latest Version | CLI 2.4.0 (April 2, 2026) |
| Setup Time | ~30 minutes |

## Installation

```bash
# Option 1: curl
curl -fsSL "https://get.maestro.mobile.dev" | bash

# Option 2: Homebrew
brew tap mobile-dev-inc/tap
brew install mobile-dev-inc/tap/maestro
```

Prerequisites: Java 17+, Xcode with Command Line Tools.

## iOS Capabilities

- **Framework-agnostic**: Swift, ObjC, SwiftUI, Flutter, RN — analyzes accessibility tree
- **No source code required**: Black-box testing
- **System interactions**: Permission dialogs, multi-app flows, orientation
- **Visual regression**: `assertScreenshot` command (v2.3.0+)
- **AI assistant**: MaestroGPT generates commands from natural language (since April 2025)
- **Maestro Studio**: Visual test builder with live UI + auto-generated YAML

## Critical Limitation

**No local iOS real-device testing.** Most requested feature since January 2023, still unresolved. Apple's UI automation restrictions are the root cause.

Workarounds:
- BrowserStack App Automate (cloud real devices)
- TestingBot (physical iOS support since Jan 2026)
- Community tool `maestro-ios-device` (USB-based, limited)

## YAML Syntax Example

```yaml
appId: com.example.myapp
---
- launchApp
- tapOn: "Login"
- inputText:
    id: "email"
    text: "test@example.com"
- tapOn: "Submit"
- assertVisible: "Welcome"
```

Advanced features: conditionals (`when`), sub-flows (`runFlow`), environment variables, JavaScript (`evalScript` with GraalJS), relative selectors, timeouts, continuous mode, recording.

## Pricing

| Tier | Price |
|------|-------|
| Local (CLI, Studio, MaestroGPT) | Free |
| Cloud | $250/device/month (iOS/Android), $125/browser/month |
| Enterprise | Custom |

## Community Feedback

**Strengths:**
- "Genuinely plug-and-play" vs Appium
- YAML readable by anyone
- Smart waiting reduces flakiness
- ~2x faster app boot than Appium
- Cross-platform with minimal adjustments

**Pain Points:**
- No local iOS real-device testing
- YAML DSL ceiling for complex enterprise scenarios
- Cryptic error messages / debugging experience
- Documentation gaps for advanced features
- Smaller ecosystem than Appium
- Cloud 15-minute soft execution limit

**G2 Rating**: 4.4/5 (15 reviews)

## See Also

- [[e2e-testing-strategy]]
- [[appium]]
- [[xcuitest]]

---

# 中文翻译

# Maestro

黑盒、YAML 声明式移动端 E2E 测试框架。[[ios-e2e-testing-research-2026]]

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | 黑盒，基于无障碍层 |
| 语言 | YAML（+ JavaScript，通过 `evalScript`） |
| iOS 支持 | 仅模拟器（不支持本地真机） |
| 许可证 | Apache 2.0（开源） |
| GitHub Stars | 13,479 |
| 最新版本 | CLI 2.4.0（2026年4月2日） |
| 上手时间 | 约30分钟 |

## 安装

```bash
# 方式一：curl
curl -fsSL "https://get.maestro.mobile.dev" | bash

# 方式二：Homebrew
brew tap mobile-dev-inc/tap
brew install mobile-dev-inc/tap/maestro
```

前提条件：Java 17+，Xcode 及命令行工具。

## iOS 能力

- **框架无关**：支持 Swift、ObjC、SwiftUI、Flutter、RN — 分析无障碍树
- **无需源代码**：黑盒测试
- **系统交互**：权限弹窗、多应用流程、屏幕方向
- **视觉回归**：`assertScreenshot` 命令（v2.3.0+）
- **AI 助手**：MaestroGPT 从自然语言生成命令（2025年4月起）
- **Maestro Studio**：可视化测试构建器，实时 UI + 自动生成 YAML

## 关键限制

**不支持本地 iOS 真机测试。** 自2023年1月以来最多人请求的功能，至今未解决。根本原因是 Apple 的 UI 自动化限制。

替代方案：
- BrowserStack App Automate（云端真机）
- TestingBot（2026年1月起支持物理 iOS 设备）
- 社区工具 `maestro-ios-device`（USB 方式，功能有限）

## YAML 语法示例

```yaml
appId: com.example.myapp
---
- launchApp
- tapOn: "Login"
- inputText:
    id: "email"
    text: "test@example.com"
- tapOn: "Submit"
- assertVisible: "Welcome"
```

高级功能：条件执行（`when`）、子流程（`runFlow`）、环境变量、JavaScript（`evalScript` + GraalJS）、相对选择器、超时设置、持续模式、录制。

## 定价

| 层级 | 价格 |
|------|------|
| 本地（CLI、Studio、MaestroGPT） | 免费 |
| 云端 | $250/设备/月（iOS/Android），$125/浏览器/月 |
| 企业版 | 定制 |

## 社区反馈

**优势：**
- 相比 Appium "开箱即用"
- YAML 任何人都能读懂
- 智能等待减少不稳定性
- 应用启动速度约为 Appium 的2倍
- 跨平台只需少量调整

**痛点：**
- 不支持本地 iOS 真机测试
- YAML DSL 在复杂企业场景下有天花板
- 错误信息不够清晰/调试体验差
- 高级功能文档不足
- 生态规模小于 Appium
- 云端执行有15分钟软限制

**G2 评分**：4.4/5（15条评价）

## 参见

- [[e2e-testing-strategy]]
- [[appium]]
- [[xcuitest]]
