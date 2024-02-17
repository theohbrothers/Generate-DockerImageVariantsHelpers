$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Set-DockerImageVariantsVersions" {

    Context 'Parameters' {

        It "Errors when -Versions is null" {
            {
                Set-DockerImageVariantsVersions -Versions $null 6>$null
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

        It "Honors -ErrorAction Continue" {
            Mock ConvertTo-Json {
                throw
            }

            Set-DockerImageVariantsVersions '0.1.0' -ErrorAction Continue -ErrorVariable err 2>$null 6>$null

            $err | Should -Not -Be $null
        }

        It "Honors -ErrorAction Stop" {
            Mock ConvertTo-Json {
                throw
            }

            {
                Set-DockerImageVariantsVersions '0.1.0' -ErrorAction Stop 6>$null
            } | Should -Throw
        }

        It "Sets versions.json" {
            Set-DockerImageVariantsVersions '0.1.0' 6>$null

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Be @"
"0.1.0"

"@

            '0.1.0' | Set-DockerImageVariantsVersions 6>$null

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Be @"
"0.1.0"

"@
        }

        It "Sets versions.json (-WhatIf)" {
            Set-DockerImageVariantsVersions '0.1.0' -WhatIf >$null 6>$null

            Test-Path $VERSIONS_JSON_FILE | Should -Be $false
        }

        It "Sets versions.json with an empty array (first arg)" {
            Set-DockerImageVariantsVersions @() 6>$null

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Be @"
[]

"@
        }

        It "Sets versions.json with a non-empty array" {
            Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' ) 6>$null

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Match @"
[
\s+"0.1.0",
\s+"0.2.0"
]

"@
        }

        It "It sets -DoubleNewlines" {
            Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' ) -DoubleNewlines 6>$null

            Get-Content $VERSIONS_JSON_FILE -Raw | Should -Match @"
[

\s+"0.1.0",

\s+"0.2.0"

]

"@
        }

    }

}

