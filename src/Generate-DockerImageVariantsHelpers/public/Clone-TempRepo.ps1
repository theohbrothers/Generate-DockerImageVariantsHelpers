function Clone-TempRepo {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    process {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            $gitRemote = { git remote get-url origin } | Execute-Command

            $tmpDir = if ($PSVersionTable.PSVersion.Major -le '5' -or $isWindows) {
                { "$env:TEMP/$( New-Guid )/$( Split-Path $gitRemote -Leaf )" } | Execute-Command
            }else {
                { "$( mktemp -d )/$( Split-Path $gitRemote -Leaf )" } | Execute-Command
            }

            # { git clone "$gitRemote" "$tmpDir" } | Execute-Command | Write-Host
            $sourceDir = { git rev-parse --show-toplevel } | Execute-Command
            Copy-Item $sourceDir $tmpDir -Recurse -Force

            # Return the temp repo path
            if ($PSCmdlet.ShouldProcess($tmpDir, 'return')) {
                $tmpDir
            }
        }catch {
            if ($callerEA -eq 'Stop') {
                throw
            }elseif ($callerEA -eq 'Continue') {
                $_ | Write-Error -ErrorAction Continue
            }
        }
    }
}
