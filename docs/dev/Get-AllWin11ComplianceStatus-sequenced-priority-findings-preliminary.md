<!-- markdownlint-disable MD013 -->

# Get-AllWin11ComplianceStatus Sequenced Priority Findings Preliminary

## Metadata

- **Status:** Draft
- **Owner:** Repository Maintainers
- **Last Updated:** 2026-06-25
- **Scope:** Provides a stand-alone sequenced implementation backlog for findings from `Get-AllWin11ComplianceStatus-improvement-opps.md` whose intrinsic priority is very high, high, or medium-high, including prerequisite ordering notes and copied supporting details.
- **Related:** [`Get-AllWin11ComplianceStatus-backlog-prioritization-rubric.md`](Get-AllWin11ComplianceStatus-backlog-prioritization-rubric.md), [`scripts/Get-AllWin11ComplianceStatus.ps1`](../../scripts/Get-AllWin11ComplianceStatus.ps1), [`tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`](../../tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1)

## Sequencing Method

This preliminary order keeps intrinsic priority first, then moves prerequisite work ahead of downstream findings when needed. Lower-priority findings that are not prerequisites are excluded from this file and preserved in `Get-AllWin11ComplianceStatus-lower-priority-improvement-backlog.md`.

No circular dependency was identified in this pass.

## 1. F013: Verify And Centralize Microsoft Graph Endpoint Contracts

**Priority:** Very high

**Rubric score:** 77.0/100. Criteria scores: C01=5, C02=2, C03=5, C04=4, C05=2, C06=4, C07=5, C08=3, C09=4, C10=5, C11=3, C12=5, C13=3, C14=5, C15=2.

**Sequence rationale:** This comes first because endpoint truth controls scope, schema, permissions, cloud support, retry behavior, and performance choices.

**Observed behavior:** Graph endpoint strings are hand-built inline in the script. The tests confirm that the script requests those strings, but they do not prove the strings are the correct Microsoft Graph contracts for live Intune data. Microsoft documentation clearly describes managed devices and compliance setting-state resources, while the setting-state path used by the script should be explicitly verified against current v1.0 endpoint documentation or SDK metadata before the script is treated as production-ready.

**Supporting evidence:** Microsoft documents `managedDevice`, `deviceCompliancePolicyState`, and `deviceCompliancePolicySettingState` resource shapes across Graph REST and Graph PowerShell documentation. The endpoint and permission mapping should be traceable to those primary sources rather than only to synthetic tests.

**Why this matters:** A synthetic test can lock in an incorrect URI just as easily as a correct one. A technical lead and cybersecurity stakeholder need confidence that the script reads the intended source of truth before using the CSV for compliance decisions.

**Affected surfaces:** Graph URI construction, permission documentation, tests, and any future research notes.

**Known dependencies:** This should happen before optimizing request count or adding more fields, because the correct endpoint family affects both schema and performance choices.

**Validation considerations:** Add unit tests for a centralized URI builder and, if maintainers want a live smoke test, make it opt-in and tenant-safe so normal CI still uses synthetic fixtures only.

### Implementation Option Analysis

**Options considered:**

- **F013-A: Keep inline endpoint strings and add source comments.** This preserves the current code shape and annotates each URI with a Microsoft Learn link, but it leaves endpoint construction scattered across the implementation.
- **F013-B: Add centralized v1.0 endpoint-builder helpers with unit tests.** This creates one small set of helper functions for managed-device, policy-state, and setting-state URIs, records the Microsoft source links in the research file, and tests the generated URIs with synthetic IDs and query parameters.
- **F013-C: Replace REST URI construction with generated Microsoft Graph PowerShell cmdlets.** This avoids hand-built URIs where cmdlets exist, but it may complicate fixture injection and may not cover every nested setting-state shape the script needs.
- **F013-D: Add an opt-in live endpoint smoke test.** This validates against a real tenant when explicitly requested, but it cannot run in normal CI and would require tenant permissions and data-safety controls.
- **F013-E: Move endpoint details into external JSON configuration.** This makes endpoints editable without code changes, but it creates a new contract surface and increases the chance of unsupported endpoint drift.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Endpoint traceability to official contracts | 30 | Highest score for an option that makes every endpoint easy to trace to Microsoft documentation or SDK metadata. |
| Synthetic testability without tenant access | 25 | Highest score for an option that improves confidence in normal CI without live Graph calls. |
| Future schema and cloud-environment support | 20 | Highest score for an option that makes later schema, projection, and national-cloud work easier. |
| Risk of introducing unsupported behavior | 15 | Highest score for an option that avoids inventing undocumented paths or mutable external endpoint definitions. |
| Implementation containment | 10 | Highest score for an option that can be reviewed without broad unrelated refactoring. |

