$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Set-DockerImageVariantsVersions" {

    Context 'Parameters' {

        It "Errors when -Versions is null" {
            Mock Set-Content {}

            {
                Set-DockerImageVariantsVersions -Versions $null
            } | Should -Throw
        }

    }

    Context 'Behavior' {

        BeforeEach {
            Push-Location "TestDrive:\"
            $VERSIONS_JSON_FILE = "TestDrive:\generate/definitions/versions.json"
            New-Item (Split-Path $VERSIONS_JSON_FILE -Parent) -ItemType Container
            # Mock Set-Content {}
        }
        AfterEach {
            Pop-Location
            # Assert-MockCalled Set-Content -Scope It -Times 1
            Remove-Item "TestDrive:\generate" -Recurse -Force
        }
        It "Sets version.json" {
            Set-DockerImageVariantsVersions '0.1.0'

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Be @"
"0.1.0"

"@

            '0.1.0' | Set-DockerImageVariantsVersions

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Be @"
"0.1.0"

"@
        }

        It "Sets version.json with an empty array (first arg)" {
            Set-DockerImageVariantsVersions @()

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Be @"
[]

"@
        }

        It "Sets version.json with a non-empty array" {
            Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' )

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Match @"
[
\s+"0.1.0",
\s+"0.2.0"
]

"@
        }

        It "It sets -DoubleNewlines" {
            Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' ) -DoubleNewlines

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Match @"
[

\s+"0.1.0",

\s+"0.2.0"

]

"@
        }

    }

}

