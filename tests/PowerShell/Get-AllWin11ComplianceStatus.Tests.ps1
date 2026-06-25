BeforeAll {
    $script:RepoRoot = Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "../..")
    $script:ScriptPath = Join-Path -Path $script:RepoRoot -ChildPath "scripts/Get-AllWin11ComplianceStatus.ps1"
    $script:FixtureRoot = Join-Path -Path $PSScriptRoot -ChildPath "Fixtures/Graph"
}

Describe "Get-AllWin11ComplianceStatus.ps1" {
    It "is committed in the expected demo script location" {
        Test-Path -LiteralPath $script:ScriptPath -PathType Leaf | Should -BeTrue
    }

    It "parses as PowerShell without syntax errors" {
        $tokens = $null
        $errors = $null

        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:ScriptPath,
            [ref]$tokens,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It "requests the Microsoft Graph Intune read scopes used by the demo" {
        $content = Get-Content -LiteralPath $script:ScriptPath -Raw

        $content | Should -Match "DeviceManagementManagedDevices\.Read\.All"
        $content | Should -Match "DeviceManagementConfiguration\.Read\.All"
    }

    It "does not contain private local source paths or tenant-shaped fixture data" {
        $content = Get-Content -LiteralPath $script:ScriptPath -Raw

        $content | Should -Not -Match "C:\\Users\\"
        $content | Should -Not -Match "VSO\\"
        $content | Should -Not -Match "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
    }
}

Describe "local Microsoft Graph fixtures" {
    It "keeps every fixture as valid strict JSON" {
        $fixtures = Get-ChildItem -LiteralPath $script:FixtureRoot -Filter "*.json" -File

        $fixtures | Should -Not -BeNullOrEmpty
        foreach ($fixture in $fixtures) {
            { Get-Content -LiteralPath $fixture.FullName -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    It "includes a paged managed-devices example for future behavior tests" {
        $pageOne = Get-Content -LiteralPath (Join-Path -Path $script:FixtureRoot -ChildPath "managed-devices-page-1.json") -Raw |
            ConvertFrom-Json

        $pageOne."@odata.nextLink" | Should -Not -BeNullOrEmpty
        $pageOne.value.Count | Should -Be 1
    }
}
