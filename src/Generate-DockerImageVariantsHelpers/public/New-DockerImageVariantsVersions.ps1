function New-DockerImageVariantsVersions {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,Position=0,HelpMessage='Package name')]
        [ValidateNotNull()]
        [string]$Package
    )

    process {
        try {
            $VERSIONS_JSON_FILE = "./generate/definitions/versions.json"
            if (Test-Path $VERSIONS_JSON_FILE) {
                throw "The file '$VERSIONS_JSON_FILE' already exists"
            }

            $content = @{
                $Package = [ordered]@{
                    versions = @(
                        '0.0.0'
                    )
                    versionsChangeScope = 'minor'
                    versionsNewScript = 'Invoke-RestMethod https://example.com/versions.json'
                }
            }
            $content = $content | ConvertTo-Json -Depth 100
            "Creating $VERSIONS_JSON_FILE" | Write-Host -ForegroundColor Green
            $item = New-Item $VERSIONS_JSON_FILE -ItemType File
            if ($PSVersionTable.PSVersion.Major -le 5) {
                [IO.File]::WriteAllLines($item.FullName, $content) # Utf8 without BOM
            }else {
                $content | Out-File $item.FullName -Encoding utf8 -Force
            }

            $item
        }catch {

        }
    }
}
