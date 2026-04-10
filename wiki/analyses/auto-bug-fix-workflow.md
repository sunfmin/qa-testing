---
title: Autonomous Bug Reproduction & Fix Workflow
type: analysis
created: 2026-04-10
updated: 2026-04-10
tags: [workflow, jira, bug-fix, automation, vision, testing, ci-cd]
sources: [claude-vision-iphone-experiment, drizz-clone-spec, midscene-js]
---

# Autonomous Bug Reproduction & Fix Workflow

An end-to-end automated workflow that reads bug tickets from JIRA, reproduces them on real devices with video evidence, analyzes source code to find and fix the root cause, writes tests at multiple levels, and verifies the fix — all with minimal human intervention.

## Overview

```
  JIRA Ticket (Bug)
        │
        ▼
  ┌─────────────┐
  │  1. PARSE   │  Extract structured repro steps from ticket
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ 2. REPRODUCE│  Execute steps on real device, record video
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ 3. EVIDENCE │  Attach video + screenshots to JIRA, confirm bug
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ 4. ANALYZE  │  Read source code, trace the bug to root cause
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ 5. TEST     │  Write integration test that fails (proves the bug)
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │  6. FIX     │  Patch the code, integration test passes
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ 7. VERIFY   │  Re-run UI flow on device, vision confirms fix
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ 8. DELIVER  │  Create PR, update JIRA, attach all evidence
  └─────────────┘
```

## Phase 1: PARSE — Extract Reproduction Steps

**Input:** JIRA ticket ID (e.g., `PROJ-1234`)

**Process:**
1. Fetch ticket via JIRA API (summary, description, comments, attachments, labels, priority)
2. Claude analyzes the ticket content and extracts:
   - **App identifier** (bundle ID / package name)
   - **Platform** (iOS / Android / both)
   - **Preconditions** (logged in? specific account? test data?)
   - **Steps to reproduce** (ordered, unambiguous)
   - **Expected behavior**
   - **Actual behavior** (the bug)
   - **Severity assessment** (crash? visual? data loss? performance?)

**Output:** Structured reproduction plan

```yaml
# Auto-generated from JIRA PROJ-1234
ticket: PROJ-1234
title: "Cart total shows $0 after removing last item and re-adding"
app:
  bundleId: com.example.shop
  platform: ios
preconditions:
  - User is logged in as test_user@example.com
  - At least one product exists in catalog
steps:
  - action: launch
  - action: tap
    target: "Products tab"
  - action: tap
    target: "first product in list"
  - action: tap
    target: "Add to Cart"
  - action: tap
    target: "Cart tab"
  - assert: "cart shows 1 item with correct price"
  - action: tap
    target: "Remove item"
  - assert: "cart is empty"
  - action: tap
    target: "Products tab"
  - action: tap
    target: "first product in list"
  - action: tap
    target: "Add to Cart"
  - action: tap
    target: "Cart tab"
  - assert: "cart total shows correct price"  # BUG: shows $0.00
expected: "Cart total reflects the product price"
actual: "Cart total shows $0.00"
```

**Failure handling:** If the ticket is too vague to extract steps, comment on JIRA asking for clarification and stop.

## Phase 2: REPRODUCE — Execute on Real Device with Recording

**Input:** Structured reproduction plan from Phase 1

**Process:**
1. Connect to device via WDA (iOS) or adb (Android)
2. Start video recording (`xcrun simctl io recordVideo` or WDA recording or `adb screenrecord`)
3. Execute each step using the **hybrid approach** from our experiment:
   - **Actions** (tap, type, swipe): WDA element find by label → exact coordinates → execute
   - **Assertions**: Screenshot → Claude vision reads and evaluates
   - **Fallback**: If WDA element find fails, use Claude vision to estimate coordinates
4. At each step, capture:
   - Screenshot (before + after)
   - Element tree snapshot
   - Step timing
   - Pass/fail status
5. Stop video recording
6. Determine: Was the bug reproduced?

**Key decisions:**
- If bug reproduces → continue to Phase 3
- If bug does NOT reproduce → retry up to 3 times with variations (different timing, different test data)
- If still no repro → comment on JIRA with video of successful flow, mark "Could not reproduce"

**Recording strategy:**
```bash
# iOS real device — WDA doesn't support recording natively
# Option A: Use QuickTime via CLI (macOS screen mirroring)
# Option B: Capture screenshots every 500ms and stitch to video (ffmpeg)
# Option C: For simulator: xcrun simctl io booted recordVideo output.mp4

# Android — straightforward
adb shell screenrecord /sdcard/bug_repro.mp4
```

