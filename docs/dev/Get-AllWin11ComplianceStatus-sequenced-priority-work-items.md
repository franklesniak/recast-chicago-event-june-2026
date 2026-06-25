<!-- markdownlint-disable MD013 -->

# Get-AllWin11ComplianceStatus Sequenced Priority Work Items

## Metadata

- **Status:** Draft
- **Owner:** Repository Maintainers
- **Last Updated:** 2026-06-25
- **Scope:** Converts the selected fixes from `Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md` into implementation-ready GitHub Issue bodies, in the same sequence as the priority findings.
- **Related:** [`Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`](Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md), [`Get-AllWin11ComplianceStatus-sequenced-priority-findings-research.md`](Get-AllWin11ComplianceStatus-sequenced-priority-findings-research.md), [`github-issue-style-guide.md`](github-issue-style-guide.md)

## Shared Guardrails For Every Work Item

- Do not commit secrets, tokens, credential-bearing URLs, tenant exports, real device names, real user principal names, or real Intune data.
- Keep default tests no-network and fixture-driven. Live Microsoft Graph calls are out of scope for this work-item set.
- Do not edit protected instruction files, including `.github/copilot-instructions.md`, files under `.github/instructions/`, root agent instruction files, or `.cursor/rules/`, unless the repository owner gives explicit authorization for that exact protected-file change.
- Preserve the existing script path `scripts/Get-AllWin11ComplianceStatus.ps1` unless a later owner-approved issue explicitly changes file layout.
- Run `Invoke-Pester -Path tests/PowerShell -Output Detailed` after PowerShell behavior changes.
- Run `npm run lint:md` after Markdown changes.
- Run `pre-commit run --all-files` before commit.

## WI-01: Centralize Microsoft Graph Endpoint Builders For The Compliance Export

### Summary

Add centralized helpers for the Microsoft Graph v1.0 URIs used by the report, and cover those helpers with no-network Pester tests. This gives maintainers one place to verify managed-device, policy-state, and setting-state endpoint contracts before later schema, retry, cloud, and performance work builds on them.

### Problem

The script currently constructs Graph endpoint strings inline. Existing tests prove the script calls those strings, but synthetic tests can preserve an incorrect endpoint just as easily as a correct one. Endpoint construction also affects `$select`, national cloud support, supportability logging, and request-count instrumentation.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`

Inspect-only candidates:

- `docs/dev/Get-AllWin11ComplianceStatus-sequenced-priority-findings-research.md`

### Requested Changes

- Add small private helpers that build the initial Graph v1.0 collection URIs from a service root, API version, resource IDs, filters, and projections.
- Keep Graph-provided `@odata.nextLink` values opaque after the first request; do not rebuild or rewrite returned next links.
- Add tests that assert generated URIs for managed devices, device compliance policy states, and device compliance policy setting states.
- Keep the existing injectable request seam for fixture-backed tests.

### Scope And Non-Goals

- Do not add a live tenant smoke test.
- Do not replace REST calls with generated Graph PowerShell cmdlets.
- Do not move endpoint definitions into external JSON configuration.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Initial Graph request URIs are generated only through centralized helpers.
- Tests prove the managed-device URI includes the selected service root, v1.0 path, Windows filter, and selected projection fields.
- Tests prove policy-state and setting-state URIs are built from device and policy identifiers.
- Existing fixture-backed export tests still pass without live Graph access.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph managed-device resource: documents the source resource and properties used by the report.
- Microsoft Graph paging and query parameters: supports following `@odata.nextLink` and using `$filter` and `$select` on initial requests.
- Research entries R001 and R003 in the research log.

## WI-02: Remove Dot-Sourcing Side Effects From The PowerShell Script

### Summary

Move strict-mode and stop-on-error behavior out of script scope so dot-sourcing the file for tests or troubleshooting does not alter the caller's session. Keep strict behavior inside functions where it protects the script's own implementation.

### Problem

The script currently runs `Set-StrictMode -Version Latest` and assigns `$ErrorActionPreference = 'Stop'` at script scope. When tests dot-source the file, those changes leak into the caller's scope and can make unrelated commands fail differently after import.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`

### Requested Changes

