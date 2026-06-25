param (
    [string]$ExportPath
)


function Get-GraphCollectionUri {
    # .SYNOPSIS
    # Builds a Microsoft Graph collection URI.
    #
    # .DESCRIPTION
    # Builds an initial Microsoft Graph collection URI from a service root,
    # API version, path segments, and optional query parameters. This helper is
    # for initial requests only; Graph-provided next links must be followed as
    # opaque URI strings.
    #
    # .PARAMETER ServiceRoot
    # The Microsoft Graph service root to use.
    #
    # .PARAMETER ApiVersion
    # The Microsoft Graph API version path segment to use.
    #
    # .PARAMETER PathSegment
    # The collection path segments to append after the API version.
    #
    # .PARAMETER Filter
    # The optional OData filter expression for the initial collection request.
    #
    # .PARAMETER Select
    # Optional projection fields for the initial collection request.
    #
    # .EXAMPLE
    # Get-GraphCollectionUri -ServiceRoot 'https://graph.microsoft.com' -ApiVersion 'v1.0' -PathSegment @('deviceManagement', 'managedDevices')
    #
    # .INPUTS
    # None. This helper does not accept pipeline input.
    #
    # .OUTPUTS
    # System.String. The absolute Microsoft Graph collection URI.
    #
    # .NOTES
    # Private helper. Positional parameter binding is an internal-caller contract only.
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceRoot,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$PathSegment,

        [string]$Filter,

        [string[]]$Select
    )

    Set-StrictMode -Version Latest

    $arrEncodedPathSegment = @(
        foreach ($strPathSegment in $PathSegment) {
            [System.Uri]::EscapeDataString($strPathSegment)
        }
    )

    $strBaseUri = "{0}/{1}/{2}" -f $ServiceRoot.TrimEnd('/'), $ApiVersion.Trim('/'), ($arrEncodedPathSegment -join '/')
    $arrQueryParameter = @()

    if (-not [string]::IsNullOrWhiteSpace($Filter)) {
        $arrQueryParameter += '$filter={0}' -f [System.Uri]::EscapeDataString($Filter)
    }

    if ($null -ne $Select -and $Select.Count -gt 0) {
        $arrQueryParameter += '$select={0}' -f [System.Uri]::EscapeDataString(($Select -join ','))
    }

    if ($arrQueryParameter.Count -eq 0) {
        return $strBaseUri
    }

    return "{0}?{1}" -f $strBaseUri, ($arrQueryParameter -join '&')
}


