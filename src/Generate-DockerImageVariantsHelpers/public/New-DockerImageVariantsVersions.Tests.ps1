$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-DockerImageVariantsVersions" {

    Context 'Parameters' {

        It "Errors when -Versions is null" {
            {
                New-DockerImageVariantsVersions -Package $null 6>$null
            } | Should -Throw
        }

    }

    Context 'Behavior' {

        BeforeEach {
            Push-Location "TestDrive:\"
            $VERSIONS_JSON_FILE = "TestDrive:\generate/definitions/versions.json"
            New-Item (Split-Path $VERSIONS_JSON_FILE -Parent) -ItemType Container
            $package = 'foo'
        }
        AfterEach {
            Pop-Location
            Remove-Item "TestDrive:\generate" -Recurse -Force
        }

        It "Creates version.json" {
            $item = New-DockerImageVariantsVersions -Package $package 6>$null

            $item | Should -Not -Be $null
            $item.FullName -eq (Get-Item $VERSIONS_JSON_FILE -Force).FullName | Should -Be $true
            Get-Content $item -Encoding utf8 -Raw | ConvertFrom-Json | Should -Not -Be $null
        }

        It "Creates version.json (-WhatIf)" {
            $item = New-DockerImageVariantsVersions '0.1.0' -WhatIf >$null 6>$null

            Test-Path $VERSIONS_JSON_FILE | Should -Be $false
            $item | Should -Be $null
        }


        It "Errors if version.json already exists" {
            New-Item $VERSIONS_JSON_FILE -ItemType File -Force > $null

            $item = New-DockerImageVariantsVersions -Package $package -ErrorVariable err 2>$null

            $item | Should -Be $null
            $err | Should -Not -Be $null
        }
    }

}

