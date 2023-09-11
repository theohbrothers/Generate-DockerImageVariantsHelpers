$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-Release" -Tag 'Unit' {

    BeforeEach {
        $env:GITHUB_TOKEN = 'foo'
        function Execute-Command {
            [CmdletBinding(DefaultParameterSetName='Default',SupportsShouldProcess)]
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
        function git {}
        Mock git {
            if ("$Args" -eq 'remote get-url origin') {
                'https://github.com/namespace/project'
            }
        }
        function Get-TagNext {}
        Mock Get-TagNext {
            'v0.1.0'
        }
        function Get-Milestones {
            ,@(
                [pscustomobject]@{
                    number = 123
                    title = 'next-release'
                    state = 'open'
                },
                [pscustomobject]@{
                    number = 122
                    title = 'v0.1.0'
                    state = 'closed'
                }
            )
        }
        Mock Invoke-RestMethod {
            param (
                $Method,
                $Uri
            )

            if ($Uri -eq 'https://api.github.com/repos/namespace/project/git/refs') {
                [pscustomobject]@{
                    name = 'v0.1.0'
                }
            }elseif ($Uri -eq 'https://api.github.com/repos/namespace/project/milestones') {
                ,(Get-Milestones)
            }elseif ($Method -eq 'PATCH' -and $Uri -eq 'https://api.github.com/repos/namespace/project/milestones/122') {
                [pscustomobject]@{
                    number = 122
                    title = 'v0.1.0-clash'
                    state = 'closed'
                }
            }elseif ($Method -eq 'PATCH' -and $Uri -eq 'https://api.github.com/repos/namespace/project/milestones/123') {
                [pscustomobject]@{
                    number = 123
                    title = Get-TagNext
                    state = 'closed'
                }
            }
        }
    }

    It "Errors if any git commands fail" {
        Mock git {
            throw "i am a git error"
        }

        {
            New-Release -ErrorAction Stop 6>$null
        } | Should Throw "i am a git error"

    }

    It "Creates new tag, renames clashed milestone if it exists, renames and closes milestone" {
        $tag = New-Release 6>$null 3>$null

        Assert-MockCalled git -Scope It -Times 4
        Assert-MockCalled Get-TagNext -Scope It -Times 1
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 4
        $tag | Should -Be (Get-TagNext)
    }

    It "Creates new tag, renames and closes milestone (-WhatIf)" {
        $tag = New-Release -WhatIf -ErrorVariable err 6>$null 3>$null

        Assert-MockCalled git -Scope It -Times 0
        Assert-MockCalled Get-TagNext -Scope It -Times 1
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 0
        $tag | Should -Be $null
        $err | Should -Be $null
    }
    It "Creates new tag, and skips renaming and closing milestone if it is already closed or does not exists" {
        function Get-Milestones {}

        $tag = New-Release 6>$null 3>$null

        Assert-MockCalled git -Scope It -Times 4
        Assert-MockCalled Get-TagNext -Scope It -Times 1
        Assert-MockCalled Invoke-RestMethod -Scope It -Times 1
        $tag | Should -Be (Get-TagNext)
    }

}