For real iOS devices without native recording, use the **screenshot-to-video approach**:
```bash
# Capture screenshots at ~2fps during test execution
while testing; do
  curl -s http://localhost:8100/screenshot | base64 -d > frame_${i}.png
  sleep 0.5
done
# Stitch with ffmpeg
ffmpeg -framerate 2 -i frame_%d.png -c:v libx264 -pix_fmt yuv420p repro.mp4
```

## Phase 3: EVIDENCE — Attach to JIRA

**Input:** Video, screenshots, step log from Phase 2

**Process:**
1. Upload video to JIRA as attachment
2. Upload annotated screenshot of the bug state (the failing assertion)
3. Add a structured comment:

```markdown
## 🤖 Automated Bug Reproduction

**Status:** ✅ Bug reproduced on iPhone 17 Pro Max (iOS 26.3)
**Video:** [repro_PROJ-1234.mp4] (attached)
**Duration:** 23.4s (12 steps)

### Steps Executed:
1. ✅ Launch app (1.2s)
2. ✅ Tap "Products tab" (0.8s)
3. ✅ Tap first product (0.9s)
4. ✅ Tap "Add to Cart" (0.7s)
5. ✅ Tap "Cart tab" (0.8s)
6. ✅ Assert: cart shows 1 item — PASSED
7. ✅ Tap "Remove item" (0.6s)
8. ✅ Assert: cart is empty — PASSED
9. ✅ Tap "Products tab" (0.8s)
10. ✅ Tap first product (0.9s)
11. ✅ Tap "Add to Cart" (0.7s)
12. ❌ Assert: cart total shows correct price — **FAILED**
    - Expected: total > $0.00
    - Actual: total shows $0.00
    - Screenshot: [bug_state.png] (attached)

### Investigating root cause...
```

4. Transition JIRA ticket to "Reproducing" or similar status

## Phase 4: ANALYZE — Find Root Cause in Source Code

**Input:** Bug description, failing assertion, app knowledge

**Process:**
1. From the bug context, identify likely code areas:
   - Bug involves "cart total" → search for cart calculation logic
   - `grep -r "cart.*total\|calculateTotal\|cartPrice" src/`
2. Read the relevant source files
3. Claude analyzes the code path:
   - Trace from UI action ("Add to Cart") through to the data layer
   - Identify where the state becomes inconsistent
   - Look for: stale caches, race conditions, missing state resets, wrong event ordering
4. Form a hypothesis:
   - "The `cartTotal` computed property reads from a cached value that isn't invalidated when items are removed and re-added in the same session"
5. Verify hypothesis by reading more code (the cache invalidation logic, the remove-item handler)

**Output:** Root cause analysis with file paths and line numbers

```markdown
## Root Cause Analysis

**Hypothesis:** Cart total cache is not invalidated on item removal

**Code path:**
1. `CartViewModel.swift:45` — `addToCart()` calls `CartService.add(product)`
2. `CartService.swift:78` — `add()` appends to `items` array and calls `recalculateTotal()`
3. `CartService.swift:92` — `removeItem()` removes from array but does NOT call `recalculateTotal()`
4. `CartService.swift:102` — `total` is a cached `var` set only by `recalculateTotal()`
5. When item is re-added after removal, `recalculateTotal()` runs but reads from stale `subtotals` dictionary that still has `quantity: 0` for the removed item

**Fix:** Call `recalculateTotal()` in `removeItem()`, or better: make `total` a computed property.

**Files to change:**
- `CartService.swift:92` — add `recalculateTotal()` call after removal
- Or refactor `total` to be computed (lines 102-105)

**Confidence:** High — the code path clearly shows the cache staleness.
```

## Phase 5: TEST — Write Integration Test That Proves the Bug

**Input:** Root cause analysis from Phase 4

**Process:**
1. Write a **unit/integration test** (not UI test) that exercises the exact code path
2. The test must **fail** on the current code (proving the bug exists)
3. The test should be fast (no UI, no device, no VLM)

```swift
// CartServiceTests.swift
func testCartTotalAfterRemoveAndReAdd() {
    let cart = CartService()
    let product = Product(id: "1", name: "Widget", price: 29.99)

    // Add item
    cart.add(product)
    XCTAssertEqual(cart.total, 29.99)

    // Remove item
    cart.removeItem(product.id)
    XCTAssertEqual(cart.total, 0.00)

    // Re-add same item — THIS IS THE BUG
    cart.add(product)
    XCTAssertEqual(cart.total, 29.99)  // FAILS: returns 0.00
}
```

