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
        function Copy-Item {}
        Mock Copy-Item {}
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

        It 'Errors (non-terminating)' {
            Mock Execute-Command {
                throw "some exception"
            }

            Clone-TempRepo -ErrorVariable err 2>$null 6>$null

            $err | Should -Not -Be $null
        }

        It 'Errors (terminating)' {
            Mock Execute-Command {
                throw "some exception"
            }

            {
                Clone-TempRepo -ErrorAction Stop 6>$null
            } | Should -Throw "some exception"
        }

    }

    Context 'Behavior' {

        It "Clones repo" {
            $output = Clone-TempRepo 6>$null

            Assert-MockCalled Copy-Item -Scope It -Times 1
            $output | Should -Match '/foo$'
        }

        It "Clones repo (-WhatIf)" {
            $output = Clone-TempRepo -WhatIf -ErrorVariable err 6>$null

            Assert-MockCalled Copy-Item -Scope It -Times 1
            $output | Should -Be $null
            $err | Should -Be $null
        }

    }

}
