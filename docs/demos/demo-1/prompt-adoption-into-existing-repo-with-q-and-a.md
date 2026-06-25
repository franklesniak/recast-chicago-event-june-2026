I want to adopt `https://github.com/franklesniak/copilot-repo-template` into this existing repository.

Please treat this first response as discovery and preflight only. Do not edit files, stage changes, commit, rename branches, merge/rebase/pull the template, change repository settings, install dependencies, run fixers/formatters, normalize line endings, or otherwise start implementation yet.

The only exception is the process difficulty log described below. You may create and update that one markdown file during preflight. Do not stage or commit it during preflight.

Stop after the preflight report even if you believe no questions remain.

## Process Difficulty Log

Throughout this work, maintain a durable difficulty log in the repository root at:

`_ADOPTION-DIFFICULTIES.md`

This file is explicitly allowed even during discovery/preflight. It is the only file you may create or edit during preflight unless I separately authorize implementation. Treat it as a process journal, not an implementation change.

Update this file continuously as difficulties occur, rather than waiting until the end. The goal is to avoid losing details due to context compaction, interruptions, long-running work, or later summarization.

Record every difficulty, friction point, uncertainty, tool limitation, validation failure, workaround, unexpected repository condition, user-decision dependency, and context-loss event. Be exhaustive. Do not filter out issues just because they were resolved quickly, seemed minor in hindsight, did not affect the final outcome, or were caused by tooling/context rather than the repository itself.

For each entry, include:

- Timestamp or phase
- Short title
- What happened
- Why it mattered
- Impact or risk
- How it was resolved or worked around
- Whether follow-up is still needed
- Related files, commands, tools, or docs where applicable

Also record:

- Any tool unavailable or partially unavailable
- Any command that failed, produced surprising output, or modified files
- Any validator/fixer that changed files
- Any dependency install or environment setup required
- Any place where template assumptions did not match the downstream repository
- Any decision that required user authorization
- Any manual GitHub setting that could not be changed locally
- Any time you lose direct context/history due to compaction or another transition; explicitly state what was lost and what source you used to continue
- Any mistake, false start, incorrect assumption, patch failure, or command quoting issue, even if resolved immediately

If context compaction or another history transition occurs, immediately read `_ADOPTION-DIFFICULTIES.md` and current repository state before continuing. Do not rely on memory alone.

At the end of the full process, include a final section in `_ADOPTION-DIFFICULTIES.md`:

`## Final Difficulty Summary`

This section must group all recorded difficulties by category, such as:

- Context/history retention
- Tooling availability
- Template procedure friction
- Repository-specific mismatches
- Validation failures
- Manual GitHub follow-ups
- Deferred technical debt
- Resolved vs unresolved items

Do not rely only on memory when producing the final summary. Read `_ADOPTION-DIFFICULTIES.md` and reconcile it against the conversation and command history before answering.

If no difficulties occurred, still create the file and state that explicitly.

First, fetch and review the latest upstream template repository:

- Read `TEMPLATE_UPDATE_PROCEDURE.md` in detail.
- Also review the existing-repository getting-started guide, `.template-sync/manifest.yml`, `.template-sync/instruction-contracts.yml`, and the template-sync helper scripts closely enough to follow the current adoption procedure.
- Resolve and report the exact upstream template commit SHA reviewed.
- If a `template` remote already exists, fetch it. If it does not exist, inspect the template using `git ls-remote`, a temporary clone, or another non-destructive method where practical. You may add a local `template` remote only if needed for accurate analysis, and you must report that local metadata change.
- Do not run `git pull template main`, `git merge template/main`, or `git rebase template/main`.

Then examine this downstream repository carefully:

- Determine whether this is first adoption or an initialized template sync by checking for `.template-sync/marker.yml`, `_TODO-repo-init.md`, or an equivalent committed adoption note.
- Inspect the working tree and report any existing tracked, untracked, or staged changes. Do not clean, revert, format, move, or normalize existing files during preflight.
- Inspect the current branch, remotes, default branch, existing CI, scripts, docs, issue/PR templates, security/conduct files, CODEOWNERS, agent instruction files, and language/tooling stacks.
- Preserve downstream project identity and existing repository-specific behavior.
- Assess the repository against current conventions, industry defaults, and the template’s assumptions. Look for structural or tooling deviations that should be addressed either during adoption or afterward.
- Assume I am open to reasonable repository reorganization when it materially improves template adoption, but propose and score the reorganization before implementing it.

For first adoption, apply the template’s first-adoption preflight model:

