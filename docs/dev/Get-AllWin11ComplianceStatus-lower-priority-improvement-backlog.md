<!-- markdownlint-disable MD013 -->

# Get-AllWin11ComplianceStatus Lower-Priority Improvement Backlog

## Metadata

- **Status:** Draft
- **Owner:** Repository Maintainers
- **Last Updated:** 2026-06-25
- **Scope:** Preserves improvement opportunities from `Get-AllWin11ComplianceStatus-improvement-opps.md` that were not included in `Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md` because their intrinsic priority is below medium-high and they were not required prerequisites for higher-priority work.
- **Related:** [`Get-AllWin11ComplianceStatus-backlog-prioritization-rubric.md`](Get-AllWin11ComplianceStatus-backlog-prioritization-rubric.md), [`Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`](Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md), [`scripts/Get-AllWin11ComplianceStatus.ps1`](../../scripts/Get-AllWin11ComplianceStatus.ps1)

## F008: Separate Library Functions From Script Entry Point

**Priority:** Medium

**Rubric score:** 42.4/100. Criteria scores: C01=1, C02=1, C03=1, C04=2, C05=2, C06=4, C07=5, C08=1, C09=3, C10=2, C11=4, C12=4, C13=2, C14=1, C15=2.

**Reason excluded from sequenced priority file:** This is useful structural cleanup, but the current high-priority work can be planned without first splitting the script into separate library and entry-point files. If later option analysis shows that a specific high-priority fix requires a file split, this finding can be pulled into the sequence as a prerequisite.

**Observed behavior:** The file serves as both a dot-sourceable function library and an executable script. Tests dot-source it to access internal functions, while the script entry point checks `$MyInvocation.InvocationName -ne '.'` before running. This works, but it makes public versus private API boundaries unclear and can make future module packaging or function-level testing awkward.

**Why this matters:** A junior maintainer benefits from a clear layout that says which functions are supported contracts and which are implementation details. A Pester testing enthusiast can write narrower tests when functions are grouped by responsibility. A technical lead can evolve the implementation more safely if the executable wrapper is thin and the reusable implementation is isolated.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, tests, README, and any future module or helper file layout.

**Known dependencies:** This is a structural refactor and should be sequenced after behavior-critical tests exist, unless it is required as a prerequisite for safer implementation of other findings.

**Validation considerations:** Tests should continue proving both dot-sourced function behavior and direct script invocation behavior.

## F024: Align PowerShell Style With Repository Conventions

**Priority:** Medium-low

**Rubric score:** 32.6/100. Criteria scores: C01=0, C02=1, C03=1, C04=1, C05=2, C06=2, C07=3, C08=0, C09=5, C10=2, C11=5, C12=2, C13=3, C14=0, C15=3.

**Reason excluded from sequenced priority file:** This is legitimate repository-conformance work, but it is mostly style and maintainability cleanup. It should be performed opportunistically when touching affected code for higher-priority fixes, or as a later dedicated cleanup once behavior changes stabilize.

**Observed behavior:** Local variable names such as `$results`, `$nextUri`, `$response`, `$value`, `$item`, `$deviceId`, and `$rows` do not use the repository's type-prefixed camelCase local-variable convention. The helper comment-based help also lacks several required sections covered in F009.

**Why this matters:** A junior team member learns local style from examples. A PSScriptAnalyzer or review workflow may later enforce stricter naming and help rules. A technical lead may want this demo script to model repository conventions because it is the central source file in the project.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, tests that inspect function output, and any future PSScriptAnalyzer findings.

**Known dependencies:** Pure naming cleanup should not be interleaved with behavior changes unless a touched block is already being edited. Help updates depend on behavior decisions from higher-priority findings.

**Validation considerations:** Run PSScriptAnalyzer after behavior changes and keep style-only churn grouped with related edits rather than as a separate cleanup commit.

