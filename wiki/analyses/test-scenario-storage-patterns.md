---
title: Test Scenario Storage Patterns
type: analysis
created: 2026-04-22
updated: 2026-04-22
tags: [scenario, storage, format, yaml, gherkin, dsl, recorder, bdd, pom]
sources: []
---

# Test Scenario Storage Patterns

How does the industry persist a "test scenario" — the sequence of actions and assertions that makes up one user journey? This page catalogs the seven mainstream approaches in 2026, their tradeoffs, and concludes with a recommendation for [[drizz-clone-spec|Iris]].

Scope: **storage format**, not test strategy. For strategy see [[e2e-testing-strategy]].

## The Seven Families

| Family | Examples | What gets stored |
|--------|----------|------------------|
| **Code-as-tests** | [[playwright]], Cypress, [[xcuitest]], [[detox]] | Source files in host language + POM layer |
| **Gherkin / BDD** | Cucumber, SpecFlow, Behave, Karate | `.feature` text + step-definition bindings |
| **YAML / DSL flow** | [[maestro]], [[midscene-js]], Karate | Domain-vocabulary YAML |
| **Recorded JSON** | Chrome DevTools Recorder, Selenium IDE `.side` | JSON with fallback selector arrays |
| **Keyword-driven** | Robot Framework, Katalon Studio | Tabular keyword sequences |
| **Binary recording** | TestComplete, Ranorex, UFT/QTP | Proprietary binary, GUI-locked |
| **AI intent** | [[drizz]], [[midscene-js]], Claude Computer Use | Natural-language intent, re-grounded at runtime |

## 1. Code-as-tests

The scenario *is* a source file. The test runner provides structure via `describe`/`it` nesting and `beforeEach` fixtures. A [[page-object-model|Page Object Model]] layer hides selectors so scenarios read like prose.

```ts
test('user can log in', async ({ page }) => {
  await page.goto('/login')
  await page.getByRole('textbox', { name: 'Email' }).fill(process.env.USER!)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await expect(page.getByText('Welcome')).toBeVisible()
})
```

- **Solves**: full expressiveness (loops, conditionals, helpers), typed APIs, IDE refactors, line-level diffs.
- **Loses**: non-developers can't author or read confidently; scenario tangled with runner glue; parameterization ad-hoc (`test.each`, env vars, fixtures).
- **Used by**: Playwright, Cypress, WebdriverIO, XCUITest, Espresso, Detox.

POM is not a storage format — it's the discipline of keeping selectors in one class (`LoginPage.emailField`). Every serious code-based suite converges on it or an equivalent.

## 2. Gherkin / BDD

Plain-text Given/When/Then, bound to step-definition code via Cucumber Expressions or regex. `Scenario Outline` + `Examples` tables give first-class data-driven runs.

```gherkin
Scenario Outline: login
  Given I am on the login page
  When I sign in as "<user>"
  Then I should see "Welcome, <user>"

  Examples:
    | user  |
    | alice |
    | bob   |
```

- **Solves**: business-readable; clean diffs; native parameterization.
- **Loses**: you maintain a *second* artifact (step defs); vague steps rot; overhead rarely pays off unless PMs actually read them.
- **Used by**: Cucumber (JVM/JS/Ruby), SpecFlow → Reqnroll (.NET), Behave (Python), Karate.

## 3. YAML / DSL Flow

Purpose-built vocabulary in YAML. [[maestro|Maestro]] is the canonical mobile example:

```yaml
appId: ${APP_ID}
---
- launchApp: { clearState: true }
- tapOn: "Email field"
- inputText: ${USER_EMAIL}
- tapOn: "Sign In"
- assertVisible: "Dashboard"
```

Parameters via CLI `-e KEY=VAL`; selectors mix literal text, accessibility IDs, and point-based fallbacks.

- **Solves**: zero boilerplate, readable, diffable, trivially machine-generated. Humans edit it; LLMs emit it.
- **Loses**: limited control flow (Maestro added `runFlow`, `repeat`, `when` incrementally); eventually you hit a wall and wish for code.
- **Used by**: Maestro, Midscene YAML mode, Karate (HTTP), Detox's older config form.

## 4. Recorded JSON (Fallback Selectors)

Schema-driven JSON emitted by a recorder. Chrome DevTools Recorder is the cleanest modern example — each step carries a **ranked array of selectors** (ARIA → CSS → XPath → text → pierce) so replay can fall back if one breaks.