- Identify discoverable repository facts yourself.
- Do not invent manual GitHub settings, reporting channels, CODEOWNERS identities, branch protection/ruleset policy, label state, Discussions state, private vulnerability reporting state, GHES hostnames, or adoption modes.
- However, do not silently leave important governance or community decisions unresolved. If a decision is needed to configure adopted files properly, ask me directly during preflight instead of guessing.
- If I intentionally defer a required manual action or maintainer policy decision, plan to record it in `_TODO-repo-init.md`.
- If GitHub settings cannot be safely queried or changed with available tooling, distinguish between facts that are unknown, decisions I need to make, and manual follow-up actions that should be recorded.
- If GitHub settings are involved, verify current official GitHub documentation before recommending branch protection/ruleset, default branch, Discussions, label, or security-reporting configuration.

Pay special attention to these maintainer decisions:

- For public repositories, determine whether security reporting should use GitHub private vulnerability reporting, a public security contact, both, or an intentional deferral.
- If a security email or contact is needed, ask me what contact to use rather than inventing one.
- For Code of Conduct files, ask what contact email or maintainer contact wording should be listed.
- For CODEOWNERS, ask which GitHub user or team should own the adopted files if it cannot be inferred.
- If the default branch is not `main`, ask whether I want to keep the current default branch or plan a future rename to `main`.
- Determine whether labels expected by the template, such as triage or review-flow labels, already exist. If they do not, ask whether they should be created during adoption, deferred to `_TODO-repo-init.md`, or omitted.
- Determine whether Discussions, branch protection, rulesets, private vulnerability reporting, and other repository settings are enabled when tooling allows. If tooling does not allow safe verification or configuration, ask what policy I want and record any deferred manual action.

For module selection:

- Derive possible modules from the current `.template-sync/manifest.yml`; do not assume a stale module list.
- Consider all plausible module selections and meaningful permutations for this repository. You may group invalid, dominated, redundant, or nonsensical permutations, but explain why they were grouped instead of individually scored.
- Develop a defensible evaluation rubric.
- Score the options in a table.
- Recommend the best module set, including any modules that should be deferred or explicitly excluded.
- Surface unknown modules, unmapped paths, and cross-module dependencies for owner decision.

For repository structure and convention alignment:

- Identify structural changes required to align with selected template modules.
- Identify structural changes that are not strictly required but would bring the repository closer to common conventions or best practices.
- Classify each proposed structural change as one of:
  - Required for template adoption
  - Recommended during template adoption
  - Recommended as a post-adoption follow-up
  - Not recommended
- Consider meaningful alternatives and permutations rather than assuming the first reasonable layout.
- Develop a rubric and scoring table for repository reorganization options.
- Recommend which structural changes belong in the adoption itself and which should become follow-up work.
- For recommended post-adoption work, draft one or more GitHub Issues sized appropriately for a sophisticated coding agent to complete after template adoption. The issue descriptions should assume template adoption has already been completed.

For protected files and template-derived governance/collaboration files:

