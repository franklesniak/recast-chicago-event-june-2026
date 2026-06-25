<!-- markdownlint-disable MD013 -->

# GitHub Issue Style Guide

## Metadata

- **Status:** Draft
- **Owner:** Repository Maintainers
- **Last Updated:** 2026-06-25
- **Scope:** Defines the GitHub Issue format to use for implementation-ready work items generated from `Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`.
- **Related:** [`Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`](Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md), [`Get-AllWin11ComplianceStatus-sequenced-priority-findings-research.md`](Get-AllWin11ComplianceStatus-sequenced-priority-findings-research.md)

## Example Issues Reviewed

- [Issue #785: Document Cross-Module Markdown Link Hygiene for Template-Managed Repositories](https://github.com/franklesniak/copilot-repo-template/issues/785)
- [Issue #779: Extend YAML guidance for `workflow_dispatch` input default fallbacks](https://github.com/franklesniak/copilot-repo-template/issues/779)
- [Issue #773: Clarify the Docs Metadata `<revision>` Baseline and Reset Rule](https://github.com/franklesniak/copilot-repo-template/issues/773)
- [Issue #756: WI-06: Add Azure Pipelines CI module while retaining GitHub Actions as primary](https://github.com/franklesniak/copilot-repo-template/issues/756)
- [Issue #752: WI-02: Add host-provider placeholder materialization for Azure DevOps adoption](https://github.com/franklesniak/copilot-repo-template/issues/752)

## Observed Pattern

Strong issues in this style are not short prompts. They are self-contained implementation contracts. A contributor should be able to open the issue cold, understand the problem, know which files to inspect or edit, avoid known traps, and validate completion without asking for hidden context.

Use this default section order when it fits the work item:

1. `## Summary`
2. `## Problem`
3. `## Affected files`
4. `## Requested changes`
5. `## Scope and non-goals`
6. `## Guardrails`
7. `## Protected-file authorization`
8. `## Metadata bump`
9. `## Acceptance criteria`
10. `## References`

Omit sections that do not apply, but do not omit safety, authorization, or validation information merely to keep the issue shorter.

## Title

Write the title as a specific implementation outcome.

- Prefer an imperative verb plus the affected contract: `Add Windows 11 OS-build filtering to the compliance export`.
- Use a work-item prefix only when the issue belongs to a numbered sequence or epic: `WI-06: Add Azure Pipelines CI module while retaining GitHub Actions as primary`.
- Include the durable noun the implementer will search for, such as `Graph retry`, `CSV no-data header`, or `PowerShell version contract`.
- Avoid titles that only restate a symptom, such as `Fix report` or `Improve script`.

## Summary

State the selected fix in one short paragraph. Include the intended user-visible outcome and the primary files or surfaces affected.

The summary should answer:

- What will be different when the issue is complete?
- Who benefits from the change?
- Which major behavior or contract is intentionally preserved?

## Problem

Explain why the current state is insufficient. Include the evidence needed to understand the failure mode without reading the whole repository.

Good problem sections:

- identify the current behavior;
- explain the consequence in user, security, reliability, or maintenance terms;
- mention whether the behavior is already covered by tests;
- avoid vague claims such as "make it better" or "clean this up".

## Affected Files

List concrete edit candidates and separate them by confidence when needed.

Use these labels:

- `Expected edit candidates:` for files the issue is expected to change.
- `Conditional edit candidates:` for files that change only if a specific design path is selected during implementation.
- `Inspect-only candidates:` for files that must be reviewed but should not be edited unless the inspection finds a concrete need.

When protected files are present, say so explicitly and keep the authorization section aligned with the file list.

## Requested Changes

Describe the selected implementation plainly enough that a cold reader can act on it.

Requested changes should:

- use normative language when behavior is required;
- identify parameters, helper functions, tests, and documentation updates by name where known;
- state default behavior and opt-in behavior separately;
- identify sequencing constraints from prerequisite findings;
- include any user-visible error or warning contract that matters.

For complex behavior, include a short compliant example and, when useful, one non-compliant example. Keep examples minimal and tied to the requested change.

## Scope And Non-Goals

Record boundaries aggressively. This prevents an implementation issue from turning into an unreviewable refactor.

Use this section to say:

- which related findings are intentionally deferred;
- which files must not be changed;
- which authentication, cloud, or platform scenarios are out of scope;
- which compatibility behavior must be preserved.

## Guardrails

Use guardrails for safety and correctness constraints that should remain true throughout implementation.

Common guardrails include:

- no secrets, tokens, credential-bearing URLs, tenant exports, or real device/user data in repository files;
- no weakening of path validation, file write safety, or Graph permission boundaries;
- no live Graph calls in default tests;
- no edits to protected instruction files unless the issue explicitly authorizes the exact file and change;
- no broad refactors beyond the selected fix.

## Protected-File Authorization

Include this section whenever a protected instruction file or style guide is in scope.

State:

- the exact protected file;
- the exact change authorized;
- who authorized it when known;
- which protected files remain out of scope.

If no protected files are in scope, the section may say: `No protected instruction files are authorized for this issue.`

## Metadata Bump

Include this section when a file with a `Last Updated` metadata field or `**Version:**` line is intentionally edited.

State:

- which file needs a metadata update;
- how to compute the date and revision;
- that the implementer must re-check the current baseline at finalization.

Do not hardcode stale expected values unless the issue also instructs the implementer to recompute them.

## Acceptance Criteria

Acceptance criteria should be the longest and most precise section for implementation-heavy issues.

Write criteria as checkable bullets. Cover:

- behavior changes;
- tests and fixtures;
- documentation updates;
- safety and privacy constraints;
- validation commands;
- expected no-change areas.

Every issue generated from the compliance-status backlog should include at least:

- `Invoke-Pester -Path tests/PowerShell -Output Detailed` passes.
- `npm run lint:md` passes when Markdown files are changed.
- `pre-commit run --all-files` passes before commit.

Add narrower validation commands when a work item touches only a specific surface.

## References

References must be inspectable and tied to the requested change.

Use primary sources where practical:

- Microsoft Learn for Graph, PowerShell, Intune, Windows release information, and Azure cloud behavior;
- GitHub Docs for GitHub issue, workflow, and repository behavior;
- repository files for current code and tests.

Each reference should include a short interpretation explaining why it matters. Avoid dumping links without saying how they affect the issue.

## Tone And Detail

Use plain, direct engineering prose.

- Be precise rather than clever.
- Prefer "MUST", "SHOULD", and "MAY" only when the level matters.
- Keep issue text self-contained; do not require private context, local machine paths, or agent session state.
- Avoid unresolved placeholder language. Use an explicit `Open question` only when implementation genuinely cannot proceed without owner input.

