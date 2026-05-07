---
title: OpenAI Codex Mac
type: entity
created: 2026-05-07
updated: 2026-05-07
tags: [openai, codex, ai-agent, macos, computer-use, multi-agent, screenshot]
sources: [ai-driven-macos-automation-2026]
---

# OpenAI Codex Mac

OpenAI's macOS desktop agent, shipped as part of the **Codex Mac app**. Originally a coding agent (CLI + IDE extension + web app), the April 16, 2026 update added **computer use**, image generation, and persistent memory, making the Mac app a peer of [[claude-computer-use|Claude Computer Use]] for general desktop automation.

The differentiator vs Anthropic's product: **multi-agent parallel control on a single Mac**, with the explicit goal that agents work alongside the developer rather than displacing them.

## Key facts

| Attribute | Value |
|-----------|-------|
| Vendor | OpenAI |
| Status | GA (computer use is the newest layer, April 2026) |
| Mac app launch | Earlier 2026; computer use feature added 2026-04-16 |
| Subscription gate | ChatGPT Plus / Pro / Business / Enterprise / Edu |
| Model family | GPT-5.x (Codex variants) |
| Perception | Screenshot-driven (no AX tree integration disclosed) |
| Distinguishing feature | Multiple agents in parallel, non-blocking with the developer |
| Surface area | CLI, web, IDE extension, **Mac app** (this entity) |

## What shipped on 2026-04-16

The Codex Mac app expanded beyond agentic coding with three additions:

1. **Background computer use** — Codex can use any app on the Mac via see/click/type with its own cursor. **Multiple agents can work in parallel without interfering with the developer's other apps.**
2. **Image generation** — image artifacts created and consumed in-flow.
3. **Memory** — Codex remembers preferences and learns from prior actions across sessions.

The Mac app also gained deeper developer-flow features: PR review, multi-file/multi-terminal views, SSH to remote devboxes, and an in-app browser for fast frontend iteration.

## How it works (perception model)

OpenAI's public materials describe screenshot-driven control: "see, click, and type with its own cursor." There is no disclosed AX-tree integration. Combined with the multi-agent parallel framing, this means each agent has its own cursor and viewport that shares the desktop with the user's interactive cursor — a non-trivial windowing/input system challenge that OpenAI handled at the app layer.

## Strengths

- **Multi-agent parallel.** The standout vs every other entry in [[ai-driven-macos-automation-2026]]. Anthropic's Mac product runs in a sandboxed user account; UI-TARS, Fazm, macos-use are single-agent. Codex's "agents alongside you" is a different shape of product.
- **Coding-flow integration.** Built into the same app developers already use for PR review, SSH devboxes, and IDE workflows. Lower context-switch tax for engineering tasks that mix code + desktop control.
- **Memory across sessions.** Persistent preferences avoid the "explain it again" cost of stateless agents.
- **Cross-surface unification.** Same login works across CLI, web, IDE, app — the Mac app is one of four entry points.

## Weaknesses

- **Screenshot-only paradigm.** Same speed and precision tradeoffs as [[claude-computer-use]]. Same AX-vs-vision gap as [[fazm]] / [[macos-use]]: faster AX-first peers exist.
- **Closed model.** GPT-5.x family only — no BYO-LLM.
- **Sandbox model is less explicit than Anthropic's.** OpenAI's framing is "doesn't interfere with your work" rather than Anthropic's named "restricted user account + per-app allowlist." Sandboxing details are less prominent in public docs.
- **Newer than the API surface.** Computer use as a Mac feature is one month old at the time of writing; Anthropic's API computer-use tool has more public documentation and reference implementations.

## Place in the landscape

The other half of the **first-party screenshot-first agent** pair (with [[claude-computer-use]]). Both are closed source, model-locked, screenshot-driven, and gated behind paid subscriptions. Codex differentiates on:

- **Parallel multi-agent.** The headline feature.
- **Coding-developer fit.** PR review + SSH + browser + computer use in one Mac app.
- **OpenAI ecosystem.** Same login as ChatGPT Plus/Pro/etc.