- Treat protected instruction files as requiring explicit path-scoped owner authorization before create/edit/delete/rename/removal. This includes `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `.cursor/rules/*.mdc`, `.hermes.md`, `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md`.
- Treat the protected-file list above as examples plus the current template procedure/manifest’s authoritative protected set. If the current upstream template defines additional protected instruction, governance, or collaboration files, include them.
- Do not treat general permission to adopt the template as permission to rewrite protected files.
- Do not treat `minimal-preservation` as protected-file edit authorization.
- Use `minimal-preservation` as the default adoption mode: preserve upstream wording and structure, substitute placeholders, remove complete delimited sections for unadopted modules, fix broken links, and record required local overrides.
- Propose `tailored` adoption only for specific files or file sets where broader downstream rewriting is genuinely justified.
- If protected files need edits, list each path, proposed decision, adoption mode, scope, reason, and exact authorization question.
- Preserve any required instruction-contract anchors unless I explicitly authorize and record a waiver/removal. Pay particular attention to retained agent protocols such as code-review handling and automated review-loop sections.

For implementation planning:

- Explain whether the adoption should use full reconciliation, first-sync delta review, or another mode supported by the current procedure.
- Explain when and how the adoption ledger should be generated or reviewed before editing protected or template-derived governance files.
- Identify validation commands that would apply to the selected modules, including first-adoption working-tree checks if template-sync support is retained.
- If newly adopted validators surface existing repository debt, plan to classify each issue as upstream-template fix, downstream-local fix, or deferred follow-up.
- Do not set or propose setting `template_sync.last_reviewed_template_commit` as durable completed state until the corresponding upstream commit has actually been reviewed through the selected adoption process and the adoption is finalized.

Your preflight response should include:

1. The upstream template commit SHA reviewed.
2. A concise summary of this repository’s current state.
3. The module-selection options, rubric, scoring table, and recommendation.
4. Any proposed repository reorganization options, rubric, scoring table, and recommendation.
5. A classification of structural changes as required for adoption, recommended during adoption, recommended post-adoption, or not recommended.
6. Draft GitHub Issue descriptions for recommended post-adoption work.
7. Protected-file candidates and the exact authorization questions needed, if any.
8. Manual GitHub settings or maintainer policy decisions that cannot be safely inferred.
9. Direct questions I need to answer before implementation, especially for security reporting, Code of Conduct contact, CODEOWNERS, labels, Discussions, branch protection/rulesets, and default branch policy.
10. A proposed validation plan.
11. Any remaining questions you cannot answer or figure out on your own.
12. A brief status note confirming that `_ADOPTION-DIFFICULTIES.md` exists and summarizing any difficulties recorded so far.

After I answer the open questions and explicitly authorize the implementation scope, proceed only within that authorized scope using explicit per-file decisions and preserving downstream customizations.

During implementation, continue updating `_ADOPTION-DIFFICULTIES.md` whenever a difficulty occurs. If implementation creates `_TODO-repo-init.md`, make sure manual follow-ups are recorded there with enough context for someone else to complete them.

Before your final implementation response:

- Re-read `_ADOPTION-DIFFICULTIES.md`.
- Add or update its `## Final Difficulty Summary`.
- Reconcile the difficulty log with the validation results and current working tree.
- In your final response, summarize the completed work, validation status, remaining manual follow-ups, and the location of the difficulty log.

---

As you work on this, I've anticipated some questions and attempted to provide answers below:

Q: Security for this public repo: enable GitHub private vulnerability reporting, publish a security email/contact, both, or defer? If email/contact is needed, what should it be?

A: I will enable GitHub private vulnerability reporting; note this as an immediate post-implementation follow-up in _TODO-repo-init.md. I will not use an email address. Configure the repository as if this is done.

---

Q: What contact method should CODE_OF_CONDUCT.md list?

A: Contact the repository maintainers using the contact information on their public GitHub profiles

---

Q: Should CODEOWNERS use @franklesniak, another user, or a team?

A: Yes, use @franklesniak

---

Q: Keep default branch master, or plan a later rename to main?

A: Plan a post-implementation rename to main. I don't know how to do this, so include explicit instructions for how I should do this using the web interface.

---

Q: Should adoption create a triage label, defer it to _TODO-repo-init.md, or omit it from templates?

A: Defer it to _TODO-repo-init.md; I will do it immediately post-implementation. Configure the repository as if this is done.

---

Q: Enable GitHub Discussions, or leave disabled and keep discussion links commented out?

A: I will enable GitHub Discussions; note this as an immediate post-implementation follow-up in _TODO-repo-init.md. Configure the repository as if this is done.

---

Q: Branch policy after CI exists: repository ruleset, classic branch protection, leave unchanged, or defer?

A: I will implement this after CI exists and the repository is fully initialized. Assume we will use whatever is the more modern approach. I don't know how to do this, so include explicit instructions for how I should do this using the web interface.

---

Q: Agent files: which of Copilot, Codex/AGENTS.md, Cursor, Claude, Hermes, Gemini should be adopted?

A: All of them

---

Q: Is github.com the correct host, with no GHES override?

A: Yes, GitHub.com

---

Q: Approve README.md as locally owned/tailored, preserving ROMSorter content and adding only development/adoption notes?

A: Yes; but only add development/adoption notes to README.md if they are critical "need to know" for adopters of ROMSorter. Otherwise, I'm fine documenting them, but they should be placed in a separate document.

---

Q: Approve renaming LICENSE.txt to LICENSE, preserving the 2020 MIT license text?

A: Yes

---

Q: Should a dedicated implementation branch be created?

A: Yes.

---

Q: Confirm package metadata for adopted Markdown tooling.

A: I'd prefer to use `ROMSorter` if/where capitalization is allowed. Where lowercase is required, then `romsorter` is acceptable. The description on the GitHub repo is: `A scripted, repeatable, customizable approach to sorting arcade machines/ROMs for emulation and preservation`. The author is `Frank Lesniak`. The repo is public, not private. However, NPM packages should remain private. The keywords for the repo are: `emulator`, `emulation`, `mame`, `mame2003` `fbneo`, `mame2010`, `mame2003plus`.

---

Q: May implementation install/use local validation dependencies as needed, especially npm ci and pre-commit setup?

A: Yes

---

Q: If PSScriptAnalyzer warnings appear, is it permissible to set CI to first-adoption mode and file cleanup follow-up rather than blocking adoption on all warning debt?

A: Yes
