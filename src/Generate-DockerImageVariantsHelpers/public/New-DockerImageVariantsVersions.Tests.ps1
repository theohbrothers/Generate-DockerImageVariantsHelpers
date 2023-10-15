$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-DockerImageVariantsVersions" {

    Context 'Parameters' {

        It "Errors when -Package is null" {
            {
                New-DockerImageVariantsVersions -Package $null 6>$null
            } | Should -Throw
        }

        It "Errors when -VersionsNewScript is null" {
            {
                New-DockerImageVariantsVersions -Package foo -VersionsNewScript $null 6>$null
            } | Should -Throw
        }

    }

    Context 'Behavior' {

        BeforeEach {
            Push-Location "TestDrive:\"
            $VERSIONS_JSON_FILE = "TestDrive:\generate/definitions/versions.json"
            New-Item (Split-Path $VERSIONS_JSON_FILE -Parent) -ItemType Container
            . "$here\Get-VersionsChanged.ps1"
            function Some-VersionNewScript {
                @( '1.0.0', '1.0.1' )
            }
        }
        AfterEach {
            Pop-Location
            Remove-Item "TestDrive:\generate" -Recurse -Force
        }

        It "Honors -ErrorAction Continue" {
            $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope minor -VersionsNewScript { some-invalid-command } -ErrorVariable err -ErrorAction Continue 2>$null

            $err | Should -Match 'some-invalid-command'
        }

        It "Honors -ErrorAction Stop" {
            {
                $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope minor -VersionsNewScript { some-invalid-command } -ErrorAction Stop
            } | Should -Throw


            {
                $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope minor -VersionsNewScript { 'not-a-version' } -ErrorAction Stop
            } | Should -Throw
        }

        It "Creates version.json (-VersionsChangeScope minor)" {
            $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope minor -VersionsNewScript { Some-VersionNewScript } -ErrorVariable err

            $item | Should -Not -Be $null
            $item.FullName -eq (Get-Item $VERSIONS_JSON_FILE -Force).FullName | Should -Be $true
            $v = Get-Content $item -Encoding utf8 -Raw | ConvertFrom-Json
            $v | Should -Not -Be $null
            $v.foo.versions | Should -Be @( '1.0.1' )
            $v.foo.versionsChangeScope | Should -Be 'minor'
            $v.foo.versionsNewScript | Should -Be 'Some-VersionNewScript'
            $err | Should -Be $null
        }

        It "Creates version.json (-VersionsChangeScope patch)" {
            $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope patch -VersionsNewScript { Some-VersionNewScript } -ErrorVariable err

            $item | Should -Not -Be $null
            $item.FullName -eq (Get-Item $VERSIONS_JSON_FILE -Force).FullName | Should -Be $true
            $v = Get-Content $item -Encoding utf8 -Raw | ConvertFrom-Json
            $v | Should -Not -Be $null
            $v.foo.versions | Should -Be @( '1.0.1', '1.0.0' )
            $v.foo.versionsChangeScope | Should -Be 'patch'
            $v.foo.versionsNewScript | Should -Be 'Some-VersionNewScript'
            $err | Should -Be $null
        }

        It "Creates version.json (-WhatIf)" {
            $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope minor -VersionsNewScript { Some-VersionNewScript } -ErrorVariable err -WhatIf 6>$null

            Test-Path $VERSIONS_JSON_FILE | Should -Be $false
            $item | Should -Be $null
            $err | Should -Be $null
        }

        It "Errors if version.json already exists" {
            New-Item $VERSIONS_JSON_FILE -ItemType File -Force > $null

            $item = New-DockerImageVariantsVersions -Package foo -VersionsChangeScope minor -VersionsNewScript { Some-VersionNewScript } -ErrorVariable err 2>$null

            $item | Should -Be $null
            $err | Should -Not -Be $null
        }

    }

}

