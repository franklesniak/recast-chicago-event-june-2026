BeforeAll {
    $script:RepoRoot = Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "../..")
    $script:ScriptPath = Join-Path -Path $script:RepoRoot -ChildPath "scripts/Get-AllWin11ComplianceStatus.ps1"
    $script:FixtureRoot = Join-Path -Path $PSScriptRoot -ChildPath "Fixtures/Graph"

    . $script:ScriptPath
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

Describe "Microsoft Graph endpoint builders" {
    It "builds the managed-device URI with the selected service root, v1.0 path, Windows filter, and projection" {
        $uri = Get-GraphManagedDeviceUri -ServiceRoot "https://graph.microsoft.us" -ApiVersion "v1.0"

        $uri | Should -Be 'https://graph.microsoft.us/v1.0/deviceManagement/managedDevices?$filter=operatingSystem%20eq%20%27Windows%27&$select=id%2CdeviceName%2CuserPrincipalName%2CcomplianceState%2ClastSyncDateTime%2CoperatingSystem%2CosVersion'
    }

    It "builds the policy-state URI from a managed-device identifier" {
        $uri = Get-GraphDeviceCompliancePolicyStateUri -DeviceId "fixture-device-001"

        $uri | Should -Be 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/fixture-device-001/deviceCompliancePolicyStates?$select=id%2CdisplayName%2Cstate'
    }

    It "builds the setting-state URI from managed-device and policy identifiers" {
        $uri = Get-GraphDeviceCompliancePolicySettingStateUri `
            -DeviceId "fixture-device-001" `
            -PolicyId "fixture-policy-001"

        $uri | Should -Be 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/fixture-device-001/deviceCompliancePolicyStates/fixture-policy-001/settingStates?$select=id%2CsettingName%2Csetting%2Cstate'
    }

    It "uses Graph-provided next links without rebuilding or rewriting them" {
        $initialUri = Get-GraphManagedDeviceUri
        $nextLink = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$skiptoken=fixture-page-2'
        $script:RequestedGraphUris = [System.Collections.Generic.List[string]]::new()
        $script:GraphResponses = @{
            $initialUri = [pscustomobject]@{
                value = @(
                    [pscustomobject]@{
                        id = "fixture-device-001"
                    }
                )
                "@odata.nextLink" = $nextLink
            }
            $nextLink = [pscustomobject]@{
                value = @(
                    [pscustomobject]@{
                        id = "fixture-device-002"
                    }
                )
            }
        }
        $graphRequest = {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Uri
            )

            $script:RequestedGraphUris.Add($Uri)
            return $script:GraphResponses[$Uri]
        }

        $devices = @(Invoke-GraphCollectionRequest -InitialUri $initialUri -GraphRequest $graphRequest)

        $devices.Count | Should -Be 2
        $script:RequestedGraphUris[0] | Should -Be $initialUri
        $script:RequestedGraphUris[1] | Should -Be $nextLink
    }
}

Describe "Export-WindowsComplianceStatusReport" {
    It "exports fixture-backed compliance rows without live Microsoft Graph access" {
        $managedDevicesPageOne = Get-Content -LiteralPath (Join-Path -Path $script:FixtureRoot -ChildPath "managed-devices-page-1.json") -Raw |
            ConvertFrom-Json
        $managedDevicesPageTwo = Get-Content -LiteralPath (Join-Path -Path $script:FixtureRoot -ChildPath "managed-devices-page-2.json") -Raw |
            ConvertFrom-Json
        $policyStates = Get-Content -LiteralPath (Join-Path -Path $script:FixtureRoot -ChildPath "compliance-policy-states-fixture-device-001.json") -Raw |
            ConvertFrom-Json
        $settingStates = Get-Content -LiteralPath (Join-Path -Path $script:FixtureRoot -ChildPath "setting-states-fixture-device-001-fixture-policy-001.json") -Raw |
            ConvertFrom-Json

        $initialManagedDeviceUri = Get-GraphManagedDeviceUri
        $managedDeviceNextLink = Get-GraphPropertyValue -InputObject $managedDevicesPageOne -Name "@odata.nextLink"
        $deviceOnePolicyUri = Get-GraphDeviceCompliancePolicyStateUri -DeviceId "fixture-device-001"
        $deviceTwoPolicyUri = Get-GraphDeviceCompliancePolicyStateUri -DeviceId "fixture-device-002"
        $deviceOneSettingUri = Get-GraphDeviceCompliancePolicySettingStateUri `
            -DeviceId "fixture-device-001" `
            -PolicyId "fixture-policy-001"
        $script:RequestedGraphUris = [System.Collections.Generic.List[string]]::new()
        $script:GraphResponses = @{
            $initialManagedDeviceUri = $managedDevicesPageOne
            $managedDeviceNextLink = $managedDevicesPageTwo
            $deviceOnePolicyUri = $policyStates
            $deviceTwoPolicyUri = [pscustomobject]@{
                value = @()
            }
            $deviceOneSettingUri = $settingStates
        }
        $graphRequest = {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Uri
            )

            $script:RequestedGraphUris.Add($Uri)
            if (-not $script:GraphResponses.ContainsKey($Uri)) {
                throw "Unexpected Graph URI: $Uri"
            }

            return $script:GraphResponses[$Uri]
        }
        $exportPath = Join-Path -Path $TestDrive -ChildPath "compliance.csv"

        $rows = @(
            Export-WindowsComplianceStatusReport `
                -ExportPath $exportPath `
                -SkipGraphConnect `
                -GraphRequest $graphRequest
        )

        Test-Path -LiteralPath $exportPath -PathType Leaf | Should -BeTrue
        $rows.Count | Should -Be 2
        $rows[0].DeviceName | Should -Be "Fixture-Windows-01"
        $rows[0]."Require BitLocker" | Should -Be "compliant"
        $rows[1].DeviceName | Should -Be "Fixture-Windows-02"
        $rows[1]."Require BitLocker" | Should -Be "none"
        $script:RequestedGraphUris | Should -Contain $managedDeviceNextLink

        $csvRows = Import-Csv -LiteralPath $exportPath
        $csvRows.Count | Should -Be 2
        $csvRows[0].DeviceId | Should -Be "fixture-device-001"
        $csvRows[0]."Secure boot enabled" | Should -Be "compliant"
    }
}
