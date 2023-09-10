function Execute-Command {
    [CmdletBinding(DefaultParameterSetName='Default',SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,ParameterSetName='Default',Position=0)]
        [ValidateNotNull()]
        [object]$Command
    ,
        [Parameter(ValueFromPipeline,ParameterSetName='Pipeline')]
        [object]$InputObject
    )

    process {
        if ($InputObject) {
            $Command = $InputObject
        }
        $scriptBlock = if ($Command -is [scriptblock]) {
            $Command
        }else {
            # This is like Invoke-Expression, dangerous
            [scriptblock]::Create($Command)
        }
        try {
            "Command: $scriptBlock" | Write-Verbose
            if ($PSCmdlet.ShouldProcess("$scriptBlock")) {
                Invoke-Command $scriptBlock
            }
            "LASTEXITCODE: $global:LASTEXITCODE" | Write-Verbose
            if ($ErrorActionPreference -eq 'Stop' -and $global:LASTEXITCODE) {
                throw "Command exit code was $global:LASTEXITCODE. Command: $scriptBlock"
            }
        }catch {
            if ($ErrorActionPreference -eq 'Stop') {
                throw
            }
            if ($ErrorActionPreference -eq 'Continue') {
                $_ | Write-Error
            }
        }
    }
}
