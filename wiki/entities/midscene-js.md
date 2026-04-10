---
title: Midscene.js
type: entity
created: 2026-04-10
updated: 2026-04-10
tags: [testing, vision-ai, ios, android, web, desktop, open-source, bytedance]
sources: [ios-e2e-testing-research-2026]
---

# Midscene.js

Vision-based UI automation framework by ByteDance. Uses VLMs to understand screenshots and interact with UIs through natural language — no selectors, no accessibility IDs needed. Supports web, iOS, Android, and desktop.

## Key Facts

| Attribute | Value |
|-----------|-------|
| Type | Pure vision, VLM-powered |
| Language | TypeScript (SDK + YAML CLI) |
| Platforms | Web (Playwright/Puppeteer), iOS (WDA), Android (adb), Desktop |
| License | MIT |
| GitHub Stars | 12,551 |
| Latest Version | 1.7.3 (April 9, 2026) |
| npm Downloads | ~69k/month |
| Created | July 2024 |

## Architecture

Monorepo with 27 packages:
- **`@midscene/core`** — AI model communication, prompt engineering, element localization
- **`@midscene/web`** — Playwright/Puppeteer adapter
- **`@midscene/android`** — adb adapter
- **`@midscene/ios`** — WebDriverAgent adapter
- **`@midscene/computer`** — Desktop adapter
- **`@midscene/cli`** — YAML script runner
- **MCP servers** — `@midscene/ios-mcp`, `@midscene/android-mcp`, `@midscene/web-bridge-mcp`, `@midscene/computer-mcp`

How it works:
1. Take screenshot of current UI
2. Send screenshot + natural language instruction to VLM
3. VLM returns coordinates for target element
4. Midscene translates to platform-specific action (tap, input, etc.)

## API Surface

### Interaction
| Method | Purpose |
|--------|---------|
| `aiAct(prompt)` / `ai(prompt)` | Multi-step interaction with AI planning |
| `aiTap(locate)` | Tap/click a visually-described element |
| `aiInput(locate, {value})` | Type text into a located element |
| `aiScroll(locate?, {direction})` | Scroll |
| `aiPinch(locate?, {direction})` | Two-finger pinch (mobile) |
| `aiKeyboardPress(locate, {keyName})` | Press a key |

### Data Extraction
| Method | Returns |
|--------|---------|
| `aiQuery<T>(dataDemand)` | Structured data matching your schema |
| `aiAsk(prompt)` | Free-form string |
| `aiBoolean(prompt)` | `boolean` |
| `aiNumber(prompt)` | `number` |

### Assertion & Wait
| Method | Purpose |
|--------|---------|
| `aiAssert(assertion)` | Throws if condition is false |
| `aiWaitFor(assertion, {timeoutMs?})` | Polls until condition is true |

## iOS Testing

**Package:** `@midscene/ios`

**Prerequisites:** macOS, Xcode, Node.js >= 18, WebDriverAgent >= 7.0 running

**Setup:**
1. Install WDA on simulator or real device
2. Verify: `curl http://localhost:8100/status`
3. `npm install @midscene/ios --save-dev`
4. Real devices: `iproxy 8100 8100 <DEVICE_ID>`

**Quick start (no-code playground):**
```bash
npx --yes @midscene/ios-playground
```

**Code example:**
```typescript
import { agentFromWebDriverAgent } from '@midscene/ios';

const agent = await agentFromWebDriverAgent({ wdaPort: 8100, wdaHost: 'localhost' });
await agent.aiAct('Search for "Headphones"');
await agent.aiWaitFor('Products are displayed');
const items = await agent.aiQuery('{itemTitle: string, price: Number}[]');
await agent.aiAssert('Multiple products visible');
```

## Android Testing

**Package:** `@midscene/android`

**Setup:** ADB installed, device connected via USB with debugging enabled.

```typescript
import { AndroidAgent, AndroidDevice, getConnectedDevices } from '@midscene/android';

const devices = await getConnectedDevices();
const device = new AndroidDevice(devices[0].udid);
const agent = new AndroidAgent(device);
await device.connect();
await agent.aiAct('open browser and navigate to ebay.com');
```

## YAML Support (First-Class)

Midscene has full YAML declarative test format — this was our key identified gap, but it already exists.

```yaml
ios:
  wdaPort: 8100
  wdaHost: localhost

tasks:
  - name: Login Flow
    flow:
      - aiTap: Login button
      - aiInput: Email field
        value: "test@example.com"
      - aiTap: Sign In
      - sleep: 2000
      - aiAssert: Welcome message is displayed
      - aiQuery: "What is the username shown?"
        name: username
```

**Run via CLI:**
```bash
npm install -g @midscene/cli
midscene run test.yaml
midscene ./midscene-scripts/   # run all YAML files in directory
```

## VLM Providers

| Provider | Models | Notes |
|----------|--------|-------|
| **Qwen** (Alibaba) | qwen3.5, qwen3.6, qwen3-vl, qwen2.5-vl | Recommended |
| **Doubao** (ByteDance) | doubao-seed, doubao-vision | Strong at UI planning |
| **Gemini** (Google) | gemini-3-pro, gemini-3-flash | Good option |
| **GPT** (OpenAI) | gpt-5 | Supported |
| **UI-TARS** (ByteDance) | 2B/7B/72B | Self-hostable, purpose-built for UI |
| **GLM-V** (Zhipu AI) | GLM-4.6V | Open-source weights |

> [!note] **No native Claude/Anthropic support.** Uses OpenAI-compatible API exclusively. Would need a proxy (e.g., LiteLLM) to use Claude as the VLM.