- Remove script-scope strict mode and script-scope `$ErrorActionPreference` assignment.
- Put `Set-StrictMode -Version Latest` inside public and private functions touched by this implementation.
- Use local stop-on-error behavior inside execution paths that need it.
- Add a Pester test that dot-sourcing the script does not change the caller's `$ErrorActionPreference`.

### Scope And Non-Goals

- Do not split the script into a separate module file.
- Do not remove strict mode entirely.
- Do not change unrelated repository PowerShell files.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Dot-sourcing the script does not change the caller's `$ErrorActionPreference`.
- Tests can still dot-source the script to access functions.
- Function execution still fails fast on unexpected errors.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Repository PowerShell guidance: dot-sourced files should not set strict mode at script scope.
- Research entry R012 in the research log.

## WI-03: Add Focused Pester Coverage For High-Risk Compliance Export Behavior

### Summary

Expand the Pester suite with targeted no-network tests for the high-risk behaviors introduced by this backlog. Tests should cover scope, schema, no-data behavior, file-write safety, retries, direct invocation, sorting, privacy, and summary output as those features are implemented.

### Problem

The current test suite covers one fixture-backed happy path. It does not cover empty data, malformed or missing IDs, Windows 11 filtering, output path failures, dependency preflight, throttling, deterministic ordering, or direct script invocation. That leaves little safety net for the selected behavior changes.

### Affected Files

Expected edit candidates:

- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `tests/PowerShell/Fixtures/`

