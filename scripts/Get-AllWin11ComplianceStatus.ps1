param (
    [Parameter(Mandatory = $true)]
    [string]$ExportPath
)

Write-Host "Authenticating to Microsoft Graph..."
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "DeviceManagementConfiguration.Read.All"

Write-Host "Querying Windows managed devices..."
try {
    $devices = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$filter=operatingSystem eq 'Windows'"
    if (-not $devices.value) {
        Write-Host "No Windows devices found or insufficient permissions."
        exit
    }
    Write-Host "Found $($devices.value.Count) Windows devices."
} catch {
    Write-Error "Failed to query managed devices: $_"
    exit
}

# Discover all unique compliance setting names (columns)
$allSettingNames = @{}

$deviceCounter = 0
foreach ($device in $devices.value) {
    $deviceCounter++
    Write-Host "[$deviceCounter/$($devices.value.Count)] Processing $($device.deviceName)..."
    try {
        $policyStates = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/deviceCompliancePolicyStates"
        foreach ($policy in $policyStates.value) {
            $settingStates = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/deviceCompliancePolicyStates/$($policy.id)/settingStates"
            foreach ($setting in $settingStates.value) {
                $colName = if ($setting.settingName) { $setting.settingName } elseif ($setting.setting) { $setting.setting } else { $null }
                if ($colName) {
                    $allSettingNames[$colName] = $true
                }
            }
        }
    } catch {
        Write-Warning "Failed to get policy/settings for device $($device.deviceName): $_"
    }
}
$settingNameList = $allSettingNames.Keys | Sort-Object

# Build output rows (one per device)
$outputRows = @()
$deviceCounter = 0
foreach ($device in $devices.value) {
    $deviceCounter++
    Write-Host "Building report row for $($device.deviceName) ($deviceCounter/$($devices.value.Count))..."
    $row = [ordered]@{
        DeviceName      = $device.deviceName
        UserPrincipal   = $device.userPrincipalName
        DeviceId        = $device.id
        ComplianceState = $device.complianceState
        LastSync        = $device.lastSyncDateTime
    }
    foreach ($settingCol in $settingNameList) {
        $row[$settingCol] = 'none'
    }
    try {
        $policyStates = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/deviceCompliancePolicyStates"
        foreach ($policy in $policyStates.value) {
            $settingStates = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/deviceCompliancePolicyStates/$($policy.id)/settingStates"
            foreach ($setting in $settingStates.value) {
                $colName = if ($setting.settingName) { $setting.settingName } elseif ($setting.setting) { $setting.setting } else { $null }
                if ($colName) {
                    $row[$colName] = $setting.state
                }
            }
        }
    } catch {
        Write-Warning "Failed to build report row for $($device.deviceName): $_"
    }
    $outputRows += [PSCustomObject]$row
}

Write-Host "Exporting results to $ExportPath ..."
try {
    $outputRows | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Export completed: $ExportPath"
} catch {
    Write-Error "Failed to export results: $_"
}