```json
{ "title": "login",
  "steps": [
    { "type": "setViewport", "width": 1280, "height": 720 },
    { "type": "click",
      "selectors": [["aria/Sign in"], ["#submit"], ["xpath///button[1]"]] },
    { "type": "change", "selectors": [["#email"]], "value": "a@b.c" }
  ]}
```

Selenium IDE `.side` follows a similar shape: `{ tests: [{ commands: [{ command, target, targets, value }] }] }` where `targets` is the fallback list.

- **Solves**: record-and-replay with no coding; fallback selectors buy some drift resilience; Chrome Recorder can export to Puppeteer/Playwright code.
- **Loses**: ugly to diff; awkward to hand-edit; weak assertions; breaks on dynamic UI.
- **Used by**: Selenium IDE, Chrome DevTools Recorder, Katalon Recorder. Playwright Codegen records → emits code, it does not persist JSON.

## 5. Keyword-driven

Tabular plain-text. Scenarios are sequences of **keywords**; keywords are composable — a high-level keyword can call lower-level ones.

```robot
*** Test Cases ***
Valid Login
    Open Login Page
    Input Username    ${USER}
    Input Password    ${PASS}
    Welcome Page Should Be Open
```

- **Solves**: very readable; layered abstraction (high-level keyword → library); strong built-in data tables.
- **Loses**: whitespace-significant syntax is fiddly; ecosystem smaller than Playwright/Cypress.
- **Used by**: Robot Framework, Katalon Studio (hybrid), TestComplete keyword view.

## 6. Binary / Proprietary Recording

Tools like TestComplete, Ranorex, and UFT/QTP serialize scenarios to proprietary binary or ProjectSuite formats, optimized for the IDE's replay engine rather than humans.

- **Solves**: captures pixel-level timing and gestures; tightly integrated authoring GUIs.
- **Loses**: not diffable, not code-reviewable, vendor lock-in, effectively unreadable to LLMs.
- **Used by**: TestComplete, Ranorex, UFT/QTP, some enterprise tools.

## 7. AI / Vision — Intent Over Coordinates

Three emergent styles, all sharing one idea: store *what the user wants*, let the runtime re-ground it every run.

**[[midscene-js|Midscene]] YAML** — semantic actions against web/android/ios/computer targets:

```yaml
ios:
  bundleId: com.example.app
tasks:
  - name: search
    flow:
      - ai: Search for "weather today"
      - aiAssert: The results show weather information
```

**[[drizz|Drizz]] plain English** — scenarios are literally lines like *"Tap the Login button; verify the cart shows 3 items"*, resolved at runtime by a VLM against a screenshot. Self-healing is the pitch.

**Claude Computer Use trajectories** — not an authored format, but the *recorded* one. JSONL where each line is a tool-use event (`screenshot`, `left_button_press` with coords, `scroll_down`) plus model reasoning. Full auditability; replay is lossy because the model re-plans each turn.

- **Solves**: the "element not found" problem — the AI re-grounds every step against the current screen.
- **Loses**: nondeterminism, cost, latency; hard to assert deeply without a structured oracle; LLM may "succeed" differently than intended.

## Cross-cutting Tradeoffs

| Dimension | Code | Gherkin | YAML/DSL | JSON record | Keyword | AI-intent |
|-----------|------|---------|----------|-------------|---------|-----------|
| Replayability when UI drifts | depends on POM | depends on step def | brittle unless AI-backed | **fallback selectors help** | good | **best — re-grounds** |
| Human readability | medium | **high** | **high** | low | **high** | **high** |
| LLM edit/emit friendliness | medium | medium | **high** | medium | medium | **high** |
| Git diff quality | **great** | **great** | **great** | poor | **great** | **great** |
| Parameterization | env, fixtures, `test.each` | `Examples` table | env (`-e`) | weak | variables section | prompt interpolation |

Two consistent industry answers to the replayability problem: **selector fallback lists** (Chrome Recorder, Selenium IDE) and **semantic re-grounding every run** (Midscene, Drizz). Coordinates are treated as a last resort everywhere credible.

## Recommendation for Iris

[[drizz-clone-spec|Iris]] is LLM + vision + [[webdriveragent|WDA]]. Its readers are both human QAs and the LLM itself. Don't invent a new format — **combine two mature ones**:

1. **Source format = Maestro-style YAML**. Diff-friendly, LLMs read/write YAML more reliably than code or JSON, humans can scan it. Each step carries three layers:
   - `intent:` — natural-language description (primary, consumed by LLM + vision)
   - `hint:` — optional `accessibilityId` / `text` / `bbox` (WDA fast path)
   - `assert:` — visual or structural assertion

