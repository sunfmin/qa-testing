---
title: Drizz
type: entity
created: 2026-04-09
updated: 2026-04-10
tags: [testing, ios, android, e2e, ai, vision-ai]
sources: [ios-e2e-testing-research-2026]
---

# Drizz

A Vision AI-powered mobile E2E testing platform. Write tests in plain English — no selectors, no source code required.

## Key Facts

| Attribute     | Value                                         |
| ------------- | --------------------------------------------- |
| Type          | Vision AI, black-box                          |
| Test Language | Plain English                                 |
| iOS Support   | Simulator (Desktop App) + Real Device (Cloud) |
| License       | Commercial (closed source)                    |
| Founded       | July 2025 (seed $2.7M)                        |
| Founders      | Ex-Amazon, Coinbase, Gojek engineers          |
| Setup Time    | Minutes                                       |

## Two Components

| Component             | Purpose                                                    | Access                |
| --------------------- | ---------------------------------------------------------- | --------------------- |
| **Drizz Desktop App** | Local test authoring, simulator connection, debugging      | macOS arm64 installer |
| **Drizz Cloud**       | Remote execution, CI/CD, reporting, real device management | app.drizz.dev         |

## How It Works (Vision AI)

1. Captures a screenshot of the current device screen
2. Feeds it into a Vision Language Model (VLM): visual layout, text recognition, element positioning
3. Matches the plain-English instruction (e.g. "Tap Login") to the visually identified element
4. Executes the action via standard channels (Xcode instruments for iOS, ADB for Android)

**Key advantage**: No dependency on XPath, Accessibility IDs, or CSS selectors. Automatically adapts to button renames and layout changes.

## Test Authoring

### Plain English Steps
```
Tap on Login
Enter email
Submit the form
Verify the cart shows 3 items
```

### System Commands
- `OPEN_APP` — Launch or restart the app
- `EXECUTE_API` — Call an API endpoint within a test flow
- `SET_GPS` — Mock device location

### Fathom Module (AI Test Generation)

Enter a high-level goal:
> "Set location to San Francisco, go to Instacart, search for Wheat, and add an item to cart"

Fathom automatically generates all intermediate steps (opening the search bar, waiting for results, selecting an item, etc.). Claims to produce steps that run correctly on the first attempt.

### Best Practices
- Write clear, outcome-focused intent descriptions
- Let Fathom handle step decomposition — focus on the goal
- Use reusable flows for common sequences (login, navigation)
- Test files are plain text, Git-friendly

## Execution Performance

| Scenario | Time per Step |
|----------|---------------|
| First run (AI inference) | ~8-10 sec |
| Cache hit (subsequent runs) | ~4-5 sec |
| 10-step test (first run) | ~90 sec |
| 10-step test (cached) | ~40-50 sec |
| Cache hit rate (mature suites) | ~90% |

## Self-Healing

When UI changes between releases:
1. Vision AI re-identifies the target element contextually instead of relying on fixed selectors
2. Interprets test steps visually at runtime (not pre-compiled)
3. Automatically adapts to layout shifts, new popups, renamed elements
4. Cache updates automatically

Claimed metrics: flakiness reduced from ~15% (Appium) to ~5%, test maintenance time reduced by 70-85%.

## CI/CD Integration

Supported platforms: GitHub Actions, GitLab CI, Jenkins, Azure DevOps, Bitrise, CircleCI

How it works:
- Drizz Cloud provides APIs for authentication, app upload, and test plan triggering
- Returns structured logs, execution IDs, and pass/fail signals
- Supports parallel execution, scheduled runs, and selective reruns

> [!note] No specific CI/CD YAML configuration examples were found in public documentation. Setup appears to use API calls to trigger test plans.

## Pricing

| Plan | Details |
|------|---------|
| **Free Trial** | 50 test runs, no credit card required |
| **Pay As You Go** | Purchase runs as needed, unlimited authoring, CI/CD integration |
| **Team** | Shared workspace, collaboration, priority support |
| **Enterprise** | On-premise/VPC, unlimited runs, SSO/SAML, dedicated account manager |

> [!note] Actual dollar amounts are not public. The pricing page (drizz.dev/pricing) returns 404.

Security certifications: SOC 2 Type II, ISO 27001, HIPAA