function Get-GraphManagedDeviceUri {
    # .SYNOPSIS
    # Builds the managed-devices collection URI.
    #
    # .DESCRIPTION
    # Builds the initial Microsoft Graph URI used to request Windows managed
    # devices for the compliance export.
    #
    # .PARAMETER ServiceRoot
    # The Microsoft Graph service root to use.
    #
    # .PARAMETER ApiVersion
    # The Microsoft Graph API version path segment to use.
    #
    # .PARAMETER Filter
    # The OData filter expression to apply to the managed-devices collection.
    #
    # .PARAMETER Select
    # The managed-device fields to request.
    #
    # .EXAMPLE
    # Get-GraphManagedDeviceUri -ServiceRoot 'https://graph.microsoft.com' -ApiVersion 'v1.0'
    #
    # .INPUTS
    # None. This helper does not accept pipeline input.
    #
    # .OUTPUTS
    # System.String. The managed-devices collection URI.
    #
    # .NOTES
    # Private helper. Positional parameter binding is an internal-caller contract only.
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$ServiceRoot = 'https://graph.microsoft.com',

        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion = 'v1.0',

        [ValidateNotNullOrEmpty()]
        [string]$Filter = "operatingSystem eq 'Windows'",

        [ValidateNotNullOrEmpty()]
        [string[]]$Select = @(
            'id',
            'deviceName',
            'userPrincipalName',
            'complianceState',
            'lastSyncDateTime',
            'operatingSystem',
            'osVersion'
        )
    )

    Set-StrictMode -Version Latest

    return Get-GraphCollectionUri `
        -ServiceRoot $ServiceRoot `
        -ApiVersion $ApiVersion `
        -PathSegment @('deviceManagement', 'managedDevices') `
        -Filter $Filter `
        -Select $Select
}


function Get-GraphDeviceCompliancePolicyStateUri {
    # .SYNOPSIS
    # Builds a device compliance policy states URI.
    #
    # .DESCRIPTION
    # Builds the initial Microsoft Graph URI used to request compliance policy
    # states for one managed device.
    #
    # .PARAMETER ServiceRoot
    # The Microsoft Graph service root to use.
    #
    # .PARAMETER ApiVersion
    # The Microsoft Graph API version path segment to use.
    #
    # .PARAMETER DeviceId
    # The managed-device identifier to place in the URI path.
    #
    # .PARAMETER Select
    # The policy-state fields to request.
    #
    # .EXAMPLE
    # Get-GraphDeviceCompliancePolicyStateUri -DeviceId 'fixture-device-001'
    #
    # .INPUTS
    # None. This helper does not accept pipeline input.
    #
    # .OUTPUTS
    # System.String. The device compliance policy states collection URI.
    #
    # .NOTES
    # Private helper. Positional parameter binding is an internal-caller contract only.
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$ServiceRoot = 'https://graph.microsoft.com',

        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion = 'v1.0',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceId,

        [ValidateNotNullOrEmpty()]
        [string[]]$Select = @(
            'id',
            'displayName',
            'state'
        )
    )

    Set-StrictMode -Version Latest

    return Get-GraphCollectionUri `
        -ServiceRoot $ServiceRoot `
        -ApiVersion $ApiVersion `
        -PathSegment @('deviceManagement', 'managedDevices', $DeviceId, 'deviceCompliancePolicyStates') `
        -Select $Select
}


function Get-GraphDeviceCompliancePolicySettingStateUri {
    # .SYNOPSIS
    # Builds a device compliance policy setting states URI.
    #
    # .DESCRIPTION
    # Builds the initial Microsoft Graph URI used to request setting states for
    # one compliance policy state on one managed device.
    #
    # .PARAMETER ServiceRoot
    # The Microsoft Graph service root to use.
    #
    # .PARAMETER ApiVersion
    # The Microsoft Graph API version path segment to use.
    #
    # .PARAMETER DeviceId
    # The managed-device identifier to place in the URI path.
    #
    # .PARAMETER PolicyId
    # The device compliance policy state identifier to place in the URI path.
    #
    # .PARAMETER Select
    # The setting-state fields to request.
    #
    # .EXAMPLE
    # Get-GraphDeviceCompliancePolicySettingStateUri -DeviceId 'fixture-device-001' -PolicyId 'fixture-policy-001'
    #
    # .INPUTS
    # None. This helper does not accept pipeline input.
    #
    # .OUTPUTS
    # System.String. The device compliance policy setting states collection URI.
    #
    # .NOTES
    # Private helper. Positional parameter binding is an internal-caller contract only.
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$ServiceRoot = 'https://graph.microsoft.com',

        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion = 'v1.0',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DeviceId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PolicyId,

        [ValidateNotNullOrEmpty()]
        [string[]]$Select = @(
            'id',
            'settingName',
            'setting',
            'state'
        )
    )

    Set-StrictMode -Version Latest

    $arrPathSegment = @(
        'deviceManagement',
        'managedDevices',
        $DeviceId,
        'deviceCompliancePolicyStates',
        $PolicyId,
        'settingStates'
    )

    return Get-GraphCollectionUri `
        -ServiceRoot $ServiceRoot `
        -ApiVersion $ApiVersion `
        -PathSegment $arrPathSegment `
        -Select $Select
}


function Get-GraphPropertyValue {
    # .SYNOPSIS
    # Reads a property value from a Graph response object.
    #
    # .DESCRIPTION
    # Reads a named property from dictionary-shaped or object-shaped Microsoft
    # Graph responses. Exact dictionary keys are preferred before PowerShell
    # object properties.
    #
    # .PARAMETER InputObject
    # The response object to inspect.
    #
    # .PARAMETER Name
    # The property name to read.
    #
    # .EXAMPLE
    # Get-GraphPropertyValue -InputObject $response -Name '@odata.nextLink'
    #
    # .INPUTS
    # None. This helper does not accept pipeline input.
    #
    # .OUTPUTS
    # System.Object. The property value, or $null when the property is absent.
    #
    # .NOTES
    # Private helper. Positional parameter binding is an internal-caller contract only.
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    Set-StrictMode -Version Latest

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary] -and $InputObject.Contains($Name)) {
        return $InputObject[$Name]
    }

    $objProperty = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $objProperty) {
        return $objProperty.Value
    }

    return $null
}


function Invoke-GraphCollectionRequest {
    # .SYNOPSIS
    # Requests all pages from a Microsoft Graph collection.
    #
    # .DESCRIPTION
    # Requests an initial Microsoft Graph collection URI and follows each
    # Graph-provided @odata.nextLink as an opaque URI without rewriting it.
    #
    # .PARAMETER InitialUri
    # The initial collection URI to request.
    #
    # .PARAMETER GraphRequest
    # A script block that accepts a URI and returns the Graph response object.
    #
    # .EXAMPLE
    # Invoke-GraphCollectionRequest -InitialUri $uri -GraphRequest $request
    #
    # .INPUTS
    # None. This helper does not accept pipeline input.
    #
    # .OUTPUTS
    # System.Object. Objects from every response page's value collection.
    #
    # .NOTES
    # Private helper. Positional parameter binding is an internal-caller contract only.
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InitialUri,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [scriptblock]$GraphRequest
    )

    Set-StrictMode -Version Latest

    $arrItem = @()
    $strNextUri = $InitialUri

    while (-not [string]::IsNullOrWhiteSpace($strNextUri)) {
        $objResponse = & $GraphRequest $strNextUri
        $objValue = Get-GraphPropertyValue -InputObject $objResponse -Name 'value'

        if ($null -ne $objValue) {
            $arrItem += @($objValue)
        }

        $objNextLink = Get-GraphPropertyValue -InputObject $objResponse -Name '@odata.nextLink'
        if ($null -eq $objNextLink -or [string]::IsNullOrWhiteSpace([string]$objNextLink)) {
            $strNextUri = $null
        } else {
            $strNextUri = [string]$objNextLink
        }
    }

    return $arrItem
}


function Export-WindowsComplianceStatusReport {
    # .SYNOPSIS
    # Exports an Intune Windows compliance report.
    #
    # .DESCRIPTION
    # Connects to Microsoft Graph, requests Windows managed devices and their
    # compliance setting states, and writes the current demo CSV report. Tests
    # may inject GraphRequest and SkipGraphConnect to use no-network fixtures.
    #
    # .PARAMETER ExportPath
    # The CSV file path to write.
    #
    # .PARAMETER ServiceRoot
    # The Microsoft Graph service root to use for initial requests.
    #
    # .PARAMETER ApiVersion
    # The Microsoft Graph API version path segment to use for initial requests.
    #
    # .PARAMETER GraphRequest
    # A script block that accepts a URI and returns the Graph response object.
    #
    # .PARAMETER SkipGraphConnect
    # Skips Connect-MgGraph. Intended for no-network tests with GraphRequest.
    #
    # .EXAMPLE
    # Export-WindowsComplianceStatusReport -ExportPath '.\out\compliance.csv'
    #
    # .INPUTS
    # None. This function does not accept pipeline input.
    #
    # .OUTPUTS
    # System.Management.Automation.PSCustomObject. The row objects written to the CSV.
    #
    # .NOTES
    # Version: 1.0.20260625.0
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExportPath,

        [ValidateNotNullOrEmpty()]
        [string]$ServiceRoot = 'https://graph.microsoft.com',

        [ValidateNotNullOrEmpty()]
        [string]$ApiVersion = 'v1.0',

        [ValidateNotNull()]
        [scriptblock]$GraphRequest = {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Uri
            )

            Invoke-MgGraphRequest -Method GET -Uri $Uri
        },

        [switch]$SkipGraphConnect
    )

    Set-StrictMode -Version Latest

    if (-not $SkipGraphConnect) {
        Write-Information -MessageData "Authenticating to Microsoft Graph..." -InformationAction Continue
        Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All", "DeviceManagementConfiguration.Read.All"
    }

    Write-Information -MessageData "Querying Windows managed devices..." -InformationAction Continue
    try {
        $strManagedDeviceUri = Get-GraphManagedDeviceUri -ServiceRoot $ServiceRoot -ApiVersion $ApiVersion
        $arrDevice = @(
            Invoke-GraphCollectionRequest -InitialUri $strManagedDeviceUri -GraphRequest $GraphRequest
        )
    } catch {
        Write-Error "Failed to query managed devices: $_"
        return
    }

    if ($arrDevice.Count -eq 0) {
        Write-Information -MessageData "No Windows devices found or insufficient permissions." -InformationAction Continue
        return
    }

    Write-Information -MessageData "Found $($arrDevice.Count) Windows devices." -InformationAction Continue

    $hashSettingName = @{}
    $intDeviceCounter = 0

    foreach ($objDevice in $arrDevice) {
        $intDeviceCounter++
        $strDeviceName = [string](Get-GraphPropertyValue -InputObject $objDevice -Name 'deviceName')
        $strDeviceId = [string](Get-GraphPropertyValue -InputObject $objDevice -Name 'id')
        Write-Information -MessageData "[$intDeviceCounter/$($arrDevice.Count)] Processing $strDeviceName..." -InformationAction Continue

        try {
            $strPolicyStateUri = Get-GraphDeviceCompliancePolicyStateUri `
                -ServiceRoot $ServiceRoot `
                -ApiVersion $ApiVersion `
                -DeviceId $strDeviceId
            $arrPolicyState = @(
                Invoke-GraphCollectionRequest -InitialUri $strPolicyStateUri -GraphRequest $GraphRequest
            )

            foreach ($objPolicyState in $arrPolicyState) {
                $strPolicyId = [string](Get-GraphPropertyValue -InputObject $objPolicyState -Name 'id')
                $strSettingStateUri = Get-GraphDeviceCompliancePolicySettingStateUri `
                    -ServiceRoot $ServiceRoot `
                    -ApiVersion $ApiVersion `
                    -DeviceId $strDeviceId `
                    -PolicyId $strPolicyId
                $arrSettingState = @(
                    Invoke-GraphCollectionRequest -InitialUri $strSettingStateUri -GraphRequest $GraphRequest
                )

                foreach ($objSettingState in $arrSettingState) {
                    $strColumnName = [string](Get-GraphPropertyValue -InputObject $objSettingState -Name 'settingName')
                    if ([string]::IsNullOrWhiteSpace($strColumnName)) {
                        $strColumnName = [string](Get-GraphPropertyValue -InputObject $objSettingState -Name 'setting')
                    }

                    if (-not [string]::IsNullOrWhiteSpace($strColumnName)) {
                        $hashSettingName[$strColumnName] = $true
                    }
                }
            }
        } catch {
            Write-Warning "Failed to get policy/settings for device ${strDeviceName}: $_"
        }
    }

    $arrSettingName = @($hashSettingName.Keys | Sort-Object)
    $arrOutputRow = @()
    $intDeviceCounter = 0

    foreach ($objDevice in $arrDevice) {
        $intDeviceCounter++
        $strDeviceName = [string](Get-GraphPropertyValue -InputObject $objDevice -Name 'deviceName')
        $strDeviceId = [string](Get-GraphPropertyValue -InputObject $objDevice -Name 'id')
        Write-Information -MessageData "Building report row for $strDeviceName ($intDeviceCounter/$($arrDevice.Count))..." -InformationAction Continue

        $hashRow = [ordered]@{
            DeviceName = $strDeviceName
            UserPrincipal = Get-GraphPropertyValue -InputObject $objDevice -Name 'userPrincipalName'
            DeviceId = $strDeviceId
            ComplianceState = Get-GraphPropertyValue -InputObject $objDevice -Name 'complianceState'
            LastSync = Get-GraphPropertyValue -InputObject $objDevice -Name 'lastSyncDateTime'
        }

        foreach ($strSettingName in $arrSettingName) {
            $hashRow[$strSettingName] = 'none'
        }

        try {
            $strPolicyStateUri = Get-GraphDeviceCompliancePolicyStateUri `
                -ServiceRoot $ServiceRoot `
                -ApiVersion $ApiVersion `
                -DeviceId $strDeviceId
            $arrPolicyState = @(
                Invoke-GraphCollectionRequest -InitialUri $strPolicyStateUri -GraphRequest $GraphRequest
            )

            foreach ($objPolicyState in $arrPolicyState) {
                $strPolicyId = [string](Get-GraphPropertyValue -InputObject $objPolicyState -Name 'id')
                $strSettingStateUri = Get-GraphDeviceCompliancePolicySettingStateUri `
                    -ServiceRoot $ServiceRoot `
                    -ApiVersion $ApiVersion `
                    -DeviceId $strDeviceId `
                    -PolicyId $strPolicyId
                $arrSettingState = @(
                    Invoke-GraphCollectionRequest -InitialUri $strSettingStateUri -GraphRequest $GraphRequest
                )

                foreach ($objSettingState in $arrSettingState) {
                    $strColumnName = [string](Get-GraphPropertyValue -InputObject $objSettingState -Name 'settingName')
                    if ([string]::IsNullOrWhiteSpace($strColumnName)) {
                        $strColumnName = [string](Get-GraphPropertyValue -InputObject $objSettingState -Name 'setting')
                    }

                    if (-not [string]::IsNullOrWhiteSpace($strColumnName)) {
                        $hashRow[$strColumnName] = Get-GraphPropertyValue -InputObject $objSettingState -Name 'state'
                    }
                }
            }
        } catch {
            Write-Warning "Failed to build report row for ${strDeviceName}: $_"
        }

        $arrOutputRow += [PSCustomObject]$hashRow
    }

    Write-Information -MessageData "Exporting results to $ExportPath ..." -InformationAction Continue
    try {
        $arrOutputRow | Export-Csv -LiteralPath $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Information -MessageData "Export completed: $ExportPath" -InformationAction Continue
    } catch {
        Write-Error "Failed to export results: $_"
        return
    }

    return $arrOutputRow
}


if ($MyInvocation.InvocationName -ne '.') {
    Export-WindowsComplianceStatusReport -ExportPath $ExportPath | Out-Null
}
