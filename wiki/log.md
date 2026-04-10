# Wiki Log

Chronological record of wiki operations.

## [2026-04-09] init | Wiki initialized
- Created directory structure: raw/, wiki/, wiki/sources/, wiki/entities/, wiki/concepts/, wiki/analyses/
- Created index.md and log.md
- Created CLAUDE.md schema

## [2026-04-09] ingest | iOS E2E Testing Research
- Researched iOS E2E test automation frameworks for existing apps
- Created wiki/sources/ios-e2e-testing-research-2026.md — framework comparison (Maestro, Appium, XCUITest, Detox, AI tools)
- Created wiki/concepts/e2e-testing-strategy.md — testing pyramid and guidelines
- Updated index.md
- Key finding: Maestro is the fastest path to get started; Appium for cross-platform; XCUITest if you have the Xcode project

## [2026-04-09] query | AI-Powered Mobile Testing Tools Deep Dive
- Researched Drizz, testRigor, Katalon TrueTest, and TestSprite in depth
- Created wiki/analyses/ai-mobile-testing-tools-2025-2026.md
- Updated index.md with new analysis entry
- Key findings:
  - Only Drizz and testRigor support native iOS app testing
  - Katalon TrueTest and TestSprite are web-only despite mobile marketing
  - Drizz (vision AI, seed-funded Jul 2025) is most streamlined for iOS but very young
  - testRigor (NLP, est. 2017) is most mature but needs BrowserStack/LambdaTest for iOS real devices
  - For testing existing iOS apps without source code: Drizz is most direct (IPA upload + English tests)

## [2026-04-09] ingest | Deep-dive on all testing tools
- Created wiki/entities/maestro.md — v2.4.0, YAML, $250/device/month cloud, no local real device iOS
- Created wiki/entities/appium.md — v3.2.2, WebDriver, ~15% flake rate, free OSS
- Created wiki/entities/xcuitest.md — Xcode 16+, native Swift, fastest execution, iOS-only
- Created wiki/entities/detox.md — v20.50.1, gray-box sync, React Native primary, MIT free
- Created wiki/analyses/ai-testing-tools-comparison.md — consolidated AI tools comparison
- Updated index.md with all new entity and analysis entries

## [2026-04-09] ingest | Drizz deep-dive
- Created wiki/entities/drizz.md — 完整 Drizz 使用指南（Vision AI 原理、Fathom 测试生成、执行性能、自愈机制、CI/CD、定价、局限性）
- Updated index.md with Drizz entity entry

## [2026-04-10] query | Drizz technical implementation research
- Updated wiki/entities/drizz.md with reverse-engineered architecture details
- Key findings:
  - 使用商业 VLM API (OpenAI/Claude/Gemini) + 可能的微调模型
  - 设备控制通过 ADB (Android) 和 simctl/Xcode (iOS)，不用 Appium
  - Desktop App 很可能是 Electron
  - 后端是 Python 微服务 + Auth0 认证
  - 公司注册于印度班加罗尔，1-10 人团队
  - 无公开源码、专利、技术论文
  - 视觉缓存是语义感知（非像素级），具体算法未公开