Conditional edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`, only as needed to expose safe function-level test seams.

### Requested Changes

- Add focused Pester contexts for each selected behavior as it is implemented.
- Keep tests synthetic and deterministic by injecting Graph request behavior at the function level.
- Use `$TestDrive` for file writes.
- Prefer precise function-level assertions over broad snapshot-only tests.

### Scope And Non-Goals

- Do not add live Microsoft Graph tests to the default suite.
- Do not expose a public scriptblock execution parameter on the script entry point only for testing.
- Do not replace Pester with CSV snapshot tests.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- New tests are fixture-backed or synthetic and do not require tenant credentials.
- Test names clearly describe the behavior under protection.
- Tests remain portable across supported PowerShell 7.4+ environments.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Existing `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`: establishes the current fixture-backed pattern.
- Research entries R001 through R012 as they apply to individual behaviors.

## WI-04: Add Direct Invocation Tests For The Script Entry Point

### Summary

Add tests that execute `scripts/Get-AllWin11ComplianceStatus.ps1` through its script entry point for safe validation and no-operation scenarios. This verifies the path users run from README examples without exposing an unsafe public scriptblock parameter.

### Problem

Existing tests dot-source the file and call the export function directly. They do not verify the direct script path, missing `-ExportPath` behavior, or future `-WhatIf` behavior. Most users will run the file as a script.

### Affected Files

Expected edit candidates:

- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `scripts/Get-AllWin11ComplianceStatus.ps1`

### Requested Changes

- Add direct invocation tests for missing or invalid `-ExportPath` behavior.
- Add a direct invocation test for a no-operation path such as `-WhatIf` after ShouldProcess support exists.
- Keep full Graph fixture coverage at the function level.

### Scope And Non-Goals

- Do not add a public `-GraphRequest` script parameter.
- Do not require Graph modules or tenant sign-in for direct invocation tests that only validate no-op behavior.
- Do not split the script into wrapper and module files.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- At least one Pester test invokes the script file directly.
- Direct invocation failure messages are useful for missing or invalid required parameters.
- Direct invocation no-op behavior does not create an export file.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `pre-commit run --all-files` passes before commit.

### References

- PowerShell script invocation behavior and repository README usage examples.
- Selected option F027-B in the preliminary findings document.

## WI-05: Filter The Export To Windows 11 Devices By Default

### Summary

Make the report truthfully scoped to Windows 11 by default. Continue requesting Windows devices from Graph, classify Windows 11 locally using `osVersion` build number 22000 or higher, and add `-IncludeAllWindows` for callers who intentionally want the broader Windows device set.

### Problem

The script and README present the export as Windows 11 compliance, but the current Graph filter is only `operatingSystem eq 'Windows'`. That can include Windows 10 or other Windows-family devices and distort compliance counts, remediation planning, and audit evidence.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `tests/PowerShell/Fixtures/`
- `README.md`

### Requested Changes

- Add local Windows 11 classification using `osVersion` and the Windows 11 build threshold of 22000.
- Keep the initial Graph filter to Windows-family devices unless endpoint research proves a safer supported server-side Windows 11 filter.
- Exclude non-Windows-11 devices by default.
- Add `-IncludeAllWindows` to include all Windows-family devices intentionally.
- Export `OperatingSystem`, `OSVersion`, and a Windows 11 classification field so consumers can audit the decision.

### Scope And Non-Goals

- Do not rename the script in this issue.
- Do not infer Windows 11 from device display names.
- Do not query live tenant data in tests.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Fixture data includes at least one Windows 11 device and one non-Windows-11 Windows device.
- Default export includes only Windows 11 devices.
- `-IncludeAllWindows` includes the broader Windows-family fixture data.
- README documents the default Windows 11 scope and the opt-in broader scope.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph managed-device resource: documents `operatingSystem` and `osVersion`.
- Windows 11 release information: identifies OS build 22000 as the first Windows 11 release family.
- Research entries R001 and R002.

## WI-06: Rename The Public Export Function For Windows 11 Scope While Preserving Compatibility

### Summary

Introduce `Export-Windows11ComplianceStatusReport` as the primary public function name while preserving `Export-WindowsComplianceStatusReport` as a compatibility wrapper. This aligns the callable function with the script's Windows 11 scope without breaking existing tests or callers immediately.

### Problem

The script file is named for Windows 11, but the public function currently says only "Windows compliance." Once the default behavior filters to Windows 11, the public function name should match the user-visible scope while avoiding a sudden breaking change.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add `Export-Windows11ComplianceStatusReport` as the primary function.
- Keep `Export-WindowsComplianceStatusReport` as a wrapper that forwards parameters to the new function.
- Update tests and README examples to use the new primary function name where a function call is shown.
- Keep direct script invocation examples anchored on the existing script path.

### Scope And Non-Goals

- Do not rename the script file.
- Do not remove the compatibility wrapper in this issue.
- Do not introduce aliases that hide parameter contract changes.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- The new function is callable after dot-sourcing the script.
- The compatibility wrapper still works for existing function-level callers.
- README and tests prefer the new primary function name.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Selected option F023-B in the preliminary findings document.
- Repository README current usage examples.

## WI-07: Expand The Compliance CSV Schema With Operational And Audit Fields

### Summary

Expand the CSV schema so each row contains enough device, policy, setting, state, and retrieval context to support compliance analysis without a second lookup. Keep the schema stable across empty and non-empty exports.

### Problem

The current export omits important context such as device IDs, Azure AD device IDs, OS version, management metadata, raw and normalized states, current values, error details, and retrieval timestamp. A consumer cannot fully audit what was queried or group results reliably.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `tests/PowerShell/Fixtures/`
- `README.md`

### Requested Changes

- Define a stable ordered column list for the report.
- Include device identifiers, device name, optional user principal name, operating system, OS version, Windows 11 classification, management agent, owner type, manufacturer, model, last sync, device compliance state, policy ID/name/state, setting ID/name/state, current value, error code, error description, retrieval timestamp, and request/run context fields where available.
- Keep missing Graph properties as blank values rather than failing row conversion.
- Update tests to assert the schema and representative values.

### Scope And Non-Goals

- Do not include raw tenant exports or real device data in fixtures.
- Do not add every possible Intune managed-device property.
- Do not remove privacy defaults from WI-17.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- CSV column order is deterministic and tested.
- Empty and non-empty exports use the same header.
- Rows include OS version and Windows 11 classification.
- Missing optional properties do not break row generation.
- README documents the important output columns and privacy-sensitive fields.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph managed-device resource and compliance policy state resources.
- Microsoft Export-Csv documentation for property-derived headers.
- Research entries R001 and R009.

## WI-08: Write A Header-Only CSV When The Export Has No Rows

### Summary

Define the no-data contract explicitly by writing a header-only CSV and warning the user when the query returns no export rows. Return an empty row set for callers using pass-through behavior.

### Problem

Piping an empty object array to `Export-Csv` creates an empty file without headers. That makes it hard to distinguish "the script succeeded and found nothing" from "the artifact is malformed."

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Write the stable report header even when no rows are emitted.
- Emit a warning that the export completed with no report rows.
- Preserve an empty pass-through result when `-PassThru` is used.
- Add tests for empty managed-device responses and empty post-filter Windows 11 results.

### Scope And Non-Goals

- Do not treat zero rows as a terminating error.
- Do not fabricate placeholder data rows.
- Do not add a separate metadata file for no-data runs.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- A no-row export creates a CSV containing exactly the stable header row.
- The warning text makes clear that the run succeeded with no report rows.
- Pass-through mode returns no row objects for no-data input.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Export-Csv documentation.
- Research entry R009.

## WI-09: Add Explicit Microsoft Graph Projections For Initial Requests

### Summary

Use `$select` on initial Microsoft Graph collection requests where supported so the script requests the properties it actually needs for the expanded schema. Preserve returned `@odata.nextLink` URLs exactly.

### Problem

The current managed-device request does not specify projected fields. That can return unnecessary data, make the data contract implicit, and obscure which properties are required for the report.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`

