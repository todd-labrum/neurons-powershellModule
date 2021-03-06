# *************************** Import Ivanti Neurons PowerShell Module *************************** 
if (Test-Path ".\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} elseif (Test-Path ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" -PathType leaf) {
    $Module = Get-Item ".\src\IvantiPSFunctions\IvantiPSFunctions.psm1" | Resolve-Path -Relative
    Write-Debug "Found module file"
} else {
    $StatusCode = "404"
    $Exception = [Exception]::new("PowerShell module cannot be found.  Error code ($($StatusCode))")
    $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
        $Exception,
        "$($StatusCode)",
        [System.Management.Automation.ErrorCategory]::FatalError,
        $TargetObject
    )
    $PSCmdlet.WriteError($ErrorRecord)
    Exit
}

# ----- Check to see if Module is signed ----- 
if ($IsWindows) {
    $Signed = Get-AuthenticodeSignature -FilePath $Module
    if ($DevMode -ne "true" -and $Signed.Status -ne "Valid") {
        Write-Error "Module is not signed."
        Exit
    }
}
else {
    Write-Debug "Skipping module certificate check."
}

# ----- Import Module ----- 
Import-Module -Name $Module -ArgumentList $DevMode -Force

#Set parameters to run
$_tenantID = ""
$_clientID = ""
$_clientSecret = ""
$_authURL = ""
$_scope = "dataservices.read"
$Landscape = "NVU"
$_daysAgo = (Get-Date).AddDays(-90)
$_date = Get-Date -Date $_daysAgo -Format 'yyyy-MM-dd'
$_filter = "LastHardwareScanDate le '$_date'"

#Run code
$_token = Get-AccessToken -AuthURL $_authURL -ClientID $_clientID -ClientSecret $_clientSecret -Scopes $_scope
$_deviceIds = Get-NeuronsData -TenantId $_tenantID -Landscape $Landscape -FilterString $_filter -Token $_token
if ($null -ne $_deviceIds -or $_deviceIds) {
    Invoke-DeleteNeuronsData -TenantId $_tenantID -Landscape $Landscape -DataEndpoint 'device' -DiscoveryIds $_deviceIds -Token $_token
} else {
    $_dbgMessage = "No devices to delete"
    Write-Host $_dbgMessage
}
