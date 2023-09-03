function Execute-Command {
    [CmdletBinding()]
    param (
        [string]$Command
    )
    Invoke-Expression $Command
    # Honor `-ErrorAction Stop` to throw terminating error for non-zero exit code
    if ($ErrorActionPreference -eq 'Stop' -and $LASTEXITCODE) {
        throw "Command exit code was $LASTEXITCODE. Command: $Command"
    }
}