For our work, the most interesting capability is **multi-agent parallel control**: a future bug-fix workflow ([[auto-bug-fix-workflow]]) could spawn multiple reproducer agents (one per device or one per scenario) in the same session if it ran on Codex Mac, where Anthropic's product is sandboxed to a single user account.

## Why it matters for our work

- **Multi-agent reproduce.** Could parallelize repro-on-N-devices in the [[auto-bug-fix-workflow]] if we adopted Codex as the runtime.
- **Coding loop alignment.** If our bug-fix or test-authoring workflows live in the same Mac app as PR review, the friction drops.
- **Vendor diversification.** Pairing Codex Mac with Claude Computer Use lets us pick the better tool per task and not commit to a single AI vendor for the desktop layer.

## References

- [OpenAI: Introducing the Codex app](https://openai.com/index/introducing-the-codex-app/)
- [OpenAI: Codex for (almost) everything](https://openai.com/index/codex-for-almost-everything/)
- [GitHub: openai/codex](https://github.com/openai/codex) — Codex CLI sibling
- [9to5Mac: OpenAI's Codex Mac app adds three key features (2026-04-16)](https://9to5mac.com/2026/04/16/openais-codex-app-adds-three-key-features-for-expanding-beyond-agentic-coding/)
- [MacRumors: OpenAI Codex Update Adds Computer Use, Image Generation, and Memory on Mac](https://www.macrumors.com/2026/04/16/openai-codex-mac-update/)
- [Codex changelog](https://developers.openai.com/codex/changelog)

## See also

- [[ai-driven-macos-automation-2026]] — Parent landscape; Codex is the OpenAI half of the first-party pair
- [[claude-computer-use]] — Anthropic counterpart
- [[fazm]] — Open source single-agent alternative
- [[ui-tars]] — Open source vision-only alternative
- [[auto-bug-fix-workflow]] — Where multi-agent parallel might pay off

---

# 中文翻译

# OpenAI Codex Mac

OpenAI 的 macOS 桌面 agent，作为 **Codex Mac 应用**的一部分发货。原本是编程 agent（CLI + IDE 扩展 + 网页应用），2026 年 4 月 16 日的更新加入了**计算机使用**、图像生成、持久化记忆，使 Mac 应用成为通用桌面自动化领域中 [[claude-computer-use|Claude Computer Use]] 的同侪。

与 Anthropic 产品的差异化：**单 Mac 上多 agent 并行控制**，明确目标是 agent 与开发者并肩工作，而非取代他们。

## 基本信息

| 属性 | 值 |
|------|-----|
| 厂商 | OpenAI |
| 状态 | GA（computer use 是最新一层，2026 年 4 月） |
| Mac 应用上线 | 2026 早些时候；computer use 功能加入于 2026-04-16 |
| 订阅门槛 | ChatGPT Plus / Pro / Business / Enterprise / Edu |
| 模型家族 | GPT-5.x（Codex 变体） |
| 感知 | 截图驱动（未披露 AX 树集成） |
| 区别特征 | 多 agent 并行，与开发者非阻塞 |
| 表面 | CLI、网页、IDE 扩展、**Mac 应用**（本实体） |

## 2026-04-16 发布了什么

Codex Mac 应用从 agentic 编程扩展，加了三件事：

1. **后台 computer use**——Codex 可以通过 see/click/type 用自己的 cursor 操作 Mac 上任何应用。**多 agent 可在不打扰开发者其他应用的情况下并行工作。**
2. **图像生成**——图像 artifact 在流程内创建与消费。
3. **记忆**——Codex 跨会话记住偏好并从此前动作学习。

Mac 应用也获得了更深的开发者流程功能：PR 审阅、多文件/多终端视图、远程 devbox 的 SSH、以及用于快速前端迭代的内置浏览器。

## 工作原理（感知模型）

OpenAI 公开材料描述了截图驱动的控制："see, click, and type with its own cursor"。没有披露的 AX 树集成。结合多 agent 并行的定位，这意味着每个 agent 拥有自己的 cursor 和视口，与用户交互 cursor 共享桌面——这是个重要的窗口/输入系统挑战，OpenAI 在应用层做了处理。

## 优势

- **多 agent 并行。**这是 [[ai-driven-macos-automation-2026]] 中相对其他条目最突出的一点。Anthropic 的 Mac 产品跑在沙箱用户账户里；UI-TARS、Fazm、macos-use 都是单 agent。Codex 的"agent 与你并肩"是不同形态的产品。
- **编程流程集成。**内置于开发者已经用来做 PR 审阅、SSH devbox、IDE 工作流的同一个应用。混合代码 + 桌面控制的工程任务上下文切换成本更低。
- **跨会话记忆。**持久化偏好避免无状态 agent 的"再解释一次"开销。
- **跨表面统一。**同一登录在 CLI、网页、IDE、应用之间通用——Mac 应用是四个入口之一。

## 劣势

- **仅截图范式。**速度与精度权衡与 [[claude-computer-use]] 相同。AX vs vision 差距与 [[fazm]] / [[macos-use]] 相同：更快的 AX-first 同行存在。
- **闭源模型。**仅 GPT-5.x 家族——不能 BYO-LLM。
- **沙箱模型不如 Anthropic 显式。**OpenAI 表述是"不打扰你的工作"，而非 Anthropic 命名的"受限用户账户 + 按应用 allowlist"。沙箱细节在公开文档中不那么显眼。
- **比 API 表面新。**作为 Mac 功能的 computer use 撰写时仅一个月历史；Anthropic 的 API computer-use 工具有更多公开文档与参考实现。

## 在生态中的位置

**第一方截图优先 agent** 对（与 [[claude-computer-use]]）的另一半。两者都是闭源、锁模型、截图驱动、付费订阅门槛。Codex 在以下方面差异化：

- **并行多 agent。**头条特性。
- **编程开发者契合。**PR 审阅 + SSH + 浏览器 + computer use 全在一个 Mac 应用里。
- **OpenAI 生态。**与 ChatGPT Plus/Pro/etc 同一登录。

对我们工作，最有意思的能力是**多 agent 并行控制**：未来的 bug-fix 工作流（[[auto-bug-fix-workflow]]）若跑在 Codex Mac 上，可在同一会话里产生多个复现 agent（一设备一个或一场景一个），而 Anthropic 的产品被沙箱限定到单个用户账户。

## 对我们工作为何重要

- **多 agent 复现。**若我们采用 Codex 作运行时，可以在 [[auto-bug-fix-workflow]] 中并行 N 设备复现。
- **编程 loop 对齐。**若我们的 bug-fix 或测试编写工作流住在和 PR 审阅相同的 Mac 应用里，摩擦会下降。
- **厂商多元化。**Codex Mac 与 Claude Computer Use 配对让我们能按任务挑更好的工具，不必把桌面层绑在单一 AI 厂商上。

## 参考

- [OpenAI：Codex app 介绍](https://openai.com/index/introducing-the-codex-app/)
- [OpenAI：Codex for (almost) everything](https://openai.com/index/codex-for-almost-everything/)
- [GitHub：openai/codex](https://github.com/openai/codex) — Codex CLI 兄弟
- [9to5Mac：OpenAI Codex Mac app 新增三大功能（2026-04-16）](https://9to5mac.com/2026/04/16/openais-codex-app-adds-three-key-features-for-expanding-beyond-agentic-coding/)
- [MacRumors：OpenAI Codex Mac 更新加入 Computer Use、图像生成与记忆](https://www.macrumors.com/2026/04/16/openai-codex-mac-update/)
- [Codex changelog](https://developers.openai.com/codex/changelog)

## 参见

- [[ai-driven-macos-automation-2026]] — 父级生态；Codex 是第一方对中的 OpenAI 一半
- [[claude-computer-use]] — Anthropic 对偶
- [[fazm]] — 开源单 agent 替代
- [[ui-tars]] — 开源纯视觉替代
- [[auto-bug-fix-workflow]] — 多 agent 并行可能受益的地方