Conditional edit candidates:

- `README.md`, if usage or permissions notes need to mention projection behavior.

### Requested Changes

- Define projection lists for managed devices and other initial collection requests where the endpoint supports `$select`.
- Include all fields required by the selected report schema.
- Ensure URI builder tests include encoded `$select` parameters.
- Continue following Graph-provided next links without appending new query parameters.

### Scope And Non-Goals

- Do not drop fields needed by later work items.
- Do not rewrite returned next links.
- Do not add `$expand` unless endpoint documentation proves it is supported for the exact resource path.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Initial managed-device requests include a tested projection list.
- The projection includes OS version, identifiers, compliance state, and schema fields needed for the report.
- Next-link handling remains opaque.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph query parameters documentation.
- Microsoft Graph paging documentation.
- Research entry R003.

## WI-10: Support Dictionary-Shaped Graph Responses In Property Reads

### Summary

Make Graph response property reads work with exact-key `IDictionary` values before falling back to PowerShell object properties. This keeps fixture and wrapper behavior robust when `Invoke-MgGraphRequest` returns broad `System.Object` shapes.

### Problem

`Invoke-MgGraphRequest` has a broad output contract, and injected test seams may provide dictionaries. A property reader that only handles `PSCustomObject` shapes is brittle and makes tests less representative of common PowerShell object handling.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`

### Requested Changes

- Update `Get-GraphPropertyValue` so it checks `System.Collections.IDictionary` exact keys first.
- Preserve existing PSObject property fallback behavior.
- Add tests for dictionary responses, including keys such as `value` and `@odata.nextLink`.

### Scope And Non-Goals

- Do not implement fuzzy key matching.
- Do not flatten nested response objects automatically.
- Do not require all tests to use dictionaries.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Dictionary responses work for collection values and next links.
- Existing fixture objects still work.
- Missing keys return the expected null or default behavior.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `pre-commit run --all-files` passes before commit.

### References

- `Invoke-MgGraphRequest` documentation: output type is `System.Object`.
- Research entry R007.

## WI-11: Add Live-Run Microsoft Graph Dependency And Authentication Preflight

### Summary

Add a live-run preflight that checks for required Graph PowerShell commands and provides clear authentication guidance before any tenant data is requested. Keep tests independent from installed Graph modules.

### Problem

The script assumes Graph PowerShell commands are available and that authentication will succeed. Missing modules or unavailable commands currently surface later as less helpful runtime failures.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Check for `Connect-MgGraph` and `Invoke-MgGraphRequest` during live execution.
- Do not auto-install modules.
- Keep `-SkipGraphConnect` for already-authenticated or test-injected function-level calls.
- Emit clear, non-secret error messages that tell users which module or command is missing.

### Scope And Non-Goals

- Do not add app-only credential parameters in this issue.
- Do not require Graph modules merely to dot-source the script or run no-network tests.
- Do not write authentication tokens or tenant identifiers to disk.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Missing Graph command preflight fails before export data requests are made.
- Tests cover missing dependency behavior without requiring the module to be installed.
- README lists the required Graph PowerShell module and sign-in expectation.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph PowerShell authentication documentation.
- Research entry R005.

## WI-12: Enforce The PowerShell 7.4 Runtime Contract

### Summary

Add `#Requires -Version 7.4` to the script and keep module dependency checks in custom live-run preflight code. This prevents unsupported Windows PowerShell execution while preserving no-network tests.

