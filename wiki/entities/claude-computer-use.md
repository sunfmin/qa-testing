---
title: Claude Computer Use
type: entity
created: 2026-05-07
updated: 2026-05-07
tags: [anthropic, claude, computer-use, ai-agent, macos, api, beta, screenshot, vision]
sources: [ai-driven-macos-automation-2026]
---

# Claude Computer Use

Anthropic's first-party desktop automation capability. Two related but distinct products share the name:

1. **The Computer Use API tool** — a beta tool spec available to developers calling the Claude API. The model receives screenshots and emits mouse/keyboard actions; the developer's runtime executes them.
2. **The Claude Computer Use product on Mac (Cowork)** — a consumer feature in the Claude Mac app, shipped to Pro/Max subscribers on 2026-03-23, that lets Claude operate the user's actual macOS desktop within a sandboxed user account.

Both are screenshot-driven (no AX tree). Both are first-party closed source. They're the reference Anthropic implementations of the screenshot-first paradigm catalogued in [[ai-driven-macos-automation-2026]].

## Key facts

| Attribute | Value |
|-----------|-------|
| Vendor | Anthropic |
| Status | Beta |
| First-class API release | 2024 (research preview), Mac-product 2026-03-23 |
| Beta header (current) | `computer-use-2025-11-24` (Opus 4.7/4.6, Sonnet 4.6, Opus 4.5) |
| Beta header (prior) | `computer-use-2025-01-24` (Sonnet 4.5/4, Haiku 4.5, Opus 4.1/4, Sonnet 3.7) |
| Tool type identifier | `computer_20251124` (current) / `computer_20250124` (prior) |
| Models supporting current tool | Claude Opus 4.7, Opus 4.6, Sonnet 4.6, Opus 4.5 |
| Mac product availability | Claude Pro ($20/mo), Claude Max ($100/mo) |
| Mac product launch | 2026-03-23 |
| Data retention | ZDR-eligible — Anthropic does not retain screenshots/actions |

## How the API tool works

```
Your runtime              Claude API
    │
    ├─ user prompt + tool spec ─▶
    │                                Claude plans
    │  ◀── tool_use {action, coords}
    │
    ├─ execute action (your code)
    ├─ capture screenshot
    │
    ├─ tool_result(image) ─────▶
    │                                Claude observes, plans next
    │  ◀── tool_use {next action}
    │
    │  ... agent loop until stop_reason != tool_use
```