## Known Customers

- **NikahForever** — 50+ test cases, 80%+ coverage, zero selector usage
- **Tata 1mg** — AI-driven stability testing

## Limitations and Risks

**Known limitations:**
- Higher first-run latency (AI inference ~8-10 sec/step)
- Visually ambiguous screens may need extra clarification
- Test logic is less directly readable than YAML
- Mobile-only (no web or desktop testing)
- Commercial product, not open source

**Risk factors:**
- Early-stage startup (founded July 2025)
- No independent reviews on G2/Capterra/Product Hunt
- Incomplete documentation and API reference
- Very small community
- Opaque pricing

## vs Traditional Tools

| Dimension | Appium | Maestro | Drizz |
|-----------|--------|---------|-------|
| Approach | Selectors (WebDriver) | YAML + Accessibility ID | Vision AI |
| Authoring speed | ~15 tests/mo/person | Moderate | ~200 tests/mo/person |
| Flakiness | ~15% | Moderate | ~5% |
| Maintenance burden | Very high | Moderate | Very low |
| Cross-platform | 2x effort | 1x (shared YAML) | 1x (shared English) |
| Open source | Yes | Yes | No |

## Bottom Line

Drizz offers a genuinely different approach to mobile testing (Vision AI). The plain-English authoring and self-healing claims are technically credible. However, the platform has not yet been publicly battle-tested — no independent reviews, opaque pricing, sparse documentation. The 50-run free trial is a low-risk way to evaluate. Best suited for teams willing to be early adopters.

## Technical Architecture (Reverse-Engineered)

### Company Background
- **Registered entity**: Drizz Automation Technologies Private Limited, incorporated Dec 2024 in Bangalore, India
- **Team**: 1-10 people (Wellfound)
- **Website**: Built on Webflow, docs on GitBook

### Vision AI Stack

**Confirmed:**
- Uses commercial VLM APIs: OpenAI, Claude (Anthropic), Gemini (Google)
- Blog mentions a **fine-tuned vision model** for element identification
- Multi-signal element identification: text recognition + icon/visual patterns + spatial positioning + color + quantitative evaluation
- Likely a hybrid approach: commercial VLMs for primary visual understanding, lighter model for cache comparison

**Unconfirmed:**
- Which specific VLM serves as the primary production model
- Whether fine-tuning is on an open-source model (e.g. Qwen-VL)
- The 8-10 sec/step latency is consistent with cloud VLM API calls

### Device Control Layer

**Confirmed:**
- **Android**: ADB + Android Emulator (standard SDK toolchain)
- **iOS**: Xcode runtime for simulator management, likely uses `simctl` for input
- **No embedded agent/SDK** in the app under test
- **Does not use Appium**

**Inferred architecture:**
```
Vision AI analyzes screenshot → determines target coordinates → sends input via ADB/simctl
```

### Visual Caching System

- Semantic-aware matching (not pixel-perfect): same layout with different text → cache hit
- Cache miss → falls back to full AI inference + cache update
- Exact algorithm undisclosed (likely structural embeddings or classical CV similarity)

### Desktop App
- macOS arm64 DMG installer
- Naming pattern (`Drizz+Desktop-Mac-arm64-...`) is consistent with **Electron** build artifacts
- For a 1-10 person startup, Electron is the most likely choice

### Backend Stack (from job postings)
- **Python** microservices architecture
- **Auth0** authentication
- REST APIs
- Standard cloud infrastructure (specific provider undisclosed)

### vs Similar Vision-Based Tools

| | Drizz | Repeato | Waldo (Tricentis) | Functionize |
|--|-------|---------|-------------------|-------------|
| Vision approach | VLM (GPT-4o/Claude/Gemini) | Local lightweight CV model | Record-replay + AI-assisted | Own neural network (10yr data) |
| Element identification | Pure vision | Visual fingerprints + selector fallback | Primarily selectors | ML + self-healing |
| Open source | None | Partial | None | None |

### Opaque Areas
- No public GitHub/npm/PyPI repositories
- No patents or technical papers
- No independent third-party technical analysis
- API documentation not publicly available

## See Also

- [[maestro]]
- [[appium]]
- [[xcuitest]]
- [[ai-testing-tools-comparison]]

