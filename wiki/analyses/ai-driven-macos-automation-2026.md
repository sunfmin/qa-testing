---
title: AI-Driven macOS Automation (2026)
type: analysis
created: 2026-05-07
updated: 2026-05-07
tags: [macos, automation, ai-agent, llm, mcp, computer-use, accessibility, vision, landscape]
sources: [web-research]
---

# AI-Driven macOS Automation (2026)

The companion piece to [[macos-desktop-automation-landscape]]. That page catalogs the macOS automation stack by **layer** (XCTest → AX → vision). This page catalogs it by **AI-integration shape**: which tools are designed for an LLM agent to drive a Mac, who ships them, and how they trade off speed, reliability, openness, and price.

Scope: tools where the *primary user is the model*, not a human writing a Maestro flow or a Playwright spec. For test-authoring frameworks see [[test-scenario-storage-patterns]].

## TL;DR

- **First-party agents shipped in spring 2026.** [[claude-computer-use|Claude Computer Use for Mac]] (Anthropic, 2026-03-23) and [[openai-codex-mac|OpenAI Codex Mac]] (2026-04-16) both control real macOS now — both are screenshot-driven, both gate sensitive apps, both require a paid subscription.
- **Open-source AX-first beats closed vision-first.** [[fazm]] (Swift, BYO-LLM) and [[macos-use]] (Python, Browser Use) show that reading the AX tree is faster (sub-second per action) and more reliable (84% vs 72% on Fazm's bench) than streaming screenshots to a vision model.
- **Specialist vision model.** [[ui-tars|UI-TARS Desktop]] from ByteDance ships its own UI-trained VLM — the only tool here that doesn't need a frontier LLM to function.
- **Benchmarks just crossed human baseline.** OSWorld-Verified leaderboard: Claude Mythos Preview 79.6%, GPT-5.5 78.7%, Claude Opus 4.7 78.0% — past the ~72% human baseline.
- **The pragmatic shape is hybrid.** Frontier LLM for planning + AX tree for grounded action + screenshot for assertion. Every serious agent converges here.

## What changed in 2026

In late 2025 macOS desktop automation for AI was either (a) Anthropic's research demo running in a Linux VM you'd never use, (b) UI-TARS's specialist model that was hard to deploy, or (c) hobbyist MCP servers gluing the AX API to Claude Desktop.

Three things flipped in spring 2026:

1. **Anthropic shipped Claude Computer Use as a Mac product** (not just an API tool) on 2026-03-23. Per-app allowlist, restricted user account, runs locally on the user's actual Mac.
2. **OpenAI shipped Codex Mac with Computer Use** on 2026-04-16 — multi-agent parallel control, the same model can drive multiple apps while the developer keeps working in others.
3. **OSWorld scores crossed the human baseline.** Public leaderboard: 79.6% (Claude Mythos), 78.7% (GPT-5.5), 78.0% (Claude Opus 4.7), surpassing ~72% human.

Combined, this means agentic macOS use stopped being a research preview and became a tier of products developers can ship against.

## Taxonomy: five shapes of AI-driven macOS automation

| Shape | Examples | Who is the model | Perception | Who ships |
|-------|----------|------------------|------------|-----------|
| **First-party agent** | [[claude-computer-use]], [[openai-codex-mac]] | Frontier LLM by the same vendor | Screenshot-first, no AX | Anthropic, OpenAI |
| **Open-source agent (AX-first)** | [[fazm]], [[macos-use]] | BYO-LLM | AX tree primary, screenshot fallback | Independent / Browser Use |
| **Specialist vision model** | [[ui-tars]] (Bytedance) | Custom-trained VLM | Pure screenshot, GUI-tuned | ByteDance |
| **MCP server (model-agnostic)** | macos-use Python MCP, mcp-remote-macos-use, mb-dev/macos-ui-automation | Any MCP-capable LLM (Claude Desktop, Cursor, Codex) | AX tree exposed as tools | Independent |
| **Commercial neuro-symbolic** | Simular Sai | Frontier LLM that emits replayable code | Hybrid + deterministic re-runs | Simular AI |

The fault lines:

- **Who chooses the LLM?** First-party fixes the model. Open-source and MCP servers leave it open. Specialist (UI-TARS) ships its own.
- **What does the model see?** Anthropic and OpenAI bet on screenshot perception scaling with model size. AX-first bets on structured grounding. Both work — AX is faster and cheaper.
- **Where does it run?** Claude/OpenAI: the user's Mac, sandboxed by macOS user accounts. Simular: a private remote VM. Open-source: the user's Mac, full privilege.

## The two grounding paradigms

The defining question of 2026 desktop agents: **does the model read pixels or does it read the AX tree?**

### Screenshot-first (Anthropic, OpenAI, UI-TARS)

The model receives a PNG of the current screen and emits `(x, y)` coordinates plus an action (`left_click`, `type`, `scroll`, `key`). The agent loop captures, sends, executes, captures, repeats.

```
Screen ──▶ PNG ──▶ VLM ──▶ {action: left_click, coord: [430, 218]} ──▶ XQuartz/CoreGraphics input ──▶ Screen
```

Strengths: works on any app, no special permissions beyond Screen Recording + Accessibility (for synthesized input), generalizes to web/canvas/games.

Weaknesses: 2-3 seconds per action (image generation + VLM inference), coordinate drift (~100-200pt error on dense UIs — confirmed in our own [[claude-vision-iphone-experiment]]), expensive token spend, no semantic identifiers to log against.

The Claude Computer Use API (`computer_20251124`) addresses some of this with a **zoom action** in Opus 4.7+ that lets the model request a sub-region rendered at full resolution before clicking. A latent admission that pure full-frame inference isn't precise enough.

### AX-first (Fazm, macos-use, mb-dev MCP)

The model receives a serialized accessibility tree:

```
Window "Mail"
  Toolbar
    Button "Compose" identifier=NewMessageButton enabled=true frame=(124,72,24,24)
  Splitter
    Sidebar role=AXOutline
      Row "Inbox" selected=true ...
```

It picks an element by identifier or label, the runtime resolves it back to a click via `AXUIElement` API. No coordinates ever leave the runtime.

Strengths: sub-second per action (no VLM inference for grounding), resolution-independent, idempotent (re-running the same plan tomorrow still works), cheap tokens.

Weaknesses: needs every UI element to be properly exposed. Custom-drawn canvases (image editors, games, some Electron apps) are invisible. Falls back to vision for those.

> [!note]
> Fazm's measured comparison on a 25-task suite: AX-first **8.2s/task at 84%** vs UI-TARS vision-first **11.4s/task at 72%**. Source: [Fazm blog, AX tree MCP](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control). Self-reported by Fazm so take the absolute numbers with skepticism, but the *direction* matches every other report we've seen.

### The hybrid that actually works

Every serious 2026 agent does both:

1. **Plan** with a frontier LLM.
2. **Ground** by reading the AX tree (cheap, structured, exact).
3. **Verify** with a screenshot when the AX result is ambiguous or when the assertion is visual ("does the chart look right?").
4. **Fall back** to vision-only when the app exposes no AX tree.

This mirrors the iOS pattern we already validated in [[claude-vision-iphone-experiment]]: WDA for grounding, Claude vision for visual assertion.

## Side-by-side comparison

| Tool | Source | License | Perception | LLM | macOS-only | First seen | Notes |
|------|--------|---------|------------|-----|------------|-----------|-------|
| **[[claude-computer-use]]** (Mac product) | Anthropic | Closed | Screenshot | Claude (4.5+) | Mac-only at launch | 2026-03-23 | Per-app gate, ZDR-eligible API |
| **[[openai-codex-mac]]** | OpenAI | Closed | Screenshot | GPT-5.x | Mac-only | 2026-04-16 | Multi-agent parallel control |
| **[[fazm]]** | Independent (M. Diakonov et al.) | Open source | AX + ScreenCaptureKit | BYO (any provider) | Yes | 2025-Q4 | Voice-first via WhisperKit, Accessibility permission only |
| **[[macos-use]]** | Browser Use | MIT | AX tree (Python) | OpenAI/Anthropic/Gemini | Yes | 2025-Q1 | Sister project to browser-use; 1.9k stars |
| **[[ui-tars]]** Desktop | ByteDance | Apache 2.0 | Screenshot (own VLM) | UI-TARS-1.5 / Seed-1.5-VL | No (Win/Mac) | 2025-Q1, v0.3.0 2025-11-04 | 29.6k stars, MCP kernel |
| **Simular Sai** | Simular AI | Closed | Hybrid + code emission | Frontier (provider not pinned) | Mac/Windows | 2025-12 | Neuro-symbolic: LLM writes replayable code |
| **mcp-remote-macos-use** | baryhuang | Open source | AX | Claude Desktop (no API key) | Yes (controls remote Mac) | 2025-Q2 | Wraps a remote Mac as MCP tools |
| **mb-dev/macos-ui-automation** | mb-dev | Open source | AX | Any MCP client | Yes | 2025-Q3 | Pure MCP server, Node |

## Decision matrix: pick by goal

| Goal | Recommendation | Why |
|------|---------------|-----|
| Ship a Mac-app feature where Claude drives the user's Mac | [[claude-computer-use]] product | First-party, sandboxed, no infra |
| Build it yourself with a custom LLM choice | [[fazm]] | Swift, BYO-LLM, open source, AX-first |
| Read the AX tree from any MCP-capable model (Cursor, Claude Desktop) | mb-dev/macos-ui-automation or [[macos-use]] | Pure MCP, model-agnostic |
| Need parallel multi-agent on one Mac | [[openai-codex-mac]] | Only product designed for parallel sessions |
| No frontier LLM API key, want self-hosted vision | [[ui-tars]] Desktop | Ships its own VLM |
| Replayable workflow that runs reliably nightly | Simular Sai | Neuro-symbolic deterministic re-runs |
| Test automation with assertions, not exploratory agent | [[appium-mac2-driver]] (Mac2) | Designed for testing, not agentic exploration |
| Drive a remote Mac from local Claude | mcp-remote-macos-use | Purpose-built for the remote case |

## Implications for our work

### For [[drizz-clone-spec|Iris]] expanding to macOS

The architecture we sketched in [[macos-desktop-automation-landscape]] holds, but the AI layer has options now:

- **Source of grounding**: Mac2's `accessibility id` (best for testing, reliable IDs) or AX tree directly via Fazm/macos-use shape (better for exploratory tests where IDs aren't seeded).
- **Source of assertion**: Claude vision via `screenshots` endpoint (for "does it look right?") — same as our iPhone hybrid.
- **Source of the agent loop**: pick from [[claude-computer-use]] tool spec (`computer_20251124`), Codex's tool definitions, or a custom loop with our own MCP shape.

