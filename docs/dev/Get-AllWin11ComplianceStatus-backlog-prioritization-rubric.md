<!-- markdownlint-disable MD013 -->

# Get-AllWin11ComplianceStatus Backlog Prioritization Rubric

## Metadata

- **Status:** Draft
- **Owner:** Repository Maintainers
- **Last Updated:** 2026-06-25
- **Scope:** Defines the weighted scoring model used to prioritize findings from `docs/dev/Get-AllWin11ComplianceStatus-improvement-opps.md` into very high, high, medium-high, medium, medium-low, low, and very low priority categories.
- **Related:** [`Get-AllWin11ComplianceStatus-improvement-opps.md`](Get-AllWin11ComplianceStatus-improvement-opps.md), [`scripts/Get-AllWin11ComplianceStatus.ps1`](../../scripts/Get-AllWin11ComplianceStatus.ps1)

## Primary Sources Consulted

- [NIST SP 800-30 Rev. 1, Guide for Conducting Risk Assessments](https://csrc.nist.gov/pubs/sp/800/30/r1/final): prioritization should support risk-informed decisions by leaders and maintainers, not just code-local preferences.
- [NIST SP 800-218, Secure Software Development Framework](https://csrc.nist.gov/pubs/sp/800/218/final): secure development work should reduce vulnerabilities, mitigate impact, and address root causes.
- [NIST Risk Management Framework](https://csrc.nist.gov/projects/risk-management): priority should account for categorization, control selection, implementation, assessment, authorization, and monitoring concerns.
- [NIST Privacy Framework](https://www.nist.gov/privacy-framework): findings involving user and device identifiers should be scored for privacy-risk management, not only functional correctness.
- [NSA/CISA secure-by-design guidance announcement](https://www.nsa.gov/Press-Room/Press-Releases-Statements/Press-Release-View/Article/3558946/nsa-and-partners-issue-additional-guidance-for-secure-by-design-software/): security outcomes, transparency, and leadership accountability justify higher weight for user-safety and operational correctness than implementation convenience.
- [Microsoft Graph throttling guidance](https://learn.microsoft.com/graph/throttling#best-practices-to-handle-throttling): Graph clients should account for throttling, `Retry-After`, and bounded retry behavior.
- [Microsoft Graph best practices](https://learn.microsoft.com/graph/best-practices-concept): Graph clients should handle paging, expected errors, and service behavior predictably.
- [Microsoft Graph query parameters](https://learn.microsoft.com/graph/query-parameters): Graph clients should use query parameters such as `$select`, `$filter`, and paging controls to shape reliable and efficient responses.
- [Microsoft Graph PowerShell authentication commands](https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands?view=graph-powershell-1.0): authentication, scopes, and Graph context are first-class operational concerns.
- [PowerShell ShouldProcess guidance](https://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.6): file-writing and state-changing functions should make preview and confirmation behavior clear where feasible.
- [Repository PowerShell instructions](../../.github/instructions/powershell.instructions.md): repository-local conventions govern script style, strict-mode placement, path handling, help, and Pester expectations.
- [Repository documentation instructions](../../.github/instructions/docs.instructions.md): generated backlog documents should be self-contained, traceable, and drift-resistant.

## Scoring Method

Each finding receives a score from 0 to 5 for every criterion.

| Score | Meaning |
| --- | --- |
| 0 | The criterion does not apply to this finding. |
| 1 | The finding has minor relevance to the criterion. |
| 2 | The finding has noticeable but limited relevance. |
| 3 | The finding materially affects the criterion for common use. |
| 4 | The finding strongly affects the criterion for important use cases. |
| 5 | The finding directly affects the criterion in a critical, recurring, or high-consequence way. |

Weighted score is calculated as:

```text
sum((criterion score / 5) * criterion weight)
```

The maximum weighted score is 100.

## Weighted Criteria

| ID | Criterion | Weight | Primary perspective | Scoring guidance |
| --- | --- | ---: | --- | --- |
| C01 | Compliance decision correctness | 14 | Business stakeholder, cybersecurity leader | Scores high when the finding can cause the report to answer the wrong compliance question, misclassify scope, or distort remediation decisions. |
| C02 | Security and privacy risk reduction | 12 | Cybersecurity technical expert, privacy stakeholder | Scores high when the finding reduces exposure of tenant data, credentials, identifiers, unsafe file access, over-permissioning, or insecure defaults. |
| C03 | Data integrity and auditability | 10 | Compliance officer, documentation lead | Scores high when the finding affects whether the CSV can serve as reliable evidence, preserve stable identifiers, explain source data, or support repeatable audit review. |
| C04 | Operational reliability and failure clarity | 10 | Operations owner, project manager | Scores high when the finding affects retry behavior, throttling, partial failures, no-data interpretation, dependency failures, or supportability during real tenant runs. |
| C05 | User actionability and experience | 8 | User experience expert, junior team member | Scores high when the finding affects first-run success, error clarity, progress visibility, command discoverability, or safe use by non-experts. |
| C06 | Testability and regression containment | 8 | Pester testing enthusiast, maintainer | Scores high when the finding enables meaningful automated coverage, prevents high-risk regressions, or exposes untested entry points and edge cases. |
| C07 | Maintainability and evolvability | 7 | Technical lead, future maintainer | Scores high when the finding reduces brittle coupling, centralizes contracts, separates responsibilities, or lowers future change risk. |
| C08 | Scalability, performance, and service-cost control | 7 | Technical expert, operations owner | Scores high when the finding affects request volume, memory growth, throttling likelihood, payload size, or runtime predictability. |
| C09 | Standards and repository conformance | 6 | Repository maintainer, documentation lead | Scores high when the finding violates or strengthens repository rules, PowerShell conventions, documentation contracts, or validation expectations. |
| C10 | Stakeholder reach and deployment diversity | 5 | Program owner, public-sector stakeholder | Scores high when the finding affects many user groups, national cloud tenants, automation contexts, or common workstation environments. |
| C11 | Evidence confidence and reproducibility | 4 | Reviewer, auditor | Scores high when the finding is supported by source code, tests, official documentation, local validation, or easily reproduced behavior. |
| C12 | Dependency leverage and sequencing impact | 3 | Project manager, technical lead | Scores high when fixing the finding unlocks several downstream fixes or must precede higher-value work. This criterion can pull a lower intrinsic priority finding into the sequenced work list as a prerequisite without changing its intrinsic score. |
| C13 | Documentation and support-load reduction | 3 | Documentation lead, support owner | Scores high when the finding reduces repeated explanation, onboarding friction, issue churn, or ambiguous troubleshooting. |
| C14 | Business urgency and reporting value | 2 | Business stakeholder, project sponsor | Scores high when the finding materially improves the timeliness or usefulness of near-term reporting decisions. |
| C15 | Implementation effort, churn, and scope fit | 1 | Maintainer, project manager | Scores high when the finding can be addressed with low churn and tight scope. This criterion is intentionally low-weighted so convenience does not outrank correctness, security, or legitimate usability concerns. |

## Priority Scale

The score-to-priority mapping is intentionally non-linear. The top categories require both a high score and a high-consequence profile so the backlog does not over-label ordinary cleanup as urgent.

| Priority | Weighted score | Additional gate |
| --- | ---: | --- |
| Very high | 76.00-100.00 | At least one of C01, C02, C03, or C04 must score 5. |
| High | 62.00-75.99 | No extra gate. |
| Medium-high | 48.00-61.99 | No extra gate. |
| Medium | 34.00-47.99 | No extra gate. |
| Medium-low | 22.00-33.99 | No extra gate. |
| Low | 12.00-21.99 | No extra gate. |
| Very low | 0.00-11.99 | No extra gate. |

If a finding scores 76.00 or higher but does not satisfy the very-high gate, assign **High**. This prevents broad but non-critical work from outranking findings that directly affect correctness, security/privacy, auditability, or operational reliability.

## Dependency Rule

Priority labels describe intrinsic importance. Sequencing may still include a lower-priority prerequisite before a high-priority item when the prerequisite is needed to implement or validate the higher-priority item safely.

Use this dependency rule when building `Get-AllWin11ComplianceStatus-sequenced-priority-findings-preliminary.md`:

1. Include every finding whose intrinsic priority is very high, high, or medium-high.
2. Add lower-priority prerequisites only when the prerequisite is explicitly needed by an included finding.
3. Keep the prerequisite's intrinsic priority label unchanged.
4. If two or more findings depend on each other in a circular way, group them as one unit of work and explain the cycle.
5. Do not promote a finding solely because it is easy, stylistic, or convenient to fix while touching adjacent code.

## Scoring Notes

- Prefer source-backed evidence over speculation. When evidence is incomplete, lower C11 and document the uncertainty in the finding.
- Treat exported tenant identifiers as privacy-relevant even when the script is read-only.
- Treat report-scope accuracy as a business and security issue, not only a naming issue.
- Treat tests as risk controls. Missing tests score higher when the uncovered behavior affects report correctness, failure handling, privacy, or file writes.
- Treat implementation effort as a tie-breaker. It should not move a correctness or security issue out of the high-priority range.

