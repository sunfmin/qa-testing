# WebDriverAgent (WDA) Wiki

## 目录

- [概述](#概述)
- [历史与维护者](#历史与维护者)
- [技术原理](#技术原理)
- [架构设计](#架构设计)
- [主要功能与用途](#主要功能与用途)
- [安装与配置](#安装与配置)
- [与 Appium 的关系](#与-appium-的关系)
- [API 端点参考](#api-端点参考)
- [常见问题与排查](#常见问题与排查)
- [替代方案与相关工具](#替代方案与相关工具)
- [项目现状](#项目现状)

---

## 概述

**WebDriverAgent (WDA)** 是一个运行在 iOS/tvOS 设备上的 **WebDriver 协议服务器**。它允许通过标准 HTTP 请求远程控制 iOS 设备和模拟器，执行启动/关闭应用、点击、滑动、截图、获取元素属性等操作。

简单来说：WDA 把一台 iOS 设备变成了一个可以通过 HTTP API 操控的自动化终端。

**仓库地址：** <https://github.com/appium/WebDriverAgent>
**NPM 包名：** `appium-webdriveragent`
**许可证：** BSD License

---

## 历史与维护者

| 时间 | 事件 |
|------|------|
| ~2015 | Facebook（现 Meta）创建 WebDriverAgent，作为内部 iOS 自动化测试工具 |
| 2017-03-14 | Appium 社区从 `facebook/WebDriverAgent` fork 到 `appium/WebDriverAgent` |
| 2025-12 | v11.0.0 发布，Node.js 包从 JavaScript 全面迁移到 TypeScript |
| 2026-04-14 | v12.0.0 发布（最新版本） |

**核心维护者：**

- **mykola-mokhnach** — 主要维护者（382+ 贡献）
- **KazuCocoa** — 233+ 贡献
- **imurchie** — 124+ 贡献
- **jlipps**（Jonathan Lipps）— Appium 项目负责人

---

## 技术原理

WDA 的核心思路可以概括为一句话：**把 Apple 的 XCTest 框架当作一个"永不结束的测试"来运行，在测试进程里启动一个 HTTP 服务器来接收外部命令。**

### 关键技术点

### 1. 基于 XCTest 框架

WDA 本质上是一个 XCTest Bundle（`WebDriverAgentRunner`）。它的入口点是一个 "测试方法"，但这个方法不会结束——它启动一个 HTTP 服务器并持续运行：

```objc
// UITestingUITests.m
- (void)testRunner {
    FBWebServer *webServer = [[FBWebServer alloc] init];
    webServer.delegate = self;
    [webServer startServing];  // 阻塞，永远不会返回
}
```

### 2. 内嵌 HTTP 服务器

WDA 内嵌了一个基于 **CocoaHTTPServer** + **RoutingHTTPServer** 的 HTTP 服务器：

- **主服务器端口：8100** — 处理 WebDriver 协议请求
- **MJPEG 服务器端口：9100** — 实时屏幕画面流（MJPEG 格式）

### 3. 实现 WebDriver 协议

WDA 实现了 [W3C WebDriver 规范](https://w3c.github.io/webdriver/webdriver-spec.html) 的大部分接口，以及部分 [Mobile JSON Wire Protocol](https://github.com/SeleniumHQ/mobile-spec/blob/master/spec-draft.md) 扩展。请求以标准 RESTful HTTP 方式发送：

```
POST /session                     → 创建会话
POST /session/:id/element         → 查找元素
POST /session/:id/element/:id/click → 点击元素
GET  /screenshot                  → 截图
DELETE /session/:id               → 销毁会话
```

### 4. 调用 Apple 私有 API

WDA 通过 Objective-C Category 扩展了 `XCUIElement`、`XCUIDevice`、`XCUIApplication` 等类，利用 XCTest 框架的公开和私有 API 实现底层操作（点击、滑动、输入、旋转等）。`PrivateHeaders` 目录包含了公开 API 未暴露的功能头文件。

### 5. USB 通信

对于真机，通过 `appium-ios-device` 库实现 USB 端口转发，无需依赖 `libimobiledevice` 等第三方工具。

---

## 架构设计

WDA 采用经典的 **客户端-服务器** 模型，整体架构分为三层：

```
┌─────────────────────────────────────┐
│   测试脚本 / Appium 客户端           │  ← Python / Java / JS 测试代码
│   (WebDriver Client)                │
└──────────────┬──────────────────────┘
               │ WebDriver HTTP 协议
               ▼
┌─────────────────────────────────────┐
│   Appium Server / XCUITest Driver   │  ← Node.js 进程
│   (appium-xcuitest-driver)          │
└──────────────┬──────────────────────┘
               │ xcodebuild / USB 端口转发
               ▼
┌─────────────────────────────────────┐
│   WebDriverAgent (设备端)            │  ← Objective-C, 运行在设备上
│   ┌───────────────────────────────┐ │
│   │ HTTP Server (port 8100)       │ │
│   │ MJPEG Server (port 9100)     │ │
│   └───────────────────────────────┘ │
│   ┌───────────────────────────────┐ │
│   │ XCTest Framework              │ │
│   │ → XCUIElement 操作            │ │
│   │ → XCUIDevice 控制             │ │
│   │ → XCUIApplication 管理        │ │
│   └───────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │ Apple 框架调用
               ▼
┌─────────────────────────────────────┐
│   被测 iOS 应用 (AUT)               │
└─────────────────────────────────────┘
```

### 设备端代码结构

```
WebDriverAgentLib/
├── Routing/          → HTTP 路由、会话管理、元素缓存
│   ├── FBWebServer
│   ├── FBRoute
│   ├── FBSession
│   └── FBElementCache
├── Commands/         → WebDriver 命令处理器
│   ├── FBElementCommands        (元素操作)
│   ├── FBFindElementCommands    (元素查找)
│   ├── FBSessionCommands        (会话管理)
│   ├── FBAlertViewCommands      (弹窗处理)
│   ├── FBScreenshotCommands     (截图)
│   ├── FBTouchActionCommands    (触摸操作)
│   ├── FBOrientationCommands    (屏幕方向)
│   └── FBCustomCommands         (自定义扩展)
├── Categories/       → ObjC Category 扩展
├── Utilities/        → 工具类（图片处理、XPath、键盘等）
└── Vendor/           → 内嵌的第三方库
```

### 通信流程

1. Appium 通过 `xcodebuild` 将 WDA 编译并安装到目标设备
2. WDA 作为 XCTest 在设备上启动，开始监听 8100 端口
3. 对于真机：通过 USB 端口转发将本机端口映射到设备的 8100 端口
4. 对于模拟器：直接通过 localhost:8100 通信
5. Appium 代理 WebDriver 命令到 WDA 的 HTTP 服务器
6. WDA 解析请求，调用 XCTest API 执行操作，返回结果

---

## 主要功能与用途

### 核心功能

| 功能 | 说明 |
|------|------|
| 应用管理 | 启动、关闭、激活、后台运行应用 |
| 元素交互 | 点击、长按、双击、输入文字、清除文字 |
| 手势操作 | 滑动、拖拽、捏合缩放、Force Touch |
| 元素查找 | 支持 accessibility id、class name、xpath、predicate string、class chain |
| 截图 | 全屏截图、元素截图、MJPEG 实时流 |
| 设备控制 | 屏幕旋转、锁屏/解锁、音量控制、Touch ID/Face ID 模拟 |
| 弹窗处理 | 系统弹窗的检测和自动处理 |
| 剪贴板 | 读写设备剪贴板内容 |
| 屏幕录制 | 录制设备屏幕视频 |

### 典型使用场景

1. **移动端自动化测试** — 最主要的用途，自动化 iOS 应用的功能测试和回归测试
2. **Appium iOS 驱动** — 作为 Appium XCUITest Driver 的核心引擎
3. **CI/CD 流水线** — 集成到 Jenkins、GitHub Actions 等 CI 系统中实现自动化回归
4. **设备农场** — AWS Device Farm、BrowserStack、Sauce Labs 等云测试平台的底层支撑
5. **tvOS 自动化** — 支持 Apple TV 的自动化测试（基于焦点导航）
6. **远程屏幕监控** — 通过 MJPEG 流实时查看设备屏幕

---

## 安装与配置

### 前置条件

- macOS 系统
- **Xcode** 已安装
- **Node.js** ^20.19.0 || ^22.12.0 || >=24.0.0
- **npm** >= 10
- 真机测试需要 Apple Developer 账号和有效的 Provisioning Profile

### 方式一：通过 Appium 安装（推荐）

```bash
# 安装 Appium
npm install -g appium

# 安装 XCUITest 驱动（自动包含 WDA）
appium driver install xcuitest

# 启动 Appium 服务
appium
```

XCUITest 驱动会自动管理 WDA 的编译、安装和启动。

### 方式二：手动安装

```bash
# 克隆仓库
git clone https://github.com/appium/WebDriverAgent.git
cd WebDriverAgent

# 安装依赖
npm install
```

然后在 Xcode 中：

1. 打开 `WebDriverAgent.xcodeproj`
2. 选择 `WebDriverAgentRunner` target
3. 在 Signing & Capabilities 中设置有效的 Development Team
4. 选择目标设备，运行测试（Cmd+U）

### 方式三：预编译包

```bash
npm run bundle          # 同时构建 iOS 和 tvOS 模拟器包
npm run bundle:ios      # 仅 iOS 模拟器
npm run bundle:tv       # 仅 tvOS 模拟器
```

### 真机配置要点

对于真机测试，必须正确配置代码签名：

```
xcodeOrgId        → Apple Developer Team ID
xcodeSigningId    → "iPhone Developer"（默认）
updatedWDABundleId → 自定义 Bundle ID（如有需要）
```

### 关键配置参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `wdaLocalPort` | 8100 | 本机映射端口 |
| `wdaRemotePort` | 8100 | 设备端端口 |
| `mjpegServerPort` | 9100 | MJPEG 流端口 |
| `derivedDataPath` | - | Xcode DerivedData 路径（缓存加速编译） |
| `usePrebuiltWDA` | false | 使用预编译的 WDA |
| `usePreinstalledWDA` | false | 使用设备上已安装的 WDA |

---

## 与 Appium 的关系

```
Appium 生态系统中的位置：

Appium (服务端框架)
├── appium-xcuitest-driver (iOS 驱动)
│   └── appium-webdriveragent (WDA Node.js 包装)
│       └── WebDriverAgent (设备端 Objective-C 组件)  ← 就是这个
├── appium-uiautomator2-driver (Android 驱动)
├── appium-mac2-driver (macOS 驱动)
└── ...其他驱动
```

**关系总结：**

- WDA 是 Appium 控制 iOS 设备的**核心引擎**
- `appium-xcuitest-driver` 依赖 `appium-webdriveragent` npm 包
- 启动 Appium iOS 会话时的流程：
  1. XCUITest Driver 通过 `xcodebuild` 编译 WDA
  2. 将 WDA 安装到目标设备
  3. 以 XCTest 方式启动 WDA
  4. 建立到 WDA HTTP 服务器的代理连接
  5. 将 Appium WebDriver 命令转发给 WDA
- WDA 也可以**独立于 Appium** 使用，直接向其 HTTP API 发送请求

---

## API 端点参考

以下是 WDA 主要的 HTTP API 端点：

### 会话管理

```
POST   /session                     创建新会话
GET    /session/:sessionId          获取会话信息
DELETE /session/:sessionId          销毁会话
GET    /status                      获取 WDA 状态
GET    /wda/healthcheck             健康检查
```

### 元素查找

```
POST   /session/:id/element         查找单个元素
POST   /session/:id/elements        查找多个元素
POST   /session/:id/element/:id/element   在元素内查找子元素
```

支持的定位策略：
- `accessibility id` — 推荐，性能最好
- `class name` — XCUIElementType
- `xpath` — 功能强大但性能较差
- `-ios predicate string` — NSPredicate 表达式
- `-ios class chain` — WDA 特有的类链查找

### 元素操作

```
POST   /session/:id/element/:id/click     点击
POST   /session/:id/element/:id/value     输入文字
POST   /session/:id/element/:id/clear     清除内容
GET    /session/:id/element/:id/text      获取文字
GET    /session/:id/element/:id/name      获取名称
GET    /session/:id/element/:id/displayed 是否可见
GET    /session/:id/element/:id/enabled   是否可用
GET    /session/:id/element/:id/rect      获取位置和大小
GET    /session/:id/element/:id/attribute/:name  获取属性
```

### 触摸与手势

```
POST   /session/:id/actions               W3C Actions（推荐）
POST   /session/:id/wda/touch/perform     Touch Action
POST   /session/:id/wda/dragfromtoforduration  拖拽
```

### 设备控制

```
GET    /session/:id/orientation           获取屏幕方向
POST   /session/:id/orientation           设置屏幕方向
POST   /session/:id/wda/lock              锁屏
POST   /session/:id/wda/unlock            解锁
GET    /screenshot                        截图
POST   /session/:id/wda/pressButton       按下物理按钮
```

### 应用管理

```
POST   /session/:id/wda/apps/launch       启动应用
POST   /session/:id/wda/apps/terminate    关闭应用
POST   /session/:id/wda/apps/activate     激活应用
GET    /session/:id/wda/apps/state        应用状态
```

---

## 常见问题与排查

### 1. 代码签名错误（真机）

**现象：** `Code signing is required for product type 'UI Testing Bundle'`

**解决：**
- 在 Xcode 中为 `WebDriverAgentRunner` target 配置有效的 Development Team
- 确保 Provisioning Profile 有效且未过期
- 如需自定义 Bundle ID，使用 `updatedWDABundleId` 参数

### 2. 端口冲突

**现象：** `Unable to start web server on port 8100`

**解决：**
```bash
# 查找占用端口的进程
lsof -i :8100
# 终止进程
kill -9 <PID>
```
或使用 `wdaLocalPort` 参数指定其他端口。

### 3. 截图超时

**现象：** `Cannot take a screenshot within 20000 ms`

**原因：** 可能与 DRM 保护内容、系统弹窗遮挡或设备负载过高有关。

**解决：**
- 关闭 DRM 保护的应用
- 增加截图超时时间
- 检查设备是否有系统弹窗阻塞

### 4. MJPEG 服务器阻塞

**现象：** WDA 所有 HTTP 请求无响应

**原因：** 当截图持续失败时，MJPEG 服务器可能阻塞整个 HTTP 管线。

**解决：** 升级到 v11.4.1+（增加了指数退避机制），或禁用 MJPEG 流。

### 5. 键盘无法关闭

**现象：** `hideKeyboard` 不生效

**原因：** WDA 原生不支持 `hideKeyboard`。

**解决：** 使用替代方案：
- 点击键盘上的 "Done"/"Return" 按钮
- 点击输入框之外的区域
- 使用 `pressButton: "home"` 回到桌面再返回

### 6. WDA 与新 Xcode 版本不兼容

**解决：** 更新到最新版本的 WDA / appium-xcuitest-driver。每个 Xcode 大版本更新通常需要 WDA 的配套更新。

### 7. Flutter 应用崩溃

**现象：** 操作 Flutter 应用时 WDA 触发崩溃

**原因：** Flutter v3.22+ 与 WDA 的某些交互存在兼容性问题。

**解决：** 关注 GitHub issue #922 的更新。

---

## 替代方案与相关工具

| 工具 | 类型 | 特点 |
|------|------|------|
| **XCUITest（原生）** | Apple 官方 | 直接用 Swift/ObjC 写测试，性能最好，但不跨平台 |
| **Detox (Wix)** | 灰盒测试 | 面向 React Native，与应用深度集成 |
| **Earl Grey (Google)** | 白盒测试 | Google 出品，与 XCTest 深度集成 |
| **Maestro** | 黑盒测试 | YAML 语法，上手简单，适合简单场景 |
| **Tidevice (Alibaba)** | 设备管理 | Python 工具，可与 WDA 配合使用 |
| **go-ios** | 设备通信 | Go 实现的 iOS 设备通信库 |
| **libimobiledevice** | 设备通信 | C 语言 iOS 设备通信库（WDA 已不再依赖） |

**何时选择 WDA / Appium：**
- 需要跨平台（iOS + Android）自动化
- 需要使用多种编程语言编写测试（Python, Java, JS, Ruby 等）
- 需要与现有 Selenium 生态集成
- 需要设备农场支持

**何时考虑替代方案：**
- 仅做 iOS 测试 → 原生 XCUITest 性能更好
- React Native 项目 → Detox 集成更深
- 简单的 UI 测试 → Maestro 更易上手

---

## 项目现状

截至 2026 年 4 月：

- **最新版本：** v12.0.0（2026-04-14 发布）
- **GitHub Stars：** 1,637
- **开发语言：** Objective-C（设备端，~1.15M 行）+ TypeScript（Node.js 包装，~94K 行）
- **维护状态：** 活跃，每周多次提交
- **支持平台：** iOS 设备/模拟器、tvOS 设备/模拟器

**v12.0.0 Breaking Changes：**
- 移除了已弃用的 idb typing
- 移除了 `includeNonModalElements` 设置
- 移除了 `shouldUseTestManagerForVisibilityDetection` capability

WDA 作为 Appium iOS 自动化的基石，在移动端测试领域仍然是事实标准，项目保持着健康的开发节奏。