You control the environment (a VM, Docker container, the user's Mac, anything). Claude plans in screenshot space; you translate coordinates into clicks in your environment.

### Available actions

**Basic** (all versions): `screenshot`, `left_click`, `type`, `key`, `mouse_move`.

**Enhanced** (`computer_20250124`): `scroll`, `left_click_drag`, `right_click`, `middle_click`, `double_click`, `triple_click`, `left_mouse_down`, `left_mouse_up`, `hold_key`, `wait`.

**Newest** (`computer_20251124`, Opus 4.7+): all of the above plus `zoom` — render a sub-region at full resolution before the model decides where to click. Activated by `enable_zoom: true` in the tool definition. A practical admission that full-frame inference loses precision on dense UIs.

### Tool parameters

| Parameter | Required | Notes |
|-----------|----------|-------|
| `type` | Yes | `computer_20251124` or `computer_20250124` |
| `name` | Yes | Must be `"computer"` |
| `display_width_px` | Yes | Display width |
| `display_height_px` | Yes | Display height |
| `display_number` | No | For X11 multi-display |
| `enable_zoom` | No | `computer_20251124` only |

### Coordinate scaling

The API constrains images to ~1568px on the long edge and ~1.15 megapixels total (Claude Opus 4.7 lifts this to 2576px on the long edge with 1:1 coordinates). For older models, you must downsample the screenshot before sending and scale Claude's coordinates back up before clicking, or clicks land on the wrong target.

## How the Mac product works

The Mac product launched 2026-03-23 wraps the same screenshot-driven approach into a consumer experience:

- **Sandboxed user account.** A separate macOS user runs the agent so it can't see/touch the developer's main account by default.
- **Per-app allowlist.** Claude prompts before opening each application. Sensitive categories (investment, trading, cryptocurrency) are blocked by default.
- **Remote-from-iPhone.** Claude can run on the Mac while the user is away — a sibling iPhone product instructs it.
- **macOS-only at launch.** No Windows/Linux date announced.

## Strengths

- **Universal app coverage.** Pure pixels — works on any UI element, including custom-drawn (canvas, games, image editors).
- **First-party.** Vetted, sandboxed, ZDR.
- **Tightly integrated planner-perception loop.** The same model plans, perceives, and decides without round-tripping through a separate VLM.
- **`zoom` action** in Opus 4.7 is a meaningful precision boost for dense UIs.

## Weaknesses

- **Latency.** 2-3s per action because of screenshot inference; Anthropic itself recommends "use cases where speed isn't critical."
- **Closed model.** No BYO-LLM (cf. [[fazm]]).
- **Coordinate fragility.** Below Opus 4.7 you must handle scaling yourself; even with it, dense UIs benefit from prompted screenshots after each step.
- **No AX tree.** Despite running on macOS, the tool reads no structured UI data — leaves a 2-3× speed gap vs AX-first peers ([[fazm]], [[macos-use]]).
- **Subscription gate** for the Mac product. API access is pay-per-token (standard tool-use pricing, +735 input tokens per tool def, +466-499 system-prompt tokens).

## Practical guidance from the docs

Anthropic's own implementation tips:

- Prompt the model to "after each step, take a screenshot and carefully evaluate if you have achieved the right outcome" — Claude otherwise assumes success.
- Prefer keyboard shortcuts for fragile UI (dropdowns, scrollbars).
- For repeatable flows, include example screenshots and tool calls in the prompt.
- Treat prompt injection seriously: pages and images can carry instructions Claude may follow. Anthropic auto-runs a classifier on screenshots and asks for user confirmation when injection is suspected.

## Pricing footprint

| Cost line | Magnitude |
|-----------|-----------|
| System prompt overhead | 466-499 tokens |
| Tool definition tokens | 735 (Claude 4.x) |
| Per-action screenshot | ~1.15MP image — see [Vision pricing](https://platform.claude.com/docs/en/build-with-claude/vision) |
| Tool result tokens | varies |

A naive 30-step task can spend 15-25k input tokens just on screenshots. Plan for it.

## Place in the landscape

This is the canonical **first-party screenshot-first agent** in [[ai-driven-macos-automation-2026]]. The contrasts:

- **vs [[openai-codex-mac]]**: same paradigm, different vendor; Codex emphasizes multi-agent parallel.
- **vs [[fazm]]**: closed Anthropic-only screenshot vs open BYO-LLM AX-first.
- **vs [[ui-tars]]**: frontier Claude vs custom UI-trained VLM.
- **vs [[appium-mac2-driver]]**: agentic exploration vs scripted test driver. Different jobs.

## Why it matters for our work

If we want to ship a Mac feature where Claude drives the user's machine and we'd rather not own the runtime, the Mac product is the path of least resistance. If we want to embed agentic Mac control in a custom app (e.g., a future macOS variant of [[drizz-clone-spec|Iris]]), the API tool with `computer_20251124` and `enable_zoom: true` is the building block — but we'd add an AX-tree side-channel ([[macos-use]] / Mac2 source dump) to recover the speed gap.

## References

- [Anthropic: Computer use tool docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)
- [Reference implementation (Docker)](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo)
- [Anthropic: Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [MacRumors: Anthropic's Claude AI Can Now Use Your Mac (2026-03-24)](https://www.macrumors.com/2026/03/24/claude-use-mac-remotely-iphone/)
- [Claude Help Center: Let Claude use your computer in Cowork](https://support.claude.com/en/articles/14128542-let-claude-use-your-computer-in-cowork)

## See also

- [[ai-driven-macos-automation-2026]] — Parent landscape; this is the reference first-party agent
- [[openai-codex-mac]] — Direct competitor (OpenAI's equivalent)
- [[ui-tars]] — Open source vision-only counterpart
- [[fazm]] — Open source AX-first counterpart
- [[claude-vision-iphone-experiment]] — Our iPhone validation that pure vision struggles on coordinates

---

# 中文翻译

# Claude Computer Use

Anthropic 第一方桌面自动化能力。两个相关但有别的产品共享此名：

1. **Computer Use API 工具**——开发者调 Claude API 时可用的 beta 工具规范。模型收截图并输出鼠标/键盘动作；开发者的运行时执行。
2. **Mac 上的 Claude Computer Use 产品（Cowork）**——Claude Mac 应用中的消费者功能，2026-03-23 向 Pro/Max 订阅者发布，让 Claude 在沙箱用户账户内操作用户真实的 macOS 桌面。

两者都是截图驱动（无 AX 树）。两者都是第一方闭源。它们是 [[ai-driven-macos-automation-2026]] 中分类的截图优先范式的 Anthropic 参考实现。

## 基本信息

| 属性 | 值 |
|------|-----|
| 厂商 | Anthropic |
| 状态 | Beta |
| 首次 API 发布 | 2024（研究预览）、Mac 产品 2026-03-23 |
| 当前 beta header | `computer-use-2025-11-24`（Opus 4.7/4.6、Sonnet 4.6、Opus 4.5） |
| 旧 beta header | `computer-use-2025-01-24`（Sonnet 4.5/4、Haiku 4.5、Opus 4.1/4、Sonnet 3.7） |
| 工具类型标识 | `computer_20251124`（当前）/ `computer_20250124`（旧） |
| 当前工具支持的模型 | Claude Opus 4.7、Opus 4.6、Sonnet 4.6、Opus 4.5 |
| Mac 产品可用性 | Claude Pro（$20/月）、Claude Max（$100/月） |
| Mac 产品上线 | 2026-03-23 |
| 数据保留 | ZDR-eligible——Anthropic 不保留截图/动作 |

## API 工具如何工作

```
你的运行时             Claude API
    │
    ├─ user prompt + tool spec ─▶
    │                                Claude 规划
    │  ◀── tool_use {action, coords}
    │
    ├─ 执行动作（你的代码）
    ├─ 抓截图
    │
    ├─ tool_result(image) ─────▶
    │                                Claude 观察、规划下一步
    │  ◀── tool_use {下一动作}
    │
    │  ... agent loop 直到 stop_reason != tool_use
```

你控制环境（VM、Docker 容器、用户的 Mac，任何）。Claude 在截图空间规划；你把坐标翻译成你环境里的点击。

### 可用动作

**基础**（所有版本）：`screenshot`、`left_click`、`type`、`key`、`mouse_move`。

**增强**（`computer_20250124`）：`scroll`、`left_click_drag`、`right_click`、`middle_click`、`double_click`、`triple_click`、`left_mouse_down`、`left_mouse_up`、`hold_key`、`wait`。

**最新**（`computer_20251124`，Opus 4.7+）：以上全部 + `zoom`——在模型决定点击位置前以全分辨率渲染子区域。在工具定义里 `enable_zoom: true` 启用。这是一个务实的承认：全帧推理在密集 UI 上精度不够。

### 工具参数

| 参数 | 必填 | 说明 |
|------|------|------|
| `type` | 是 | `computer_20251124` 或 `computer_20250124` |
| `name` | 是 | 必须为 `"computer"` |
| `display_width_px` | 是 | 显示宽度 |
| `display_height_px` | 是 | 显示高度 |
| `display_number` | 否 | X11 多显示器用 |
| `enable_zoom` | 否 | 仅 `computer_20251124` |

### 坐标缩放

API 把图像约束到长边 ~1568px、总像素 ~1.15 兆（Claude Opus 4.7 提到长边 2576px 且坐标 1:1）。对旧模型，必须先把截图下采样再发，并把 Claude 的坐标按比例放大再点击，否则点不中。

## Mac 产品如何工作

2026-03-23 上线的 Mac 产品把同样的截图驱动方式包装成消费者体验：

- **沙箱用户账户。**一个独立的 macOS 用户跑 agent，默认看不见/碰不到开发者主账户。
- **按应用 allowlist。**Claude 在打开每个应用前都问。敏感类别（投资、交易、加密）默认禁止。
- **从 iPhone 远程驱动。**Claude 可以在用户不在时跑 Mac——一个 iPhone 兄弟产品下指令。
- **发布时仅 macOS。**未公布 Windows/Linux 时间表。

## 优势

- **应用覆盖通用。**纯像素——任意 UI 元素都行，含自绘（canvas、游戏、图像编辑器）。
- **第一方。**审过、有沙箱、ZDR。
- **规划-感知 loop 紧密集成。**同一模型规划、感知、决策，不需要中转去外部 VLM。
- **`zoom` 动作**在 Opus 4.7 上对密集 UI 的精度提升是实质的。

## 劣势

- **延迟。**因截图推理每动作 2-3 秒；Anthropic 自己推荐"速度不关键的用例"。
- **闭源模型。**不能 BYO-LLM（对比 [[fazm]]）。
- **坐标脆弱。**低于 Opus 4.7 必须自己处理缩放；即使有它，密集 UI 仍受益于每步后的截图提示。
- **无 AX 树。**尽管跑在 macOS 上，工具不读结构化 UI 数据——比 AX-first 同行（[[fazm]]、[[macos-use]]）慢 2-3 倍。
- **订阅门槛**适用于 Mac 产品。API 是按 token 付费（标准 tool-use 定价，每个工具定义 +735 input tokens，系统提示 +466-499 tokens）。

## 文档里的实操建议

Anthropic 自己的实现 tips：

- 提示模型"每步之后截图并仔细判断是否达到了正确结果"——否则 Claude 默认假定成功。
- 对脆弱 UI（下拉、滚动条）首选键盘快捷键。
- 可重复流程在 prompt 里附上成功的截图与 tool calls 示例。
- 严肃对待 prompt injection：网页与图像可携带 Claude 可能跟随的指令。Anthropic 在截图上自动跑分类器，疑似注入时让用户确认。

## 成本足迹

| 成本项 | 量级 |
|--------|------|
| 系统提示开销 | 466-499 tokens |
| 工具定义 tokens | 735（Claude 4.x） |
| 每动作截图 | ~1.15MP 图像——参见 [Vision 定价](https://platform.claude.com/docs/en/build-with-claude/vision) |
| 工具结果 tokens | 不一 |

朴素的 30 步任务光截图就能花 15-25k input tokens。提前规划。

## 在生态中的位置

这是 [[ai-driven-macos-automation-2026]] 中标准的**第一方截图优先 agent**。对比：

- **vs [[openai-codex-mac]]**：同范式、不同厂商；Codex 强调多 agent 并行。
- **vs [[fazm]]**：闭源 Anthropic only 截图 vs 开源 BYO-LLM AX-first。
- **vs [[ui-tars]]**：前沿 Claude vs 自训 UI VLM。
- **vs [[appium-mac2-driver]]**：agentic 探索 vs 脚本化测试 driver。任务不同。

## 对我们工作为何重要

若我们想出一个由 Claude 驱动用户机器的 Mac 功能，且不想自己持有运行时，Mac 产品是阻力最小的路径。若我们要把 agentic Mac 控制嵌入到自己的应用里（如未来 macOS 版的 [[drizz-clone-spec|Iris]]），带 `computer_20251124` 与 `enable_zoom: true` 的 API 工具是基石——但我们会再加一个 AX 树侧通道（[[macos-use]] / Mac2 source dump）来弥补速度差。

## 参考

- [Anthropic：Computer use 工具文档](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)
- [参考实现（Docker）](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo)
- [Anthropic：Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [MacRumors：Anthropic Claude AI 现可使用你的 Mac（2026-03-24）](https://www.macrumors.com/2026/03/24/claude-use-mac-remotely-iphone/)
- [Claude Help Center：Let Claude use your computer in Cowork](https://support.claude.com/en/articles/14128542-let-claude-use-your-computer-in-cowork)

## 参见

- [[ai-driven-macos-automation-2026]] — 父级生态；这是参考第一方 agent
- [[openai-codex-mac]] — 直接竞品（OpenAI 同类）
- [[ui-tars]] — 开源纯视觉对偶
- [[fazm]] — 开源 AX-first 对偶
- [[claude-vision-iphone-experiment]] — 我们 iPhone 验证：纯视觉在坐标上吃力