---

# 中文翻译

# Drizz

Vision AI 驱动的移动端 E2E 测试平台。用纯英文编写测试，无需选择器或源代码。

## 基本信息

| 属性 | 值 |
|------|-----|
| 类型 | Vision AI，黑盒 |
| 测试语言 | 纯英文 |
| iOS 支持 | 模拟器（Desktop App）+ 真机（Cloud） |
| 许可证 | 商业（闭源） |
| 成立时间 | 2025年7月（种子轮 $2.7M） |
| 创始人 | 前 Amazon、Coinbase、Gojek 工程师 |
| 上手时间 | 分钟级 |

## 两个组件

| 组件 | 用途 | 访问方式 |
|------|------|----------|
| **Drizz Desktop App** | 本地编写测试、连接模拟器、调试 | macOS arm64 安装包 |
| **Drizz Cloud** | 远程执行、CI/CD、报告、真机管理 | app.drizz.dev |

## 工作原理（Vision AI）

1. 截取当前设备屏幕截图
2. 送入 Vision Language Model (VLM) 分析：视觉布局、文字识别、元素位置关系
3. 将英文指令（如 "Tap Login"）匹配到识别出的视觉元素
4. 通过标准通道执行操作（iOS 用 Xcode instruments，Android 用 ADB）

**核心优势**：不依赖 XPath、Accessibility ID、CSS 选择器。按钮改名、布局变化都能自动适应。

## 测试编写

### 纯英文步骤
```
Tap on Login
Enter email
Submit the form
Verify the cart shows 3 items
```

### 系统命令
- `OPEN_APP` — 启动或重启 App
- `EXECUTE_API` — 在测试流程中调用 API
- `SET_GPS` — 模拟设备位置

### Fathom 模块（AI 生成测试）

输入高级目标：
> "Set location to San Francisco, go to Instacart, search for Wheat, and add an item to cart"

Fathom 自动生成所有中间步骤（打开搜索栏、等待结果、选择商品等）。声称首次生成即可正确运行。

### 最佳实践
- 写清晰的、以结果为导向的意图描述
- 让 Fathom 处理步骤分解，专注于目标
- 用可复用流程处理常见序列（登录、导航）
- 测试文件是纯文本，可以用 Git 管理

## 执行性能

| 场景 | 每步耗时 |
|------|----------|
| 首次运行（AI 推理） | ~8-10 秒 |
| 缓存命中（后续运行） | ~4-5 秒 |
| 10步测试（首次） | ~90 秒 |
| 10步测试（缓存） | ~40-50 秒 |
| 成熟套件缓存命中率 | ~90% |

## 自愈能力

当 UI 在版本间变化时：
1. Vision AI 根据上下文重新识别目标元素（而非依赖固定选择器）
2. 运行时视觉解释测试步骤（不是预编译）
3. 自动适应布局变化、新弹窗、重命名元素
4. 缓存自动更新

声称指标：不稳定率从 ~15%（Appium）降至 ~5%，测试维护时间减少 70-85%。

## CI/CD 集成

支持平台：GitHub Actions、GitLab CI、Jenkins、Azure DevOps、Bitrise、CircleCI

工作方式：
- Drizz Cloud 提供 API 进行认证、App 上传、测试计划触发
- 返回结构化日志、执行 ID、通过/失败信号
- 支持并行执行、计划运行、选择性重跑

> [!note] 具体的 CI/CD 配置 YAML 示例未在公开文档中找到。设置似乎是通过 API 调用触发测试计划。

## 定价

| 计划 | 说明 |
|------|------|
| **Free Trial** | 50 次测试运行，无需信用卡 |
| **Pay As You Go** | 按需购买运行次数，无限测试编写，CI/CD 集成 |
| **Team** | 共享工作区，协作功能，优先支持 |
| **Enterprise** | 本地/VPC 部署，无限运行，SSO/SAML，专属客户经理 |

> [!note] 具体价格金额未公开。定价页面（drizz.dev/pricing）返回 404。

安全认证：SOC 2 Type II、ISO 27001、HIPAA

## 已知客户

- **NikahForever** — 50+ 测试用例，80%+ 覆盖率，零选择器使用
- **Tata 1mg** — AI 驱动的稳定性测试

