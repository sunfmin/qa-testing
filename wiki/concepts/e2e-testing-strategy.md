---
title: E2E Testing Strategy
type: concept
created: 2026-04-09
updated: 2026-04-10
tags: [e2e, strategy, testing-pyramid, best-practices]
sources: [ios-e2e-testing-research-2026]
---

# E2E Testing Strategy

## Testing Pyramid for Mobile

```
        /  E2E  \        ← Few, critical journeys only (<30 min suite)
       / Integration \    ← API contracts, service boundaries
      /    Unit Tests   \ ← Most tests here (fast, isolated)
```

E2E tests validate the **full user experience** end-to-end. They are the most expensive to write and maintain, so focus on critical paths.

## What to E2E Test
- **Authentication flows** (login, signup, password reset)
- **Core business journeys** (the thing users pay for)
- **Payment/checkout** (if applicable)
- **Onboarding/first-run experience**
- **Cross-feature flows** that span multiple screens

## What NOT to E2E Test
- Edge cases (use unit tests)
- API contract validation (use integration tests)
- Visual pixel-perfect checks (use snapshot tests)
- Every permutation of form input (use unit tests)

## Execution Guidelines
- Target **<30 minute** total suite runtime
- Use **parallel execution** across devices/simulators
- Run on **real devices** for release validation
- Run on **simulators** for fast developer feedback
- Integrate into **CI/CD** — block merges on E2E failure for critical paths

## Related
- [[ios-e2e-testing-research-2026]] — framework comparison
- [[maestro]] — recommended quick-start framework
- [[appium]] — industry standard for cross-platform
- [[xcuitest]] — Apple's native testing framework

---

# 中文翻译

# E2E 测试策略

## 移动端测试金字塔

```
        /  E2E  \        ← 少量，仅关键用户路径（套件<30分钟）
       /  集成测试  \     ← API 契约，服务边界
      /    单元测试    \  ← 大部分测试在这里（快速，隔离）
```

E2E 测试验证**完整的用户体验**。它们是编写和维护成本最高的测试，因此应聚焦于关键路径。

## 应该做 E2E 测试的场景
- **认证流程**（登录、注册、密码重置）
- **核心业务路径**（用户付费使用的功能）
- **支付/结账**（如适用）
- **引导/首次体验**
- **跨功能流程**（跨越多个页面）

## 不应该做 E2E 测试的场景
- 边界情况（用单元测试）
- API 契约验证（用集成测试）
- 视觉像素级检查（用快照测试）
- 表单输入的所有排列（用单元测试）

## 执行指南
- 目标套件总运行时间 **<30分钟**
- 跨设备/模拟器**并行执行**
- 发布验证使用**真机**
- 开发迭代使用**模拟器**以获得快速反馈
- 集成到 **CI/CD** — 关键路径的 E2E 失败应阻止合并

## 相关页面
- [[ios-e2e-testing-research-2026]] — 框架对比
- [[maestro]] — 推荐的快速起步框架
- [[appium]] — 跨平台行业标准
- [[xcuitest]] — Apple 原生测试框架
