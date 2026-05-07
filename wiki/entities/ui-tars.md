---
title: UI-TARS Desktop
type: entity
created: 2026-05-07
updated: 2026-05-07
tags: [bytedance, ui-tars, ai-agent, vlm, computer-use, electron, mcp, open-source, vision]
sources: [ai-driven-macos-automation-2026]
---

# UI-TARS Desktop

ByteDance's open-source GUI agent, the only project in [[ai-driven-macos-automation-2026]] that **ships its own vision-language model** specifically trained for desktop and mobile UI control. Cross-platform (Windows + macOS), Electron-based, MCP-extensible.

If [[claude-computer-use]] and [[openai-codex-mac]] are the closed-source first-party vision agents, UI-TARS is the open-source specialist alternative.

## Key facts

| Attribute | Value |
|-----------|-------|
| Vendor | ByteDance |
| GitHub | [bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) |
| Stars | 29.6k |
| License | Apache 2.0 |
| Latest version | v0.3.0 (2025-11-04) |
| Implementation | Electron desktop app, TypeScript (89.1%) |
| CLI | `npm install @agent-tars/cli@latest -g` (Node.js ≥22) |
| Platforms | Windows, macOS, plus browser-based operators |
| Models | UI-TARS-1.5 / Seed-1.5-VL / Seed-1.6 series — own VLM family |
| External LLM support | Volcengine Doubao, Anthropic Claude (via MCP) |
| Architecture | MCP kernel + Event Stream protocol |
| MCP role | Both kernel built on MCP and consumes external MCP servers |

## How it works

```
Natural language input
    │
    ▼
Agent core (TypeScript, Electron)
    │
    ▼
VLM (UI-TARS-1.5 / Seed-1.x-VL — runs locally or via API)
    │
    ▼
Screenshot ──▶ VLM ──▶ {action, coordinates, reasoning}
    │
    ▼
Synthesized mouse/keyboard ──▶ OS
    │
    ▼
[loop]
```

The agent is a vision-only loop, but it sits on an **MCP kernel**: the same architecture lets external MCP servers extend its capabilities (file system, browsers, custom tools). Action and observation events flow through an Event Stream protocol designed for context engineering across long horizons.

## What's distinctive

- **Own VLM family.** Most agents call out to GPT-4o / Claude / Gemini. UI-TARS uses ByteDance's UI-TARS-1.5 (and the Seed-1.5/1.6-VL series) — models trained specifically on screenshots of desktop and mobile UIs. The claim is higher accuracy on UI elements (buttons, dropdowns, text fields) than general vision models.
- **No external API required (in principle).** The custom model can run locally — useful for self-hosted deployments, air-gapped environments, or cost-sensitive scaled use.
- **MCP-native kernel.** Mounting external MCP servers extends what the agent can touch. Pairs naturally with [[macos-use]]'s MCP for Mac control or with first-party MCP integrations.
- **Cross-platform.** Windows + macOS in one codebase; the only entity here that isn't macOS-only.
- **Remote operator features.** v0.2.0 (2025-06-12) added Remote Computer Operator and Remote Browser Operator — both free in the OSS distribution.

## Limitations

- **Vision-only on macOS.** No AX-tree integration — same speed and precision tradeoffs as [[claude-computer-use]]. Fazm's self-reported bench puts it at 11.4s/task, 72% on a 25-task suite.
- **Specialist VLM has a smaller world model.** UI-TARS-1.5 is excellent at "what is this button" but worse at general reasoning than frontier LLMs. For tasks that mix UI control with code or multi-step reasoning, the gap shows.
- **Electron app DX.** Heavier install footprint than Swift-native peers like [[fazm]]; not a viable embedded library for Mac apps.
- **Less integrated with macOS specifics.** No specific story for AX permission flow, Apple Silicon optimizations, ScreenCaptureKit, etc. — it's cross-platform first.

## Place in the landscape

The **specialist vision model** entry in [[ai-driven-macos-automation-2026]]. Adjacent positions:

- **vs [[claude-computer-use]]**: open source + own VLM vs closed Anthropic + frontier Claude. UI-TARS is cheaper at scale; Claude is smarter per step.
- **vs [[fazm]]**: vision-only with own model vs AX-first with BYO-LLM. Different tradeoffs on the same desktop control problem.
- **vs [[macos-use]]**: vision-only Electron app vs Python AX-tree library. Both open source; very different stacks.