## 局限性和风险

**已知局限：**
- 首次运行延迟较高（AI 推理 ~8-10 秒/步）
- 视觉模糊的界面可能需要额外澄清
- 测试逻辑不如 YAML 直观可读
- 仅支持移动端（无 Web、桌面测试）
- 商业产品，非开源

**风险因素：**
- 早期创业公司（2025年7月成立）
- 无 G2/Capterra/Product Hunt 独立评价
- 文档和 API 参考不完整
- 社区规模很小
- 定价不透明

## vs 传统工具

| 维度 | Appium | Maestro | Drizz |
|------|--------|---------|-------|
| 方法 | 选择器（WebDriver） | YAML + Accessibility ID | Vision AI |
| 编写速度 | ~15 tests/月/人 | 中等 | ~200 tests/月/人 |
| 不稳定率 | ~15% | 中等 | ~5% |
| 维护负担 | 非常高 | 中等 | 非常低 |
| 跨平台 | 2x 工作量 | 1x（共享 YAML） | 1x（共享英文） |
| 开源 | 是 | 是 | 否 |

## 底线评估

Drizz 提供了真正不同的移动测试方法（Vision AI）。纯英文编写和自愈能力在技术上可信。但平台尚未经过公众检验——无独立评价、定价不透明、文档稀缺。50 次免费试用是低风险的评估方式。适合愿意做早期采用者的团队。

## 技术架构（逆向调研）

### 公司背景
- **注册实体**：Drizz Automation Technologies Private Limited，2024年12月注册于印度班加罗尔
- **团队**：1-10 人（Wellfound）
- **网站**：Webflow 构建，文档用 GitBook

### Vision AI 技术栈

**已确认：**
- 使用商业 VLM API：OpenAI、Claude (Anthropic)、Gemini (Google)
- 博客提到使用**微调视觉模型**识别元素
- 多信号元素识别系统：文字识别 + 图标/视觉模式 + 空间位置 + 颜色 + 数量评估
- 可能是混合方案：商业 VLM 做主要视觉理解，轻量级模型做缓存比对

**未确认：**
- 具体使用哪个 VLM 作为生产主力
- 是否基于开源模型（如 Qwen-VL）微调
- 8-10 秒/步延迟与云端 VLM API 调用一致

### 设备控制层

**已确认：**
- **Android**：ADB + Android Emulator（标准 SDK 工具链）
- **iOS**：Xcode runtime 管理模拟器，可能用 `simctl` 发送输入
- **无嵌入式 Agent/SDK** — 不在被测 App 中植入任何东西
- **不使用 Appium**

**推断架构：**
```
Vision AI 分析截图 → 确定目标坐标 → 通过 ADB/simctl 发送输入命令
```

### 视觉缓存系统

- 语义感知匹配（非像素级）：布局相同但文字不同 → 缓存命中
- 缓存未命中 → 回退到完整 AI 推理 + 更新缓存
- 具体算法未公开（可能是结构嵌入或经典 CV 相似度）

### Desktop App
- macOS arm64 DMG 安装包
- 命名模式（`Drizz+Desktop-Mac-arm64-...`）与 **Electron** 构建产物一致
- 对于 1-10 人创业公司，Electron 是最可能的选择

### 后端技术栈（来自招聘信息）
- **Python** 微服务架构
- **Auth0** 认证
- REST API
- 标准云基础设施（具体提供商未公开）

### vs 类似视觉测试工具

| | Drizz | Repeato | Waldo (Tricentis) | Functionize |
|--|-------|---------|-------------------|-------------|
| 视觉方案 | VLM (GPT-4o/Claude/Gemini) | 本地轻量 CV 模型 | 录制回放 + AI 辅助 | 自有神经网络（10年数据） |
| 元素识别 | 纯视觉 | 视觉指纹 + 选择器回退 | 主要选择器 | ML + 自愈 |
| 开源 | 无 | 部分 | 无 | 无 |

### 不透明之处
- 无公开 GitHub/npm/PyPI 仓库
- 无专利或技术论文
- 无独立第三方技术分析
- API 文档未公开

## 参见

- [[maestro]]
- [[appium]]
- [[xcuitest]]
- [[ai-testing-tools-comparison]]
