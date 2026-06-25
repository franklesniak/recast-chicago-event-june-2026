<!-- markdownlint-disable MD013 -->

# Get-AllWin11ComplianceStatus Sequenced Priority Findings Research

## Metadata

- **Status:** Draft
- **Owner:** Repository Maintainers
- **Last Updated:** 2026-06-25
- **Scope:** Records primary-source and in-repository research used to evaluate implementation options for the sequenced priority findings in `Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`.
- **Related:** [`Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`](Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md), [`Get-AllWin11ComplianceStatus-backlog-prioritization-rubric.md`](Get-AllWin11ComplianceStatus-backlog-prioritization-rubric.md)

## Research Log

### R001: Managed Device Properties Support Windows Scope Decisions

**Related findings:** F001, F005, F012, F013, F025

**Source:** [Microsoft Graph `managedDevice` resource](https://learn.microsoft.com/graph/api/resources/intune-devices-manageddevice?view=graph-rest-1.0#properties)

**Relevant facts:** Microsoft documents `operatingSystem` as a broad read-only string such as Windows or iOS, and separately documents `osVersion` as the operating-system version string for the managed device.

**Interpretation:** A report named for Windows 11 should not rely only on `operatingSystem eq 'Windows'`. The implementation should request `osVersion`, use it in the report schema, and either filter Windows 11 devices explicitly or rename/re-scope the script so the output claim is true.

### R002: Windows 11 Release Information Establishes Build 22000 As The First Windows 11 Build Family

**Related findings:** F001, F005, F026

**Source:** [Windows 11 release information](https://learn.microsoft.com/windows/release-health/windows11-release-information#windows-11-release-history)

**Relevant facts:** Microsoft documents "Version 21H2 (OS build 22000)" as the initial Windows 11 release family, and later Windows 11 releases use higher build families such as 22621.

**Interpretation:** If the script must distinguish Windows 11 from older Windows clients using Intune `osVersion`, a defensible local rule is to treat Windows devices with an OS build number of 22000 or higher as Windows 11. The implementation should still export `osVersion` so the report consumer can audit the classification.

### R003: Microsoft Graph Paging And Query Parameters Shape Request Design

**Related findings:** F006, F012, F013, F017

**Sources:** [Microsoft Graph paging](https://learn.microsoft.com/graph/paging), [Microsoft Graph query parameters](https://learn.microsoft.com/graph/query-parameters)

**Relevant facts:** Microsoft Graph collection responses can be paged and clients should follow `@odata.nextLink` until no next link remains. Query parameters such as `$filter`, `$select`, and `$top` are documented mechanisms for shaping collection responses.

**Interpretation:** The existing next-link loop is directionally correct, but endpoint builders should preserve next-link URLs as opaque strings and initial requests should use explicit projections once the report schema is defined.

### R004: Graph Throttling Requires Retry-After And Bounded Backoff Handling

**Related findings:** F006, F007, F021

**Source:** [Microsoft Graph throttling guidance](https://learn.microsoft.com/graph/throttling#best-practices-to-handle-throttling)

**Relevant facts:** Microsoft Graph clients should detect HTTP 429, respect the `Retry-After` header, and use exponential backoff when `Retry-After` is absent. Microsoft also notes that batched request failures need per-request retry handling.

**Interpretation:** Any production-ready request wrapper should treat throttling and transient service errors as expected operational states, with a bounded retry count and test-injectable delay behavior.

### R005: Graph PowerShell Authentication Supports More Than Interactive Global-Cloud Sessions

**Related findings:** F002, F014, F019, F022

**Sources:** [`Connect-MgGraph`](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/connect-mggraph?view=graph-powershell-1.0), [Microsoft Graph PowerShell authentication commands](https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands?view=graph-powershell-1.0)

**Relevant facts:** Microsoft Graph PowerShell supports delegated and app-only authentication patterns, scope-based interactive sign-in, tenant selection, context scope, device-code authentication, and environment selection.

**Interpretation:** The script should keep tests independent from live sign-in while exposing safe live-run parameters such as tenant ID, device-code sign-in, and Graph environment. Secret-bearing app credentials should not be written into examples or repository files.

### R006: Microsoft Graph National Cloud Roots Differ From Global Graph

**Related findings:** F014, F019

**Source:** [Microsoft Graph national cloud deployments](https://learn.microsoft.com/graph/deployments#microsoft-graph-and-graph-explorer-service-root-endpoints)

**Relevant facts:** Microsoft documents distinct service roots for Global (`https://graph.microsoft.com`), US Government L4 (`https://graph.microsoft.us`), US Government L5 (`https://dod-graph.microsoft.us`), and China operated by 21Vianet (`https://microsoftgraph.chinacloudapi.cn`).

**Interpretation:** Hardcoding `https://graph.microsoft.com` excludes supported non-global environments. Endpoint construction should derive the service root from a validated environment or explicit base URI.

### R007: Invoke-MgGraphRequest Has A Broad Output Contract

**Related findings:** F020

**Source:** [`Invoke-MgGraphRequest`](https://learn.microsoft.com/powershell/module/microsoft.graph.authentication/invoke-mggraphrequest?view=graph-powershell-1.0)

**Relevant facts:** Microsoft documents `Invoke-MgGraphRequest` as returning `System.Object`.

**Interpretation:** `Get-GraphPropertyValue` should either clearly accept only `PSCustomObject` responses or support common PowerShell object shapes such as dictionaries. Because the script exposes an injected `GraphRequest` test seam, supporting dictionaries improves test ergonomics and wrapper flexibility.

### R008: Graph Troubleshooting Benefits From Request IDs And Dates

**Related findings:** F007, F021

**Source:** [Troubleshooting Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/troubleshooting?view=graph-powershell-1.0#using--debug)

**Relevant facts:** Microsoft identifies response headers such as `request-id` and `date` as useful support information for diagnosing failures.

**Interpretation:** A request wrapper should preserve sanitized supportability context when available. It must not log authorization headers, access tokens, or tenant-sensitive payloads.

### R009: Export-Csv Header Behavior Depends On Submitted Objects

**Related findings:** F004, F005, F017

**Source:** [`Export-Csv`](https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/export-csv?view=powershell-7.6)

**Relevant facts:** Microsoft documents that `Export-Csv` writes headers from object properties. A local PowerShell check confirmed that piping an empty array to `Export-Csv` creates an empty file with no header row.

**Interpretation:** If an empty report should still be machine-readable, the script must write a known header row rather than relying on an object pipeline with zero rows.

### R010: ShouldProcess Provides Native WhatIf And Confirm Semantics

**Related findings:** F003, F016

**Source:** [Everything you wanted to know about ShouldProcess](https://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.6)

**Relevant facts:** Adding `SupportsShouldProcess` to a function's `CmdletBinding` enables native `-WhatIf` and `-Confirm` behavior. Microsoft also documents explicit `-Force` patterns for commands that need confirmation bypass semantics.

**Interpretation:** The export function should use PowerShell-native preview/confirmation semantics for file writes where practical, and should define `-Force` and no-clobber behavior deliberately.

### R011: #Requires Prevents Unsupported Script Execution

**Related findings:** F002, F022

**Source:** [`about_Requires`](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-7.6)

**Relevant facts:** `#Requires` can prevent a script from running unless required PowerShell versions or modules are present, and its requirements apply before script execution.

**Interpretation:** `#Requires -Version 7.4` is a clear way to enforce the README's PowerShell support boundary, but module requirements may be better handled through custom preflight so tests can still dot-source the script without a live Graph module requirement.

### R012: Repository PowerShell Guidance Restricts Script-Scope Strict Mode In Dot-Sourced Files

**Related findings:** F011, F024

**Source:** [Repository PowerShell instructions](../../.github/instructions/powershell.instructions.md)

**Relevant facts:** The repository guidance states that files intended to be dot-sourced directly into a caller's scope should not place `Set-StrictMode -Version Latest` at script scope; strict mode should be placed inside functions instead.

**Interpretation:** Because tests dot-source the script, strict mode should move into function bodies or another isolated execution scope. This change should be verified by a test that caller preference state is not changed by dot-sourcing.