### Problem

The repository expects modern PowerShell behavior, but the script does not enforce its runtime baseline. Running it under older shells can produce confusing failures.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add `#Requires -Version 7.4` near the top of the script.
- Keep Graph module requirements out of `#Requires` so tests and no-op import paths do not require installed Graph modules.
- Update README and help text to state the PowerShell 7.4+ requirement.

### Scope And Non-Goals

- Do not add `#Requires -Modules Microsoft.Graph.*`.
- Do not support Windows PowerShell 5.1 for this script.
- Do not alter repository-wide PowerShell version policy files.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Direct script execution under unsupported PowerShell versions is blocked by `#Requires`.
- Tests still pass under PowerShell 7.4+.
- README documents the PowerShell requirement.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- PowerShell `about_Requires` documentation.
- Research entry R011.

## WI-13: Add Safe Delegated Authentication Parameters

### Summary

Expose safe delegated authentication controls for live runs, including tenant selection, device-code sign-in, context scope, and Graph environment. Preserve `-SkipGraphConnect` for existing authenticated sessions and tests.

### Problem

The current script only supports a narrow implicit interactive sign-in flow. Operators may need tenant targeting, device-code sign-in, process-scoped contexts, or national cloud environments without embedding secrets in commands or files.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add parameters such as `-TenantId`, `-UseDeviceCode`, `-ContextScope`, and `-GraphEnvironment` to the script and primary function.
- Pass supported values through to `Connect-MgGraph` during live sign-in.
- Keep `-SkipGraphConnect` available for callers that already established context.
- Document safe delegated examples without secrets.

### Scope And Non-Goals

- Do not add raw token, client secret, certificate password, or credential-bearing URL parameters.
- Do not persist Graph contexts or tokens in repository files.
- Do not implement app-only authentication in this work item.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Tests verify that delegated auth parameters are translated into the expected connect call arguments.
- `-SkipGraphConnect` bypasses connection attempts.
- README examples do not contain placeholder secrets.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- `Connect-MgGraph` documentation.
- Microsoft Graph PowerShell authentication commands.
- Research entry R005.

## WI-14: Support Microsoft Graph Cloud Environment Selection

### Summary

Derive Graph service roots from a validated `-GraphEnvironment` parameter and allow an advanced explicit `-GraphBaseUri` override for specialized testing or future environments. Use the selected root consistently in endpoint builders.

### Problem

The script currently hardcodes `https://graph.microsoft.com`, which excludes documented national cloud deployments. Endpoint helpers must support the selected Graph root before environment-aware authentication can be reliable.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add a validated `GraphEnvironment` option for Global, USGov, USGovDoD, and China clouds.
- Map each environment to the documented Microsoft Graph service root.
- Pass the selected environment to `Connect-MgGraph` when connecting.
- Use the resolved service root in all initial URI builders.
- Add an explicit `GraphBaseUri` override for tests or advanced scenarios, with validation that it is an absolute HTTPS URI.

### Scope And Non-Goals

- Do not invent undocumented cloud names.
- Do not make live calls to national clouds in tests.
- Do not allow non-HTTPS service roots.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- URI builder tests cover at least Global and one national cloud root.
- Invalid base URIs are rejected before Graph requests.
- README documents supported environment names.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph national cloud deployments.
- `Connect-MgGraph` environment parameter documentation.
- Research entries R005 and R006.

## WI-15: Validate Export Paths Before Graph Requests

### Summary

Resolve and validate the export path before making Graph requests. Reject directory targets, create valid parent directories, and fail early on unsafe or unwritable paths.

### Problem

The script currently waits until after Graph retrieval to discover many file path problems. That can waste time, produce confusing failures, and risk writing to unintended locations.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Resolve `-ExportPath` to an absolute filesystem path.
- Reject directory targets and invalid provider paths.
- Create the parent directory when appropriate.
- Preflight write access before live Graph collection starts, while respecting `-WhatIf`.
- Use literal-path semantics for file operations.

### Scope And Non-Goals

