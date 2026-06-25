## Description

<!-- Summarize the change and why it is needed. -->

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Configuration or tooling change
- [ ] Template-sync maintenance

## Checklist

- [ ] I followed `.github/copilot-instructions.md` and the applicable files under `.github/instructions/`.
- [ ] I kept secrets, tenant identifiers, real device names, and personal data out of committed files.
- [ ] I added or updated tests where appropriate.
- [ ] I updated documentation where behavior or workflows changed.
- [ ] I ran `pre-commit run --all-files` or documented why it could not be run.

<!-- template-sync: begin powershell-reference-only -->
### PowerShell

- [ ] Pester passes locally: `Invoke-Pester -Path tests/ -Output Detailed`
- [ ] PSScriptAnalyzer was reviewed locally:
  `Invoke-ScriptAnalyzer -Path .\scripts\Get-AllWin11ComplianceStatus.ps1 -Settings .\.github\linting\PSScriptAnalyzerSettings.psd1`

<!-- template-sync: end powershell-reference-only -->
<!-- template-sync: begin data-ci-reference-only -->
### Data Files And Workflows

- [ ] Markdown, JSON, YAML, and GitHub Actions changes pass the retained validation hooks.
- [ ] Mocked Microsoft Graph fixtures contain no real tenant, device, or user data.

<!-- template-sync: end data-ci-reference-only -->

## Validation

<!-- Paste the commands run and their results. -->

## Related Issues

<!-- Link related issues, for example: Closes #123 -->
