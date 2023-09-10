$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Clone-TempRepo" -Tag Unit {

    BeforeEach {
        function git {}
        Mock git {
            if ("$Args" -eq 'remote get-url origin') {
                'https://github.com/theohbrothers/foo'
            }
            if ($Args[0] -eq 'clone') {
                "cloning into '$( $Args[2] )'"
            }
        }
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

            $Command = if ($InputObject) { $InputObject } else { $Command }
            Invoke-Command $Command
        }
    }

    Context 'Error handling' {

        It "Honors -ErrorAction Stop" {
            Mock Execute-Command {
                if ($ErrorActionPreference -eq 'Stop') {
                    throw "some exception"
                }
            }

            {
                Clone-TempRepo -ErrorAction Stop 6>$null
            } | Should -Throw "some exception"
        }

    }

    Context 'Behavior' {

        It "Clones repo" {
            $output = Clone-TempRepo 6>$null

            Assert-MockCalled git -Scope It -Times 2
            $output | Should -Match '/foo$'
        }

        It "Clones repo (-WhatIf)" {
            $output = Clone-TempRepo -WhatIf -ErrorVariable err 6>$null

            Assert-MockCalled git -Scope It -Times 2
            $output | Should -Be $null
            $err | Should -Be $null
        }

    }

}
