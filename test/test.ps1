param (
    [string]$Tag = ''
)
$MODULE_NAME = (Get-Item $PSScriptRoot/../).Name
$MODULE_DIR = "$PSScriptRoot/../src/$MODULE_NAME"
$MODULE_MANIFEST = "$MODULE_DIR/$MODULE_NAME.psd1"

Set-StrictMode -Version Latest
$global:PesterDebugPreference_ShowFullErrors = $true

# Install Pester if needed
$pester = Get-Module Pester -ListAvailable -ErrorAction SilentlyContinue
$pesterMinVersion = [version]'4.0.0'
$pesterMaxVersion = [version]'4.10.1'
if ( ! $pester -or ! ($pester.Version | ? { $_ -ge $pesterMinVersion -and $_ -le $pesterMaxVersion }) ) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Install-Module Pester -Force -Scope CurrentUser -MinimumVersion $pesterMinVersion -MaximumVersion $pesterMaxVersion -ErrorAction Stop
    }else {
        Install-Module Pester -Force -Scope CurrentUser -MinimumVersion $pesterMinVersion -MaximumVersion $pesterMaxVersion -SkipPublisherCheck -ErrorAction Stop
    }
}
Get-Module Pester -ListAvailable
Import-Module Pester -MinimumVersion $pesterMinVersion -MaximumVersion $pesterMaxVersion -Force -ErrorAction Stop

# Install required modules
$manifest = (Get-Content $MODULE_MANIFEST -Raw | Invoke-Expression)
foreach ($m in $manifest.RequiredModules) {
    $m = $m.Clone()
    $m['Name'] = $m['ModuleName']
    $m.Remove('ModuleName')
    if (!(Get-InstalledModule @m -ErrorAction SilentlyContinue)) {
        "Installing required module: $( $m['Name'] )" | Write-Host -ForegroundColor Green
        Install-Module @m -Force -Scope CurrentUser -ErrorAction Stop
    }
    Get-Module $m['Name'] -ListAvailable
}

# Test the module manifest
Test-ModuleManifest "$MODULE_MANIFEST" -ErrorAction Stop

# Unload required modules (not needed for unit tests)
# foreach ($m in $manifest.RequiredModules) {
#     Get-Module -Name $m['ModuleName'] | Remove-Module -Force -ErrorAction Stop
# }

# Import our module
Get-Module "$MODULE_NAME" | Remove-Module -Force
Import-Module $MODULE_MANIFEST -Force -ErrorAction Stop

if ($Tag) {
    # Run Unit Tests
    $res = Invoke-Pester -Script $MODULE_DIR -Tag $Tag -PassThru -ErrorAction Stop
    if ($res.FailedCount -gt 0) {
        "$( $res.FailedCount ) $Tag tests failed." | Write-Host
    }
    if ($res -and $res.FailedCount -gt 0) {
        throw
    }
}else {
    # Run Unit Tests
    $res = Invoke-Pester -Script $MODULE_DIR -Tag 'Unit' -PassThru -ErrorAction Stop
    if ($res.FailedCount -gt 0) {
        "$( $res.FailedCount ) unit tests failed." | Write-Host
    }

    # Run Integration Tests
    $res2 = Invoke-Pester -Script $MODULE_DIR -Tag 'Integration' -PassThru -ErrorAction Stop
    if ($res2.FailedCount -gt 0) {
        "$( $res2.FailedCount ) integration tests failed." | Write-Host
    }

    if (($res -and $res.FailedCount -gt 0) -or ($res2 -and $res2.FailedCount)) {
        throw
    }
}