2. **Runtime trajectory = JSONL** (mirrors Claude Computer Use). Each step logs `screenshot_ref`, `model_reasoning`, `action`, `result`. This is a **by-product** for debug and replay audit, not the authored source. Authors only maintain YAML.

3. **Parameterization = Maestro + Gherkin hybrid**. CLI `-e KEY=VAL` plus YAML `${VAR}` interpolation, plus an optional `examples:` array that borrows Scenario Outline's data-driven spirit.

4. **Explicitly rejected**:
   - Pure code — sacrifices the LLM-authoring advantage.
   - Pure JSON recording — diff disaster, LLM edits pollute.
   - Pure Gherkin — step-definition abstraction buys nothing for an LLM.
   - Binary — unreadable to LLMs.

5. **The layered-field trick** resolves the readability-vs-stability tension: `intent` gives Midscene-style semantic routing; the optional `hint` gives deterministic WDA lookup when present. Best of both.

One-line summary: **YAML for intent (humans + LLM), JSONL for trajectories (debug), optional hint fields (WDA fast path)** — three responsibilities, three formats, all borrowed from proven tools.

## See Also

- [[maestro]] — canonical YAML-flow mobile runner, the format Iris should imitate
- [[midscene-js]] — semantic-action YAML with vision re-grounding
- [[drizz]] — plain-English intent + self-healing replay
- [[drizz-clone-spec]] — Iris spec, the page this analysis directly informs
- [[claude-vision-iphone-experiment]] — why hybrid intent + WDA hint beats pure vision
- [[e2e-testing-strategy]] — strategy layer (when to E2E), complementary to this format layer

## References

