function Clone-TempRepo {
    [CmdletBinding()]
    param ()

    process {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        try {
            $gitRemote = git remote get-url origin
            if ($LASTEXITCODE) { throw }

            $tmpDir = if ($PSVersionTable.PSVersion.Major -le '5' -or $isWindows) {
                "$env:TEMP/$( New-Guid )/$( Split-Path $gitRemote -Leaf )"
            }else {
                "$( mktemp -d )/$( Split-Path $gitRemote -Leaf )"
            }
            if ($LASTEXITCODE) { throw }

            git clone "$gitRemote" "$tmpDir" | Write-Host
            if ($LASTEXITCODE) { throw }

            # Return the temp repo path
            $tmpDir
        }catch {
            if ($callerEA -eq 'Stop') {
                throw
            }elseif ($callerEA -eq 'Continue') {
                $_ | Write-Error
            }
        }
    }
}
