# Contributing

Thanks for helping improve this PowerShell demo repository. Keep changes small, self-contained, and backed by local validation evidence.

## Setup

Clone the repository:

```bash
git clone https://github.com/franklesniak/recast-chicago-event-june-2026.git
cd recast-chicago-event-june-2026
```

Install Node.js dependencies for Markdown tooling:

```bash
npm install
```

Install `pre-commit` with `pip` or `pipx`:

```bash
pip install pre-commit
pre-commit install
```

Python is needed for pre-commit hooks and retained template-sync helper scripts. It is tooling for this repository, not adopted Python project source.

## Validation

Run the aggregate hook gate before opening a pull request:

```bash
pre-commit run --all-files
```

Run Markdown checks when documentation changes:

```bash
npm run lint:md
npm run lint:md:links
npm run lint:md:nested
```

Run PowerShell checks when scripts or tests change:

```powershell
Invoke-ScriptAnalyzer -Path .\scripts\Get-AllWin11ComplianceStatus.ps1 -Settings .\.github\linting\PSScriptAnalyzerSettings.psd1
Invoke-Pester -Path tests/ -Output Detailed
```

Run the downstream template-sync validator after module pruning, marker changes, or retained template-surface changes:

```bash
python .template-sync/scripts/validate_downstream_adoption.py --require-marker
```

## Rules

- Do not commit secrets, credentials, tenant IDs, real device names, customer data, or private local paths.
- Do not contact Microsoft Graph, Intune, or any network service from tests.
- Use fake local fixtures under `tests/PowerShell/Fixtures/`.
- Read [`.github/copilot-instructions.md`](.github/copilot-instructions.md) before making changes.
- Read the relevant retained style guide under `.github/instructions/` before editing matching files.
- Include any pre-commit auto-fixes in the same change as the related edit.

## Pull Requests

In each PR, include:

- What changed
- Tests or validation commands run
- Any skipped validation and why
- Remaining risk that needs human review, especially for live Graph behavior

Open issues at <https://github.com/franklesniak/recast-chicago-event-june-2026/issues>.
