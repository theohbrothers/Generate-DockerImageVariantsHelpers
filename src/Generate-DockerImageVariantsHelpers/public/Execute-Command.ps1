function Execute-Command {
    [CmdletBinding(DefaultParameterSetName='Default')]
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
            Invoke-Command $scriptBlock
            "LASTEXITCODE: $LASTEXITCODE" | Write-Verbose
            if ($ErrorActionPreference -eq 'Stop' -and $LASTEXITCODE) {
                throw "Command exit code was $LASTEXITCODE. Command: $scriptBlock"
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