- Do not weaken path traversal or provider validation to make odd paths work.
- Do not delete existing files as part of validation.
- Do not support non-file providers for CSV output.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Invalid export paths fail before any Graph request is issued.
- Directory targets are rejected with a useful error.
- Missing parent directories are created for real runs.
- Tests cover valid paths, directory targets, and pre-Graph failure order.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Repository safety guidance for path traversal and file access boundaries.
- PowerShell file provider and path behavior as used by the implementation.

## WI-16: Add NoClobber, Force, And WhatIf Behavior To CSV Export

### Summary

Add PowerShell-native file-write controls for the export operation. Support `-NoClobber`, `-Force`, and `-WhatIf` while keeping the current overwrite behavior as the default for compatibility.

### Problem

The current export overwrites files without a clear preview or no-clobber option. Users need a safe way to prevent accidental replacement and a native PowerShell way to preview file writes.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add `SupportsShouldProcess` to the primary export function.
- Implement `-WhatIf` so no CSV file is created and no Graph requests are required for the no-operation path.
- Add `-NoClobber` to fail when the target file already exists.
- Add `-Force` for deliberate overwrite or confirmation bypass semantics where applicable.
- Keep overwrite as the default when neither `-NoClobber` nor `-WhatIf` is used.

### Scope And Non-Goals

- Do not force interactive confirmation by default.
- Do not change unrelated file-writing behavior outside this script.
- Do not delete or rename existing files as a backup strategy.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- `-WhatIf` reports the intended file write and creates no file.
- `-NoClobber` fails before overwriting an existing file.
- Default overwrite behavior remains tested.
- Direct invocation no-op tests cover `-WhatIf`.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- PowerShell ShouldProcess guidance.
- Research entry R010.

## WI-17: Protect User Principal Names And Ignore Local Export Artifacts

### Summary

Do not write user principal names to the report by default. Add an explicit `-IncludeUserPrincipalName` opt-in, and ignore local `out/` exports so generated CSV artifacts are less likely to be committed accidentally.

### Problem

