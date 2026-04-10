---
title: XCUITest
type: entity
created: 2026-04-09
updated: 2026-04-10
tags: [testing, ios, e2e, apple, native, white-box]
sources: [ios-e2e-testing-research-2026]
---

# XCUITest

Apple's native UI testing framework, built into Xcode. [[ios-e2e-testing-research-2026]]

## Key Facts

| Attribute | Value |
|-----------|-------|
| Type | White/gray-box, native |
| Language | Swift / Objective-C |
| iOS Support | Simulator + real device (first-class) |
| License | Proprietary (part of Xcode, free) |
| Maturity | 11 years (since 2015) |
| Setup Time | 1-2 hours (with Xcode project) |
| Platform | iOS / macOS / tvOS / watchOS only |

## Setup

1. Xcode → File → New → Target → "UI Testing Bundle"
2. Configure scheme to include UI test target
3. Write tests in Swift/ObjC using `XCTestCase`

## Test Syntax

```swift
let app = XCUIApplication()
app.launch()

// Element queries
app.buttons["startButton"].tap()
app.textFields["emailField"].typeText("test@example.com")

// Assertions
XCTAssertTrue(element.exists)
let appeared = element.waitForExistence(timeout: 5.0)

// Xcode 16: wait for disappearance
element.waitForNonExistence(withTimeout: 5.0)
```

## Testing Without Source Code

Supported since Xcode 9 via bundle identifier:

```swift
let myApp = XCUIApplication(bundleIdentifier: "com.company.myapp")
myApp.launch()
// Full element query and interaction support
```

Limitation: Cannot add `.accessibilityIdentifier` without source code.

## Notable Features

- **Accessibility audits**: `performAccessibilityAudit()` (iOS 17+)
- **Performance metrics**: `XCTApplicationLaunchMetric`, `XCTCPUMetric`, `XCTMemoryMetric`
- **Parallel execution**: `-parallel-testing-enabled YES`
- **Xcode 26 (beta)**: Record-and-replay via XCUIAutomation, video recordings, enhanced result viewer

## CI/CD

```bash
xcodebuild test \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallel-testing-enabled YES
```

- Xcode Cloud: 41% adoption among iOS devs
- GitHub Actions: `macos-14` runner + `xcode-select`
- Also: Jenkins, Fastlane, Bitrise

## Community Feedback

**Strengths:**
- Fastest iOS test execution (~50% faster than Appium)
- Immediate compatibility with new iOS versions
- Deep Xcode integration (debugging, breakpoints, result bundles)
- No extra dependencies

**Pain Points:**
- Animations/async cause flakiness
- Each test relaunches app (~9-12s per test)
- WebView content largely opaque
- iOS-only (no Android)
- Verbose boilerplate, no built-in page object pattern
- Vague error messages in SwiftUI

## See Also

- [[maestro]]
- [[appium]]
- [[e2e-testing-strategy]]

---

# 中文翻译

# XCUITest

Apple 原生 UI 测试框架，内置于 Xcode。[[ios-e2e-testing-research-2026]]

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | 白/灰盒，原生 |
| 语言 | Swift / Objective-C |
| iOS 支持 | 模拟器 + 真机（一等支持） |
| 许可证 | 专有（Xcode 自带，免费） |
| 成熟度 | 11年（2015年至今） |
| 上手时间 | 1-2小时（需要 Xcode 项目） |
| 平台 | 仅 iOS / macOS / tvOS / watchOS |

## 设置

1. Xcode → File → New → Target → "UI Testing Bundle"
2. 配置 Scheme 包含 UI 测试目标
3. 使用 `XCTestCase` 以 Swift/ObjC 编写测试

## 测试语法

```swift
let app = XCUIApplication()
app.launch()

// 元素查询
app.buttons["startButton"].tap()
app.textFields["emailField"].typeText("test@example.com")

// 断言
XCTAssertTrue(element.exists)
let appeared = element.waitForExistence(timeout: 5.0)

// Xcode 16：等待元素消失
element.waitForNonExistence(withTimeout: 5.0)
```

## 无源码测试

自 Xcode 9 起支持通过 Bundle Identifier 测试：

```swift
let myApp = XCUIApplication(bundleIdentifier: "com.company.myapp")
myApp.launch()
// 支持完整的元素查询和交互
```

限制：没有源码无法添加 `.accessibilityIdentifier`。

## 主要功能

- **无障碍审计**：`performAccessibilityAudit()`（iOS 17+）
- **性能指标**：`XCTApplicationLaunchMetric`、`XCTCPUMetric`、`XCTMemoryMetric`
- **并行执行**：`-parallel-testing-enabled YES`
- **Xcode 26（beta）**：通过 XCUIAutomation 录制回放、视频录制、增强结果查看器

## CI/CD

```bash
xcodebuild test \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -parallel-testing-enabled YES
```

- Xcode Cloud：41% 的 iOS 开发者使用
- GitHub Actions：`macos-14` 运行器 + `xcode-select`
- 其他：Jenkins、Fastlane、Bitrise

## 社区反馈

**优势：**
- 最快的 iOS 测试执行速度（比 Appium 快约50%）
- 新 iOS 版本立即兼容
- 与 Xcode 深度集成（调试、断点、结果包）
- 无额外依赖

**痛点：**
- 动画/异步导致不稳定
- 每个测试都重启应用（每个测试约9-12秒）
- WebView 内容基本不可见
- 仅限 iOS（不支持 Android）
- 样板代码冗长，无内置 Page Object 模式
- SwiftUI 中错误信息模糊

## 参见

- [[maestro]]
- [[appium]]
- [[e2e-testing-strategy]]
