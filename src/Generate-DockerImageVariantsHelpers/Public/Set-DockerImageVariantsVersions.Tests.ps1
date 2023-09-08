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

        It "Sets version.json (pipeline)" {
            Mock Set-Content {}

            '0.1.0' | Set-DockerImageVariantsVersions

            Assert-MockCalled Set-Content -Scope It -Times 1
        }

        It "Sets version.json with an empty array" {
            Mock Set-Content {}

            Set-DockerImageVariantsVersions -Versions @()

            Assert-MockCalled Set-Content -Scope It -Times 1
        }

        It "Sets version.json with an empty array (first arg)" {
            Mock Set-Content {}

            Set-DockerImageVariantsVersions @()

            Assert-MockCalled Set-Content -Scope It -Times 1
        }

        It "Sets version.json with a non-empty array" {
            Mock Set-Content {}

            Set-DockerImageVariantsVersions -Versions @( '0.1.0', '0.2.0' )

            Assert-MockCalled Set-Content -Scope It -Times 1
        }

    }

}