| Option | Traceability (30) | Testability (25) | Future support (20) | Unsupported-behavior risk (15) | Containment (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F013-A | 18 | 5 | 4 | 9 | 10 | 46 |
| F013-B | 27 | 25 | 18 | 13 | 9 | 92 |
| F013-C | 22 | 12 | 12 | 11 | 5 | 62 |
| F013-D | 25 | 4 | 8 | 10 | 3 | 50 |
| F013-E | 10 | 15 | 12 | 4 | 6 | 47 |

**Selected option:** Implement **F013-B**. Add centralized URI-builder helpers for the Microsoft Graph v1.0 endpoints used by the report, keep next-link URLs opaque after Graph returns them, and add no-network Pester tests that prove each initial request URI is generated from the selected service root, API version, IDs, filter, and projection list. Do not add a live tenant smoke test in this work item.

## 2. F011: Remove Dot-Sourcing Side Effects From Script Scope

**Priority:** Medium-high

**Rubric score:** 56.4/100. Criteria scores: C01=1, C02=2, C03=1, C04=4, C05=4, C06=5, C07=4, C08=0, C09=5, C10=3, C11=5, C12=5, C13=3, C14=1, C15=3.

**Sequence rationale:** This is a prerequisite for safer test expansion because the current test import path can change caller behavior.

**Observed behavior:** Tests dot-source `scripts/Get-AllWin11ComplianceStatus.ps1` to access its functions. The file runs `Set-StrictMode -Version Latest` and assigns `$ErrorActionPreference = 'Stop'` at script scope. When dot-sourced, those changes occur in the caller's scope rather than being isolated inside the script's own invocation.

**Why this matters:** A junior maintainer or test author can dot-source the file and unknowingly change their session's error and strict-mode behavior. That can make unrelated commands fail differently after import, create confusing test interactions, and violate the repository PowerShell guidance for files that are intended to be dot-sourced. It also makes the script-library dual role in F008 riskier.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`, and any maintainer workflow that dot-sources the script for troubleshooting.

**Known dependencies:** This should be resolved before larger refactors or new tests rely on dot-sourcing behavior. A likely fix is moving strict mode into functions and avoiding caller-scope preference changes when dot-sourced.

**Validation considerations:** Tests can dot-source the file in a controlled scope and assert that caller-level `$ErrorActionPreference` and strict mode behavior are not changed.

### Implementation Option Analysis

**Options considered:**

- **F011-A: Leave script-scope state as-is and document it.** This avoids code churn, but it keeps caller-scope side effects.
- **F011-B: Move strict mode and stop-on-error behavior into functions and direct-invocation flow.** This keeps the single-file structure while preventing dot-source import from changing caller preferences.
- **F011-C: Split reusable functions into a separate module-like file and make the script a thin wrapper.** This is clean structurally, but it expands the change into the lower-priority F008 refactor.
- **F011-D: Keep script-scope state but change tests to dot-source in an isolated child process.** This protects tests but does not protect maintainers who dot-source manually.
- **F011-E: Remove strict mode entirely.** This avoids caller side effects but loses a useful runtime safety guard.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Caller-scope isolation | 35 | Highest score for fully preventing dot-source preference and strict-mode leaks. |
| Repository PowerShell-rule conformance | 25 | Highest score for aligning with the dot-sourced-file strict-mode rule. |
| Preservation of current test seam | 15 | Highest score for keeping tests able to dot-source functions without live Graph access. |
| Scope containment | 10 | Highest score for avoiding structural file splits unless required. |
| Future refactor compatibility | 15 | Highest score for a path that does not block later module extraction. |

| Option | Isolation (35) | Conformance (25) | Test seam (15) | Containment (10) | Refactor compatibility (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F011-A | 0 | 0 | 15 | 10 | 3 | 28 |
| F011-B | 35 | 25 | 15 | 9 | 13 | 97 |
| F011-C | 35 | 25 | 12 | 3 | 15 | 90 |
| F011-D | 8 | 0 | 10 | 7 | 4 | 29 |
| F011-E | 30 | 10 | 15 | 8 | 4 | 67 |

**Selected option:** Implement **F011-B**. Remove script-scope `Set-StrictMode -Version Latest` and script-scope `$ErrorActionPreference = 'Stop'`, place strict mode inside functions, and set local stop-on-error behavior only in the execution path that needs it. Add a Pester assertion that dot-sourcing the script does not change the caller's `$ErrorActionPreference`.

## 3. F010: Add Focused Pester Coverage Beyond The Single Happy Path

**Priority:** High

**Rubric score:** 76.0/100. Criteria scores: C01=4, C02=3, C03=4, C04=4, C05=3, C06=5, C07=4, C08=2, C09=5, C10=4, C11=5, C12=5, C13=3, C14=3, C15=2. The score crosses the very-high threshold, but the very-high gate is not met because none of C01, C02, C03, or C04 is scored 5.

**Sequence rationale:** Tests should expand before broad behavioral edits so later implementation steps have regression coverage.

**Observed behavior:** The retained PowerShell test covers paged managed devices, one device with one policy and one setting, one device with no policy state, CSV creation, and request count. It does not test missing device IDs, missing policy IDs, no devices, Graph errors, throttling, output path edge cases, dependency preflight, direct script invocation, Windows 11 filtering, or schema stability.

**Why this matters:** The script interacts with external data, produces a compliance artifact, and is likely to evolve. A Pester testing enthusiast would expect targeted tests around boundary behavior. A project manager benefits because regression tests reduce review cycle time and allow riskier fixes, such as retry or schema changes, to be made with confidence.

**Affected surfaces:** `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`, fixtures under `tests/PowerShell/Fixtures/`, and any future helper files.

**Known dependencies:** Test expansion should be sequenced before or alongside behavior changes that would otherwise be difficult to validate.

**Validation considerations:** New tests should preserve the existing no-network pattern by injecting Graph request behavior and using `$TestDrive` for file writes.

### Implementation Option Analysis

**Options considered:**

- **F010-A: Keep only the current integration-style happy-path test.** This avoids test churn but leaves high-priority behavior uncovered.
- **F010-B: Add focused synthetic tests for each selected high-priority behavior as it is implemented.** This grows coverage around boundaries without requiring live Graph or an exhaustive matrix.
- **F010-C: Build a large fixture matrix before any implementation work.** This maximizes up-front coverage but delays fixes and may encode behavior before decisions are final.
- **F010-D: Add live Graph integration tests gated by environment variables.** This can detect real endpoint drift but requires tenant data, permissions, and careful skip behavior.
- **F010-E: Replace Pester with snapshot CSV tests only.** This validates final artifacts but loses function-level diagnostics for edge cases.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Coverage of high-risk behavior | 30 | Highest score for tests covering scope, schema, path safety, failure, and no-data behavior. |
| No-network determinism | 25 | Highest score for tests that run reliably in local and CI environments without tenant access. |
| Diagnostic precision | 20 | Highest score for tests that identify which function or contract failed. |
| Maintenance cost | 15 | Highest score for tests that avoid brittle over-fixturing. |
| Implementation cadence support | 10 | Highest score for tests that can be added alongside each fix without blocking all progress. |

| Option | Risk coverage (30) | Determinism (25) | Diagnostics (20) | Maintenance (15) | Cadence (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F010-A | 5 | 25 | 8 | 15 | 4 | 57 |
| F010-B | 26 | 25 | 18 | 13 | 10 | 92 |
| F010-C | 30 | 25 | 16 | 6 | 2 | 79 |
| F010-D | 20 | 4 | 10 | 3 | 3 | 40 |
| F010-E | 14 | 24 | 8 | 10 | 6 | 62 |

**Selected option:** Implement **F010-B**. Add focused Pester tests with synthetic Graph responses and `$TestDrive` file paths as each selected implementation change is made. Keep live Graph tests out of the default suite.

## 4. F027: Add Direct Script Invocation Tests

**Priority:** Medium-high

**Rubric score:** 51.6/100. Criteria scores: C01=2, C02=0, C03=2, C04=3, C05=4, C06=5, C07=3, C08=0, C09=4, C10=3, C11=5, C12=3, C13=4, C14=2, C15=3.

**Sequence rationale:** This extends F010 to the user-facing path before CLI behavior, naming, and parameter contracts are changed.

**Observed behavior:** Existing tests dot-source the script and call `Export-WindowsComplianceStatusReport` directly. They do not execute the file as a script, so they do not verify the `$MyInvocation.InvocationName -ne '.'` entry-point behavior, missing `-ExportPath` error, or direct CLI parameter contract.

**Why this matters:** Most users will run the file as a script, not dot-source it. A user-experience reviewer needs direct invocation to be tested because that path controls error messages and examples. A project manager wants the README command to be backed by a test.

**Affected surfaces:** `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`, script parameter binding, and README usage examples.

**Known dependencies:** This should be handled after or alongside F011 so the script's import and execution paths are deliberately separated.

**Validation considerations:** Pester can invoke the script in a child PowerShell process or through `& $scriptPath` with injected-safe switches and fixture-backed request injection if the design exposes a test seam.

### Implementation Option Analysis

**Options considered:**

- **F027-A: Do not test direct script invocation.** This keeps tests simple but leaves the README usage path unverified.
- **F027-B: Test direct invocation only for parameter validation and no-operation paths.** This validates the CLI entry point without adding a scriptblock injection parameter to the executable script.
- **F027-C: Add a public `-GraphRequest` script parameter so direct invocation can run full fixture-backed exports.** This gives high coverage but exposes arbitrary scriptblock execution as a public entry-point feature.
- **F027-D: Run direct invocation in a child process after installing or mocking Graph commands globally.** This approximates user execution but is heavier and less portable.
- **F027-E: Split the script into a wrapper and module so direct invocation tests can mock the module boundary.** This is structurally clean but pulls in the lower-priority F008 refactor.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| User-facing entry-point coverage | 30 | Highest score for directly exercising the path users run from README examples. |
| Avoidance of unsafe public test seams | 25 | Highest score for avoiding public parameters that execute caller-provided code. |
| Portability across CI platforms | 20 | Highest score for tests that run on Windows, Linux, and macOS without tenant dependencies. |
| Failure-message confidence | 15 | Highest score for asserting parameter and preflight errors users actually see. |
| Refactor independence | 10 | Highest score for not requiring file layout changes. |

| Option | Entry coverage (30) | Safe seams (25) | Portability (20) | Failure confidence (15) | Independence (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F027-A | 0 | 25 | 20 | 0 | 10 | 55 |
| F027-B | 20 | 25 | 20 | 14 | 10 | 89 |
| F027-C | 28 | 3 | 18 | 12 | 8 | 69 |
| F027-D | 24 | 18 | 8 | 12 | 6 | 68 |
| F027-E | 30 | 25 | 18 | 13 | 2 | 88 |

**Selected option:** Implement **F027-B**. Add direct invocation tests for CLI parameter validation and safe no-operation behavior, such as missing export path and future `-WhatIf` behavior, while keeping full Graph fixture coverage at the function level. Do not add a public scriptblock execution parameter to the script entry point.

## 5. F001: Narrow Device Query To Windows 11 Devices

**Priority:** Very high

**Rubric score:** 79.0/100. Criteria scores: C01=5, C02=3, C03=5, C04=3, C05=4, C06=4, C07=3, C08=3, C09=3, C10=4, C11=5, C12=5, C13=4, C14=5, C15=3.

**Sequence rationale:** This is the highest-scoring report-correctness issue and should follow endpoint verification so the final scope decision uses the right source data.

**Observed behavior:** The script name and README describe a Windows 11 compliance export, but the Graph query filters only `operatingSystem eq 'Windows'`. That includes Windows devices broadly, not specifically Windows 11 devices. The exported rows also do not include OS version or build fields that would let a report consumer distinguish Windows 10, Windows 11, and other Windows-family records after export.

**Supporting evidence:** Microsoft documents `operatingSystem` as a broad string such as Windows or iOS, and separately documents `osVersion` on the [`managedDevice` resource](https://learn.microsoft.com/graph/api/resources/intune-devices-manageddevice?view=graph-rest-1.0#properties).

**Why this matters:** A business stakeholder, cybersecurity leader, or compliance officer could use the CSV as if it represented Windows 11 compliance while it actually includes all Intune-managed Windows devices returned by the endpoint. That can distort compliance rates, remediation planning, executive reporting, and audit evidence. A technical maintainer also cannot validate the "Win11" claim from the output because the discriminating OS version/build evidence is omitted.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, `README.md`, tests under `tests/PowerShell/`, and any downstream issue or report generated from the CSV.

**Known dependencies:** Research is needed against Microsoft Graph managed device properties to determine the safest way to identify Windows 11 in Intune data. Candidate approaches include querying a version/build property, exporting version/build data without filtering to Windows 11, renaming the script and documentation to "Windows compliance" instead of "Windows 11 compliance", or offering an explicit parameter that controls Windows-family versus Windows 11-only scope.

**Validation considerations:** Synthetic fixtures should include at least one Windows 10-like device and one Windows 11-like device so tests prove the final behavior matches the chosen scope.

### Implementation Option Analysis

**Options considered:**

- **F001-A: Rename and re-document the script as an all-Windows compliance export.** This makes the current filter truthful but abandons the Windows 11-specific user intent.
- **F001-B: Keep the broad Graph filter and locally classify Windows 11 using `osVersion` build number.** This uses documented managed-device data and avoids relying on unsupported Graph filtering for parsed version components.
- **F001-C: Add `-IncludeAllWindows` so Windows 11 remains the default while broader Windows reporting is explicit.** This combines F001-B with an escape hatch for users who want the old broad scope.
- **F001-D: Attempt a Graph-side `osVersion` filter for Windows 11 build families.** This may reduce local filtering work, but support for version comparison semantics on this property is not established by the current research.
- **F001-E: Export `osVersion` only and leave filtering to report consumers.** This improves auditability but keeps the script name and default report scope misleading.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Truthfulness of Windows 11 report scope | 35 | Highest score for ensuring default exported rows are Windows 11 devices. |
| Reliance on documented properties | 25 | Highest score for using Microsoft-documented fields without unsupported query semantics. |
| Backward usability for broader Windows reporting | 15 | Highest score for preserving a deliberate path to the current broad report. |
| Auditability of classification | 15 | Highest score for exporting the evidence used to classify devices. |
| Testability with synthetic fixtures | 10 | Highest score for behavior that can be proven without tenant data. |

| Option | Scope truth (35) | Documented properties (25) | Broad-report usability (15) | Auditability (15) | Testability (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F001-A | 22 | 25 | 15 | 8 | 8 | 78 |
| F001-B | 32 | 24 | 4 | 15 | 10 | 85 |
| F001-C | 35 | 24 | 15 | 15 | 10 | 99 |
| F001-D | 30 | 8 | 10 | 12 | 7 | 67 |
| F001-E | 8 | 25 | 15 | 15 | 9 | 72 |

**Selected option:** Implement **F001-C**. Keep the default report scoped to Windows 11 by requesting and exporting `osVersion`, locally treating Windows devices with build number 22000 or higher as Windows 11, and add an explicit `-IncludeAllWindows` switch for users who intentionally want the broader Windows-family export.

## 6. F023: Reconcile Script Name, Verb, And Export Behavior

**Priority:** Medium-high

**Rubric score:** 59.4/100. Criteria scores: C01=4, C02=1, C03=3, C04=2, C05=5, C06=2, C07=3, C08=1, C09=3, C10=4, C11=5, C12=4, C13=5, C14=4, C15=2.

**Sequence rationale:** Naming should be resolved immediately after the Windows 11 scope decision so the script name, function name, and README do not encode conflicting promises.

**Observed behavior:** The file is named `Get-AllWin11ComplianceStatus.ps1`, the main function is named `Export-WindowsComplianceStatusReport`, and the script's primary effect is writing a CSV. "Win11" is abbreviated in the file name, "Windows" is used in the function name, and "Get" in the file name implies pipeline output more than file export.

**Why this matters:** A user-experience expert sees a discoverability gap: users cannot infer whether the script gets data, exports a file, targets all Windows devices, or targets Windows 11 only. A documentation lead will have to explain naming drift repeatedly. A technical maintainer may prefer a name that matches the final scope decision from F001.

**Affected surfaces:** Script file name, README links, tests, future GitHub issue titles, and possibly direct command examples.

**Known dependencies:** This should follow the scope decision in F001. If the script remains Windows-only rather than Windows 11-only, renaming becomes more important.

**Validation considerations:** Tests and README examples need to be updated together with any rename so direct invocation paths remain correct.

### Implementation Option Analysis

**Options considered:**

- **F023-A: Rename the script file to `Export-Windows11ComplianceStatusReport.ps1`.** This aligns verb and behavior but breaks the user-provided path and increases migration churn.
- **F023-B: Keep the script file path and introduce `Export-Windows11ComplianceStatusReport` as the primary function with a compatibility wrapper.** This aligns the public function with behavior while preserving the existing script location.
- **F023-C: Rename only the README and help text while keeping function names unchanged.** This reduces churn but leaves code-level naming drift.
- **F023-D: Convert the script into a pure `Get-*` command that streams objects and leaves CSV export to callers.** This aligns the file verb but changes the primary user workflow.
- **F023-E: Add a new wrapper script with the better name and keep the old script as a delegating compatibility shim.** This is user-friendly but creates two script entry points to maintain.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Naming truthfulness | 30 | Highest score for names that clearly communicate Windows 11 scope and CSV export behavior. |
| Compatibility with current user path | 25 | Highest score for not breaking the script path named in the task and README. |
| Documentation/code alignment | 20 | Highest score for matching README, help, tests, and function names. |
| Maintenance simplicity | 15 | Highest score for avoiding duplicate entry points or confusing wrappers. |
| Future rename optionality | 10 | Highest score for leaving a clear path to a later file rename if desired. |

| Option | Truthfulness (30) | Compatibility (25) | Alignment (20) | Simplicity (15) | Future optionality (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F023-A | 30 | 2 | 18 | 12 | 8 | 70 |
| F023-B | 26 | 25 | 18 | 13 | 9 | 91 |
| F023-C | 10 | 25 | 7 | 14 | 3 | 59 |
| F023-D | 18 | 8 | 15 | 8 | 6 | 55 |
| F023-E | 28 | 20 | 18 | 7 | 10 | 83 |

**Selected option:** Implement **F023-B**. Keep `scripts/Get-AllWin11ComplianceStatus.ps1` as the script path for this iteration, add `Export-Windows11ComplianceStatusReport` as the primary implementation function, and keep `Export-WindowsComplianceStatusReport` as a compatibility wrapper that calls the new function. Update tests, README, and help to use the Windows 11 function name.

## 7. F005: Expand The Report Schema For Operational Use

**Priority:** High

**Rubric score:** 75.2/100. Criteria scores: C01=4, C02=3, C03=5, C04=3, C05=4, C06=4, C07=4, C08=2, C09=3, C10=5, C11=4, C12=5, C13=4, C14=5, C15=2.

**Sequence rationale:** Schema decisions are prerequisites for no-data handling, projections, privacy controls, deterministic sorting, enum handling, and streaming output.

**Observed behavior:** The current CSV includes device name, user principal name, operating system, device compliance state, management agent, last sync time, policy name/state, setting name/state, and setting error code. It omits commonly useful triage and audit fields such as managed device ID, Azure AD device ID, OS version/build, ownership, enrollment type, model/manufacturer, policy ID, setting ID, and a stable row source URI or retrieval timestamp.

**Why this matters:** A cybersecurity technical expert needs stable identifiers to reconcile rows with Intune, Entra ID, and incident or remediation systems. A cybersecurity officer or business stakeholder needs enough context to group remediation by device population, ownership, and recency. A junior team member needs IDs in the export so they can investigate a row without guessing which duplicate display name is involved.

**Affected surfaces:** CSV schema, script row shaping, tests, README example expectations, and downstream GitHub issues.

**Known dependencies:** Graph property research is needed to avoid inventing unsupported fields. Privacy and data-minimization trade-offs should be explicitly scored because adding identifiers and user fields increases sensitivity of exported CSV files.

**Validation considerations:** Fixtures should include the selected fields and tests should assert property names using order-insensitive checks unless column ordering is intentionally part of the CSV contract.

### Implementation Option Analysis

**Options considered:**

- **F005-A: Add only `OsVersion` to support Windows 11 filtering.** This fixes the immediate scope evidence gap but does not help triage or audit duplicate display names.
- **F005-B: Add an operational schema with stable IDs, OS evidence, device metadata, policy IDs, setting IDs, current value, error description, and retrieval timestamp.** This gives report consumers enough context to investigate rows while staying within one CSV.
- **F005-C: Add every available managed-device and setting-state property.** This maximizes data availability but creates a sensitive, wide, and unstable export.
- **F005-D: Split into multiple normalized CSV files for devices, policies, and settings.** This is analytically cleaner but is too much structure for the current demo script.
- **F005-E: Keep the current schema and document its limitations.** This avoids churn but leaves operational users without stable identifiers.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Investigation usefulness | 30 | Highest score for fields that let a user find the exact device, policy, and setting. |
| Data minimization balance | 20 | Highest score for adding needed fields without dumping all tenant data. |
| Schema stability | 20 | Highest score for fields likely to stay stable and testable. |
| CSV usability | 15 | Highest score for a single artifact that remains understandable in spreadsheet tools. |
| Support for downstream findings | 15 | Highest score for enabling filtering, no-data headers, projections, sorting, and enum decisions. |

| Option | Investigation (30) | Minimization (20) | Stability (20) | CSV usability (15) | Downstream support (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F005-A | 10 | 20 | 18 | 15 | 8 | 71 |
| F005-B | 28 | 16 | 18 | 14 | 15 | 91 |
| F005-C | 30 | 3 | 8 | 5 | 11 | 57 |
| F005-D | 28 | 15 | 16 | 5 | 12 | 76 |
| F005-E | 5 | 18 | 15 | 15 | 2 | 55 |

**Selected option:** Implement **F005-B**. Expand the single CSV schema to include stable identifiers and evidence fields needed for investigation: device ID, Azure AD device ID, device name, UPN according to the selected privacy mode, operating system, OS version, Windows 11 classification, compliance states, management agent, ownership/manufacturer/model where available, last sync time, policy ID/name/state, setting ID/name/state, current value, error code, error description, and report retrieval timestamp.

## 8. F004: Introduce An Explicit No-Data Contract

**Priority:** High

**Rubric score:** 68.6/100. Criteria scores: C01=4, C02=1, C03=5, C04=4, C05=4, C06=4, C07=3, C08=1, C09=3, C10=4, C11=5, C12=4, C13=4, C14=4, C15=3.

**Sequence rationale:** A no-data contract depends on the chosen report schema because a header-only CSV needs a stable column list.

**Observed behavior:** If the Graph query returns no devices, `$rows` is an empty array and the pipeline to `Export-Csv` creates an empty file with no headers in local PowerShell behavior. The script does not define whether a no-device result should create a CSV with headers, create an empty file, skip file creation, warn the user, or return a structured status.

**Supporting evidence:** Microsoft documents that `Export-Csv` uses submitted object properties to generate the first header row; if no object is submitted, there is no object from which to derive headers. See [`Export-Csv`](https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/export-csv?view=powershell-7.6).

**Why this matters:** A compliance report with no rows can mean "everything failed to query", "there are no matching devices", or "the filter was too narrow". A business stakeholder needs the artifact to be interpretable, and a testing enthusiast needs a clear contract to assert. A documentation lead also needs the README to tell users what to expect when no devices match.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, README usage guidance, and Pester tests.

**Known dependencies:** This can be resolved after the report schema is made explicit, because an empty CSV with headers requires a known column list.

**Validation considerations:** Tests should include a no-device fixture and assert the exact file contents, returned object count, and any warning or status behavior.

### Implementation Option Analysis

**Options considered:**

- **F004-A: Preserve the current empty file behavior.** This avoids code changes but leaves the artifact ambiguous and headerless.
- **F004-B: Write a header-only CSV when no rows match and emit a warning.** This creates a machine-readable artifact and tells the user the export completed with no matching devices.
- **F004-C: Skip file creation when no rows match.** This avoids empty artifacts but makes automation handle missing files.
- **F004-D: Throw an error when no rows match.** This makes the condition visible but treats a valid empty result as a failure.
- **F004-E: Write a separate JSON summary sidecar for no-data runs.** This is explicit but adds a second artifact and scope.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Artifact interpretability | 35 | Highest score for output that clearly communicates an empty-but-successful result. |
| Automation friendliness | 25 | Highest score for predictable file existence and stable headers. |
| User visibility | 15 | Highest score for a visible warning or summary without treating success as failure. |
| Schema consistency | 15 | Highest score for matching non-empty report columns. |
| Implementation focus | 10 | Highest score for avoiding extra artifact formats. |

| Option | Interpretability (35) | Automation (25) | Visibility (15) | Schema (15) | Focus (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F004-A | 0 | 8 | 0 | 0 | 10 | 18 |
| F004-B | 35 | 25 | 14 | 15 | 9 | 98 |
| F004-C | 10 | 5 | 12 | 0 | 9 | 36 |
| F004-D | 14 | 10 | 15 | 0 | 8 | 47 |
| F004-E | 28 | 16 | 12 | 10 | 3 | 69 |

**Selected option:** Implement **F004-B**. When no rows match, write a CSV containing the full selected header row and no data rows, emit a warning that no matching devices were exported, and return an empty row array from the function.

## 9. F012: Use Explicit Graph Projections For Required Properties

**Priority:** Medium-high

**Rubric score:** 60.6/100. Criteria scores: C01=3, C02=1, C03=4, C04=3, C05=2, C06=3, C07=4, C08=4, C09=3, C10=3, C11=5, C12=4, C13=2, C14=2, C15=3.

**Sequence rationale:** Projections should follow endpoint and schema decisions so every exported field is intentionally requested.

**Observed behavior:** The managed-device request uses a filter but no explicit `$select`. The policy-state and setting-state requests also rely on default response shapes. The script then reads a fixed set of properties from those responses.

**Supporting evidence:** Microsoft Graph query-parameter guidance describes `$select` as the way to return a chosen set of properties and recommends limiting returned properties for potentially large result sets. See [Microsoft Graph query parameters](https://learn.microsoft.com/graph/query-parameters) and [Microsoft Graph PowerShell query parameters](https://learn.microsoft.com/powershell/microsoftgraph/use-query-parameters?view=graph-powershell-1.0#property-parameter).

**Why this matters:** A technical expert wants the request contract to match the output contract. A performance reviewer wants smaller payloads. A maintainer wants tests to prove that every exported column is intentionally requested rather than accidentally present in a default Graph response.

**Affected surfaces:** Graph URI construction, report schema, tests, and README documentation for the exported fields.

**Known dependencies:** The selected output schema in F005 should be decided before adding `$select`, otherwise the request projection may need repeated churn.

**Validation considerations:** Tests should assert the exact generated managed-device URI and the selected property list once the schema is finalized.

### Implementation Option Analysis

**Options considered:**

- **F012-A: Continue relying on default Graph response properties.** This avoids query construction changes but leaves the schema implicit.
- **F012-B: Add `$select` only to the managed-device collection request.** This handles the largest payload and most schema fields, but policy and setting fields remain implicit.
- **F012-C: Add projection lists to every initial endpoint where Microsoft Graph supports them.** This makes the request contract mirror the CSV schema.
- **F012-D: Use Graph PowerShell cmdlet `-Property` parameters instead of REST `$select`.** This is idiomatic for generated cmdlets but does not fit the current raw REST request seam.
- **F012-E: Request all fields but add runtime validation that required fields are present.** This improves failure clarity but does not reduce payload or clarify requested schema.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Request/schema alignment | 35 | Highest score for ensuring every exported field is intentionally requested. |
| Payload efficiency | 20 | Highest score for reducing unnecessary Graph response data. |
| Compatibility with injected REST seam | 15 | Highest score for preserving current no-network tests. |
| Endpoint support caution | 15 | Highest score for applying projections only where support is documented or verified. |
| Test clarity | 15 | Highest score for deterministic URI assertions. |

| Option | Alignment (35) | Efficiency (20) | REST seam (15) | Support caution (15) | Test clarity (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F012-A | 4 | 0 | 15 | 10 | 4 | 33 |
| F012-B | 20 | 14 | 15 | 12 | 10 | 71 |
| F012-C | 32 | 20 | 15 | 12 | 14 | 93 |
| F012-D | 25 | 18 | 5 | 12 | 8 | 68 |
| F012-E | 16 | 0 | 15 | 15 | 8 | 54 |

**Selected option:** Implement **F012-C**. Define projection lists alongside the endpoint builders and add `$select` to initial collection requests where the endpoint supports query parameters. Preserve `@odata.nextLink` as returned by Graph rather than rebuilding projection parameters for subsequent pages.

## 10. F020: Make Graph Response Property Reading More Shape-Tolerant

**Priority:** Medium-high

**Rubric score:** 57.8/100. Criteria scores: C01=3, C02=1, C03=4, C04=3, C05=2, C06=4, C07=4, C08=1, C09=3, C10=3, C11=4, C12=4, C13=2, C14=2, C15=3.

**Sequence rationale:** The response accessor is a small but important foundation before richer request wrappers, synthetic failures, and endpoint tests rely on multiple response shapes.

**Observed behavior:** `Get-GraphPropertyValue` reads `$InputObject.PSObject.Properties[$Name]`. That works for `PSCustomObject` fixtures, but it does not explicitly handle dictionaries, case variants, or Graph SDK output types beyond ordinary object properties. `Invoke-MgGraphRequest` documents `System.Object` output rather than a narrow type.

**Supporting evidence:** Microsoft documents `Invoke-MgGraphRequest` output as `System.Object`, which leaves room for callers and tests to provide different object shapes. See [`Invoke-MgGraphRequest`](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/invoke-mggraphrequest?view=graph-powershell-1.0).

**Why this matters:** A test author or future wrapper could inject hashtables and get unexpected nulls even when keys exist. A technical maintainer should either intentionally support only `PSCustomObject` responses or make the helper robust across common PowerShell data shapes.

**Affected surfaces:** `Get-GraphPropertyValue`, all Graph collection parsing, tests, and injected request extension points.

**Known dependencies:** This can be implemented independently but should be tested before broader retry or endpoint work relies on richer injected response objects.

**Validation considerations:** Tests should cover `PSCustomObject`, ordered dictionaries, hashtables, missing keys, null input, and the literal `@odata.nextLink` property name.

### Implementation Option Analysis

**Options considered:**

- **F020-A: Keep `PSObject.Properties` only.** This preserves current behavior but makes the injected request seam less flexible.
- **F020-B: Add exact-key `IDictionary` support before falling back to object properties.** This supports hashtable fixtures and Graph wrapper outputs without changing object behavior.
- **F020-C: Add exact and case-insensitive dictionary/property lookup.** This is more forgiving but may hide casing mistakes for Graph property names.
- **F020-D: Convert every response through `ConvertTo-Json` and `ConvertFrom-Json`.** This normalizes shape but is inefficient and can alter types.
- **F020-E: Require injected test responses to be `PSCustomObject` and document that contract.** This is explicit but needlessly restrictive.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Supported response-shape breadth | 30 | Highest score for covering common object and dictionary shapes. |
| Preservation of Graph property exactness | 20 | Highest score for not masking important property-name mistakes. |
| Performance and type preservation | 20 | Highest score for avoiding serialization or unnecessary copies. |
| Test-seam ergonomics | 20 | Highest score for making synthetic responses easy to author. |
| Behavioral predictability | 10 | Highest score for clear lookup order and null behavior. |

| Option | Shape breadth (30) | Exactness (20) | Performance (20) | Test ergonomics (20) | Predictability (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F020-A | 10 | 20 | 20 | 8 | 8 | 66 |
| F020-B | 24 | 20 | 20 | 18 | 9 | 91 |
| F020-C | 28 | 10 | 19 | 20 | 7 | 84 |
| F020-D | 25 | 12 | 4 | 14 | 5 | 60 |
| F020-E | 5 | 20 | 20 | 4 | 10 | 59 |

**Selected option:** Implement **F020-B**. Update `Get-GraphPropertyValue` to read exact keys from `System.Collections.IDictionary` responses before using `PSObject.Properties`, preserve null-on-missing behavior, and add tests for `PSCustomObject`, hashtable, ordered dictionary, null, and `@odata.nextLink`.

## 11. F002: Add Microsoft Graph Dependency And Authentication Preflight

**Priority:** High

**Rubric score:** 70.4/100. Criteria scores: C01=2, C02=4, C03=2, C04=5, C05=5, C06=4, C07=4, C08=1, C09=4, C10=4, C11=4, C12=4, C13=5, C14=3, C15=3.

**Sequence rationale:** Preflight checks should exist before expanding authentication modes, cloud support, and retry behavior.

**Observed behavior:** The script directly calls `Connect-MgGraph` and `Invoke-MgGraphRequest` when live Graph access is used. If the Microsoft Graph PowerShell SDK is missing, too old, or unavailable in the current session, the user receives a generic command-not-found or runtime failure. The script also does not expose a clear failure message for authentication or permission problems.

**Why this matters:** From a user-experience and junior-maintainer perspective, the first failure mode is difficult to act on. From a project-manager perspective, unclear setup failures increase support time. From a cybersecurity perspective, users under pressure may over-consent permissions or run ad hoc commands to "make it work" when the script does not clearly state the required module and scopes at runtime.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, README usage guidance, and Pester tests for missing dependency behavior.

**Known dependencies:** The chosen fix should preserve test injection through `-GraphRequest` and `-SkipGraphConnect` while adding live-run checks that do not require network access during unit tests.

**Validation considerations:** Tests should prove that missing Graph commands produce a deterministic, actionable error before the script attempts Graph requests.

### Implementation Option Analysis

**Options considered:**

- **F002-A: Add `#Requires -Modules Microsoft.Graph.Authentication`.** This blocks unsupported live runs early, but it also blocks dot-sourced tests on systems without the module.
- **F002-B: Add live-run preflight that checks required Graph commands only when Graph connection/request commands are needed.** This keeps tests module-independent and gives actionable errors for real users.
- **F002-C: Rely on PowerShell command-not-found errors and improve README guidance only.** This is easy but keeps poor first-run diagnostics.
- **F002-D: Automatically install Microsoft Graph modules when missing.** This may help users, but it performs network/package operations and can create supply-chain and consent surprises.
- **F002-E: Import Microsoft Graph modules unconditionally at script load.** This clarifies dependency but still breaks test import when the module is missing.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Actionable user failure | 30 | Highest score for clear instructions before live Graph work begins. |
| Preservation of offline tests | 25 | Highest score for keeping synthetic tests free of Graph module installation. |
| Security and supply-chain restraint | 20 | Highest score for avoiding automatic installs or secret-handling changes. |
| Alignment with runtime support boundary | 15 | Highest score for coordinating with PowerShell version and module contract. |
| Implementation simplicity | 10 | Highest score for a small, testable helper. |

| Option | User failure (30) | Offline tests (25) | Security restraint (20) | Support boundary (15) | Simplicity (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F002-A | 24 | 2 | 19 | 15 | 8 | 68 |
| F002-B | 30 | 25 | 20 | 14 | 9 | 98 |
| F002-C | 5 | 25 | 18 | 8 | 10 | 66 |
| F002-D | 20 | 10 | 3 | 8 | 2 | 43 |
| F002-E | 18 | 4 | 18 | 12 | 7 | 59 |

**Selected option:** Implement **F002-B**. Add a preflight helper that checks for `Connect-MgGraph` and `Invoke-MgGraphRequest` only when the script is going to connect to or call live Graph. The error should name the missing command, identify the Microsoft Graph PowerShell SDK prerequisite, and avoid auto-installing anything.

## 12. F022: State A PowerShell Version And Module Contract

**Priority:** High

**Rubric score:** 63.2/100. Criteria scores: C01=1, C02=2, C03=2, C04=4, C05=5, C06=4, C07=3, C08=1, C09=4, C10=4, C11=5, C12=4, C13=5, C14=2, C15=3.

**Sequence rationale:** Runtime and module boundaries should be defined with dependency preflight so unsupported hosts fail clearly.

**Observed behavior:** The README recommends PowerShell 7.4 or later, but the script itself has no `#requires` line and does not check the running PowerShell version. It also uses modern PowerShell patterns and Microsoft Graph commands without declaring whether Windows PowerShell 5.1 is supported.

**Why this matters:** A junior user may run the script in Windows PowerShell because it is still common on Windows endpoints. Without a clear runtime contract, failures can look like script bugs rather than an unsupported host. A project manager also needs the support boundary to be explicit before asking others to adopt the script.

**Affected surfaces:** Script header, README prerequisites, CI matrix, tests, and any module preflight.

**Known dependencies:** This should be coordinated with F002 so module and runtime checks produce one clear preflight result.

**Validation considerations:** Tests can isolate version-check logic into a helper and assert behavior with synthetic version values rather than requiring multiple PowerShell hosts locally.

### Implementation Option Analysis

**Options considered:**

- **F022-A: Add `#Requires -Version 7.4` and keep module checks in custom preflight.** This enforces the README's version boundary while preserving module-independent tests.
- **F022-B: Add custom runtime version checks instead of `#Requires`.** This allows friendlier errors but permits more script parsing before failure.
- **F022-C: Support Windows PowerShell 5.1 and PowerShell 7.4+.** This broadens reach but increases compatibility burden and conflicts with the README recommendation.
- **F022-D: Document PowerShell 7.4 only in README and do not enforce it.** This is low churn but lets users hit confusing runtime differences.
- **F022-E: Add `#Requires -Version 7.4` and `#Requires -Modules`.** This is strict but harms tests and offline analysis when Graph modules are absent.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Support-boundary clarity | 30 | Highest score for making unsupported hosts fail before confusing behavior occurs. |
| Test and analysis ergonomics | 20 | Highest score for not requiring live Graph modules for non-live work. |
| Alignment with README and CI | 20 | Highest score for matching documented and exercised PowerShell versions. |
| Compatibility maintenance burden | 15 | Highest score for avoiding unsupported multi-edition promises. |
| Error actionability | 15 | Highest score for users understanding what to install or change. |

| Option | Boundary clarity (30) | Ergonomics (20) | README/CI alignment (20) | Maintenance burden (15) | Actionability (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F022-A | 30 | 18 | 20 | 15 | 13 | 96 |
| F022-B | 22 | 20 | 17 | 12 | 15 | 86 |
| F022-C | 10 | 12 | 6 | 2 | 8 | 38 |
| F022-D | 5 | 20 | 8 | 12 | 4 | 49 |
| F022-E | 30 | 4 | 20 | 15 | 10 | 79 |

**Selected option:** Implement **F022-A**. Add `#Requires -Version 7.4` to enforce the documented PowerShell support boundary, keep Graph module checks in live-run preflight, and update help/README language so the version and module expectations match.

## 13. F019: Add Flexible Authentication Parameters Without Storing Secrets

**Priority:** Medium-high

**Rubric score:** 60.6/100. Criteria scores: C01=2, C02=4, C03=2, C04=4, C05=4, C06=3, C07=3, C08=1, C09=3, C10=4, C11=4, C12=3, C13=4, C14=3, C15=2.

**Sequence rationale:** Expanded authentication should come after preflight boundaries and before environment-specific Graph connection behavior.

**Observed behavior:** The live-run path uses only interactive delegated `Connect-MgGraph -Scopes ...`. There is no parameter for `TenantId`, device-code authentication, context scope, cloud environment, or pre-authenticated app-only workflows. The only authentication-related switch is `-SkipGraphConnect`.

**Supporting evidence:** `Connect-MgGraph` supports delegated, app-only, managed identity, environment-variable, tenant, environment, and context-scope parameter sets. See [`Connect-MgGraph`](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/connect-mggraph?view=graph-powershell-1.0).

**Why this matters:** A user in a browserless session may need device-code authentication. A tenant administrator may need to pin a tenant. An automation owner may want app-only authentication through preconfigured context rather than interactive consent. A cybersecurity reviewer needs any expanded authentication support to avoid secrets in code, command examples, or repository files.

**Affected surfaces:** Script parameters, README prerequisites, help text, and tests for connection invocation.

**Known dependencies:** This finding should be coordinated with environment support from F014 and dependency preflight from F002.

**Validation considerations:** Tests should mock or inject the connect operation so authentication parameter routing is validated without real sign-in or secrets.

### Implementation Option Analysis

**Options considered:**

- **F019-A: Keep only interactive delegated authentication.** This is simple but excludes common automation and browserless scenarios.
- **F019-B: Add safe delegated parameters: `TenantId`, `UseDeviceCode`, `ContextScope`, and Graph environment.** This expands usability without handling secrets in the script.
- **F019-C: Add app-only client secret and certificate parameters.** This supports automation but risks secret-handling complexity and command-example leakage.
- **F019-D: Require callers to pre-authenticate and always use `-SkipGraphConnect`.** This avoids auth code but makes first-run experience poor.
- **F019-E: Accept a raw access token parameter.** This is flexible but increases secret exposure risk in command history and logs.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Authentication scenario coverage | 30 | Highest score for covering common safe live-run scenarios. |
| Secret-exposure avoidance | 25 | Highest score for not accepting or logging bearer tokens, client secrets, or credential objects. |
| User setup clarity | 20 | Highest score for mapping parameters to Microsoft Graph PowerShell behavior. |
| Testability of connection routing | 15 | Highest score for allowing connection arguments to be asserted without sign-in. |
| Scope containment | 10 | Highest score for avoiding a full authentication framework. |

| Option | Scenario coverage (30) | Secret avoidance (25) | Setup clarity (20) | Testability (15) | Containment (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F019-A | 8 | 25 | 10 | 12 | 10 | 65 |
| F019-B | 24 | 25 | 18 | 14 | 9 | 90 |
| F019-C | 30 | 8 | 12 | 10 | 3 | 63 |
| F019-D | 12 | 25 | 7 | 10 | 8 | 62 |
| F019-E | 22 | 2 | 6 | 8 | 4 | 42 |

**Selected option:** Implement **F019-B**. Add safe delegated authentication parameters for tenant selection, device-code authentication, context scope, and environment routing. Keep `-SkipGraphConnect` for pre-authenticated or test sessions. Do not add raw token, client secret, or certificate parameters in this work item.

## 14. F014: Support Microsoft Graph Cloud And Environment Selection

**Priority:** High

**Rubric score:** 63.2/100. Criteria scores: C01=1, C02=3, C03=3, C04=4, C05=4, C06=3, C07=4, C08=3, C09=4, C10=5, C11=4, C12=3, C13=3, C14=3, C15=2.

**Sequence rationale:** Environment support depends on centralized endpoint construction and authentication parameter routing.

**Observed behavior:** The script hardcodes `https://graph.microsoft.com/v1.0` into every request URI. It does not expose a Graph environment, base URI, or API-version parameter. It also does not connect to a named Microsoft Graph PowerShell environment.

**Supporting evidence:** Microsoft Graph endpoint docs list national cloud availability for Intune APIs, and `Connect-MgGraph` supports an `-Environment` parameter. See [`Connect-MgGraph`](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/connect-mggraph?view=graph-powershell-1.0).

**Why this matters:** Organizations in US Government, DoD, China-operated, or other non-global cloud environments cannot use a global-only URI safely. A cybersecurity officer or public-sector stakeholder may need the report but be unable to run it against the correct endpoint without editing source code.

**Affected surfaces:** Script parameters, URI construction, authentication behavior, README prerequisites, and tests.

**Known dependencies:** This finding depends on centralizing endpoint construction from F013.

**Validation considerations:** Tests should verify that a custom Graph base URI flows into managed-device, policy-state, setting-state, and next-link behavior without corrupting absolute `@odata.nextLink` URLs returned by Graph.

### Implementation Option Analysis

**Options considered:**

- **F014-A: Keep the global Graph endpoint hardcoded.** This preserves the current script but excludes national-cloud users.
- **F014-B: Add a validated `GraphEnvironment` parameter and derive the Graph service root from Microsoft-documented endpoints.** This supports known clouds and connects cleanly to `Connect-MgGraph -Environment`.
- **F014-C: Add only a free-form `GraphBaseUri` parameter.** This is flexible but can create unsupported or misspelled endpoints.
- **F014-D: Add both `GraphEnvironment` and an advanced `GraphBaseUri` override.** This supports known environments by default and leaves a controlled escape hatch for test or future endpoints.
- **F014-E: Detect the environment from existing `Get-MgContext`.** This helps pre-authenticated sessions but does not solve initial connection or tests.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| National-cloud correctness | 30 | Highest score for known Microsoft Graph service roots and matching authentication environment. |
| Misconfiguration resistance | 20 | Highest score for validated values over free-form strings. |
| Advanced/test flexibility | 15 | Highest score for still allowing controlled non-default roots when needed. |
| Endpoint-builder integration | 20 | Highest score for cleanly feeding centralized URI builders. |
| Documentation clarity | 15 | Highest score for making user-facing environment choices simple. |

| Option | Cloud correctness (30) | Resistance (20) | Flexibility (15) | Builder integration (20) | Documentation (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F014-A | 0 | 20 | 0 | 8 | 4 | 32 |
| F014-B | 27 | 20 | 8 | 18 | 15 | 88 |
| F014-C | 18 | 6 | 15 | 16 | 8 | 63 |
| F014-D | 28 | 17 | 15 | 18 | 13 | 91 |
| F014-E | 16 | 15 | 6 | 10 | 6 | 53 |

**Selected option:** Implement **F014-D**. Add a `GraphEnvironment` parameter with known values and documented service roots, pass it to `Connect-MgGraph`, and allow an advanced `GraphBaseUri` override for tests or future environments. Endpoint builders should use the resolved service root for initial requests and preserve Graph-provided next links untouched.

## 15. F003: Harden Output Path Handling And CSV Write Safety

**Priority:** High

**Rubric score:** 68.2/100. Criteria scores: C01=2, C02=4, C03=4, C04=4, C05=4, C06=4, C07=3, C08=1, C09=5, C10=3, C11=5, C12=4, C13=3, C14=2, C15=3.

**Sequence rationale:** File write safety should precede overwrite controls, privacy controls, and streaming changes.

**Observed behavior:** The script accepts any non-empty `ExportPath`, creates the parent directory with `New-Item -Path`, and writes the CSV with `Export-Csv -LiteralPath`. It does not resolve the path to an absolute filesystem path before the write, reject wildcard characters in parent paths before `New-Item -Path`, preflight writeability, detect a directory path passed as the export target, or offer a safe overwrite contract.

**Why this matters:** The repository PowerShell guidance emphasizes literal-path handling and writeability testing for file outputs. A user-experience expert would also expect a clear error before an expensive Graph collection starts if the destination cannot be written. A cybersecurity technical reviewer would care that path handling does not accidentally expand wildcard characters or write somewhere surprising when paths contain characters such as `[` or `]`.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1` and tests that write to `$TestDrive`.

**Known dependencies:** This finding can be addressed independently of Graph behavior, but it should happen before adding heavier runtime workflows so failures occur early and consistently.

**Validation considerations:** Tests should cover parent directory creation for literal paths with wildcard-like characters, directory-as-file rejection, existing file overwrite behavior, and unwritable parent or file targets where practical without relying on host-specific ACL behavior.

### Implementation Option Analysis

**Options considered:**

- **F003-A: Keep the current `Split-Path`, `New-Item -Path`, and `Export-Csv -LiteralPath` flow.** This is simple but keeps wildcard and preflight gaps.
- **F003-B: Resolve the export target to an absolute filesystem path, create parent directories through .NET, reject directory targets, and preflight file writeability before Graph requests.** This directly addresses path safety and early failure.
- **F003-C: Require users to create the output directory manually.** This reduces script write behavior but harms ergonomics and still needs file write checks.
- **F003-D: Write to a temporary file and rename over the target only after successful Graph collection.** This improves atomicity but does not by itself solve path validation or overwrite policy.
- **F003-E: Restrict exports to a fixed `out/` directory.** This protects the repository but is too inflexible for real users.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Literal path safety | 30 | Highest score for avoiding wildcard interpretation and unexpected providers. |
| Early failure before Graph work | 25 | Highest score for detecting unwritable targets before network calls. |
| User ergonomics | 15 | Highest score for still creating reasonable parent directories automatically. |
| Portability | 15 | Highest score for behavior that works across supported PowerShell platforms. |
| Compatibility with overwrite controls | 15 | Highest score for integrating cleanly with no-clobber, force, and ShouldProcess behavior. |

| Option | Path safety (30) | Early failure (25) | Ergonomics (15) | Portability (15) | Overwrite compatibility (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F003-A | 10 | 2 | 15 | 12 | 4 | 43 |
| F003-B | 28 | 25 | 14 | 14 | 13 | 94 |
| F003-C | 18 | 18 | 3 | 15 | 10 | 64 |
| F003-D | 18 | 10 | 10 | 10 | 12 | 60 |
| F003-E | 25 | 20 | 2 | 14 | 8 | 69 |

**Selected option:** Implement **F003-B**. Add a path-resolution and writeability-preflight helper that resolves the export target to an absolute filesystem path, rejects directory targets, creates parent directories with literal semantics, and verifies the file can be opened for writing before starting Graph collection.

## 16. F016: Define Overwrite, No-Clobber, And ShouldProcess Behavior

**Priority:** High

**Rubric score:** 63.2/100. Criteria scores: C01=2, C02=3, C03=4, C04=4, C05=4, C06=4, C07=3, C08=0, C09=4, C10=3, C11=5, C12=4, C13=3, C14=2, C15=3.

**Sequence rationale:** Overwrite and confirmation semantics should be built on the hardened output-path contract from F003.

**Observed behavior:** `Export-WindowsComplianceStatusReport` overwrites the export file by default through `Export-Csv`. It does not expose `-NoClobber`, `-Force`, or `SupportsShouldProcess`, and direct script execution suppresses returned rows with `Out-Null`.

**Why this matters:** A user-experience expert expects a file-exporting command to be explicit about overwriting. A project manager wants repeatable scheduled reports, while an analyst may want protection from overwriting the last known-good export. A PowerShell maintainer expects potentially destructive file writes to participate in `-WhatIf` and `-Confirm` when feasible.

**Affected surfaces:** Function parameters, script parameters, help text, README usage examples, and output-path tests.

**Known dependencies:** This should be coordinated with F003 so file preflight, overwrite policy, and final write behavior are a single coherent contract.

**Validation considerations:** Tests should cover default overwrite behavior, no-clobber rejection, force behavior for read-only files where portable, and `-WhatIf` avoiding file creation.

### Implementation Option Analysis

**Options considered:**

- **F016-A: Keep overwriting by default without explicit controls.** This preserves current behavior but gives users no native preview or protection.
- **F016-B: Add `SupportsShouldProcess`, `-NoClobber`, and `-Force` while keeping overwrite as the default unless `-NoClobber` is set.** This preserves scheduled-run usability and adds safety controls.
- **F016-C: Make no-clobber the default and require `-Force` to overwrite.** This is safest for interactive users but may break repeatable report jobs.
- **F016-D: Always write timestamped output files.** This avoids overwrites but makes automation and fixed-path workflows harder.
- **F016-E: Prompt manually before overwriting without `ShouldProcess`.** This duplicates native PowerShell behavior and is harder to test.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| PowerShell-native safety semantics | 30 | Highest score for using `ShouldProcess`, `-WhatIf`, and `-Confirm` correctly. |
| Scheduled-report compatibility | 20 | Highest score for preserving noninteractive fixed-path exports. |
| Accidental overwrite protection | 20 | Highest score for an easy no-clobber path. |
| Testability of file behavior | 15 | Highest score for deterministic assertions around create, overwrite, and preview modes. |
| User mental model simplicity | 15 | Highest score for matching common PowerShell file-export patterns. |

| Option | Native safety (30) | Scheduled compatibility (20) | Overwrite protection (20) | Testability (15) | Simplicity (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F016-A | 2 | 20 | 0 | 5 | 8 | 35 |
| F016-B | 28 | 20 | 16 | 14 | 14 | 92 |
| F016-C | 28 | 10 | 20 | 14 | 11 | 83 |
| F016-D | 12 | 8 | 20 | 10 | 8 | 58 |
| F016-E | 10 | 6 | 12 | 6 | 5 | 39 |

**Selected option:** Implement **F016-B**. Add `SupportsShouldProcess`, `-NoClobber`, and `-Force`. Preserve overwrite-by-default behavior for repeatable exports, but make `-NoClobber` reject existing targets and make `-WhatIf` avoid file creation.

## 17. F015: Add Data Sensitivity Controls For Exported Tenant Data

**Priority:** High

**Rubric score:** 70.6/100. Criteria scores: C01=2, C02=5, C03=4, C04=3, C05=4, C06=4, C07=3, C08=1, C09=5, C10=4, C11=5, C12=3, C13=5, C14=3, C15=3.

**Sequence rationale:** Privacy controls depend on the chosen schema and output path behavior, but the repository ignore guidance can be separated if useful.

**Observed behavior:** The CSV includes device names and user principal names. The README warns not to commit tenant exports, but `.gitignore` does not ignore common export locations such as `out/` or generated compliance CSV names. The script also has no option to omit, redact, or hash user-identifying fields.

**Why this matters:** A cybersecurity officer sees device and user identifiers as sensitive operational data. A business stakeholder needs reports to be shareable at the right level of detail. A junior team member could accidentally place a tenant export under the repository because the usage example writes to `.\out\win11-compliance.csv` while the repository does not ignore `out/`.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1`, `.gitignore`, README data-safety guidance, CSV schema, and tests.

**Known dependencies:** Redaction choices depend on the selected report schema in F005. Ignoring generated export paths can be handled independently, but it should avoid hiding committed synthetic fixtures.

**Validation considerations:** Tests should assert redaction behavior if implemented. Repository checks should confirm synthetic fixtures remain tracked while likely real export outputs are ignored.

### Implementation Option Analysis

**Options considered:**

- **F015-A: Keep exporting UPNs by default and rely only on README warnings.** This preserves current output but provides no technical guardrail.
- **F015-B: Omit user principal names by default and add an explicit opt-in to include them.** This favors data minimization while preserving a deliberate path to user-level triage.
- **F015-C: Add `UserPrincipalNameMode` with `Omit`, `Include`, and `Hash`.** This is flexible but hashing introduces salt/key management questions and can create a false sense of anonymity.
- **F015-D: Split sensitive columns into a separate restricted CSV.** This supports differential sharing but adds artifact complexity.
- **F015-E: Keep schema unchanged and add `.gitignore` patterns only.** This reduces accidental commits but not report sharing risk.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Default data minimization | 35 | Highest score for reducing sensitive identifiers without user action. |
| Triage usefulness when authorized | 20 | Highest score for still supporting legitimate user-level investigation. |
| Misuse resistance | 20 | Highest score for avoiding weak anonymization or easy accidental disclosure. |
| Repository leak prevention | 15 | Highest score for reducing accidental commits of generated reports. |
| Implementation clarity | 10 | Highest score for a small parameter contract users can understand. |

| Option | Minimization (35) | Authorized triage (20) | Misuse resistance (20) | Leak prevention (15) | Clarity (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F015-A | 0 | 20 | 4 | 4 | 9 | 37 |
| F015-B | 35 | 17 | 18 | 12 | 9 | 91 |
| F015-C | 28 | 20 | 10 | 12 | 6 | 76 |
| F015-D | 30 | 18 | 17 | 12 | 4 | 81 |
| F015-E | 4 | 20 | 8 | 15 | 8 | 55 |

**Selected option:** Implement **F015-B**. Omit user principal names from exported rows by default, add an explicit `-IncludeUserPrincipalName` switch for authorized user-level triage, and add repository ignore patterns for common generated export locations such as `out/`. Keep synthetic test fixtures trackable.

## 18. F007: Add Graph Throttling, Retry, Timeout, And Partial-Failure Policy

**Priority:** High

**Rubric score:** 75.6/100. Criteria scores: C01=3, C02=2, C03=4, C04=5, C05=4, C06=4, C07=4, C08=4, C09=3, C10=5, C11=5, C12=5, C13=3, C14=4, C15=2.

**Sequence rationale:** Retry and partial-failure behavior should follow endpoint centralization, response-shape hardening, and dependency preflight.

**Observed behavior:** The injected `GraphRequest` script block is called directly. Any transient Graph error, throttling response, timeout, or per-device failure stops the whole export with the raw exception behavior. There is no retry strategy, no `Retry-After` handling, no maximum retry limit, no timeout policy, and no defined partial-report behavior.

**Supporting evidence:** Microsoft Graph throttling guidance says clients should detect HTTP 429, honor the `Retry-After` response header, and use exponential backoff when the header is absent. See [Microsoft Graph throttling guidance](https://learn.microsoft.com/graph/throttling#best-practices-to-handle-throttling).

**Why this matters:** For operational use, tenant-scale Graph reads should handle transient service behavior predictably. A cybersecurity leader needs to know whether a report is complete before acting on it. A technical expert needs bounded retries and deterministic failure semantics so the script does not hang or silently omit devices.

**Affected surfaces:** Graph request wrapper, error handling, CSV schema or metadata, README operational guidance, and tests.

**Known dependencies:** This should follow or accompany dependency/authentication preflight work so live Graph behavior is routed through a single wrapper that can apply retry and failure policy consistently.

**Validation considerations:** Tests should simulate throttling and transient failure through injected `GraphRequest` behavior and assert retry count, delay bypass/injection for fast tests, and final error or partial-output behavior.

### Implementation Option Analysis

**Options considered:**

- **F007-A: Let Graph exceptions fail immediately.** This is simple but treats expected throttling and transient errors as unrecoverable.
- **F007-B: Add a bounded retry wrapper that honors `Retry-After`, retries selected transient status codes, and supports test-injected sleep.** This directly follows Graph guidance and keeps tests fast.
- **F007-C: Use Microsoft Graph SDK retry middleware by replacing raw requests with generated cmdlets.** This may help for cmdlet-covered paths but disrupts the existing request seam and endpoint work.
- **F007-D: Continue after per-device failures and write a partial CSV by default.** This maximizes output but risks silent incomplete compliance reports.
- **F007-E: Retry indefinitely until Graph succeeds.** This can eventually recover but risks unbounded runtime and quota waste.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Alignment with Graph retry guidance | 30 | Highest score for honoring `Retry-After` and bounded backoff. |
| Completeness-safety balance | 25 | Highest score for avoiding silent partial reports while handling transient failures. |
| Testability without real delays | 20 | Highest score for injected or bypassable sleep behavior. |
| Scope fit with current REST seam | 15 | Highest score for improving reliability without rewriting the Graph layer. |
| Runtime predictability | 10 | Highest score for bounded attempts and clear final failure. |

| Option | Graph guidance (30) | Completeness safety (25) | Testability (20) | Scope fit (15) | Predictability (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F007-A | 0 | 14 | 18 | 15 | 8 | 55 |
| F007-B | 29 | 23 | 20 | 14 | 10 | 96 |
| F007-C | 22 | 18 | 8 | 5 | 8 | 61 |
| F007-D | 14 | 5 | 16 | 12 | 8 | 55 |
| F007-E | 12 | 10 | 3 | 10 | 0 | 35 |

**Selected option:** Implement **F007-B**. Add a bounded Graph request wrapper with configurable maximum retries, `Retry-After` handling when available, exponential backoff fallback, and a sleep scriptblock used by tests to avoid real waits. Keep the default policy fail-closed: if retries are exhausted, fail the export rather than silently producing an incomplete compliance artifact.

## 19. F021: Capture Supportability Context For Graph Failures

**Priority:** High

**Rubric score:** 63.2/100. Criteria scores: C01=2, C02=2, C03=4, C04=5, C05=4, C06=3, C07=3, C08=1, C09=3, C10=4, C11=5, C12=3, C13=5, C14=3, C15=2.

**Sequence rationale:** Supportability fields should be designed with the same request wrapper used for retry and partial failure.

**Observed behavior:** The script does not capture response headers, status codes, request IDs, dates, or target URIs when a Graph request fails. Errors bubble from the underlying request call without a script-level supportability wrapper.

**Supporting evidence:** Microsoft Graph PowerShell troubleshooting guidance notes that response headers such as `request-id` and `date` help support teams determine the cause of failures. See [troubleshooting Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/troubleshooting?view=graph-powershell-1.0#using--debug).

**Why this matters:** A help desk, cybersecurity operations team, or Microsoft support case owner needs request identifiers and timestamps to investigate service-side failures. A technical maintainer also needs a sanitized failure summary that does not leak tokens or tenant-sensitive payloads.

**Affected surfaces:** Graph request wrapper, error handling, verbose output, README troubleshooting notes, and tests.

**Known dependencies:** This belongs near F007 because retries and failure wrapping should share one request wrapper.

**Validation considerations:** Tests should inject failures with synthetic headers and assert that the script preserves safe supportability fields while excluding authorization headers or tokens.

### Implementation Option Analysis

**Options considered:**

- **F021-A: Keep raw Graph exceptions only.** This avoids wrapper work but loses safe support context.
- **F021-B: Wrap final Graph failures with URI, status code, request ID, date, and retry count when available.** This gives supportable errors without logging secrets.
- **F021-C: Log full request and response payloads for every failure.** This maximizes detail but risks leaking tenant data and tokens.
- **F021-D: Write a separate diagnostics file beside the CSV.** This preserves context but adds another sensitive artifact to manage.
- **F021-E: Require users to rerun with `-Debug` for support data.** This keeps normal output clean but puts burden on the user after a failure.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Support usefulness | 30 | Highest score for including fields support teams can act on. |
| Secret and tenant-data restraint | 25 | Highest score for excluding tokens, authorization headers, and raw payloads. |
| Error readability | 20 | Highest score for concise messages users can paste into an issue safely. |
| Compatibility with retry wrapper | 15 | Highest score for sharing data with F007 without duplicate plumbing. |
| Artifact simplicity | 10 | Highest score for avoiding additional diagnostics files unless needed. |

| Option | Support usefulness (30) | Data restraint (25) | Readability (20) | Retry compatibility (15) | Simplicity (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F021-A | 6 | 25 | 8 | 5 | 10 | 54 |
| F021-B | 28 | 24 | 18 | 15 | 9 | 94 |
| F021-C | 30 | 0 | 5 | 10 | 4 | 49 |
| F021-D | 24 | 12 | 12 | 12 | 3 | 63 |
| F021-E | 12 | 20 | 6 | 5 | 10 | 53 |

**Selected option:** Implement **F021-B**. When the retry wrapper gives up, throw an actionable error that includes the safe target URI, status code, Graph request ID, response date, and retry count when available. Do not log authorization headers, access tokens, or response bodies.

## 20. F006: Reduce N-Plus-One Graph Request Cost Or Make It Explicit

**Priority:** Medium-high

**Rubric score:** 55.0/100. Criteria scores: C01=2, C02=1, C03=2, C04=4, C05=3, C06=3, C07=3, C08=5, C09=2, C10=4, C11=4, C12=3, C13=2, C14=3, C15=2.

**Sequence rationale:** Request-cost optimization should follow endpoint validation and retry policy so it optimizes the correct behavior.

**Observed behavior:** The script retrieves managed devices, then for each device retrieves policy states, then for each policy retrieves setting states. This creates at least one additional Graph request per device and may create more than one per device when multiple compliance policies exist.

**Supporting evidence:** Microsoft Graph paging guidance states that clients should expect collection responses to be paged and continue using `@odata.nextLink` until no next link remains. Query-parameter guidance also recommends using property selection to limit returned data. See [paging](https://learn.microsoft.com/graph/paging) and [query parameters](https://learn.microsoft.com/graph/query-parameters).

**Why this matters:** In large Intune tenants, this request pattern can be slow, more likely to hit throttling, and harder to estimate before a user runs it. A project manager needs predictable runtime expectations, a technical lead needs a scalable design, and a user-experience reviewer needs progress feedback or controls for long runs.

**Affected surfaces:** Graph request flow, runtime documentation, tests, and any future retry/throttling behavior.

**Known dependencies:** Research is needed to determine whether Microsoft Graph supports an equivalent batched, expanded, delta, report, or export endpoint that safely reduces request count without losing setting-level detail. If no better endpoint exists, the script should document and instrument the request model.

**Validation considerations:** Tests should verify request count for representative fixture sizes and prove that any batching or throttling logic preserves row shape.

### Implementation Option Analysis

**Options considered:**

- **F006-A: Leave the request model undocumented.** This avoids work but keeps runtime cost opaque.
- **F006-B: Make the current request model explicit with request-count tracking, verbose output, and documentation while adding projection and retry improvements.** This is honest about the N-plus-one shape without premature endpoint changes.
- **F006-C: Replace per-device requests with Microsoft Graph JSON batching.** This can reduce HTTP round trips but adds per-request retry handling for batched 429 responses.
- **F006-D: Switch to a summary/report endpoint if research proves it provides equivalent setting-level detail.** This could be better, but current research has not established an equivalent v1.0 endpoint for the exact row shape.
- **F006-E: Parallelize per-device requests.** This may speed up small tenants but can worsen throttling and complicate failure handling.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Honesty about operational cost | 25 | Highest score for making request volume visible to users and maintainers. |
| Throttling risk management | 25 | Highest score for avoiding concurrency or batching choices that complicate throttling. |
| Preservation of setting-level detail | 20 | Highest score for keeping the report row contract intact. |
| Evidence basis | 15 | Highest score for choices supported by current primary-source research. |
| Implementation risk | 15 | Highest score for changes that do not rewrite the data model prematurely. |

| Option | Cost honesty (25) | Throttling risk (25) | Detail preservation (20) | Evidence basis (15) | Implementation risk (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F006-A | 0 | 8 | 20 | 5 | 15 | 48 |
| F006-B | 24 | 22 | 20 | 14 | 13 | 93 |
| F006-C | 18 | 10 | 18 | 10 | 6 | 62 |
| F006-D | 18 | 22 | 8 | 5 | 8 | 61 |
| F006-E | 12 | 3 | 20 | 8 | 4 | 47 |

**Selected option:** Implement **F006-B**. Keep the current per-device/per-policy expansion model for now, but make it explicit by tracking Graph request count, surfacing it in verbose output or the run summary, and documenting the request pattern. Do not add batching or parallelism until a separate endpoint-specific design proves equivalent data and retry behavior.

## 21. F017: Stream Or Chunk Report Generation For Large Tenants

**Priority:** Medium-high

**Rubric score:** 54.6/100. Criteria scores: C01=1, C02=1, C03=3, C04=4, C05=3, C06=3, C07=4, C08=5, C09=2, C10=4, C11=3, C12=3, C13=2, C14=3, C15=1.

**Sequence rationale:** Streaming depends on stable schema, no-data behavior, and output write safety.

**Observed behavior:** The script stores every expanded report row in a `List[object]`, converts the list to an array, pipes the whole array to `Export-Csv`, and returns the whole array. Large tenants with many devices, policies, and settings can produce a large in-memory row set.

**Why this matters:** A technical expert cares about memory growth, and a user-experience reviewer cares about the script appearing stuck until all data has been collected. A cybersecurity operations team may need to run the report across thousands of devices, where all-at-once collection can make the script slower and more fragile.

**Affected surfaces:** Export function implementation, return contract, CSV write strategy, progress behavior, and tests.

**Known dependencies:** Streaming depends on a stable schema from F005 and a no-data/header contract from F004.

**Validation considerations:** Tests should prove the header is written once, rows are appended deterministically, and the function can still return useful summary data without needing to keep every row in memory.

### Implementation Option Analysis

**Options considered:**

- **F017-A: Keep materializing every row in memory.** This preserves the current return contract but does not improve large-tenant behavior.
- **F017-B: Stream rows to CSV per sorted device and add `-PassThru` for callers who need row objects returned.** This reduces default memory pressure while preserving an explicit row-return path.
- **F017-C: Always stream and never return row objects.** This is memory-efficient but breaks current function callers and tests.
- **F017-D: Write one temporary CSV per device and merge them.** This limits memory but creates many intermediate files and cleanup failure modes.
- **F017-E: Add a maximum row limit and stop when exceeded.** This prevents runaway memory but can produce incomplete reports.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Default memory reduction | 30 | Highest score for avoiding all-row materialization during normal script use. |
| Compatibility with test and advanced caller needs | 20 | Highest score for preserving an explicit row-object return path. |
| Deterministic CSV compatibility | 20 | Highest score for working with selected sort and schema behavior. |
| File-write safety | 15 | Highest score for avoiding many temporary artifacts or partial writes. |
| Implementation clarity | 15 | Highest score for a straightforward writer flow. |

| Option | Memory (30) | Compatibility (20) | Determinism (20) | Write safety (15) | Clarity (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F017-A | 0 | 20 | 20 | 14 | 15 | 69 |
| F017-B | 25 | 18 | 17 | 13 | 12 | 85 |
| F017-C | 30 | 4 | 16 | 14 | 13 | 77 |
| F017-D | 24 | 12 | 10 | 4 | 5 | 55 |
| F017-E | 12 | 10 | 6 | 10 | 8 | 46 |

**Selected option:** Implement **F017-B**. Make normal script execution write rows incrementally to the CSV after a stable header is known and devices are processed in deterministic order. Add `-PassThru` so tests and advanced callers can intentionally collect row objects from the function.

## 22. F018: Add Progress, Verbose Output, And Run Summary

**Priority:** Medium-high

**Rubric score:** 55.2/100. Criteria scores: C01=2, C02=1, C03=3, C04=4, C05=5, C06=3, C07=2, C08=1, C09=2, C10=4, C11=4, C12=3, C13=5, C14=3, C15=3.

**Sequence rationale:** Progress and summary behavior should reflect retry, partial-failure, streaming, and schema decisions.

**Observed behavior:** The script emits no progress, verbose messages, request counts, row counts, elapsed time, or completion summary. A long run has no visible heartbeat unless an error occurs.

**Why this matters:** A user-experience expert and project manager both need the script to feel controllable during long tenant scans. A technical maintainer benefits from `Write-Verbose` details when troubleshooting Graph calls. A cybersecurity leader needs a completion summary that distinguishes "export succeeded with zero findings" from "nothing visible happened."

**Affected surfaces:** Script output, help text, tests, and documentation examples.

**Known dependencies:** This should follow the partial-failure policy in F007 so the run summary can accurately report success, retry, skipped devices, and failed devices.

**Validation considerations:** Tests can capture verbose output and assert summary object properties without requiring real timing.

### Implementation Option Analysis

**Options considered:**

- **F018-A: Keep the script silent except for errors.** This is clean for automation but unhelpful for long runs.
- **F018-B: Add `Write-Verbose` messages and a structured summary object while keeping default output quiet.** This supports troubleshooting and automation without noisy default output.
- **F018-C: Add `Write-Progress` for every device and policy.** This improves interactivity but can slow or clutter noninteractive runs.
- **F018-D: Print human-readable status lines by default.** This helps casual users but pollutes pipeline and scheduled-job output.
- **F018-E: Write a separate run summary file.** This is durable but adds another artifact and privacy considerations.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Long-run observability | 30 | Highest score for users being able to understand progress and completion. |
| Pipeline cleanliness | 25 | Highest score for keeping default stdout machine-safe. |
| Automation-friendly summary | 20 | Highest score for structured counts and status. |
| Testability | 15 | Highest score for output that can be asserted without timing flakiness. |
| User opt-in control | 10 | Highest score for surfacing extra detail only when requested. |

| Option | Observability (30) | Cleanliness (25) | Summary (20) | Testability (15) | Opt-in (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F018-A | 0 | 25 | 0 | 10 | 8 | 43 |
| F018-B | 24 | 25 | 20 | 14 | 10 | 93 |
| F018-C | 28 | 18 | 8 | 8 | 8 | 70 |
| F018-D | 22 | 5 | 8 | 12 | 2 | 49 |
| F018-E | 18 | 25 | 18 | 10 | 6 | 77 |

**Selected option:** Implement **F018-B**. Add verbose messages for major phases and Graph request counts, and return a structured summary when row passthrough is not requested. Keep default script execution quiet except for warnings and errors.

## 23. F025: Define Deterministic Row Ordering

**Priority:** Medium-high

**Rubric score:** 52.6/100. Criteria scores: C01=3, C02=0, C03=5, C04=2, C05=3, C06=4, C07=3, C08=1, C09=2, C10=3, C11=4, C12=3, C13=2, C14=3, C15=3.

**Sequence rationale:** Sorting keys should be selected after the report schema defines stable identifiers and display fields.

**Observed behavior:** The CSV row order follows the order returned by Microsoft Graph pages, policy states, and setting states. The script does not define or enforce a deterministic sort order.

**Why this matters:** A business stakeholder comparing two CSV reports may see noisy diffs if upstream ordering changes. A testing enthusiast wants stable output. A technical maintainer needs to know whether preserving Graph order is intentional or whether reports should be sorted by device, policy, and setting identifiers.

**Affected surfaces:** Report generation, CSV output, tests, README report interpretation guidance, and issue work items.

**Known dependencies:** This depends on the final report schema from F005 because the sort keys should be stable identifiers or documented display fields.

**Validation considerations:** Fixtures should include out-of-order devices, policies, and settings to prove the chosen ordering.

### Implementation Option Analysis

**Options considered:**

- **F025-A: Preserve Graph return order and document that order is not guaranteed.** This avoids sorting work but keeps noisy report diffs.
- **F025-B: Sort devices, policies, and settings before row emission using stable IDs and display fields.** This provides deterministic output while still allowing incremental per-device writing.
- **F025-C: Sort only final rows immediately before export.** This is simple but conflicts with streaming because it requires all rows in memory.
- **F025-D: Add a user-selectable sort parameter.** This is flexible but adds complexity and test permutations.
- **F025-E: Sort by display names only.** This is readable but unstable when names duplicate or are missing.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Report diff stability | 30 | Highest score for deterministic row ordering across repeated runs. |
| Compatibility with incremental writing | 20 | Highest score for not requiring full-row materialization. |
| Duplicate-name resilience | 20 | Highest score for using stable IDs as tie-breakers. |
| User readability | 15 | Highest score for grouping rows in a way humans can scan. |
| Test simplicity | 15 | Highest score for a single documented ordering rule. |

| Option | Diff stability (30) | Incremental compatibility (20) | Duplicate resilience (20) | Readability (15) | Test simplicity (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F025-A | 2 | 20 | 2 | 8 | 10 | 42 |
| F025-B | 29 | 18 | 20 | 14 | 14 | 95 |
| F025-C | 30 | 2 | 20 | 14 | 14 | 80 |
| F025-D | 26 | 10 | 18 | 15 | 6 | 75 |
| F025-E | 18 | 18 | 5 | 15 | 12 | 68 |

**Selected option:** Implement **F025-B**. Sort devices by device name then device ID, policy states by policy name then policy ID, and setting states by setting name then setting ID before emitting rows. This keeps rows stable without requiring a final all-row sort.

## 24. F026: Normalize Or Document Compliance State Casing And Enum Values

**Priority:** Medium-high

**Rubric score:** 57.4/100. Criteria scores: C01=3, C02=1, C03=5, C04=3, C05=3, C06=4, C07=3, C08=1, C09=2, C10=3, C11=4, C12=3, C13=3, C14=3, C15=2.

**Sequence rationale:** Enum behavior depends on endpoint choice and schema decisions.

**Observed behavior:** The script passes compliance state strings through from Graph without documenting whether values are normalized. Current fixtures use `noncompliant`, while Microsoft Graph documentation for related compliance status enums includes values such as `nonCompliant` and other case-sensitive spellings.

**Why this matters:** A report consumer may group by state in Excel, Power BI, or a SIEM. Case drift can split categories unexpectedly. A cybersecurity technical expert needs predictable state semantics, while a documentation lead needs to explain whether raw Graph values or normalized values are exported.

**Affected surfaces:** CSV schema, row conversion, tests, README, and any downstream issue text.

**Known dependencies:** This should be decided with the schema work in F005 and the endpoint verification in F013 because enum sets can differ by resource type.

**Validation considerations:** Tests should include representative casing variants and assert either raw preservation or documented normalization.

### Implementation Option Analysis

**Options considered:**

- **F026-A: Preserve raw Graph state values only and document that casing comes from Graph.** This avoids altering source data but leaves grouping pain.
- **F026-B: Normalize state values in place.** This simplifies grouping but destroys raw evidence and can mis-handle future enum members.
- **F026-C: Export both raw and normalized state columns.** This preserves source evidence while giving report consumers stable grouping keys.
- **F026-D: Normalize only known states and blank unknown values.** This avoids unexpected categories but hides useful future Graph values.
- **F026-E: Add a separate lookup table document for state meanings.** This helps documentation but does not improve the CSV.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| Raw evidence preservation | 25 | Highest score for keeping original Graph values available. |
| Consumer grouping reliability | 25 | Highest score for stable, predictable grouping fields. |
| Future enum resilience | 20 | Highest score for not failing or hiding unknown values. |
| Schema clarity | 15 | Highest score for column names that clearly distinguish raw and normalized values. |
| Implementation effort fit | 15 | Highest score for a simple conversion helper and tests. |

| Option | Evidence (25) | Grouping (25) | Future resilience (20) | Schema clarity (15) | Effort fit (15) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F026-A | 25 | 5 | 20 | 10 | 15 | 75 |
| F026-B | 4 | 25 | 10 | 10 | 12 | 61 |
| F026-C | 25 | 24 | 18 | 14 | 12 | 93 |
| F026-D | 4 | 20 | 3 | 8 | 10 | 45 |
| F026-E | 22 | 8 | 18 | 5 | 12 | 65 |

**Selected option:** Implement **F026-C**. Preserve raw Graph state values in existing-style columns and add normalized state columns for device, policy, and setting states. Unknown values should normalize predictably without being blanked so future Graph enum members remain visible.

## 25. F009: Improve Comment-Based Help To Match Repository Standards

**Priority:** Medium-high

**Rubric score:** 49.6/100. Criteria scores: C01=2, C02=1, C03=3, C04=2, C05=4, C06=2, C07=2, C08=0, C09=5, C10=3, C11=5, C12=3, C13=5, C14=2, C15=3.

**Sequence rationale:** Help should be updated after behavior decisions so documentation reflects the final command contract.

**Observed behavior:** The top-level script help and helper function help contain useful summaries and parameters, but they do not include the full repository-standard help sections such as `.DESCRIPTION`, `.EXAMPLE`, `.INPUTS`, `.OUTPUTS`, and `.NOTES` for each function. The top-level help also does not document expected output columns, no-data behavior, permissions, module prerequisites, or positional parameter behavior.

**Why this matters:** A documentation lead and junior team member rely on `Get-Help` output when they are not reading the repository README. A user-experience reviewer expects the script itself to explain its contract at the point of use. A maintainer needs help text to stay aligned with versioning, output, and validation behavior.

**Affected surfaces:** `scripts/Get-AllWin11ComplianceStatus.ps1` and README.

**Known dependencies:** Help updates should trail behavior decisions for scope, schema, output path, and no-data handling so the help does not codify unstable behavior.

**Validation considerations:** Pester tests or analyzer checks can inspect comment-based help completeness for public functions if the project wants to enforce this level of documentation.

### Implementation Option Analysis

**Options considered:**

- **F009-A: Update only README and leave comment-based help minimal.** This helps repository readers but not `Get-Help` users.
- **F009-B: Fully update help for the script entry and public functions after behavior changes.** This aligns user-facing help with the final contract.
- **F009-C: Fully update help for every helper function in the same change.** This maximizes style conformance but creates a large documentation-heavy diff.
- **F009-D: Add a help-completeness Pester test before updating help.** This enforces quality but can slow current behavior work.
- **F009-E: Suppress help expectations for private helpers.** This reduces churn but conflicts with repository guidance.

**Option evaluation rubric:**

| Criterion | Weight | Scoring guidance |
| --- | ---: | --- |
| User-facing help completeness | 30 | Highest score for documenting parameters, examples, inputs, outputs, notes, and report behavior. |
| Alignment with final behavior | 25 | Highest score for waiting until scope, schema, auth, and file behavior are decided. |
| Repository standard conformance | 20 | Highest score for matching required help sections where practical. |
| Diff reviewability | 15 | Highest score for keeping help updates focused on public surfaces first. |
| Enforcement value | 10 | Highest score for leaving a path to automated help checks later. |

| Option | Help completeness (30) | Behavior alignment (25) | Standard conformance (20) | Reviewability (15) | Enforcement value (10) | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| F009-A | 8 | 20 | 4 | 15 | 2 | 49 |
| F009-B | 28 | 25 | 16 | 13 | 7 | 89 |
| F009-C | 30 | 25 | 20 | 5 | 8 | 88 |
| F009-D | 18 | 10 | 18 | 8 | 10 | 64 |
| F009-E | 12 | 20 | 6 | 14 | 2 | 54 |

**Selected option:** Implement **F009-B**. After behavior changes are finalized, update comment-based help for the script entry and public functions with complete user-facing sections, including prerequisites, permissions, output columns, no-data behavior, privacy behavior, examples, and version notes. Keep private-helper help improvements focused on helpers touched by the implementation.