User principal names can be sensitive operational data. A default export that includes them increases privacy exposure, especially when CSV files are generated inside the repository.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`
- `.gitignore`

### Requested Changes

- Leave the `UserPrincipalName` field blank or absent by default according to the final stable schema decision.
- Add `-IncludeUserPrincipalName` to explicitly include the Graph value.
- Document the privacy behavior in README and help text.
- Add `out/` to `.gitignore` while keeping test fixtures trackable.

### Scope And Non-Goals

- Do not redact or transform real tenant exports in the repository; real exports should not be committed.
- Do not hide synthetic fixture data needed by tests.
- Do not add telemetry or external logging.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Default exports do not contain fixture user principal name values.
- `-IncludeUserPrincipalName` includes the values in tests.
- `.gitignore` ignores local `out/` artifacts without hiding fixtures.
- README explains the privacy opt-in.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Repository safety guidance: no secrets or sensitive data in code or repo artifacts.
- Research entry R001 for the managed-device user fields that may be requested.

## WI-18: Add Bounded Retry Handling For Graph Throttling And Transient Failures

### Summary

Wrap Graph requests in bounded retry handling that honors `Retry-After`, uses exponential backoff when needed, and surfaces a clear terminating error after retries are exhausted.

### Problem

The current script has no retry policy. Microsoft Graph throttling and transient service errors can make otherwise valid exports fail immediately, especially in larger tenants or request-heavy runs.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add a request wrapper around Graph calls.
- Retry HTTP 429 and selected transient 5xx failures up to a bounded retry count.
- Respect `Retry-After` when present.
- Use exponential fallback delay when `Retry-After` is missing.
- Inject sleep behavior for tests so retry tests do not wait in real time.
- Fail closed with a clear error when retries are exhausted.

### Scope And Non-Goals

- Do not add parallel requests in this issue.
- Do not add Microsoft Graph JSON batching.
- Do not silently skip failed devices or policies without an explicit future partial-failure design.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Tests cover success after retry, retry-after delay capture, exponential fallback, and exhausted retries.
- Retry behavior does not require real sleeps in tests.
- Non-retryable errors still fail promptly.
- README documents retry behavior at a high level.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph throttling guidance.
- Research entry R004.

## WI-19: Include Sanitized Graph Supportability Context In Failures

### Summary

When Graph requests fail, include safe supportability context such as request URI, status code, request ID, response date, and retry count. Never include authorization headers, tokens, secrets, or request bodies.

### Problem

Plain request failures are hard to diagnose. Microsoft troubleshooting guidance points users toward request IDs and response dates, but the script does not preserve that context for support.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Capture safe response metadata where available.
- Add the metadata to final terminating errors after retry exhaustion or non-retryable failures.
- Sanitize any diagnostic output to exclude auth headers, tokens, bodies, and secret-like values.
- Add tests with synthetic exceptions carrying status and header data.

### Scope And Non-Goals

- Do not log full Graph responses by default.
- Do not write a diagnostic log file.
- Do not include tenant data beyond the requested URI path and query needed for troubleshooting.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Failure messages include safe request ID and date when synthetic responses provide them.
- Failure messages include retry count after exhausted retry attempts.
- Tests prove authorization headers or token-like values are not emitted.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph PowerShell troubleshooting guidance.
- Research entry R008.

## WI-20: Surface Graph Request Count And Document The Current Request Model

### Summary

Keep the current per-device and per-policy expansion model, but make its cost visible. Track Graph request count, expose it in verbose output and run summary, and document that batching or parallelism is intentionally deferred.

### Problem

The report can issue one or more requests per device and policy, but users cannot see that request volume. Without request-count visibility, performance and throttling behavior are harder to explain.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Track the total number of Graph requests made by the export.
- Include request count in verbose output and the structured summary.
- Keep setting-level detail intact.
- Document the current N-plus-one style expansion model honestly.

### Scope And Non-Goals

- Do not add batching.
- Do not add parallelism.
- Do not switch to a different report endpoint without a separate endpoint-specific design.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Existing fixture tests assert representative request counts.
- Summary output includes request count.
- Verbose output includes major request phases or totals.
- README documents the request model and why large tenants may take longer.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph throttling guidance.
- Microsoft Graph paging documentation.
- Research entries R003 and R004.

## WI-21: Stream CSV Rows By Default And Add PassThru For Row Objects

### Summary

Write CSV rows incrementally during normal execution after the stable header is known. Add `-PassThru` for tests and advanced callers that intentionally need row objects returned.

### Problem

The current implementation collects all expanded rows in memory before exporting. Large tenants can produce many device, policy, and setting combinations, increasing memory pressure and delaying visible output.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Write the CSV header once.
- Append rows as devices are processed in deterministic order.
- Add `-PassThru` to return row objects when explicitly requested.
- Return a structured summary by default when pass-through is not used.
- Keep tests able to inspect row objects through `-PassThru`.

### Scope And Non-Goals

- Do not create per-device temporary CSV files.
- Do not remove row-object access entirely.
- Do not add row limits that produce incomplete reports.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Default execution does not require retaining all rows before writing.
- `-PassThru` returns row objects in deterministic order.
- Header is written exactly once.
- Empty exports still write only the header.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Export-Csv documentation.
- Research entry R009.

## WI-22: Add Verbose Progress Detail And A Structured Run Summary

### Summary

Add opt-in `Write-Verbose` detail for major phases and return a structured summary object when `-PassThru` is not requested. Keep default script output quiet except for warnings and errors.

### Problem

A long-running export currently has no heartbeat, no row count, no request count, and no completion summary. Users cannot easily tell whether the script succeeded with no rows or did nothing visible.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `README.md`

### Requested Changes

- Add verbose messages for connection, path validation, device retrieval, row emission, retry events, and completion.
- Return a structured summary object by default, including export path, device count, row count, request count, retry count, elapsed time, and no-data status.
- Keep direct script execution quiet by discarding or not writing summary output unless the user calls the function directly.
- Keep `-PassThru` focused on row objects.

### Scope And Non-Goals

- Do not write status lines to stdout by default.
- Do not create a separate summary file.
- Do not add per-device `Write-Progress` unless a later issue requires it.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Function callers receive a structured summary object when not using `-PassThru`.
- `-Verbose` produces useful phase and count details.
- Direct script execution remains quiet unless warnings or errors occur.
- Tests assert summary properties without timing flakiness.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- PowerShell verbose stream behavior.
- Selected option F018-B in the preliminary findings document.

## WI-23: Emit Compliance Rows In Deterministic Device Policy And Setting Order

### Summary

Sort devices, policy states, and setting states before emitting rows. Use readable display fields first and stable identifiers as tie-breakers so repeated exports produce stable diffs.

### Problem

The current CSV order follows Microsoft Graph response order. If upstream ordering changes, users comparing report files may see noisy diffs that do not represent actual compliance changes.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `tests/PowerShell/Fixtures/`
- `README.md`

### Requested Changes

- Sort devices by device name then device ID.
- Sort policy states by policy name then policy ID.
- Sort setting states by setting name then setting ID.
- Add out-of-order fixture data proving the emitted row order.
- Keep ordering compatible with incremental CSV writing.

### Scope And Non-Goals

- Do not add user-selectable sort parameters.
- Do not require a final all-row sort that defeats streaming.
- Do not sort only by display name.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- Row order is deterministic in tests even when fixture responses are unordered.
- Duplicate or missing names fall back to stable identifiers.
- README mentions that output order is deterministic.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Selected option F025-B in the preliminary findings document.
- Research entry R001 for stable managed-device identifiers.

## WI-24: Export Raw And Normalized Compliance State Columns

### Summary

Preserve raw Graph compliance state values and add normalized state columns for grouping. Unknown future values should remain visible rather than being blanked.

### Problem

Graph enum values can vary in casing, such as `nonCompliant` versus lowercase fixture values. If the CSV only contains raw values, consumers may get split categories in Excel, Power BI, or SIEM tooling. If the script overwrites raw values, it loses source evidence.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`
- `tests/PowerShell/Fixtures/`
- `README.md`