4. Run the test → verify it **fails** (red)
5. If the test passes (bug not reproduced at unit level), the root cause hypothesis is wrong → go back to Phase 4

**Why integration test first, not UI test:**
- 100x faster execution (milliseconds vs minutes)
- Deterministic (no VLM, no device, no flakiness)
- Pinpoints the exact code under test
- Serves as a regression guard forever
- CI-friendly (runs on every commit)

## Phase 6: FIX — Patch the Code

**Input:** Root cause analysis + failing test from Phase 5

**Process:**
1. Apply the minimal fix identified in Phase 4
2. Run the integration test → verify it **passes** (green)
3. Run the full existing test suite → verify no regressions
4. If tests fail, iterate on the fix

```swift
// CartService.swift — FIX
func removeItem(_ productId: String) {
    items.removeAll { $0.id == productId }
    subtotals.removeValue(forKey: productId)  // Clean up subtotals dict
    recalculateTotal()  // ← THIS WAS MISSING
}
```

**Guard rails:**
- Fix must be minimal (no refactoring beyond what's needed)
- All existing tests must still pass
- If fix touches >3 files or >50 lines, flag for human review before proceeding

## Phase 7: VERIFY — Re-run UI Flow on Device

**Input:** Fixed code deployed to device

**Process:**
1. Build the app with the fix
2. Install on device
3. Re-run the exact same reproduction steps from Phase 2
4. Record video again
5. Claude vision verifies the previously-failing assertion now **passes**
6. Capture "fixed state" screenshot

**Verification checklist:**
- [ ] The specific bug assertion passes
- [ ] No new visual anomalies in the flow
- [ ] App doesn't crash at any step
- [ ] Performance is not degraded (step timings within 2x of baseline)

**If verification fails:** The fix is incomplete → go back to Phase 4 with new evidence.

## Phase 8: DELIVER — Create PR and Update JIRA

**Input:** All evidence from Phases 1-7

**Process:**

### 1. Create Git Branch and PR

```bash
git checkout -b fix/PROJ-1234-cart-total-after-remove
git add CartService.swift CartServiceTests.swift
git commit -m "Fix cart total not updating after remove and re-add

Root cause: removeItem() did not call recalculateTotal() or clean
subtotals dictionary, causing stale cached total on re-add.

Fixes PROJ-1234"
gh pr create --title "Fix cart total after remove and re-add" --body "..."
```

### 2. PR Description

```markdown
## Summary
Fixes PROJ-1234: Cart total shows $0 after removing last item and re-adding.

## Root Cause
`CartService.removeItem()` removed the item from the `items` array but did not:
1. Clean up the `subtotals` dictionary entry
2. Call `recalculateTotal()`

When the same product was re-added, `recalculateTotal()` read stale data
from `subtotals` (quantity: 0), resulting in a $0.00 total.

## Fix
- Added `subtotals.removeValue(forKey:)` and `recalculateTotal()` to `removeItem()`
- Added integration test `testCartTotalAfterRemoveAndReAdd`

## Evidence
- 🎥 Bug reproduction video: [repro_PROJ-1234.mp4]
- 🎥 Fix verification video: [verify_PROJ-1234.mp4]
- 📸 Bug state screenshot: [bug_state.png]
- 📸 Fixed state screenshot: [fixed_state.png]
- ✅ Integration test: `CartServiceTests.testCartTotalAfterRemoveAndReAdd`
- ✅ Full test suite passes

## Test Plan
- [x] Integration test reproduces and verifies fix
- [x] UI test on real device confirms fix
- [x] Existing test suite passes
- [ ] Human review of code change
```

### 3. Update JIRA

```markdown
## 🤖 Automated Fix Delivered

**PR:** [#456 — Fix cart total after remove and re-add](link)
**Branch:** fix/PROJ-1234-cart-total-after-remove

### Root Cause
`CartService.removeItem()` did not recalculate total or clean subtotals dict.
See PR for full analysis.

### Evidence
- 🎥 Reproduction video: [repro_PROJ-1234.mp4] (attached)
- 🎥 Verification video: [verify_PROJ-1234.mp4] (attached)
- ✅ Integration test added
- ✅ UI verification passed on iPhone 17 Pro Max (iOS 26.3)

### Status
Awaiting human review of PR. Transitioning to "In Review".
```

4. Transition JIRA to "In Review"
5. Assign PR reviewer (from JIRA assignee's team)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Bug Fix Agent                                │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │  JIRA    │  │  Device  │  │  Source   │  │  CI Pipeline   │  │
│  │  Client  │  │  Control │  │  Analyzer │  │                │  │
│  └────┬─────┘  └────┬─────┘  └────┬──────┘  └───────┬────────┘  │
│       │             │             │                  │           │
│  ┌────┴─────────────┴─────────────┴──────────────────┴────────┐  │
│  │                   Claude Code (Orchestrator)                │  │
│  │                                                              │  │
│  │  - Reads JIRA tickets (Atlassian MCP)                       │  │
│  │  - Controls device (WDA/adb via wda.sh)                     │  │
│  │  - Reads screenshots (native vision)                        │  │
│  │  - Analyzes source code (Read/Grep tools)                   │  │
│  │  - Writes tests and fixes (Edit/Write tools)                │  │
│  │  - Creates PRs (gh CLI)                                     │  │
│  │  - Records video (ffmpeg screenshot stitching)              │  │
│  └──────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘

External dependencies:
  - JIRA (Atlassian MCP or REST API)
  - iPhone/Android via WDA/adb
  - Git + GitHub (gh CLI)
  - Xcode (build app with fix)
  - ffmpeg (video from screenshots)
```

## Tool Requirements

| Tool | Purpose | Already Available |
|------|---------|-------------------|
| Atlassian MCP | Read/write JIRA tickets | ✅ (installed in Claude Code) |
| WDA + wda.sh | Device control + screenshots | ✅ (from experiment) |
| Claude vision (Read) | Screenshot assertions | ✅ (built-in) |
| Grep/Read/Edit | Source code analysis and patching | ✅ (built-in) |
| gh CLI | Create PRs | ✅ (installed) |
| ffmpeg | Stitch screenshots to video | Need to install |
| xcodebuild | Build app with fix | ✅ (installed) |

## Trigger Modes

### 1. Manual (Claude Code prompt)
```
"Fix bug PROJ-1234"
```

### 2. Scheduled (cron via Claude Code triggers)
```
Every morning: scan JIRA for new bugs with label "auto-fixable" → process each
```

### 3. CI/CD hook (webhook on JIRA ticket creation)
```
JIRA webhook → triggers Claude Code agent → runs workflow
```

## Confidence Scoring

Not all bugs should be auto-fixed. Score each phase:

| Phase | Confidence Signal | Threshold |
|-------|------------------|-----------|
| Parse | Steps extractable from ticket | Must extract ≥3 steps |
| Reproduce | Bug visually confirmed by vision | Vision confidence ≥0.8 |
| Analyze | Root cause traced to specific lines | Must identify ≤3 files |
| Test | Integration test fails then passes | Must be red→green |
| Fix | Change is small and contained | ≤50 lines, ≤3 files |
| Verify | UI flow passes end-to-end | All assertions pass |

**If any phase falls below threshold:** Stop, comment findings on JIRA, assign to human developer.

**Auto-fix confidence levels:**
- **High** (all green): Create PR, request review, suggest auto-merge
- **Medium** (1-2 yellow): Create PR, request review, flag concerns
- **Low** (any red): Comment analysis on JIRA, do NOT create PR

## Optimizations

### Speed
- **Parallel source analysis**: While reproducing on device, start reading source code in parallel (use ticket description to guess code areas)
- **Cached WDA sessions**: Keep device session alive across runs
- **Pre-built app pool**: Keep recent app builds ready for deployment
- **Skip video on re-runs**: Only record video on first reproduction and final verification

### Accuracy
- **Multi-device verification**: Run on both iOS and Android if applicable
- **Regression suite**: Run full existing test suite, not just new test
- **Diff review**: Before creating PR, Claude reviews its own diff for quality

### Cost
- **Vision only for assertions**: Actions use WDA element finding (free, instant)
- **Cache reproduction plans**: If same bug type recurs, reuse step patterns
- **Batch processing**: Group related tickets, share device sessions

## Example: Full Run

```
$ claude "Fix bug PROJ-1234"

🔍 Phase 1: PARSE
   Reading JIRA PROJ-1234... "Cart total shows $0 after remove and re-add"
   Extracted 12 reproduction steps.

📱 Phase 2: REPRODUCE
   Connecting to iPhone 17 Pro Max...
   Recording video...
   Step 1/12: Launch app ✅ (1.2s)
   Step 2/12: Tap "Products" ✅ (0.8s)
   ...
   Step 12/12: Assert cart total > $0 ❌ FAILED — shows $0.00
   Bug reproduced. Video saved (23.4s).

📎 Phase 3: EVIDENCE
   Uploaded repro_PROJ-1234.mp4 to JIRA
   Uploaded bug_state.png to JIRA
   Added reproduction comment to JIRA

🔬 Phase 4: ANALYZE
   Searching source code for cart logic...
   Found: CartService.swift, CartViewModel.swift
   Root cause: removeItem() doesn't recalculate total
   Confidence: HIGH

🧪 Phase 5: TEST
   Writing integration test...
   Running test... ❌ FAILED (as expected — proves the bug)
   Test: testCartTotalAfterRemoveAndReAdd

🔧 Phase 6: FIX
   Applying fix to CartService.swift:92...
   Running integration test... ✅ PASSED
   Running full test suite... ✅ 247/247 passed

📱 Phase 7: VERIFY
   Building app with fix...
   Installing on device...
   Re-running reproduction steps...
   Recording video...
   Step 12/12: Assert cart total > $0 ✅ PASSED — shows $29.99
   Fix verified. Video saved.

🚀 Phase 8: DELIVER
   Created branch: fix/PROJ-1234-cart-total-after-remove
   Created PR #456 with evidence
   Updated JIRA: status → "In Review"
   Done. Awaiting human review.
```

## See Also

- [[claude-vision-iphone-experiment]] — hybrid WDA+vision approach (foundation for Phase 2/7)
- [[drizz-clone-spec]] — Iris spec (device control architecture)
- [[midscene-js]] — alternative pure-vision approach
- [[e2e-testing-strategy]] — testing pyramid (integration test before UI test)

---

# 中文翻译

# 自主 Bug 复现与修复工作流

一个端到端的自动化工作流：从 JIRA 读取 Bug 工单，在真实设备上复现并录制视频证据，分析源代码找到根因并修复，编写多层测试，验证修复——全程最少人工干预。

## 总览

```
JIRA 工单 → 解析复现步骤 → 设备上复现(录像) → 附证据到 JIRA
    → 分析源码定位根因 → 写集成测试(先失败) → 修复代码(测试通过)
    → 设备上重跑 UI 验证(视觉确认) → 创建 PR + 更新 JIRA
```

## 8 个阶段

### 1. PARSE — 从工单提取复现步骤
从 JIRA 获取工单，Claude 分析内容提取结构化复现计划（应用标识、前置条件、步骤、预期/实际行为）。

### 2. REPRODUCE — 在真机上执行并录像
使用混合方案（WDA 元素查找做操作 + Claude 视觉做断言），执行每个步骤，全程录制视频。

### 3. EVIDENCE — 附证据到 JIRA
上传视频、截图，添加结构化评论（每步通过/失败状态），更新工单状态。

### 4. ANALYZE — 分析源码找根因
搜索相关代码，Claude 追踪从 UI 操作到数据层的代码路径，形成假设并验证。

### 5. TEST — 写集成测试证明 Bug 存在
编写不依赖 UI 的集成/单元测试，复现 Bug（测试必须失败）。比 UI 测试快 100 倍，确定性强。

### 6. FIX — 修复代码
应用最小修复，集成测试通过，现有测试套件无回归。

### 7. VERIFY — 在设备上视觉验证
用修复后的应用重跑 Phase 2 的步骤，Claude 视觉确认之前失败的断言现在通过。

### 8. DELIVER — 创建 PR，更新 JIRA
创建分支和 PR（附所有证据），更新 JIRA 状态为"待审核"。

## 关键设计决策

### 为什么集成测试优先于 UI 测试？
- 快 100 倍（毫秒 vs 分钟）
- 确定性（无 VLM、无设备、无不稳定性）
- 精确定位被测代码
- 永久回归保护
- CI 友好

### 信心评分
每个阶段都有信心阈值。低于阈值时停止自动修复，将分析结果评论到 JIRA，分配给人工开发者。

### 混合方案（来自实验发现）
- **操作**：WDA 元素查找（快速、精确、免费）
- **断言**：Claude 视觉读取截图（擅长理解）
- **回退**：WDA 找不到元素时用视觉估算坐标

## 触发方式

1. **手动**：`claude "Fix bug PROJ-1234"`
2. **定时**：每天扫描带 "auto-fixable" 标签的新 Bug
3. **Webhook**：JIRA 创建工单时自动触发

## 参见

- [[claude-vision-iphone-experiment]] — 混合 WDA+视觉方案
- [[drizz-clone-spec]] — 设备控制架构
- [[e2e-testing-strategy]] — 测试金字塔
