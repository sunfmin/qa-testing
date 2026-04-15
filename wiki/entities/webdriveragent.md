---
title: WebDriverAgent (WDA)
type: entity
created: 2026-04-15
updated: 2026-04-15
tags: [wda, ios, tvos, automation, xctest, webdriver, appium, objective-c]
sources: [webdriveragent-wiki]
---

# WebDriverAgent (WDA)

A WebDriver protocol server that runs on iOS/tvOS devices, turning them into remotely controllable automation endpoints via HTTP API. Originally created by Facebook (~2015), now maintained by the Appium community. [[appium]]

## Key Facts

| Attribute | Value |
|-----------|-------|
| Type | WebDriver protocol server (device-side) |
| Language | Objective-C (device, ~1.15M lines) + TypeScript (Node.js wrapper, ~94K lines) |
| Platforms | iOS devices/simulators, tvOS devices/simulators |
| License | BSD |
| GitHub | [appium/WebDriverAgent](https://github.com/appium/WebDriverAgent) — 1,637 stars |
| Latest Version | v12.0.0 (2026-04-14) |
| NPM Package | `appium-webdriveragent` |
| Maintenance | Active — multiple commits per week |
| Key Maintainer | mykola-mokhnach (382+ contributions) |

## How It Works

WDA is an XCTest bundle (`WebDriverAgentRunner`) whose test method never returns — it starts an HTTP server and runs indefinitely:

```objc
- (void)testRunner {
    FBWebServer *webServer = [[FBWebServer alloc] init];
    webServer.delegate = self;
    [webServer startServing];  // blocks forever
}
```

**Two servers run on device:**
- **Port 8100** — Main HTTP server handling WebDriver protocol requests
- **Port 9100** — MJPEG server streaming live screen frames

WDA implements the [W3C WebDriver spec](https://w3c.github.io/webdriver/webdriver-spec.html) plus Mobile JSON Wire Protocol extensions. It uses Objective-C categories to extend `XCUIElement`, `XCUIDevice`, and `XCUIApplication` with both public and private Apple APIs.

## Architecture Position

```
Test Script (Python/Java/JS)
    │ WebDriver HTTP
    ▼
Appium Server + XCUITest Driver (Node.js)
    │ xcodebuild / USB port forwarding
    ▼
WebDriverAgent (Obj-C, on device)
    │ XCTest framework calls
    ▼
App Under Test
```

For real devices: USB port forwarding via `appium-ios-device` (no `libimobiledevice` dependency).
For simulators: direct `localhost:8100` communication.

## Element Locator Strategies

Ranked by performance:

1. **`accessibility id`** — Fastest, recommended for all new tests
2. **`class name`** — XCUIElementType matching
3. **`-ios predicate string`** — NSPredicate expressions, powerful filters
4. **`-ios class chain`** — WDA-specific, faster than xpath with similar flexibility
5. **`xpath`** — Most flexible but significantly slower; avoid in performance-critical tests

## Key API Endpoints

| Category | Examples |
|----------|----------|
| Session | `POST /session`, `DELETE /session/:id`, `GET /status` |
| Find | `POST /session/:id/element` (single), `/elements` (multiple) |
| Actions | `POST /session/:id/element/:id/click`, `/value`, `/clear` |
| Read | `GET /session/:id/element/:id/text`, `/displayed`, `/rect` |
| Touch | `POST /session/:id/actions` (W3C Actions — recommended) |
| Device | `GET /screenshot`, `POST /session/:id/orientation`, `/wda/lock` |
| Apps | `POST /session/:id/wda/apps/launch`, `/terminate`, `/activate` |

## Configuration

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `wdaLocalPort` | 8100 | Host-side mapped port |
| `wdaRemotePort` | 8100 | Device-side port |
| `mjpegServerPort` | 9100 | MJPEG stream port |
| `derivedDataPath` | — | Cache Xcode builds for faster startup |
| `usePrebuiltWDA` | false | Skip compilation, use pre-built binary |
| `usePreinstalledWDA` | false | Use WDA already installed on device |

## Known Issues

- **MJPEG pipeline block**: When screenshots fail continuously, the MJPEG server can block all HTTP requests. Fixed in v11.4.1+ with exponential backoff.
- **Flutter incompatibility**: Flutter v3.22+ triggers WDA crashes in some interactions (GitHub #922).
- **No native `hideKeyboard`**: Must tap "Done"/"Return", tap outside the field, or press Home.
- **Xcode version coupling**: Each Xcode major release typically requires a WDA update.
- **Code signing on real devices**: Requires valid Development Team and Provisioning Profile — a persistent pain point.

## Version History

| Version | Date | Notable Change |
|---------|------|---------------|
| v12.0.0 | 2026-04-14 | Removed deprecated idb typing, `includeNonModalElements`, `shouldUseTestManagerForVisibilityDetection` |
| v11.4.1 | — | MJPEG exponential backoff fix |
| v11.0.0 | 2025-12 | Node.js package migrated from JavaScript to TypeScript |
| fork | 2017-03-14 | Appium community forked from `facebook/WebDriverAgent` |
| origin | ~2015 | Created by Facebook as internal iOS automation tool |

## Relationship to This Project

WDA is the **device control layer** for two key initiatives:

- **[[drizz-clone-spec|Iris]]** — Uses WDA for element finding (primary) with Claude vision as fallback for assertion/understanding. The hybrid approach was validated in the [[claude-vision-iphone-experiment]].
- **[[auto-bug-fix-workflow]]** — Uses WDA actions + Claude vision assertions for autonomous bug reproduction and verification on real devices.

> [!note]
> WDA can be used **independently of Appium** by sending HTTP requests directly to port 8100. This is the approach our project takes — we use WDA as a device control API without the full Appium stack.

## See Also

- [[appium]] — WDA is the core engine behind Appium's iOS automation
- [[xcuitest]] — The Apple framework WDA is built on top of
- [[drizz-clone-spec]] — Iris spec that depends on WDA for real device support
- [[claude-vision-iphone-experiment]] — Experiment validating WDA + vision hybrid approach

---

# 中文翻译

# WebDriverAgent (WDA)

运行在 iOS/tvOS 设备上的 WebDriver 协议服务器，通过 HTTP API 将设备变为可远程控制的自动化终端。最初由 Facebook 于约2015年创建，现由 Appium 社区维护。[[appium]]

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | WebDriver 协议服务器（设备端） |
| 语言 | Objective-C（设备端，约115万行）+ TypeScript（Node.js 封装，约9.4万行） |
| 平台 | iOS 设备/模拟器、tvOS 设备/模拟器 |
| 许可证 | BSD |
| GitHub | [appium/WebDriverAgent](https://github.com/appium/WebDriverAgent) — 1,637 stars |
| 最新版本 | v12.0.0（2026-04-14） |
| NPM 包 | `appium-webdriveragent` |
| 维护状态 | 活跃——每周多次提交 |
| 核心维护者 | mykola-mokhnach（382+ 贡献） |

## 工作原理

WDA 是一个 XCTest bundle（`WebDriverAgentRunner`），其测试方法永不返回——启动 HTTP 服务器后持续运行：

```objc
- (void)testRunner {
    FBWebServer *webServer = [[FBWebServer alloc] init];
    webServer.delegate = self;
    [webServer startServing];  // 永久阻塞
}
```

**设备上运行两个服务器：**
- **8100 端口** — 主 HTTP 服务器，处理 WebDriver 协议请求
- **9100 端口** — MJPEG 服务器，实时推送屏幕画面流

WDA 实现了 [W3C WebDriver 规范](https://w3c.github.io/webdriver/webdriver-spec.html) 以及 Mobile JSON Wire Protocol 扩展。通过 Objective-C Category 扩展 `XCUIElement`、`XCUIDevice` 和 `XCUIApplication`，利用 Apple 公开和私有 API。

## 架构位置

```
测试脚本 (Python/Java/JS)
    │ WebDriver HTTP
    ▼
Appium 服务器 + XCUITest Driver (Node.js)
    │ xcodebuild / USB 端口转发
    ▼
WebDriverAgent (Obj-C，运行在设备上)
    │ XCTest 框架调用
    ▼
被测应用
```

真机：通过 `appium-ios-device` 实现 USB 端口转发（不依赖 `libimobiledevice`）。
模拟器：直接通过 `localhost:8100` 通信。

## 元素定位策略

按性能排序：

1. **`accessibility id`** — 最快，推荐用于所有新测试
2. **`class name`** — XCUIElementType 匹配
3. **`-ios predicate string`** — NSPredicate 表达式，支持强大的过滤条件
4. **`-ios class chain`** — WDA 特有，比 xpath 快且灵活性相近
5. **`xpath`** — 最灵活但明显更慢；性能敏感场景应避免使用

## 关键 API 端点

| 类别 | 示例 |
|------|------|
| 会话 | `POST /session`、`DELETE /session/:id`、`GET /status` |
| 查找 | `POST /session/:id/element`（单个）、`/elements`（多个） |
| 操作 | `POST /session/:id/element/:id/click`、`/value`、`/clear` |
| 读取 | `GET /session/:id/element/:id/text`、`/displayed`、`/rect` |
| 触摸 | `POST /session/:id/actions`（W3C Actions — 推荐） |
| 设备 | `GET /screenshot`、`POST /session/:id/orientation`、`/wda/lock` |
| 应用 | `POST /session/:id/wda/apps/launch`、`/terminate`、`/activate` |

## 配置参数

| 参数 | 默认值 | 用途 |
|------|--------|------|
| `wdaLocalPort` | 8100 | 主机端映射端口 |
| `wdaRemotePort` | 8100 | 设备端端口 |
| `mjpegServerPort` | 9100 | MJPEG 流端口 |
| `derivedDataPath` | — | 缓存 Xcode 构建以加速启动 |
| `usePrebuiltWDA` | false | 跳过编译，使用预编译包 |
| `usePreinstalledWDA` | false | 使用设备上已安装的 WDA |

## 已知问题

- **MJPEG 管线阻塞**：截图持续失败时，MJPEG 服务器可能阻塞所有 HTTP 请求。v11.4.1+ 通过指数退避修复。
- **Flutter 不兼容**：Flutter v3.22+ 在某些交互中触发 WDA 崩溃（GitHub #922）。
- **无原生 `hideKeyboard`**：需点击"Done"/"Return"、点击输入框外区域、或按 Home 键。
- **Xcode 版本耦合**：每个 Xcode 大版本更新通常需要配套更新 WDA。
- **真机代码签名**：需要有效的 Development Team 和 Provisioning Profile——持续的痛点。

## 版本历史

| 版本 | 日期 | 重要变更 |
|------|------|----------|
| v12.0.0 | 2026-04-14 | 移除已弃用的 idb typing、`includeNonModalElements`、`shouldUseTestManagerForVisibilityDetection` |
| v11.4.1 | — | MJPEG 指数退避修复 |
| v11.0.0 | 2025-12 | Node.js 包从 JavaScript 迁移到 TypeScript |
| fork | 2017-03-14 | Appium 社区从 `facebook/WebDriverAgent` fork |
| 起源 | ~2015 | Facebook 作为内部 iOS 自动化工具创建 |

## 与本项目的关系

WDA 是两个关键计划的**设备控制层**：

- **[[drizz-clone-spec|Iris]]** — 使用 WDA 进行元素查找（主要方式），Claude 视觉作为断言/理解的后备。混合方案在 [[claude-vision-iphone-experiment]] 中得到验证。
- **[[auto-bug-fix-workflow]]** — 使用 WDA 操作 + Claude 视觉断言，在真机上进行自主 Bug 复现和验证。

> [!note]
> WDA 可以**独立于 Appium** 使用，直接向 8100 端口发送 HTTP 请求即可。我们的项目就是这种方式——将 WDA 作为设备控制 API，不需要完整的 Appium 技术栈。

## 参见

- [[appium]] — WDA 是 Appium iOS 自动化的核心引擎
- [[xcuitest]] — WDA 构建于其上的 Apple 框架
- [[drizz-clone-spec]] — 依赖 WDA 支持真机的 Iris 规格
- [[claude-vision-iphone-experiment]] — 验证 WDA + 视觉混合方案的实验
