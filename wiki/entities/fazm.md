---
title: Fazm
type: entity
created: 2026-05-07
updated: 2026-05-07
tags: [macos, ai-agent, swift, accessibility, screencapturekit, voice, open-source, byo-llm]
sources: [ai-driven-macos-automation-2026]
---

# Fazm

A Swift-native, open-source macOS AI agent that controls the desktop through the Accessibility API plus ScreenCaptureKit, with a bring-your-own-LLM design and a voice-first UX. The clearest contemporary expression of the **AX-first hybrid** thesis ([[ai-driven-macos-automation-2026|see analysis]]).

## Key facts

| Attribute | Value |
|-----------|-------|
| Type | macOS-native AI agent (desktop control) |
| Language | Swift |
| Platform | macOS only (Apple Silicon optimized) |
| License | Open source |
| Built by | Matthew Diakonov and team |
| Authoring time | ~6 months pre-launch |
| Permissions required | Accessibility access only — **no Screen Recording** |
| LLM strategy | BYO-LLM, including local models |
| Speech | WhisperKit (local, on-device, zero-latency on Apple Silicon) |
| Vision capture | `ScreenCaptureKit` raw pixel buffers from the GPU |
| Position in landscape | Open-source AX-first agent ([[ai-driven-macos-automation-2026]]) |

## How it works

```
Voice / text input
    │
    ▼
WhisperKit (local STT)
    │
    ▼
LLM planner (BYO — Claude, GPT, local Ollama, etc.)
    │
    ▼
Action picker
    │
    ├──▶ AX tree read (AXUIElement) ── primary grounding
    │
    └──▶ ScreenCaptureKit screenshot ── fallback / verification
    │
    ▼
Synthesized input event ──▶ macOS app
```

Two distinguishing implementation choices:

1. **Accessibility API as primary grounding.** Fazm reads the structured AX tree (`AXButton, label='Send', enabled=true`) instead of streaming screenshots through a vision model. Vision is reserved for cases where AX is incomplete or the assertion is visual.
2. **No Screen Recording permission.** Because the AX tree carries enough state for most actions, Fazm avoids the Screen Recording TCC prompt entirely. Vision frames go through ScreenCaptureKit only when needed and (per the public materials) without persistent capture.

## Performance claim (self-reported)

On a 25-task suite Fazm reports:

| Tool | Time/task | Success rate |
|------|-----------|--------------|
| **Fazm** (AX-first) | **8.2s** | **84%** |
| UI-TARS (vision-only) | 11.4s | 72% |

Source: [Fazm blog](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control). Self-reported, so absolute numbers are biased; the AX-vs-vision direction matches third-party reporting.

## Design strengths (relative to alternatives)

- **Sub-second action cycle on most tasks** — vision-first agents pay 2-3s per action for VLM inference; AX-first sidesteps it.
- **BYO-LLM** — works with frontier APIs (Claude/GPT) or local models (Ollama, MLX, etc.). Compare to [[claude-computer-use]] (Anthropic-locked) or [[openai-codex-mac]] (OpenAI-locked).
- **Voice-first UX** with on-device WhisperKit — no cloud round-trip for transcription.
- **Privacy-leaning permissions** — Accessibility-only, no screen recording.
- **Apple Silicon native** — Swift + GPU pixel buffers + MLX-friendly LLM choices align with the platform.

## Limitations

- **Not a testing framework.** No assertion model, no fixture/teardown lifecycle, no parallel sessions. For QA workflows see [[appium-mac2-driver]].
- **AX coverage gap** — apps that custom-render (image editors, games, some Electron) need vision fallback; Fazm leans on it but it's still the slow path.
- **Single agent** — no multi-agent parallelism the way [[openai-codex-mac]] advertises.
- **Maturity** — newer than the closed-source first-party tools; the surface and semantics are still moving.

## Place in the landscape