### For [[auto-bug-fix-workflow]] on desktop

The reproduce → analyze → verify cycle could plug directly into Claude Computer Use's tool API. We'd lose vendor-neutrality but gain a vetted, sandboxed runtime. Open question: whether the macOS Computer Use sandbox blocks the things our workflow needs (Xcode, simulators, file mounts). The "investment / crypto blocked by default" allowlist pattern suggests it'll trip on anything legal-flagged.

### What's still missing

- **An AX-tree MCP server we'd actually pin.** macos-use is Python (heavy for distribution), mb-dev is Node (lighter), nothing is Swift-native + signed + Mac App Store-compatible.
- **A test-shaped assertion layer on top of any of these.** Computer Use is for *doing*, not *verifying* — it doesn't model "did the right thing happen" beyond a screenshot. Mac2 still wins for true testing.

## Key references

- [Anthropic: Computer use tool docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool) — beta `computer-use-2025-11-24` for Opus 4.7/4.6, Sonnet 4.6, Opus 4.5
- [OpenAI: Introducing the Codex app](https://openai.com/index/introducing-the-codex-app/)
- [MacRumors: Anthropic's Claude AI Can Now Use Your Mac While You're Away (2026-03-24)](https://www.macrumors.com/2026/03/24/claude-use-mac-remotely-iphone/)
- [9to5Mac: OpenAI's Codex Mac app adds three key features (2026-04-16)](https://9to5mac.com/2026/04/16/openais-codex-app-adds-three-key-features-for-expanding-beyond-agentic-coding/)
- [Fazm blog: macOS accessibility tree MCP server for desktop control](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control)
- [Fazm blog: Best open source computer use AI agents 2026](https://fazm.ai/blog/best-open-source-computer-use-ai-agents-2026)
- [GitHub: bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) — 29.6k stars, v0.3.0
- [GitHub: browser-use/macOS-use](https://github.com/browser-use/macOS-use) — 1.9k stars, MIT
- [GitHub: baryhuang/mcp-remote-macos-use](https://github.com/baryhuang/mcp-remote-macos-use)
- [TechCrunch: Simular's AI agent wants to run your Mac (2025-12-02)](https://techcrunch.com/2025/12/02/simular-releases-mac-os-ai-agent-raises-21-5m-from-felicis-with-windows-coming-soon/)
- [OSWorld benchmark](https://os-world.github.io/) and [verified leaderboard](https://llm-stats.com/benchmarks/osworld-verified)

## See also

- [[macos-desktop-automation-landscape]] — Layered (XCTest/AX/vision) view of the same space, written one month earlier; this page is the AI-integration counterpart
- [[fazm]] — Swift-native open-source agent
- [[claude-computer-use]] — Anthropic's first-party tool and Mac product
- [[openai-codex-mac]] — OpenAI's Mac agent
- [[ui-tars]] — ByteDance specialist VLM agent
- [[macos-use]] — Browser Use's macOS variant
- [[claude-vision-iphone-experiment]] — iOS analog: hybrid grounding + vision wins
- [[appium-mac2-driver]] — XCTest-based driver, the QA-tool counterpart to these agentic tools

---

# 中文翻译

# AI 驱动的 macOS 自动化（2026）

[[macos-desktop-automation-landscape]] 的姐妹篇。那一页按**层级**（XCTest → AX → 视觉）整理 macOS 自动化栈，本页按 **AI 集成形态**整理：哪些工具就是为 LLM agent 控制 Mac 而设计的、谁在做、它们在速度/可靠性/开放度/价格上如何取舍。

范围：**主要使用者是模型本身**的工具，而非由人撰写 Maestro flow 或 Playwright spec 的测试框架。后者参见 [[test-scenario-storage-patterns]]。

## 结论速览

- **2026 年春，第一方 agent 上线了。**[[claude-computer-use|Claude Computer Use for Mac]]（Anthropic，2026-03-23）与 [[openai-codex-mac|OpenAI Codex Mac]]（2026-04-16）现在都能控制真实 macOS——两者都是截图驱动、都对敏感应用做了门禁、都需要付费订阅。
- **开源 AX-first 优于闭源 vision-first。**[[fazm]]（Swift, BYO-LLM）和 [[macos-use]]（Python, Browser Use）都证明：读 AX 树比把截图喂给视觉模型更快（每动作亚秒级）也更可靠（Fazm 自测 84% vs 72%）。
- **专用视觉模型路线。**ByteDance 的 [[ui-tars|UI-TARS Desktop]] 自带为 UI 训练的 VLM——本页唯一不需要前沿 LLM 即可工作的工具。
- **基准刚跨过人类基线。**OSWorld-Verified 排行榜：Claude Mythos Preview 79.6%、GPT-5.5 78.7%、Claude Opus 4.7 78.0%——已超过约 72% 的人类基线。
- **务实的形态是混合。**前沿 LLM 做规划 + AX 树做 grounding + 截图做断言。所有认真的 agent 都收敛到这里。

## 2026 年发生了什么

2025 年末，AI 驱动的 macOS 桌面自动化要么是 (a) Anthropic 跑在你永远不会用的 Linux VM 里的 research demo，要么是 (b) UI-TARS 难以部署的专用模型，要么是 (c) 把 AX API 粘到 Claude Desktop 的爱好者 MCP 服务器。

2026 年春有三件事翻转了这一切：

1. **Anthropic 把 Claude Computer Use 作为 Mac 产品**（而非仅 API 工具）发布于 2026-03-23。按应用许可、受限用户账户、本地跑在用户真实 Mac 上。
2. **OpenAI 在 Mac 上发布了带 Computer Use 的 Codex** 于 2026-04-16——多 agent 并行控制，同一个模型可以驱动多个应用，开发者同时还能在其他应用里继续工作。
3. **OSWorld 分数跨过人类基线。**公开排行榜：79.6%（Claude Mythos）、78.7%（GPT-5.5）、78.0%（Claude Opus 4.7），超过约 72% 的人类基线。

合起来，这意味着 agentic macOS 使用不再是研究预览，而是开发者可以面向其打造产品的产品层。

## 分类：AI 驱动 macOS 自动化的五种形态

| 形态 | 例子 | 模型是谁 | 感知 | 谁在做 |
|------|------|---------|------|------|
| **第一方 agent** | [[claude-computer-use]]、[[openai-codex-mac]] | 同厂前沿 LLM | 截图优先、无 AX | Anthropic、OpenAI |
| **开源 agent（AX-first）** | [[fazm]]、[[macos-use]] | BYO-LLM | AX 树为主、截图兜底 | 独立 / Browser Use |
| **专用视觉模型** | [[ui-tars]]（ByteDance） | 自训 VLM | 纯截图、GUI 调优 | ByteDance |
| **MCP 服务器（模型无关）** | macos-use Python MCP、mcp-remote-macos-use、mb-dev/macos-ui-automation | 任何 MCP-capable LLM（Claude Desktop、Cursor、Codex） | AX 树暴露为 tools | 独立 |
| **商业神经-符号** | Simular Sai | 前沿 LLM 输出可重放代码 | 混合 + 确定性重跑 | Simular AI |

分界点：

- **谁选 LLM？**第一方写死模型。开源和 MCP 服务器留给用户。专用（UI-TARS）自带模型。
- **模型看到什么？**Anthropic 和 OpenAI 押注截图感知会随模型规模变好。AX-first 押注结构化 grounding。两者都能用——AX 更快更便宜。
- **跑在哪里？**Claude/OpenAI：用户 Mac，由 macOS 用户账户做沙箱。Simular：私有远程 VM。开源：用户 Mac，全权限。

## 两种 grounding 范式

2026 年桌面 agent 的核心问题：**模型读像素还是读 AX 树？**

### 截图优先（Anthropic、OpenAI、UI-TARS）

模型收到当前屏幕的 PNG，输出 `(x, y)` 坐标加动作（`left_click`、`type`、`scroll`、`key`）。Agent loop 截图、发送、执行、再截图、循环。

```
屏幕 ──▶ PNG ──▶ VLM ──▶ {action: left_click, coord: [430, 218]} ──▶ XQuartz/CoreGraphics 输入 ──▶ 屏幕
```

优势：任何应用都能用，除了 Screen Recording + Accessibility 不需要特殊权限，能泛化到 web/canvas/游戏。

劣势：每动作 2-3 秒（图像生成 + VLM 推理）、坐标漂移（密集 UI 上 ~100-200pt 误差——已在我们自己的 [[claude-vision-iphone-experiment]] 中验证）、token 开销大、没有可日志化的语义标识符。

Claude Computer Use API（`computer_20251124`）通过 Opus 4.7+ 的 **zoom action** 部分缓解了这一点：模型可以请求一个子区域以全分辨率渲染再点击。这是对"纯全帧推理精度不够"的隐式承认。

### AX-first（Fazm、macos-use、mb-dev MCP）

模型收到序列化的 accessibility 树：

```
Window "Mail"
  Toolbar
    Button "Compose" identifier=NewMessageButton enabled=true frame=(124,72,24,24)
  Splitter
    Sidebar role=AXOutline
      Row "Inbox" selected=true ...
```

它根据 identifier 或 label 选元素，运行时通过 `AXUIElement` API 解析回点击。坐标永远不离开运行时。

优势：每动作亚秒级（grounding 不走 VLM 推理）、与分辨率无关、幂等（明天重跑同一计划仍然有效）、token 便宜。

劣势：需要每个 UI 元素被正确暴露。自绘 canvas（图像编辑器、游戏、部分 Electron 应用）不可见。这些 fall back 到视觉。

> [!note]
> Fazm 在 25 任务测试集上的实测：AX-first **8.2 秒/任务，84%** vs UI-TARS 视觉 **11.4 秒/任务，72%**。来源：[Fazm 博客 AX 树 MCP](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control)。Fazm 自报，绝对数字保留怀疑，但**方向**与我们见到的所有其他报告一致。

### 真正可用的混合方案

每一个认真的 2026 agent 都两者都做：

1. **规划**用前沿 LLM。
2. **Grounding** 读 AX 树（便宜、结构化、精确）。
3. **验证**在 AX 模糊或断言是视觉的时候用截图（"图表看起来对吗？"）。
4. **兜底**应用没暴露 AX 树时纯视觉。

这与我们已经在 [[claude-vision-iphone-experiment]] 验证的 iOS 模式相同：WDA 做 grounding，Claude vision 做视觉断言。

## 工具横向对比

| 工具 | 来源 | 许可证 | 感知 | LLM | macOS 限定 | 首次出现 | 备注 |
|------|------|--------|------|-----|-----------|---------|------|
| **[[claude-computer-use]]**（Mac 产品） | Anthropic | 闭源 | 截图 | Claude (4.5+) | 发布时仅 Mac | 2026-03-23 | 按应用门禁、ZDR-eligible API |
| **[[openai-codex-mac]]** | OpenAI | 闭源 | 截图 | GPT-5.x | 仅 Mac | 2026-04-16 | 多 agent 并行控制 |
| **[[fazm]]** | 独立（M. Diakonov 等） | 开源 | AX + ScreenCaptureKit | BYO（任何 provider） | 是 | 2025-Q4 | 通过 WhisperKit 语音优先，仅需 Accessibility 权限 |
| **[[macos-use]]** | Browser Use | MIT | AX 树（Python） | OpenAI/Anthropic/Gemini | 是 | 2025-Q1 | browser-use 的姐妹项目；1.9k stars |
| **[[ui-tars]]** Desktop | ByteDance | Apache 2.0 | 截图（自带 VLM） | UI-TARS-1.5 / Seed-1.5-VL | 否（Win/Mac） | 2025-Q1，v0.3.0 2025-11-04 | 29.6k stars，MCP kernel |
| **Simular Sai** | Simular AI | 闭源 | 混合 + 代码生成 | 前沿 LLM（厂商未定） | Mac/Windows | 2025-12 | 神经-符号：LLM 写可重放代码 |
| **mcp-remote-macos-use** | baryhuang | 开源 | AX | Claude Desktop（无需 API key） | 是（控制远程 Mac） | 2025-Q2 | 把远程 Mac 包装为 MCP tools |
| **mb-dev/macos-ui-automation** | mb-dev | 开源 | AX | 任何 MCP 客户端 | 是 | 2025-Q3 | 纯 MCP 服务器，Node |

## 决策矩阵：按目标选

| 目标 | 推荐 | 理由 |
|------|------|------|
| 在 Mac 应用功能里让 Claude 驱动用户 Mac | [[claude-computer-use]] 产品 | 第一方、有沙箱、无基础设施 |
| 自己造，要自由选 LLM | [[fazm]] | Swift、BYO-LLM、开源、AX-first |
| 让任何 MCP-capable 模型（Cursor、Claude Desktop）读 AX 树 | mb-dev/macos-ui-automation 或 [[macos-use]] | 纯 MCP、模型无关 |
| 单 Mac 上需要并行多 agent | [[openai-codex-mac]] | 唯一为并行设计的产品 |
| 没有前沿 LLM API key，要自托管视觉 | [[ui-tars]] Desktop | 自带 VLM |
| 需要每晚可靠重跑的工作流 | Simular Sai | 神经-符号确定性重跑 |
| 带断言的测试自动化，而非探索式 agent | [[appium-mac2-driver]]（Mac2） | 为测试设计，不为 agentic 探索 |
| 从本地 Claude 控制远程 Mac | mcp-remote-macos-use | 专为远程场景打造 |

## 对我们工作的影响

### Iris 扩展到 macOS

我们在 [[macos-desktop-automation-landscape]] 草拟的架构仍然成立，但 AI 层现在有选项：

- **Grounding 来源**：Mac2 的 `accessibility id`（测试最佳，可靠 ID）或直接通过 Fazm/macos-use 形态读 AX 树（探索性测试更好，无需种 ID）。
- **断言来源**：通过 `screenshots` 端点的 Claude vision（用于"看起来对吗？"）——与我们的 iPhone 混合一致。
- **Agent loop 来源**：从 [[claude-computer-use]] 工具规范（`computer_20251124`）、Codex 的工具定义、或我们自己的 MCP 形态中选。

### Auto Bug Fix 工作流上桌面

复现 → 分析 → 验证循环可以直接接到 Claude Computer Use 的工具 API。我们会失去 vendor 中立但获得一个有沙箱、被审过的运行时。开放问题：macOS Computer Use 沙箱是否会挡住我们工作流需要的东西（Xcode、模拟器、文件挂载）。"投资 / 加密默认禁止"的 allowlist 模式提示它会绊在任何法务标记的东西上。

### 还缺什么

- **一个我们真愿意 pin 的 AX 树 MCP 服务器。**macos-use 是 Python（分发重）、mb-dev 是 Node（轻一些）、没有 Swift 原生 + 已签名 + Mac App Store 兼容的。
- **任何之上的测试断言层。**Computer Use 是为**做**，不是**验证**——它不建模"做对了吗"，仅止于截图。真正测试还是 Mac2 胜出。

## 关键参考

- [Anthropic：Computer use 工具文档](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool) — beta `computer-use-2025-11-24` 适用于 Opus 4.7/4.6、Sonnet 4.6、Opus 4.5
- [OpenAI：Codex app 介绍](https://openai.com/index/introducing-the-codex-app/)
- [MacRumors：Anthropic Claude AI 现可在你不在时使用你的 Mac（2026-03-24）](https://www.macrumors.com/2026/03/24/claude-use-mac-remotely-iphone/)
- [9to5Mac：OpenAI Codex Mac app 新增三大功能（2026-04-16）](https://9to5mac.com/2026/04/16/openais-codex-app-adds-three-key-features-for-expanding-beyond-agentic-coding/)
- [Fazm 博客：用于桌面控制的 macOS accessibility 树 MCP 服务器](https://fazm.ai/blog/macos-accessibility-tree-mcp-server-desktop-control)
- [Fazm 博客：2026 年最佳开源 computer use AI agent](https://fazm.ai/blog/best-open-source-computer-use-ai-agents-2026)
- [GitHub：bytedance/UI-TARS-desktop](https://github.com/bytedance/UI-TARS-desktop) — 29.6k stars, v0.3.0
- [GitHub：browser-use/macOS-use](https://github.com/browser-use/macOS-use) — 1.9k stars，MIT
- [GitHub：baryhuang/mcp-remote-macos-use](https://github.com/baryhuang/mcp-remote-macos-use)
- [TechCrunch：Simular AI agent 想要替你跑 Mac（2025-12-02）](https://techcrunch.com/2025/12/02/simular-releases-mac-os-ai-agent-raises-21-5m-from-felicis-with-windows-coming-soon/)
- [OSWorld 基准](https://os-world.github.io/) 与 [verified 排行榜](https://llm-stats.com/benchmarks/osworld-verified)

## 参见

- [[macos-desktop-automation-landscape]] — 同一空间的分层（XCTest/AX/视觉）视图，比本页早一个月写；本页是其 AI 集成对偶
- [[fazm]] — Swift 原生开源 agent
- [[claude-computer-use]] — Anthropic 第一方工具与 Mac 产品
- [[openai-codex-mac]] — OpenAI Mac agent
- [[ui-tars]] — ByteDance 专用 VLM agent
- [[macos-use]] — Browser Use 的 macOS 变体
- [[claude-vision-iphone-experiment]] — iOS 对偶：grounding + vision 混合胜出
- [[appium-mac2-driver]] — 基于 XCTest 的 driver，本页 agentic 工具的 QA 工具对偶