- [Maestro API Reference — Commands](https://docs.maestro.dev/api-reference/commands)
- [Midscene.js — Automate with scripts in YAML](https://midscenejs.com/automate-with-scripts-in-yaml.html)
- [Chrome DevTools Recorder reference](https://developer.chrome.com/docs/devtools/recorder/reference)
- [Cucumber Gherkin Reference](https://cucumber.io/docs/gherkin/reference/)
- [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#test-data-syntax)
- [Playwright Codegen](https://playwright.dev/docs/codegen)
- [Selenium IDE `.side` format](https://www.qafox.com/new-selenium-ide-saves-the-tests-with-side-extension-file-having-json-content/)
- [Anthropic Computer Use tool docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/computer-use-tool)

---

# 中文翻译

# 测试 Scenario 持久化模式

业界如何保存一个"测试 scenario"——也就是组成一条用户路径的动作和断言序列？本页梳理 2026 年主流的七种做法、tradeoff，并给出 [[drizz-clone-spec|Iris]] 的推荐方案。

范围：**存储格式**，不是测试策略。策略层请参见 [[e2e-testing-strategy]]。

## 七大流派

| 流派 | 代表工具 | 存的是什么 |
|------|----------|-----------|
| **代码即测试** | [[playwright]]、Cypress、[[xcuitest]]、[[detox]] | 宿主语言源文件 + POM 层 |
| **Gherkin / BDD** | Cucumber、SpecFlow、Behave、Karate | `.feature` 文本 + step definitions 绑定 |
| **YAML / DSL flow** | [[maestro]]、[[midscene-js]]、Karate | 领域动词的 YAML |
| **JSON 录制** | Chrome DevTools Recorder、Selenium IDE `.side` | 带 fallback selector 数组的 JSON |
| **Keyword-driven** | Robot Framework、Katalon Studio | 表格形式的 keyword 序列 |
| **二进制录制** | TestComplete、Ranorex、UFT/QTP | 专有二进制，锁死在 GUI |
| **AI 意图** | [[drizz]]、[[midscene-js]]、Claude Computer Use | 自然语言意图 + 运行时重新定位 |

## 1. 代码即测试

Scenario **就是**一个源码文件。测试 runner 用 `describe`/`it` 嵌套和 `beforeEach` fixture 提供结构。[[page-object-model|Page Object Model]] 层把 selector 隐藏起来，让 scenario 读起来像散文。

```ts
test('user can log in', async ({ page }) => {
  await page.goto('/login')
  await page.getByRole('textbox', { name: 'Email' }).fill(process.env.USER!)
  await page.getByRole('button', { name: 'Sign in' }).click()
  await expect(page.getByText('Welcome')).toBeVisible()
})
```

- **优点**：表达力满级（循环、条件、辅助函数）、类型化 API、IDE 重构、行级 diff。
- **缺点**：非开发者难以撰写/阅读；scenario 与 runner 胶水代码缠在一起；参数化手段零散（`test.each`、env、fixture）。
- **使用者**：Playwright、Cypress、WebdriverIO、XCUITest、Espresso、Detox。

POM 不是存储格式，而是"selector 集中在一个类里"的纪律（`LoginPage.emailField`）。任何规模化的代码测试套件最终都会收敛到 POM 或等价物。

## 2. Gherkin / BDD

纯文本 Given/When/Then，通过 Cucumber Expressions 或正则绑定到 step definitions 代码。`Scenario Outline` + `Examples` 表天然支持数据驱动。

```gherkin
Scenario Outline: 登录
  Given 我在登录页
  When 我以 "<user>" 身份登录
  Then 我应该看到 "Welcome, <user>"

  Examples:
    | user  |
    | alice |
    | bob   |
```

- **优点**：业务可读；diff 清晰；原生支持参数化。
- **缺点**：需要维护**第二份产物**（step defs）；模糊的步骤会逐渐腐烂；只有 PM 真的会读时才值得投入。
- **使用者**：Cucumber (JVM/JS/Ruby)、SpecFlow → Reqnroll (.NET)、Behave (Python)、Karate。

## 3. YAML / DSL 流

专门设计的领域动词放在 YAML 里。[[maestro|Maestro]] 是移动端经典范例：

```yaml
appId: ${APP_ID}
---
- launchApp: { clearState: true }
- tapOn: "Email field"
- inputText: ${USER_EMAIL}
- tapOn: "Sign In"
- assertVisible: "Dashboard"
```

参数化通过 CLI `-e KEY=VAL`；selector 混用字面文本、accessibility id、和坐标回退。

- **优点**：零样板代码、可读、可 diff、机器易生成。人能改，LLM 也能生成。
- **缺点**：控制流有限（Maestro 后来才加了 `runFlow`、`repeat`、`when`）；最终你会撞墙想要代码。
- **使用者**：Maestro、Midscene YAML 模式、Karate (HTTP)、早期 Detox 配置。

## 4. JSON 录制（Fallback Selectors）

带 schema 的 JSON，由 recorder 产生。Chrome DevTools Recorder 是最干净的现代范例——每一步带一个**排序过的 selector 数组**（ARIA → CSS → XPath → text → pierce），重放时可以降级。

```json
{ "title": "login",
  "steps": [
    { "type": "setViewport", "width": 1280, "height": 720 },
    { "type": "click",
      "selectors": [["aria/Sign in"], ["#submit"], ["xpath///button[1]"]] },
    { "type": "change", "selectors": [["#email"]], "value": "a@b.c" }
  ]}
```

Selenium IDE `.side` 是类似结构：`{ tests: [{ commands: [{ command, target, targets, value }] }] }`，`targets` 是回退列表。

- **优点**：录制即回放，无需写代码；fallback selector 提供一定抗漂移能力；Chrome Recorder 可导出为 Puppeteer/Playwright 代码。
- **缺点**：diff 丑陋；手改困难；断言弱；遇到动态 UI 就崩。
- **使用者**：Selenium IDE、Chrome DevTools Recorder、Katalon Recorder。Playwright Codegen 录制→输出代码，**不**持久化 JSON。

## 5. Keyword-driven

表格式的纯文本。Scenario 是 keyword 序列，keyword 可以组合——高层 keyword 调用低层 keyword。

```robot
*** Test Cases ***
Valid Login
    Open Login Page
    Input Username    ${USER}
    Input Password    ${PASS}
    Welcome Page Should Be Open
```

- **优点**：可读性强；分层抽象（高层 keyword → 底层库）；内置数据表格强大。
- **缺点**：空白敏感的语法很容易出错；生态比 Playwright/Cypress 小。
- **使用者**：Robot Framework、Katalon Studio（混合）、TestComplete keyword 视图。

## 6. 二进制 / 专有录制

TestComplete、Ranorex、UFT/QTP 之类把 scenario 序列化成专有二进制或 ProjectSuite 格式，为 IDE 的回放引擎优化，不为人类优化。

- **优点**：捕捉像素级时序和手势；与创作 GUI 深度集成。
- **缺点**：无法 diff、无法 code review、供应商锁定、LLM 基本读不动。
- **使用者**：TestComplete、Ranorex、UFT/QTP、部分企业工具。

## 7. AI / Vision——意图优先于坐标

三种涌现出的风格，共享同一核心理念：**存用户想做什么，运行时重新定位**。

**[[midscene-js|Midscene]] YAML**——针对 web/android/ios/computer 目标的语义动作：

```yaml
ios:
  bundleId: com.example.app
tasks:
  - name: search
    flow:
      - ai: 搜索 "今天的天气"
      - aiAssert: 结果展示了天气信息
```

**[[drizz|Drizz]] 纯英文**——测试字面上就是 *"点击登录按钮；验证购物车显示 3 件商品"* 这样的句子，运行时由 VLM 对屏幕截图解析。主打自愈。

**Claude Computer Use 轨迹**——不是用来**撰写**的格式，而是**记录**的格式。JSONL，每行一个工具调用事件（`screenshot`、`left_button_press` 带坐标、`scroll_down`）加上模型推理。完整可审计；但回放有损，因为模型每一轮都重新规划。

- **优点**：解决"元素找不到"问题——AI 每一步都对当前屏幕重新定位。
- **缺点**：非确定性、成本、延迟；没有结构化 oracle 时断言乏力；LLM 可能以**不同方式**"成功"。

## 横向 Tradeoff 对比

| 维度 | 代码 | Gherkin | YAML/DSL | JSON 录制 | Keyword | AI 意图 |
|------|------|---------|----------|-----------|---------|---------|
| UI 漂移时的可重放性 | 取决于 POM | 取决于 step def | 无 AI 兜底则脆弱 | **fallback selector 有帮助** | 好 | **最好——重定位** |
| 人类可读性 | 中 | **高** | **高** | 低 | **高** | **高** |
| LLM 读写友好度 | 中 | 中 | **高** | 中 | 中 | **高** |
| Git diff 质量 | **优** | **优** | **优** | 差 | **优** | **优** |
| 参数化 | env、fixture、`test.each` | `Examples` 表 | env (`-e`) | 弱 | variables section | prompt 插值 |

业界应对可重放性问题的两条共识：**selector fallback 列表**（Chrome Recorder、Selenium IDE）与**每次运行语义重定位**（Midscene、Drizz）。坐标在所有可信方案里都是**最后手段**。

## 给 Iris 的推荐方案

[[drizz-clone-spec|Iris]] 是 LLM + vision + [[webdriveragent|WDA]]。读者既有人类 QA 也有 LLM 自己。**不要发明新格式，混搭两种成熟范式**：

1. **源格式 = Maestro 风格 YAML**。Diff 友好，LLM 读写 YAML 比代码和 JSON 都更稳，人类一眼能看懂。每个 step 带三层：
   - `intent:` — 自然语言描述（主字段，给 LLM + vision 用）
   - `hint:` — 可选的 `accessibilityId` / `text` / `bbox`（WDA 快路径）
   - `assert:` — 视觉或结构化断言

2. **运行时轨迹 = JSONL**（仿 Claude Computer Use）。每步记录 `screenshot_ref`、`model_reasoning`、`action`、`result`。这是**副产物**用于调试和回放审计，不是源文件。作者只维护 YAML。

3. **参数化 = Maestro + Gherkin 混合**。CLI `-e KEY=VAL` + YAML `${VAR}` 插值，再加可选的 `examples:` 数组借鉴 Scenario Outline 的数据驱动精神。

4. **明确拒绝**：
   - 纯代码——失去 LLM 生成 scenario 的卖点。
   - 纯 JSON 录制——diff 灾难，LLM 反复编辑会污染。
   - 纯 Gherkin——step definitions 的抽象对 LLM 毫无价值。
   - 二进制——LLM 读不动。

5. **分层字段**是平衡可读性与稳定性的关键：`intent` 提供 Midscene 风格的语义路由；可选的 `hint` 在出现时提供确定性的 WDA 查找。两全其美。

一句话：**YAML 写意图（给人+LLM 看）、JSONL 记轨迹（给调试看）、可选 hint 层（给 WDA 快路径）**——三层职责分明，每层都抄自成熟工具。

## 参见

- [[maestro]] — Iris 应模仿的经典 YAML 流移动端 runner
- [[midscene-js]] — 带视觉重定位的语义动作 YAML
- [[drizz]] — 纯英文意图 + 自愈回放
- [[drizz-clone-spec]] — Iris 规格书，本分析直接服务于它
- [[claude-vision-iphone-experiment]] — 为什么"意图 + WDA hint 混合"胜过纯 vision
- [[e2e-testing-strategy]] — 策略层（何时做 E2E），与本页的格式层互补
