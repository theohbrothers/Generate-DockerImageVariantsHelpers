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
        Invoke-Expression $Command

        # Honor `-ErrorAction Stop` for non-zero exit code
        if ($ErrorActionPreference -eq 'Stop' -and $LASTEXITCODE) {
            throw "Command exit code was $LASTEXITCODE. Command: $Command"
        }
    }
}