**Configuration:**
```bash
export MIDSCENE_MODEL_NAME="qwen-vl-max-latest"
export MIDSCENE_MODEL_API_KEY="sk-xxx"
export MIDSCENE_MODEL_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"
export MIDSCENE_MODEL_FAMILY="qwen3.5"
```

## MCP Servers (Claude Code Integration)

```json
{
  "mcpServers": {
    "midscene-ios": {
      "command": "npx",
      "args": ["-y", "@midscene/ios-mcp"],
      "env": {
        "MIDSCENE_MODEL_BASE_URL": "...",
        "MIDSCENE_MODEL_API_KEY": "...",
        "MIDSCENE_MODEL_NAME": "...",
        "MIDSCENE_MODEL_FAMILY": "..."
      }
    }
  }
}
```

> [!note] There is an open bug (#2150): "Error occurs when triggering Midscene with skills in Claude Code."

## Caching

- Caches AI planning steps and element locations in `.cache.yaml` files
- Four strategies: disabled, read-write (default), read-only, write-only
- Reported speedup: 51s → 28s (~45% faster)
- `aiQuery`, `aiAssert` results are NOT cached (dynamic state)

## Performance

- **Per-step latency:** 3-10 seconds (VLM inference round-trip)
- **10-step test:** ~60-90 seconds without cache, ~30-50 seconds with cache
- Non-deterministic (VLM is probabilistic)
- Every step incurs VLM API cost

## CI/CD

```yaml
# GitHub Actions
- name: Run Midscene tests
  env:
    MIDSCENE_MODEL_API_KEY: ${{ secrets.MODEL_API_KEY }}
    MIDSCENE_MODEL_NAME: 'qwen-vl-max-latest'
    MIDSCENE_MODEL_FAMILY: 'qwen3.5'
  run: |
    npm install -g @midscene/cli
    midscene ./midscene-scripts/
```

Reports: HTML replay reports with screenshots at each step.

## Limitations

- **Speed:** 3-10s per step due to VLM inference
- **Non-deterministic:** Same prompt can produce different results across runs
- **No native Claude support:** Needs OpenAI-compatible API proxy
- **Cost:** Every test step incurs VLM API charges
- **Claude Code integration bugs:** Open issue #2150
- **Real iOS device setup:** Complex (certificates, Developer Mode, WDA, port forwarding)
- **API still stabilizing:** Rapid version churn (v1.0 was recent)

## When to Use vs Not

**Choose Midscene when:**
- UI changes frequently and selector maintenance is painful
- Testing canvas/WebGL apps (no DOM)
- Non-engineers need to write tests
- Need cross-platform (web + mobile + desktop) with one framework

**Don't choose Midscene when:**
- Need fast, deterministic CI (3-10s/step is too slow)
- Need pixel-perfect assertions
- Zero API cost is required
- Performance-critical pipelines

## See Also

- [[drizz]] — commercial tool with similar vision AI approach
- [[drizz-clone-spec]] — Iris spec that Midscene may largely replace
- [[appium]] — traditional selector-based alternative
- [[maestro]] — YAML-based alternative using accessibility layer

---

# 中文翻译

# Midscene.js

字节跳动出品的视觉 UI 自动化框架。使用 VLM 理解截图并通过自然语言与界面交互——无需选择器、无需无障碍 ID。支持 Web、iOS、Android 和桌面。

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | 纯视觉，VLM 驱动 |
| 语言 | TypeScript（SDK + YAML CLI） |
| 平台 | Web、iOS（WDA）、Android（adb）、桌面 |
| 许可证 | MIT |
| GitHub Stars | 12,551 |
| 最新版本 | 1.7.3（2026年4月9日） |
| npm 下载量 | ~6.9万/月 |

## 架构

27 个包的 Monorepo：核心引擎 + 各平台适配器 + CLI + MCP 服务器。

工作原理：截图 → 发送到 VLM + 自然语言指令 → VLM 返回坐标 → 转换为平台操作。

## iOS 测试

通过 WebDriverAgent（与 Appium 相同方案）。支持模拟器和真机。

```typescript
const agent = await agentFromWebDriverAgent({ wdaPort: 8100 });
await agent.aiAct('搜索 "耳机"');
await agent.aiAssert('显示了多个产品');
```

## YAML 支持（一等公民）

```yaml
ios:
  wdaPort: 8100
tasks:
  - name: 登录流程
    flow:
      - aiTap: 登录按钮
      - aiInput: 邮箱输入框
        value: "test@example.com"
      - aiAssert: 显示欢迎消息
```

运行：`midscene run test.yaml`

## VLM 提供商

支持 Qwen（推荐）、Doubao、Gemini、GPT-5、UI-TARS（可自托管）。**不原生支持 Claude**，需要 OpenAI 兼容 API 代理。

## MCP 服务器

提供 `@midscene/ios-mcp`、`@midscene/android-mcp` 等，可直接在 Claude Code 中使用。但有已知的 Claude Code 集成 bug（#2150）。

## 性能

- 每步 3-10 秒（VLM 推理）
- 缓存可提速约 45%
- 非确定性（VLM 是概率性的）
- 每步都有 VLM API 成本

## 对 Iris 项目的影响

Midscene.js 已经实现了 Iris 规格中计划的几乎所有功能：
- iOS 真机支持（WDA）✓
- Android（adb）✓
- YAML 声明式测试 ✓
- CLI 运行器 ✓
- MCP 服务器 ✓
- 视觉缓存 ✓

建议基于 Midscene.js 构建，而非从零开发。

## 参见

- [[drizz]] — 类似视觉 AI 方法的商业工具
- [[drizz-clone-spec]] — Midscene.js 可能大幅取代的 Iris 规格
- [[appium]] — 传统选择器方案
- [[maestro]] — 基于无障碍层的 YAML 方案
