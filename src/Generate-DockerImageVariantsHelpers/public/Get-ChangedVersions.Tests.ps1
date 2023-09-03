$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-ChangedVersions" {

    $versions = @(
        '0.0.0'
        '0.1.0'
        '1.0.0'
    )
    $VersionsNew = @(
        '0.0.0'
        '0.1.1'
        '1.0.1'
        '1.2.0'
        '2.0.0'
    )

    Context 'Behavior' {

        It "Return original versions when none changed" {
            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $versions
            Compare-Object $versions $changedVersions | Should -Be $null
        }

        It "Gets new versions (as strings)" {
            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew
            Compare-Object $VersionsNew $changedVersions | Should -Be $null
        }

        It "Gets new versions (as objects)" {
            $changedVersions = Get-ChangedVersions -Versions $versions -VersionsNew $VersionsNew -AsObject

            Compare-Object $VersionsNew @($changedVersions.Keys) | Should -Be $null
            Compare-Object $VersionsNew @($changedVersions.Values | % { $_['to'] })  | Should -Be $null
        }

    }

}
