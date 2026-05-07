---
title: macos-use (Browser Use)
type: entity
created: 2026-05-07
updated: 2026-05-07
tags: [browser-use, macos, ai-agent, accessibility, python, mlx, mcp, open-source]
sources: [ai-driven-macos-automation-2026]
---

# macos-use (Browser Use)

The macOS sibling of the popular **Browser Use** project. A Python library that exposes the macOS Accessibility API as a structured tool surface for AI agents, so an LLM can drive any Mac app the way Browser Use drives a webpage.

Tagline from the repo: *"Tell your MacBook what to do, and it's done — across ANY app."*

## Key facts

| Attribute | Value |
|-----------|-------|
| GitHub | [browser-use/macOS-use](https://github.com/browser-use/macOS-use) |
| Stars | 1.9k |
| License | MIT |
| Language | Python (100%) |
| Sister project | [browser-use/browser-use](https://github.com/browser-use/browser-use) (web variant) |
| Perception | macOS Accessibility tree |
| Supported LLMs | OpenAI, Anthropic, Google Gemini (DeepSeek R1 coming) |
| Local inference | `mlx_use` module (Apple Silicon MLX-based) |
| UI | `gradio_app` for visual demo / interactive use |
| Configuration | Environment-based API keys |

## How it works

```
User prompt ("open the calculator app")
    │
    ▼
LLM (OpenAI / Anthropic / Gemini / local MLX)
    │
    ▼
Tool call: read AX tree of focused app
    │
    ▼
AX tree returned as structured text
    │
    ▼
Tool call: click element by AX identifier or label
    │
    ▼
Synthesized AX action ──▶ macOS app
    │
    ▼
[loop until task complete]
```

The agent runs in Python, queries the AX tree as its primary observation, and uses an LLM to decide the next action. The pattern mirrors Browser Use exactly — substitute "AX tree" for "DOM" and "AXClick" for "DOMClick" — which is the project's whole pitch.

## Components

- **Core library** — Python wrapper around `AXUIElement` C API for read + action
- **`mlx_use`** — Apple Silicon local inference path; uses MLX-compatible models
- **`gradio_app`** — interactive UI for demos and exploratory use; not the production interface
- **LLM provider abstraction** — env-var-keyed config for OpenAI, Anthropic, Gemini

## Strengths

- **AX-first paradigm with the strongest brand recognition.** Browser Use is the household-name OSS browser agent; the macOS variant inherits goodwill, design language, and integration patterns.
- **Pythonic.** Easy to wire into existing Python pipelines, notebooks, MCP servers, or test harnesses.
- **Multi-provider LLMs.** Real BYO-LLM, including local MLX inference. Compare to closed-source first-party tools that lock the model.
- **MIT license.** Permissive — drop into commercial products without copyleft drag.

## Limitations

- **Not Swift / not embeddable in a Mac app.** Python distribution is heavy compared to a Swift framework like [[fazm]]'s. For a Mac app shipping to end users, Python's deployment story is awkward.
- **Reliability per provider.** The maintainers note OpenAI and Anthropic work best; Gemini is "available but less reliable" — typical AX-tool experience but worth knowing.
- **No assertion / test framework.** Agentic, not test-shaped. For QA workflows still want [[appium-mac2-driver]].
- **Smaller community than Browser Use proper.** 1.9k stars vs the parent project's much larger footprint; less external tooling, fewer recipes.
- **No first-class MCP server in this repo (as of writing).** The Browser Use ecosystem has MCP integrations but the macos-use repo specifically is a Python library, not a packaged MCP server. (Not to be confused with `mcp-remote-macos-use`, a separate Swift project for remote Mac control.)

## Place in the landscape

The **open-source AX-first agent (Python flavor)** in [[ai-driven-macos-automation-2026]]. Direct neighbors:

- **vs [[fazm]]**: Python library + headless vs Swift app + voice UX. Same paradigm; very different developer experience and packaging story.
- **vs [[claude-computer-use]]** / [[openai-codex-mac]]: open-source AX-first BYO-LLM vs closed screenshot-first vendor-locked.
- **vs [[ui-tars]]**: AX tree (Python) vs vision (Electron). Both open source, opposite perception models.

## Why it matters for our work

- **Reference for an AX-tree client we might build.** If [[drizz-clone-spec|Iris]] grows a macOS variant, the read/act surface macos-use exposes is exactly what we'd want — but in Swift to fit our Apple-native stack.
- **Drop-in for Python research.** For exploratory experiments or prototype agents that don't need to ship as an app, macos-use is the fastest way to try an AX-first agent on a real Mac.
- **Pairs with the [[auto-bug-fix-workflow]].** Could serve as the macOS half of a future bug-fix workflow that already uses Python tooling around WDA.

## References

- [GitHub: browser-use/macOS-use](https://github.com/browser-use/macOS-use) — primary repo, 1.9k stars
- [GitHub: browser-use/browser-use](https://github.com/browser-use/browser-use) — sister project (web)
- [Vibe Sparking AI: macos-use — Give AI Agents Real Hands on macOS](https://www.vibesparking.com/en/blog/tools/mcp/2026-03-22-macos-use-mcp-server-ai-control-macos-apps/)
- [Fazm blog: Open Source AI Agents you can run locally on Mac in 2026](https://fazm.ai/blog/open-source-ai-agents-mac-2026) — comparison context

## See also

- [[ai-driven-macos-automation-2026]] — Parent landscape
- [[macos-desktop-automation-landscape]] — Layered view (macos-use sits in the AX layer)
- [[fazm]] — Swift-native sibling (same paradigm)
- [[claude-computer-use]] — Closed-source screenshot-first counterpoint
- [[ui-tars]] — Open-source vision-first counterpoint

---

# 中文翻译

# macos-use（Browser Use）

热门 **Browser Use** 项目的 macOS 兄弟。一个 Python 库，把 macOS Accessibility API 暴露为面向 AI agent 的结构化工具表面，让 LLM 可以像 Browser Use 驱动网页一样驱动任何 Mac 应用。

仓库标语：*"告诉你的 MacBook 该做什么，事就成了——任意应用。"*

## 基本信息

| 属性 | 值 |
|------|-----|
| GitHub | [browser-use/macOS-use](https://github.com/browser-use/macOS-use) |
| Stars | 1.9k |
| 许可证 | MIT |
| 语言 | Python（100%） |
| 姐妹项目 | [browser-use/browser-use](https://github.com/browser-use/browser-use)（网页变体） |
| 感知 | macOS Accessibility 树 |
| 支持的 LLM | OpenAI、Anthropic、Google Gemini（DeepSeek R1 即将） |
| 本地推理 | `mlx_use` 模块（基于 Apple Silicon MLX） |
| UI | 可视化演示/交互使用的 `gradio_app` |
| 配置 | 基于环境变量的 API key |

## 工作原理

```
用户 prompt（"打开计算器"）
    │
    ▼
LLM（OpenAI / Anthropic / Gemini / 本地 MLX）
    │
    ▼
Tool call：读聚焦应用的 AX 树
    │
    ▼
AX 树以结构化文本返回
    │
    ▼
Tool call：按 AX identifier 或 label 点击元素
    │
    ▼
合成的 AX 动作 ──▶ macOS 应用
    │
    ▼
[循环直到任务完成]
```

Agent 跑在 Python 里，把 AX 树作为主要观察，用 LLM 决定下一步动作。模式与 Browser Use 完全相同——把 "AX 树"代入"DOM"，"AXClick"代入"DOMClick"——这就是项目的全部卖点。

## 组件

- **核心库**——Python 封装的 `AXUIElement` C API，用于读 + 动作
- **`mlx_use`**——Apple Silicon 本地推理路径；用 MLX 兼容模型
- **`gradio_app`**——演示和探索性使用的交互 UI；不是生产接口
- **LLM provider 抽象**——OpenAI、Anthropic、Gemini 的 env-var 配置

## 优势

- **AX-first 范式中品牌认知最强。**Browser Use 是家喻户晓的 OSS 浏览器 agent；macOS 变体继承了好评、设计语言、集成模式。
- **Pythonic。**易于接入现有 Python pipeline、notebook、MCP 服务器或测试 harness。
- **多 provider LLM。**真正的 BYO-LLM，含本地 MLX 推理。对比锁模型的闭源第一方工具。
- **MIT 许可证。**宽松——可丢进商业产品而无 copyleft 牵扯。

## 局限

- **非 Swift / 不可嵌入 Mac 应用。**Python 分发比 [[fazm]] 那样的 Swift 框架重得多。对发给终端用户的 Mac 应用，Python 部署故事不顺。
- **provider 间可靠性差异。**维护者指出 OpenAI 和 Anthropic 表现最好；Gemini "可用但不那么可靠"——典型 AX 工具体验，但值得知道。
- **无断言 / 无测试框架。**Agentic 的，非测试形态。QA 工作流仍要 [[appium-mac2-driver]]。
- **社区比 Browser Use 本体小。**1.9k stars vs 母项目大得多的足迹；外部工具更少、配方更少。
- **本仓库无一等公民 MCP 服务器（撰写时）。**Browser Use 生态有 MCP 集成，但 macos-use 仓库本身是 Python 库，不是打包的 MCP 服务器。（别与 `mcp-remote-macos-use` 混淆——那是远程 Mac 控制的另一个 Swift 项目。）

## 在生态中的位置

[[ai-driven-macos-automation-2026]] 中的**开源 AX-first agent（Python 风味）**。直接邻居：

- **vs [[fazm]]**：Python 库 + 无头 vs Swift 应用 + 语音 UX。范式相同；DX 和打包故事差异巨大。
- **vs [[claude-computer-use]]** / [[openai-codex-mac]]：开源 AX-first BYO-LLM vs 闭源截图优先锁厂商。
- **vs [[ui-tars]]**：AX 树（Python）vs 视觉（Electron）。都开源，感知模型相反。

## 对我们工作为何重要

- **可能要建的 AX 树客户端的参考。**若 [[drizz-clone-spec|Iris]] 长出 macOS 变体，macos-use 暴露的读/动作表面正是我们想要的——只是要 Swift 以匹配我们 Apple 原生栈。
- **Python 研究的 drop-in。**对探索性实验或不需要打包成应用的原型 agent，macos-use 是在真实 Mac 上试 AX-first agent 最快的方式。
- **可与 [[auto-bug-fix-workflow]] 配对。**可作为已经在 WDA 周边用 Python 工具的未来 bug-fix 工作流的 macOS 那一半。

## 参考

- [GitHub：browser-use/macOS-use](https://github.com/browser-use/macOS-use) — 主仓库，1.9k stars
- [GitHub：browser-use/browser-use](https://github.com/browser-use/browser-use) — 姐妹项目（网页）
- [Vibe Sparking AI：macos-use — Give AI Agents Real Hands on macOS](https://www.vibesparking.com/en/blog/tools/mcp/2026-03-22-macos-use-mcp-server-ai-control-macos-apps/)
- [Fazm 博客：2026 年可在 Mac 本地运行的开源 AI Agent](https://fazm.ai/blog/open-source-ai-agents-mac-2026) — 对比上下文

## 参见

- [[ai-driven-macos-automation-2026]] — 父级生态
- [[macos-desktop-automation-landscape]] — 分层视图（macos-use 位于 AX 层）
- [[fazm]] — Swift 原生兄弟（同范式）
- [[claude-computer-use]] — 闭源截图优先对照
- [[ui-tars]] — 开源视觉优先对照
