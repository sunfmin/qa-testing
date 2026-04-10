# Wiki Index

A structured, interlinked knowledge base for QA testing automation.

## Sources
- [iOS E2E Testing Research 2026](sources/ios-e2e-testing-research-2026.md) — Comprehensive comparison of frameworks (Maestro, Appium, XCUITest, Detox) and AI-powered tools for automating E2E tests on existing iOS apps.

## Entities
- [Maestro](entities/maestro.md) — YAML-based black-box mobile E2E testing, fastest setup, simulator-only for iOS
- [Appium + WebdriverIO](entities/appium.md) — Industry-standard cross-platform mobile automation, WebDriver protocol
- [XCUITest](entities/xcuitest.md) — Apple's native UI testing framework, fastest iOS execution, Xcode-integrated
- [Detox](entities/detox.md) — Gray-box E2E testing for React Native, in-process synchronization
- [Drizz](entities/drizz.md) — Vision AI mobile testing, plain English tests, no selectors needed
- [Midscene.js](entities/midscene-js.md) — ByteDance's vision-based UI automation: iOS/Android/Web/Desktop, YAML CLI, MCP servers, 12.5k stars

## Concepts
- [E2E Testing Strategy](concepts/e2e-testing-strategy.md) — Testing pyramid, what to test, execution guidelines for mobile E2E.

## Analyses
- [AI-Powered Mobile Testing Tools (2025-2026)](analyses/ai-mobile-testing-tools-2025-2026.md) — Deep comparison of Drizz, testRigor, Katalon TrueTest, and TestSprite
- [AI Testing Tools Comparison](analyses/ai-testing-tools-comparison.md) — Summary: only 2 of 4 AI tools support native iOS
- [Drizz Clone Spec (Iris)](analyses/drizz-clone-spec.md) — Local macOS app spec: Vision AI mobile testing, Swift+SwiftUI, BYO-LLM, open source
- [Existing Vision Testing Tools](analyses/existing-vision-testing-tools.md) — Landscape: Midscene.js (12.6k stars), ios-simulator-mcp, appium-mcp, Claude Computer Use. Recommends pivot to composition over greenfield.
- [Claude Vision + WDA iPhone Experiment](analyses/claude-vision-iphone-experiment.md) — Real device test on iPhone 17 Pro Max. Key finding: pure vision is bad at coordinates (100-200pt error), hybrid WDA+vision is optimal. Reframes Midscene vs Iris approach.