## Why it matters for our work

- **Self-hosting option.** If we want a local or sandboxed agent without sending screenshots to Anthropic/OpenAI, UI-TARS is the open-source path. Useful for sensitive-data scenarios or for the "no API key" subset of users.
- **MCP composition.** UI-TARS's MCP kernel is the cleanest way to compose multiple Mac control surfaces (AX tree via macos-use + vision via UI-TARS + screenshot assertions via Claude) — relevant if we ever want a heterogeneous agent.
- **Bench reference.** UI-TARS is the most-cited vision-only datapoint in the AX-vs-vision debate; benchmarks against Fazm anchor the speed/accuracy tradeoff numbers.

## References

- [GitHub: bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) — primary repo, 29.6k stars
- [UI-TARS Desktop releases](https://github.com/bytedance/UI-TARS-desktop/releases) — v0.3.0 (2025-11-04)
- [GitHub: bytedance/UI-TARS](https://github.com/bytedance/UI-TARS) — model repo
- [VentureBeat: ByteDance's UI-TARS can take over your computer, outperforms GPT-4o and Claude](https://venturebeat.com/ai/bytedances-ui-tars-can-take-over-your-computer-outperforms-gpt-4o-and-claude)
- [UI-TARS Desktop DeepWiki](https://deepwiki.com/bytedance/UI-TARS-desktop/5-ui-tars-desktop-application)
- [The Decoder: Bytedance launches Agent TARS](https://the-decoder.com/bytedance-launches-agent-tars-an-open-source-ai-automation-agent/)

## See also

- [[ai-driven-macos-automation-2026]] — Parent landscape; UI-TARS is the specialist VLM entry
- [[macos-desktop-automation-landscape]] — Layered view; UI-TARS sits in Layer 3 (vision)
- [[claude-computer-use]] — Closed-source frontier-LLM counterpart
- [[fazm]] — Open-source AX-first counterpart
- [[macos-use]] — MCP-friendly companion (could be mounted as a tool inside UI-TARS's kernel)
- [[claude-vision-iphone-experiment]] — Validates the vision-only weakness on coordinate inference

---

# 中文翻译

# UI-TARS Desktop

字节跳动的开源 GUI agent，是 [[ai-driven-macos-automation-2026]] 中唯一**自带视觉-语言模型**的项目，模型专为桌面与移动 UI 控制训练。跨平台（Windows + macOS），基于 Electron，MCP 可扩展。

若 [[claude-computer-use]] 和 [[openai-codex-mac]] 是闭源第一方视觉 agent，UI-TARS 就是开源的专用替代。

## 基本信息

| 属性 | 值 |
|------|-----|
| 厂商 | 字节跳动 |
| GitHub | [bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) |
| Stars | 29.6k |
| 许可证 | Apache 2.0 |
| 最新版本 | v0.3.0（2025-11-04） |
| 实现 | Electron 桌面应用，TypeScript（89.1%） |
| CLI | `npm install @agent-tars/cli@latest -g`（Node.js ≥22） |
| 平台 | Windows、macOS，加上 browser-based operators |
| 模型 | UI-TARS-1.5 / Seed-1.5-VL / Seed-1.6 系列——自有 VLM 家族 |
| 外部 LLM 支持 | Volcengine Doubao、Anthropic Claude（通过 MCP） |
| 架构 | MCP kernel + Event Stream 协议 |
| MCP 角色 | 既以 MCP 为 kernel 又消费外部 MCP 服务器 |

## 工作原理

```
自然语言输入
    │
    ▼
Agent 核心（TypeScript, Electron）
    │
    ▼
VLM（UI-TARS-1.5 / Seed-1.x-VL——本地或 API）
    │
    ▼
截图 ──▶ VLM ──▶ {action, coordinates, reasoning}
    │
    ▼
合成鼠标/键盘 ──▶ OS
    │
    ▼
[循环]
```

Agent 是纯视觉 loop，但坐于一个 **MCP kernel** 之上：同一架构允许外部 MCP 服务器扩展其能力（文件系统、浏览器、自定义工具）。动作与观察事件流过为长程上下文工程设计的 Event Stream 协议。

## 区别在哪

- **自有 VLM 家族。**多数 agent 外调 GPT-4o / Claude / Gemini。UI-TARS 用字节的 UI-TARS-1.5（和 Seed-1.5/1.6-VL 系列）——为桌面与移动 UI 截图专门训练的模型。声称 UI 元素（按钮、下拉、文本框）准确率高于通用视觉模型。
- **原则上不需外部 API。**自定义模型可本地跑——对自托管部署、隔离环境或对成本敏感的规模化使用有用。
- **MCP 原生 kernel。**挂载外部 MCP 服务器扩展 agent 能触及的范围。与 [[macos-use]] 的 MCP for Mac 控制或第一方 MCP 集成自然搭配。
- **跨平台。**Windows + macOS 一份代码；本生态唯一非 macOS 限定的条目。
- **远程 operator 功能。**v0.2.0（2025-06-12）加入了 Remote Computer Operator 和 Remote Browser Operator——OSS 发行版中均免费。

## 局限

- **macOS 上仅视觉。**无 AX 树集成——速度与精度权衡同 [[claude-computer-use]]。Fazm 自报 bench 把它放在 25 任务集上的 11.4 秒/任务、72%。
- **专用 VLM 世界模型更小。**UI-TARS-1.5 在"这是哪个按钮"上很强，但通用推理弱于前沿 LLM。混合 UI 控制和代码或多步推理的任务上差距显现。
- **Electron 应用 DX。**安装体积比 [[fazm]] 等 Swift 原生同行更大；不是 Mac 应用可嵌入的库。
- **与 macOS 特性集成较少。**对 AX 权限流程、Apple Silicon 优化、ScreenCaptureKit 等没有专门叙事——它是跨平台优先。

## 在生态中的位置

[[ai-driven-macos-automation-2026]] 中的**专用视觉模型**条目。相邻位置：

- **vs [[claude-computer-use]]**：开源 + 自有 VLM vs 闭源 Anthropic + 前沿 Claude。UI-TARS 在规模上更便宜；Claude 每步更聪明。
- **vs [[fazm]]**：纯视觉自有模型 vs AX-first BYO-LLM。同一桌面控制问题不同的取舍。
- **vs [[macos-use]]**：纯视觉 Electron 应用 vs Python AX 树库。都开源；栈差异很大。

## 对我们工作为何重要

- **自托管选项。**若我们想要本地或沙箱 agent 而不把截图发给 Anthropic/OpenAI，UI-TARS 是开源路径。对敏感数据场景或"无 API key"子集用户有用。
- **MCP 组合。**UI-TARS 的 MCP kernel 是组合多个 Mac 控制表面（macos-use 的 AX 树 + UI-TARS 的视觉 + Claude 的截图断言）最干净的方式——若我们将来想要异构 agent 时相关。
- **Bench 参考。**UI-TARS 是 AX vs 视觉之争中被引用最多的纯视觉数据点；与 Fazm 对比锚定了速度/准确率权衡数字。

## 参考

- [GitHub：bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) — 主仓库，29.6k stars
- [UI-TARS Desktop releases](https://github.com/bytedance/UI-TARS-desktop/releases) — v0.3.0（2025-11-04）
- [GitHub：bytedance/UI-TARS](https://github.com/bytedance/UI-TARS) — 模型仓库
- [VentureBeat：字节 UI-TARS 可以接管你的电脑，性能超过 GPT-4o 和 Claude](https://venturebeat.com/ai/bytedances-ui-tars-can-take-over-your-computer-outperforms-gpt-4o-and-claude)
- [UI-TARS Desktop DeepWiki](https://deepwiki.com/bytedance/UI-TARS-desktop/5-ui-tars-desktop-application)
- [The Decoder：Bytedance launches Agent TARS](https://the-decoder.com/bytedance-launches-agent-tars-an-open-source-ai-automation-agent/)

## 参见

- [[ai-driven-macos-automation-2026]] — 父级生态；UI-TARS 是专用 VLM 条目
- [[macos-desktop-automation-landscape]] — 分层视图；UI-TARS 在第 3 层（视觉）
- [[claude-computer-use]] — 闭源前沿 LLM 对偶
- [[fazm]] — 开源 AX-first 对偶
- [[macos-use]] — MCP 友好同伴（可作为 UI-TARS kernel 内的 tool 挂载）
- [[claude-vision-iphone-experiment]] — 验证纯视觉在坐标推理上的弱点
