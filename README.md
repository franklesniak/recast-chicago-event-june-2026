# Recast Chicago Event June 2026

This repository contains a prepared PowerShell demo script for reviewing agent-assisted script changes with local tests, analyzers, and repository rules.

The main script is [`scripts/Get-AllWin11ComplianceStatus.ps1`](scripts/Get-AllWin11ComplianceStatus.ps1). It signs in to Microsoft Graph, queries Intune managed Windows devices, reads device compliance policy setting states, and exports a CSV report.

## What Is In This Repo

- `scripts/Get-AllWin11ComplianceStatus.ps1` - demo copy of the compliance report script
- `tests/PowerShell/` - Pester tests and fake Microsoft Graph JSON fixtures
- `.github/instructions/` - retained Markdown, PowerShell, JSON, YAML, and Git attributes guidance
- `.github/workflows/` - GitHub Actions validation for pre-commit, Markdown, PowerShell, and data files
- `.template-sync/` - retained template-sync support for future maintenance against `franklesniak/copilot-repo-template`

The tests and fixtures must not use live tenant data, real device names, credentials, customer identifiers, or private local paths.

## Local Validation

Install Node.js dependencies for Markdown tooling:

```bash
npm install
```

Install pre-commit with `pip` or `pipx`, then run:

```bash
pre-commit run --all-files
```

Run Markdown validation:

```bash
npm run lint:md
npm run lint:md:links
npm run lint:md:nested
```

Run PowerShell validation:

```powershell
Invoke-ScriptAnalyzer -Path .\scripts\Get-AllWin11ComplianceStatus.ps1 -Settings .\.github\linting\PSScriptAnalyzerSettings.psd1
Invoke-Pester -Path tests/ -Output Detailed
```

Run template-sync adoption validation:

```bash
python .template-sync/scripts/validate_downstream_adoption.py --require-marker
```

PowerShell CI currently uses the PSScriptAnalyzer `first-adoption` gate because the copied demo script intentionally retains warning-level debt for the follow-up code review task.

## Development Notes

Before changing the script, read [`.github/copilot-instructions.md`](.github/copilot-instructions.md) and [`.github/instructions/powershell.instructions.md`](.github/instructions/powershell.instructions.md).

Keep script behavior changes small and reviewable. Local tests should prove behavior with mocked or fixture data only; live Microsoft Graph or Intune validation is a separate human-controlled check.

## License

MIT License. See [LICENSE](LICENSE).
