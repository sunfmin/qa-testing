---
title: Detox
type: entity
created: 2026-04-09
updated: 2026-04-10
tags: [testing, ios, android, e2e, react-native, gray-box]
sources: [ios-e2e-testing-research-2026]
---

# Detox (by Wix)

Gray-box E2E testing framework, primarily for React Native. [[ios-e2e-testing-research-2026]]

## Key Facts

| Attribute | Value |
|-----------|-------|
| Type | Gray-box (in-process synchronization) |
| Language | JavaScript / TypeScript |
| iOS Support | Simulator + real device (RN apps) |
| License | MIT (free) |
| GitHub Stars | 11,880 |
| Latest Version | 20.50.1 (March 23, 2026) |
| npm Downloads | ~1.9M/month |
| Setup Time | 2-4 hours |

## React Native Only?

**Primarily RN, but limited native iOS support exists.** A working `demo-native-ios` example exists in the repo. However, for pure native Swift apps you lose the gray-box synchronization advantages that make Detox special. Tests are always in JS/TS regardless.

## How Synchronization Works (Defining Feature)

Detox's native client lives **inside** the app process, monitoring:

| Resource | What It Watches |
|----------|----------------|
| Network | In-flight HTTP/HTTPS requests |
| Main thread | Dispatch queues, NSOperationQueue |
| UI layout | Layout passes, Shadow Queue |
| JS timers | setTimeout, setInterval |
| Animations | Core Animation, reanimated |
| RN bridge | Async messages crossing the bridge |

Before any test action, Detox waits until ALL resources report idle. No `sleep()` needed.

## Test Syntax

```javascript
describe('Login', () => {
  it('should login', async () => {
    await element(by.id('email')).typeText('user@test.com');
    await element(by.id('loginButton')).tap();
    await expect(element(by.text('Welcome'))).toBeVisible();
  });
});
```

## Detox Copilot (AI-powered, Oct 2024)

```javascript
await copilot.perform(
  'Navigate to Products page',
  'Tap Add to Cart for first product',
  'Verify Added to Cart popup appears'
);
```

LLM-agnostic — bring your own provider.

## Community Feedback

**Strengths:**
- When working: flakiness under 2%
- Rich action/matcher API
- Strong TypeScript support
- Actively maintained by Wix

**Pain Points:**
- Complex initial setup
- Physical device reliability issues (2/10 success rate reported)
- Looping animations break synchronization
- Android setup requires more boilerplate
- JS-only test authoring

## See Also

- [[maestro]]
- [[appium]]
- [[e2e-testing-strategy]]

---

# 中文翻译

# Detox（Wix 出品）

灰盒 E2E 测试框架，主要面向 React Native。[[ios-e2e-testing-research-2026]]

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | 灰盒（进程内同步） |
| 语言 | JavaScript / TypeScript |
| iOS 支持 | 模拟器 + 真机（RN 应用） |
| 许可证 | MIT（免费） |
| GitHub Stars | 11,880 |
| 最新版本 | 20.50.1（2026年3月23日） |
| npm 下载量 | ~190万/月 |
| 上手时间 | 2-4小时 |

## 仅限 React Native？

**主要面向 RN，但有限支持原生 iOS。** 仓库中有一个可运行的 `demo-native-ios` 示例。但对于纯原生 Swift 应用，你会失去让 Detox 与众不同的灰盒同步优势。测试始终需要用 JS/TS 编写。

## 同步机制工作原理（核心特性）

Detox 的原生客户端运行在应用进程**内部**，监控以下资源：

| 资源 | 监控内容 |
|------|----------|
| 网络 | 进行中的 HTTP/HTTPS 请求 |
| 主线程 | Dispatch 队列、NSOperationQueue |
| UI 布局 | 布局传递、Shadow Queue |
| JS 定时器 | setTimeout、setInterval |
| 动画 | Core Animation、reanimated |
| RN Bridge | 跨桥异步消息 |

在执行任何测试操作之前，Detox 等待所有资源报告空闲。无需 `sleep()`。

## 测试语法

```javascript
describe('Login', () => {
  it('should login', async () => {
    await element(by.id('email')).typeText('user@test.com');
    await element(by.id('loginButton')).tap();
    await expect(element(by.text('Welcome'))).toBeVisible();
  });
});
```

## Detox Copilot（AI 驱动，2024年10月）

```javascript
await copilot.perform(
  'Navigate to Products page',
  'Tap Add to Cart for first product',
  'Verify Added to Cart popup appears'
);
```

LLM 无关 — 可使用任意 AI 提供商。

## 社区反馈

**优势：**
- 正常工作时：不稳定率低于 2%
- 丰富的 action/matcher API
- 强大的 TypeScript 支持
- Wix 积极维护

**痛点：**
- 初始设置复杂
- 物理设备可靠性问题（有报告称成功率仅 2/10）
- 循环动画会破坏同步机制
- Android 设置需要更多样板代码
- 只能用 JS 编写测试

## 参见

- [[maestro]]
- [[appium]]
- [[e2e-testing-strategy]]