Fazm is the cleanest open-source instance of the **AX-first + vision-fallback hybrid** that we already validated for iOS in [[claude-vision-iphone-experiment]]. If [[drizz-clone-spec|Iris]] expands to macOS and we want to keep the vendor-neutral design, Fazm's shape is the closest reference architecture in 2026.

The relationship to other tools:
- **vs [[claude-computer-use]]**: AX-first vs screenshot-first; open-source BYO-LLM vs closed Anthropic-only
- **vs [[macos-use]]**: Swift-native + voice vs Python-only + headless
- **vs [[ui-tars]]**: structured AX vs custom-trained VLM
- **vs [[appium-mac2-driver]]**: agentic exploration vs scripted test automation

## Why it's interesting for our work

Most relevant if we want to **own the agent loop** and pick our own model. The closed-source first-party tools commit us to a vendor's model and sandbox. Fazm shows the open-source path is viable today on Mac, and it's already living the iOS pattern we proved out.

## References

- [Fazm: Open Source macOS AI Agent on GitHub](https://fazm.ai/blog/fazm-macos-ai-agent-github) — overview
- [Engineering a macOS AI Agent: ScreenCaptureKit and Swift](https://earezki.com/ai-news/2026-03-17-what-we-learned-building-a-macos-ai-agent-in-swift-screencapturekit-accessibility-apis-async-pipelines/) — third-party engineering account
- [Fazm blog: macOS accessibility tree for desktop control](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control) — bench numbers
- [Fazm blog index](https://fazm.ai/blog) — comparison posts on Fazm vs Simular vs UI-TARS

## See also

- [[ai-driven-macos-automation-2026]] — Parent landscape page; Fazm is one of five shapes
- [[macos-desktop-automation-landscape]] — Layered view including AX layer where Fazm lives
- [[claude-computer-use]] — First-party closed-source counterpart
- [[macos-use]] — Python sister project (different DX, same paradigm)
- [[ui-tars]] — Vision-only counterexample
- [[claude-vision-iphone-experiment]] — iOS validation of the same hybrid pattern

---

# 中文翻译

# Fazm

Swift 原生的开源 macOS AI agent，通过 Accessibility API 加 ScreenCaptureKit 控制桌面，BYO-LLM 设计，语音优先 UX。是 **AX-first 混合**论点（[[ai-driven-macos-automation-2026|见分析]]）当代最清晰的体现。

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | macOS 原生 AI agent（桌面控制） |
| 语言 | Swift |
| 平台 | 仅 macOS（Apple Silicon 优化） |
| 许可证 | 开源 |
| 作者 | Matthew Diakonov 与团队 |
| 开发耗时 | 上线前约 6 个月 |
| 所需权限 | 仅 Accessibility——**不需要 Screen Recording** |
| LLM 策略 | BYO-LLM，含本地模型 |
| 语音 | WhisperKit（本地、设备端、Apple Silicon 上零延迟） |
| 视觉捕获 | `ScreenCaptureKit` 直接从 GPU 取原始 pixel buffer |
| 在生态中的位置 | 开源 AX-first agent（[[ai-driven-macos-automation-2026]]） |

## 工作原理

```
语音 / 文本输入
    │
    ▼
WhisperKit（本地 STT）
    │
    ▼
LLM 规划器（BYO——Claude, GPT, 本地 Ollama 等）
    │
    ▼
动作选择器
    │
    ├──▶ AX 树读取（AXUIElement）—— 主要 grounding
    │
    └──▶ ScreenCaptureKit 截图 —— 兜底 / 验证
    │
    ▼
合成输入事件 ──▶ macOS 应用
```

两个区别于其他工具的实现选择：

1. **以 Accessibility API 为主要 grounding。**Fazm 读结构化的 AX 树（`AXButton, label='Send', enabled=true`），而非把截图喂给视觉模型。视觉只在 AX 不完整或断言是视觉性时才用。
2. **不需要 Screen Recording 权限。**因为 AX 树对大多数动作已经够用，Fazm 完全避开了 Screen Recording TCC 弹窗。视觉帧仅在需要时通过 ScreenCaptureKit 取，且（按公开材料）不持久化。

## 性能数据（自报）

25 任务测试集上 Fazm 报告：

| 工具 | 每任务耗时 | 成功率 |
|------|-----------|--------|
| **Fazm**（AX-first） | **8.2 秒** | **84%** |
| UI-TARS（纯视觉） | 11.4 秒 | 72% |

来源：[Fazm 博客](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control)。自报，绝对数字有偏，但 AX vs 视觉的方向与第三方报告一致。

## 设计优势（相对替代品）

- **大多数任务亚秒级动作循环**——视觉优先 agent 每动作要付 2-3 秒 VLM 推理；AX-first 绕过它。
- **BYO-LLM**——前沿 API（Claude/GPT）或本地模型（Ollama、MLX 等）都可。对比 [[claude-computer-use]]（锁 Anthropic）或 [[openai-codex-mac]]（锁 OpenAI）。
- **语音优先 UX**，设备端 WhisperKit——转写无云端往返。
- **隐私倾向的权限**——只需 Accessibility，无屏幕录制。
- **Apple Silicon 原生**——Swift + GPU pixel buffer + MLX 友好的 LLM 选择都贴合平台。

## 局限

- **不是测试框架。**无断言模型、无 fixture/teardown 生命周期、无并行会话。QA 工作流参见 [[appium-mac2-driver]]。
- **AX 覆盖盲点**——自绘的应用（图像编辑器、游戏、部分 Electron）需要视觉兜底；Fazm 会用但仍是慢路径。
- **单 agent**——无 [[openai-codex-mac]] 宣称的那种多 agent 并行。
- **成熟度**——比闭源第一方工具年轻；接口与语义仍在动。

## 在生态中的位置

Fazm 是我们已经在 iOS 上验证（[[claude-vision-iphone-experiment]]）的 **AX-first + 视觉兜底混合**最干净的开源实现。若 [[drizz-clone-spec|Iris]] 扩展到 macOS 且我们希望保持厂商中立设计，Fazm 的形态就是 2026 年最近的参考架构。

与其他工具的关系：
- **vs [[claude-computer-use]]**：AX-first vs 截图优先；开源 BYO-LLM vs 闭源 Anthropic only
- **vs [[macos-use]]**：Swift 原生 + 语音 vs 仅 Python + 无头
- **vs [[ui-tars]]**：结构化 AX vs 自训 VLM
- **vs [[appium-mac2-driver]]**：agentic 探索 vs 脚本化测试自动化

## 对我们工作为何有意思

最相关于我们想**自己掌握 agent loop 并自选模型**的场景。闭源第一方工具把我们绑在 vendor 的模型和沙箱上。Fazm 表明开源路径在 2026 年的 Mac 上是可行的，并且它已经在跑我们 iOS 上验证过的模式。

## 参考

- [Fazm：开源 macOS AI Agent in GitHub](https://fazm.ai/blog/fazm-macos-ai-agent-github) — 总览
- [Engineering a macOS AI Agent：ScreenCaptureKit 与 Swift](https://earezki.com/ai-news/2026-03-17-what-we-learned-building-a-macos-ai-agent-in-swift-screencapturekit-accessibility-apis-async-pipelines/) — 第三方工程笔记
- [Fazm 博客：用于桌面控制的 macOS accessibility 树](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control) — bench 数据
- [Fazm 博客索引](https://fazm.ai/blog) — Fazm vs Simular vs UI-TARS 对比文

## 参见

- [[ai-driven-macos-automation-2026]] — 父级生态分析；Fazm 是五种形态之一
- [[macos-desktop-automation-landscape]] — 包含 Fazm 所在 AX 层的分层视图
- [[claude-computer-use]] — 第一方闭源对偶
- [[macos-use]] — Python 姐妹项目（DX 不同，范式相同）
- [[ui-tars]] — 纯视觉对照
- [[claude-vision-iphone-experiment]] — 同一混合模式的 iOS 验证
