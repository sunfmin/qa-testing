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

## [2026-04-10] maintenance | Bilingual rewrite
- Updated CLAUDE.md rule: English first, complete Chinese translation at end under `# 中文翻译`
- Rewrote all 8 wiki pages to bilingual format
- Pushed to GitHub: github.com/sunfmin/qa-testing

## [2026-04-10] analysis | Drizz Clone Spec (Iris)
- Created wiki/analyses/drizz-clone-spec.md — full product specification for a local macOS Drizz clone
- Codename: Iris
- Key design decisions:
  - Swift + SwiftUI native macOS app
  - BYO-LLM: protocol-based VLM provider (OpenAI, Anthropic, Google, Ollama)
  - Device control via simctl (iOS) and adb (Android)
  - Visual cache with perceptual hashing (pHash) + SQLite
  - YAML test file format with plain-English steps
  - 5-phase implementation plan (~10 weeks)
- Updated index.md

## [2026-04-10] update | Iris spec: real device support + CLI runner + Claude Code vision
- Major spec update to wiki/analyses/drizz-clone-spec.md
- Added real physical device support:
  - iOS real devices via WebDriverAgent (WDA) over USB/Wi-Fi
  - Android real devices via adb (works identically to emulators)
  - `iris setup ios-device` command for one-time WDA setup
  - DeviceManager with unified discovery across all device types
- Added CLI runner (iris):
  - Headless command-line tool sharing Core Engine with GUI
  - JUnit XML, JSON, HTML report output
  - GitHub Actions integration examples (simulator + real device jobs)
  - `.iris.yaml` project-level config file
  - Exit codes for CI pass/fail
- Changed vision approach to Claude Code integration:
  - Primary: Claude Code's native vision (Read tool for screenshots)
  - Fallback: Direct Anthropic API for standalone CI/CD
  - Removed OpenAI/Gemini/Ollama providers (simplified)
- Restructured to 6-phase plan (~12 weeks), CLI-first approach

## [2026-04-10] experiment | Claude Vision + WDA on real iPhone
- Tested on iPhone 17 Pro Max (iOS 26.3) via WebDriverAgent over USB
- Setup: Appium xcuitest-driver → built WDA → iproxy 8100 → W3C Actions API
- Test flow: Home → Spotlight → Settings → General → About (read device info)
- Created wiki/analyses/claude-vision-iphone-experiment.md
- Key findings:
  - Pure vision coordinate estimation is unreliable (100-200pt Y-axis error)
  - WDA element finding is instant and exact
  - Vision excels at understanding/assertions, fails at precise locating
  - Hybrid approach (WDA for actions + Vision for assertions) is optimal
  - This reframes Midscene.js: its pure-vision locating is fundamentally slower and less precise than WDA accessibility tree
  - Midscene still wins for canvas/WebGL and cross-platform visual matching
  - Recommended Iris architecture: WDA element find (primary) → Claude vision fallback → Claude assertions