### Requested Changes

- Keep raw Graph state columns for device, policy, and setting states.
- Add normalized state columns for device, policy, and setting states.
- Normalize predictably, using invariant casing and simple known-value cleanup where appropriate.
- Preserve unknown values in normalized form rather than returning blank.
- Add tests for representative casing variants.

### Scope And Non-Goals

- Do not hide unknown enum values.
- Do not replace raw state evidence with normalized-only values.
- Do not add a separate lookup-table document in this issue.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- CSV includes both raw and normalized state fields.
- Tests prove raw casing is preserved.
- Tests prove normalized values group expected casing variants together.
- Unknown state values remain visible.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when README changes.
- `pre-commit run --all-files` passes before commit.

### References

- Microsoft Graph compliance resources and enum-style status fields.
- Research entries R001 and R002 as schema context.

## WI-25: Update Comment-Based Help For The Final Script Contract

### Summary

After behavior changes are implemented, update comment-based help for the script entry point and public functions so `Get-Help` explains prerequisites, parameters, output, privacy behavior, no-data behavior, examples, and version notes.

### Problem

The current help is useful but incomplete for the expanded contract. Users who rely on `Get-Help` need the same critical information as README readers, especially around authentication, Windows 11 scope, output columns, safe file writing, and privacy options.

### Affected Files

Expected edit candidates:

- `scripts/Get-AllWin11ComplianceStatus.ps1`
- `README.md`
- `tests/PowerShell/Get-AllWin11ComplianceStatus.Tests.ps1`, if help completeness is tested.

### Requested Changes

- Update top-level script comment-based help.
- Update public function help for `Export-Windows11ComplianceStatusReport` and the compatibility wrapper.
- Include `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.INPUTS`, `.OUTPUTS`, and `.NOTES` sections where practical.
- Document prerequisites, required Graph permissions at a high level, output columns, no-data behavior, privacy defaults, `-WhatIf`, `-NoClobber`, `-Force`, `-PassThru`, and Graph environment behavior.
- Keep private-helper help updates focused on helpers materially changed by this implementation.

### Scope And Non-Goals

- Do not edit repository style guides without explicit protected-file authorization.
- Do not add a full help-completeness enforcement framework unless it is a small, focused test.
- Do not document secret-bearing examples.

### Protected-File Authorization

No protected instruction files are authorized for this issue.

### Acceptance Criteria

- `Get-Help` for the script and primary public function describes the final behavior accurately.
- README and comment-based help do not contradict each other.
- Help examples use safe placeholder-free commands.
- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes.
- `pre-commit run --all-files` passes before commit.

### References

- Repository PowerShell documentation standards.
- Microsoft PowerShell comment-based help conventions.
- Selected option F009-B in the preliminary findings document.
