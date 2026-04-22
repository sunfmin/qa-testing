---
title: Appium Mac2 Driver (WebDriverAgentMac)
type: entity
created: 2026-04-22
updated: 2026-04-22
tags: [macos, automation, xctest, webdriver, appium, objective-c, desktop]
sources: [macos-desktop-automation-2026]
---

# Appium Mac2 Driver (WebDriverAgentMac)

The macOS analog to [[webdriveragent|WDA]]. A WebDriver protocol server that runs on the Mac, turning any macOS app into a remotely controllable automation endpoint via HTTP. Internally bundles `WebDriverAgentMac` — an Xcode project whose code was **borrowed from Facebook's original WebDriverAgent** and adapted for AppKit/XCTest on the desktop. [[appium]]

## Key Facts

| Attribute | Value |
|-----------|-------|
| Type | WebDriver protocol server (host-side, XCTest-based) |
| Language | 78% Objective-C + 19.5% TypeScript + 2.4% C |
| Platforms | macOS 11+ (Big Sur and later) |
| License | Apache 2.0 |
| GitHub | [appium/appium-mac2-driver](https://github.com/appium/appium-mac2-driver) — 172 stars |
| Latest Version | v3.3.1 (2026-04-15) |
| NPM Package | `appium-mac2-driver` |
| Default Port | 10100 (vs. WDA's 8100) |
| Requires | Xcode 13+ (14.3+ for deep links, 15+ for native recording / a11y audit) |
| Predecessor | `appium-mac-driver` (deprecated), `appium-for-mac` (deprecated) |

## How It Works

Exactly like WDA, but for macOS:

```
Test Script (Python/Java/JS)
    │ WebDriver HTTP
    ▼
Appium Server + Mac2 Driver (Node.js)
    │ localhost:10100
    ▼
WebDriverAgentMac (Obj-C XCTest bundle)
    │ XCTest / AX API calls
    ▼
macOS App Under Test
```

The WebDriverAgentMac Xcode project runs as an XCTest process on the same Mac. Unlike iOS (where WDA runs on a physically separate device), on macOS the "device under test" and the test runner are the same machine — so there's no USB/port-forwarding layer. The driver still maintains the WDA abstraction because it lets the same W3C WebDriver client code control both platforms.

## Relation to Facebook's WDA

Quoting the README: *"Borrows the original idea and parts of the source code from Facebook's archived WebDriverAgent iOS project."* The `WebDriverAgentMac` directory is structurally parallel to the iOS `WebDriverAgent` — `FBWebServer`, `FBRouteRequest`, `FBElementCache`, the MJPEG streamer, the whole `FB*` class hierarchy, ported to AppKit. If you know WDA internals, Mac2's code layout will feel immediately familiar.

## Prerequisites (Real Pain Points)

1. **xcode-select** must point to a full Xcode install (not CommandLineTools).
2. **Accessibility permission** must be granted to `Xcode Helper.app` — located at `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/` — via System Settings → Privacy & Security → Accessibility. One-time, manual, required.
3. **testmanagerd auth bypass** (macOS 12+): run `automationmodetool enable-automationmode-without-authentication` or every session will prompt for the admin password.
4. **Code signing** the `WebDriverAgentRunner` target to silence "unidentified developer" alerts — use `appium driver run mac2 open-wda` to open the Xcode project.
5. Use `appium driver doctor mac2` to auto-validate the above.

## Element Locator Strategies

Same ranking as WDA:

1. **`accessibility id`** / `id` / `name` — maps to AX identifier, fastest
2. **`class name`** — XCUIElementType enum (e.g., `XCUIElementTypeButton`)
3. **`-ios predicate string`** — reused name; NSPredicate against element attributes
4. **`-ios class chain`** — XPath-shaped syntax, backed by predicate lookups
5. **`xpath`** — XPath 2.0 since v1.20.0; slowest

Available element attributes: `elementType`, `frame`, `label`, `title`, `identifier`, `value`, `enabled`, `focused`, `selected`, `hittable`, `placeholderValue`.

## Platform-Specific Extensions (`macos:` commands)

Mac2 exposes a rich set of `macos:` extension endpoints that WDA doesn't have equivalents for:

| Category | Commands |
|----------|----------|
| Gestures | `macos: click`, `rightClick`, `doubleClick`, `hover`, `scroll`, `clickAndDrag`, `clickAndDragAndHold` |
| Touch Bar | `macos: press`, `tap`, `doubleTap`, `pressAndDrag`, `pressAndDragAndHold` |
| Keyboard | `macos: keys` (array of strings or `{key, modifierFlags}`; modifier bitmask: Shift=2, Ctrl=4, Option=8, Cmd=16) |
| App mgmt | `macos: launchApp`, `activateApp`, `terminateApp`, `queryAppState` |
| Scripting | `macos: appleScript` — execute AppleScript/JXA inline; returns stdout |
| Media | `macos: startRecordingScreen` (FFMPEG), `startNativeScreenRecording` (XCTest, Xcode 15+), `screenshots`, `listDisplays` |
| Clipboard | `macos: setClipboard`, `getClipboard` (plaintext/image/url) |
| Deep links | `macos: deepLink` — open URL in app (Xcode 14.3+) |
| A11y audit | `macos: performAccessibilityAudit` — returns accessibility issues (Xcode 15+) |
| Source | `macos: source` — xml or description format element tree dump |

The `macos: appleScript` escape hatch is important: anything XCTest can't do (Finder operations, window manager tricks, Mission Control, Spotlight) can usually be done by dropping to AppleScript/JXA from the same session.

## W3C Actions Support

Only mouse pointer actions. No touch, no multi-finger trackpad gestures through W3C actions (use `macos:` gesture extensions instead). Actions time out at 5 minutes.

## Configuration

| Capability | Default | Purpose |
|------------|---------|---------|
| `platformName` | — | Must be `mac` |
| `automationName` | — | Must be `mac2` |
| `appium:bundleId` | — | App to launch (e.g., `com.apple.TextEdit`) |
| `appium:appPath` | — | Alternative: path to `.app` bundle |
| `appium:systemPort` | 10100 | WebDriverAgentMac HTTP port |
| `appium:systemHost` | 127.0.0.1 | Listen address |
| `appium:serverStartupTimeout` | 120000 ms | Wait for WDA to boot |
| `appium:webDriverAgentMacUrl` | — | Connect to pre-running WDA instead of launching one |
| `appium:skipAppKill` | false | Keep app alive on session end |
| `appium:prerun` / `appium:postrun` | — | AppleScript hooks |
| `appium:arguments` / `appium:environment` | — | Pass args/env to the app |

## Known Issues

- **No parallel sessions** — "highly discouraged" by the maintainers. The macOS accessibility layer is effectively single-threaded, and HID (mouse/keyboard) is exclusive. One session per Mac.
- **"Unidentified developer" alert** on first run — requires manual re-signing of the WDA target.
- **Accessibility permission creep** — every Xcode major version tends to relocate `Xcode Helper.app`, forcing users to re-grant AX permission.
- **xcodebuild startup cost** — cold boot of WebDriverAgentMac is 10-20s; use `appium:webDriverAgentMacUrl` to reuse a running instance.
- **No MJPEG stream equivalent** — Mac2 relies on `startRecordingScreen` or per-frame `screenshots`; there's no continuous stream like WDA's port 9100.

## Differences vs. iOS WDA

| Aspect | iOS WDA (port 8100) | Mac2 / WebDriverAgentMac (port 10100) |
|--------|---------------------|---------------------------------------|
| Runs on | Separate iOS device | Same Mac as the test runner |
| Transport | USB port forwarding or Wi-Fi | `localhost` only |
| Live video | MJPEG server on :9100 | None — discrete screenshots or FFMPEG recording |
| Parallelism | Multiple devices OK | One session per Mac |
| AppleScript | N/A | First-class `macos: appleScript` extension |
| Touch | W3C touch + swipe/pinch | Mouse-only W3C actions; Touch Bar via `macos:` |
| Code signing pain | Provisioning profile per device | Local signing of WDA target only |

## Relationship to This Project

Mac2 is the candidate **desktop control layer** for future macOS variants of:

- **[[drizz-clone-spec|Iris]]** — if Iris ever needs to test macOS apps (currently iOS-focused), Mac2 is the exact analog of our current WDA integration. Same element strategies, same HTTP-to-XCTest shape, same hybrid-with-Claude-vision pattern should apply.
- **[[auto-bug-fix-workflow]]** — for desktop-app bug reproduction, Mac2's `screenshots` + `macos: keys` + `macos: click` cover the action vocabulary our workflow needs; `macos: appleScript` covers the gaps.

> [!note]
> Mac2 can be used **independently of Appium** — same as WDA — by launching WebDriverAgentMac via `xcodebuild` and hitting port 10100 directly. Appium just provides a Node wrapper and session lifecycle. For our use case (single-purpose desktop control), direct HTTP is viable.

## Alternatives (when Mac2 is the wrong fit)

| Tool | When to prefer | Trade-off |
|------|---------------|-----------|
| Raw `AXUIElement` C API | Embedded in a Swift/Obj-C app, no Xcode test bundle available | Much more code; no WebDriver wrapping |
| Hammerspoon (Lua) | End-user desktop automation / hotkeys | Not built for test assertions or CI |
| SikuliX (image matching) | Legacy apps with no AX tree | Brittle to resolution/theme changes |
| `cliclick` CLI | Quick scripted clicks from shell | No element finding, pure coordinates |
| Claude Computer Use / UI-TARS | Unknown apps, exploratory agents | Vision-only, 72-84% task success, slow |
| Fazm / macos-use (AX-tree MCP) | LLM agent reading the a11y tree | Not a testing tool; no assertion model |

See [[macos-desktop-automation-landscape]] for the full comparison.

## See Also

- [[webdriveragent]] — iOS sibling; Mac2 is its direct architectural descendant
- [[appium]] — Parent framework; Mac2 plugs in as a driver
- [[xcuitest]] — XCTest is also what Mac2 sits on top of, just for macOS apps
- [[macos-desktop-automation-landscape]] — Full landscape analysis including non-Appium options

---

# 中文翻译

# Appium Mac2 Driver（WebDriverAgentMac）

macOS 版的 [[webdriveragent|WDA]]。一个运行在 Mac 上的 WebDriver 协议服务器，通过 HTTP 将任意 macOS 应用变为可远程控制的自动化终端。内部捆绑了 `WebDriverAgentMac`——一个 Xcode 工程，其代码**借自 Facebook 原版 WebDriverAgent**，移植到 AppKit/XCTest 桌面端。[[appium]]

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | WebDriver 协议服务器（主机端，基于 XCTest） |
| 语言 | 78% Objective-C + 19.5% TypeScript + 2.4% C |
| 平台 | macOS 11+（Big Sur 及以上） |
| 许可证 | Apache 2.0 |
| GitHub | [appium/appium-mac2-driver](https://github.com/appium/appium-mac2-driver) — 172 stars |
| 最新版本 | v3.3.1（2026-04-15） |
| NPM 包 | `appium-mac2-driver` |
| 默认端口 | 10100（WDA 是 8100） |
| 依赖 | Xcode 13+（深链需 14.3+，原生录屏/可访问性审计需 15+） |
| 前身 | `appium-mac-driver`（已弃用）、`appium-for-mac`（已弃用） |

## 工作原理

与 WDA 完全一致，只是目标是 macOS：

```
测试脚本 (Python/Java/JS)
    │ WebDriver HTTP
    ▼
Appium 服务器 + Mac2 Driver (Node.js)
    │ localhost:10100
    ▼
WebDriverAgentMac (Obj-C XCTest bundle)
    │ XCTest / AX API 调用
    ▼
被测 macOS 应用
```

WebDriverAgentMac Xcode 工程作为 XCTest 进程运行在同一台 Mac 上。与 iOS 不同（WDA 运行在独立设备上），macOS 的"被测设备"与测试运行器是同一台机器——因此没有 USB/端口转发层。Driver 保留 WDA 抽象是为了让同一套 W3C WebDriver 客户端代码能同时控制两个平台。

## 与 Facebook WDA 的关系

引用 README：*"借用了 Facebook 已归档的 WebDriverAgent iOS 工程的原始思路和部分源码。"* `WebDriverAgentMac` 目录在结构上与 iOS 的 `WebDriverAgent` 平行——`FBWebServer`、`FBRouteRequest`、`FBElementCache`、MJPEG 推流器、整个 `FB*` 类层次，全部移植到 AppKit。熟悉 WDA 内部结构的人，看 Mac2 代码会立刻感到眼熟。

## 前置条件（真正的痛点）

1. **xcode-select** 必须指向完整 Xcode（不是 CommandLineTools）。
2. **辅助功能权限**必须授予 `Xcode Helper.app`——位于 `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/`——通过 系统设置 → 隐私与安全性 → 辅助功能。一次性手动操作，必须。
3. **testmanagerd 免密**（macOS 12+）：运行 `automationmodetool enable-automationmode-without-authentication`，否则每次会话都会弹管理员密码框。
4. **代码签名** `WebDriverAgentRunner` target，以消除"来自身份不明开发者"弹窗——用 `appium driver run mac2 open-wda` 打开 Xcode 工程。
5. 使用 `appium driver doctor mac2` 自动校验以上条件。

## 元素定位策略

排名与 WDA 相同：

1. **`accessibility id`** / `id` / `name` — 映射到 AX identifier，最快
2. **`class name`** — XCUIElementType 枚举（如 `XCUIElementTypeButton`）
3. **`-ios predicate string`** — 名字复用；针对元素属性的 NSPredicate
4. **`-ios class chain`** — XPath 形态的语法，背后用 predicate 查找
5. **`xpath`** — 自 v1.20.0 起支持 XPath 2.0；最慢

可用元素属性：`elementType`、`frame`、`label`、`title`、`identifier`、`value`、`enabled`、`focused`、`selected`、`hittable`、`placeholderValue`。

## 平台特有扩展（`macos:` 命令）

Mac2 暴露一组 WDA 没有对应项的 `macos:` 扩展端点：

| 类别 | 命令 |
|------|------|
| 手势 | `macos: click`、`rightClick`、`doubleClick`、`hover`、`scroll`、`clickAndDrag`、`clickAndDragAndHold` |
| Touch Bar | `macos: press`、`tap`、`doubleTap`、`pressAndDrag`、`pressAndDragAndHold` |
| 键盘 | `macos: keys`（字符串数组或 `{key, modifierFlags}`；修饰位：Shift=2, Ctrl=4, Option=8, Cmd=16） |
| 应用管理 | `macos: launchApp`、`activateApp`、`terminateApp`、`queryAppState` |
| 脚本 | `macos: appleScript` — 内联执行 AppleScript/JXA；返回 stdout |
| 媒体 | `macos: startRecordingScreen`（FFMPEG）、`startNativeScreenRecording`（XCTest，Xcode 15+）、`screenshots`、`listDisplays` |
| 剪贴板 | `macos: setClipboard`、`getClipboard`（plaintext/image/url） |
| 深链 | `macos: deepLink` — 在应用中打开 URL（Xcode 14.3+） |
| 可访问性审计 | `macos: performAccessibilityAudit` — 返回无障碍问题（Xcode 15+） |
| 源树 | `macos: source` — xml 或 description 格式的元素树 dump |

`macos: appleScript` 这个后门很重要：XCTest 做不到的（Finder 操作、窗口管理、Mission Control、Spotlight）通常都能在同一会话里通过 AppleScript/JXA 完成。

## W3C Actions 支持

仅支持鼠标指针动作。不支持触摸，也不支持通过 W3C actions 的多指触控板手势（改用 `macos:` 手势扩展）。Action 5 分钟超时。

## 配置

| Capability | 默认值 | 用途 |
|------------|--------|------|
| `platformName` | — | 必须为 `mac` |
| `automationName` | — | 必须为 `mac2` |
| `appium:bundleId` | — | 要启动的应用（如 `com.apple.TextEdit`） |
| `appium:appPath` | — | 替代方案：`.app` bundle 的路径 |
| `appium:systemPort` | 10100 | WebDriverAgentMac HTTP 端口 |
| `appium:systemHost` | 127.0.0.1 | 监听地址 |
| `appium:serverStartupTimeout` | 120000 ms | 等待 WDA 启动 |
| `appium:webDriverAgentMacUrl` | — | 连接已运行的 WDA，而不是新启动一个 |
| `appium:skipAppKill` | false | 会话结束后保持应用运行 |
| `appium:prerun` / `appium:postrun` | — | AppleScript 钩子 |
| `appium:arguments` / `appium:environment` | — | 传给应用的参数/环境变量 |

## 已知问题

- **不支持并发会话** — 维护者"强烈不建议"。macOS 辅助功能层实际上是单线程的，HID（鼠标/键盘）是排他的。一台 Mac 一个会话。
- **"身份不明开发者"弹窗** — 首次运行需手动重新签名 WDA target。
- **辅助功能权限漂移** — 每个 Xcode 大版本都会改 `Xcode Helper.app` 的位置，强制用户重新授权。
- **xcodebuild 启动成本** — WebDriverAgentMac 冷启动 10-20 秒；用 `appium:webDriverAgentMacUrl` 复用已运行实例。
- **无 MJPEG 等价物** — Mac2 依赖 `startRecordingScreen` 或逐帧 `screenshots`；没有 WDA 8100 那种连续推流。

## 与 iOS WDA 的差异

| 方面 | iOS WDA（端口 8100） | Mac2 / WebDriverAgentMac（端口 10100） |
|------|---------------------|--------------------------------------|
| 运行于 | 独立 iOS 设备 | 与测试运行器同一台 Mac |
| 传输 | USB 端口转发或 Wi-Fi | 仅 `localhost` |
| 实时视频 | :9100 上的 MJPEG 服务器 | 无 — 离散截图或 FFMPEG 录屏 |
| 并行 | 多设备 OK | 每台 Mac 单会话 |
| AppleScript | 无 | 一等公民 `macos: appleScript` 扩展 |
| 触摸 | W3C 触摸 + 滑动/捏合 | 仅鼠标 W3C actions；Touch Bar 走 `macos:` |
| 代码签名痛点 | 每设备 provisioning profile | 仅本地签名 WDA target |

## 与本项目的关系

Mac2 是未来 macOS 变体的候选**桌面控制层**：

- **[[drizz-clone-spec|Iris]]** — 若 Iris 将来要测 macOS 应用（目前只做 iOS），Mac2 就是我们当前 WDA 集成的对等物。相同的元素策略，相同的 HTTP-to-XCTest 形态，相同的"混合 Claude 视觉"模式应都适用。
- **[[auto-bug-fix-workflow]]** — 对于桌面应用的 bug 复现，Mac2 的 `screenshots` + `macos: keys` + `macos: click` 覆盖了我们工作流需要的动作词汇；`macos: appleScript` 填补剩余缺口。

> [!note]
> Mac2 可以**独立于 Appium 使用**——与 WDA 相同——通过 `xcodebuild` 启动 WebDriverAgentMac 然后直接请求 10100 端口。Appium 只是提供一个 Node 封装和会话生命周期管理。对于我们的用例（单一目的的桌面控制），直接 HTTP 是可行的。

## 替代方案（Mac2 不合适时）

| 工具 | 何时优先 | 取舍 |
|------|---------|------|
| 原生 `AXUIElement` C API | 嵌入在 Swift/Obj-C 应用内、没有 Xcode test bundle | 代码量大得多；没有 WebDriver 封装 |
| Hammerspoon（Lua） | 终端用户桌面自动化/热键 | 不为测试断言或 CI 设计 |
| SikuliX（图像匹配） | 没有 AX 树的遗留应用 | 对分辨率/主题变化非常脆弱 |
| `cliclick` CLI | 从 shell 快速脚本化点击 | 没有元素查找，纯坐标 |
| Claude Computer Use / UI-TARS | 未知应用、探索式 agent | 纯视觉，任务成功率 72-84%，慢 |
| Fazm / macos-use（AX 树 MCP） | LLM agent 读取可访问性树 | 不是测试工具；无断言模型 |

完整对比见 [[macos-desktop-automation-landscape]]。

## 参见

- [[webdriveragent]] — iOS 兄弟；Mac2 是其直接架构后代
- [[appium]] — 父框架；Mac2 以 driver 形式接入
- [[xcuitest]] — Mac2 同样构建其上，只是面向 macOS 应用
- [[macos-desktop-automation-landscape]] — 包括非 Appium 选项的完整生态分析
