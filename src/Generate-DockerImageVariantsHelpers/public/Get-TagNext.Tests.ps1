$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-TagNext" {

    BeforeEach {
        function Execute-Command {
            & $Args[0]
        }
        function Get-TagMostRecent {}
        function Get-Branch {
            'mybranch'
        }
        function Get-CommitTitles {}
        function git {
            if ("$Args" -eq 'tag --sort=taggerdate') {
                Get-TagMostRecent
            }
            if ("$Args" -eq 'rev-parse --abbrev-ref HEAD') {
                Get-Branch
            }
            if ("$Args" -eq 'log master..mybranch --format=%s') {
                Get-CommitTitles
            }
        }
    }

    It "Errors (non-terminating) if next tag cannot be determined" {
        function Get-TagMostRecent {}

        Get-TagNext -ErrorAction Continue -ErrorVariable err 2>$null

        $err | Should -Not -Be $null
    }

    It "Errors (terminating) if next tag cannot be determined" {
        function Get-TagMostRecent {}

        {
            Get-TagNext -ErrorAction Stop
        } | Should -Throw 'No tags found in this repo'
    }

    It "Errors if no commits are found between master and branch" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {}

        {
            Get-TagNext -ErrorAction Stop
        } | Should -Throw "No commits found between 'master' and '$( Get-Branch )'"
    }

    It "Get next tag in calver according to previous commit titles (major)" {
        function Get-TagMostRecent {
            $yesterday = (Get-Date).AddDays(-1)
            "$( Get-Date $yesterday -Format 'yyyyMMdd' ).0.0" # yesterday
        }
        function Get-CommitTitles {
            'Breaking: Change foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
    }

    It "Get next tag in calver according to previous commit titles (minor)" {
        function Get-TagMostRecent {
            "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }
        function Get-CommitTitles {
            'Enhancement: Enhance foo'
        }
        $tag = Get-TagNext
        $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).1.0" # today
    }

    It "Get next tag in calver according to previous commit titles (patch)" {
        function Get-TagMostRecent {
            "$( Get-Date -Format 'yyyyMMdd' ).0.0" # today
        }
        function Get-CommitTitles {
            'Fix: Fix foo'
        }
        $tag = Get-TagNext
        $tag | Should -Be "$( Get-Date -Format 'yyyyMMdd' ).0.1" # today
    }

    It "Get next tag in semver according to previous commit titles (major)" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {
            'Breaking: Change foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "v1.0.0"
    }

    It "Get next tag in semver according to previous commit titles (minor)" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {
            'Enhancement: Enhance foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "v0.1.0"
    }

    It "Get next tag in semver according to previous commit titles (patch)" {
        function Get-TagMostRecent {
            'v0.0.1'
        }
        function Get-CommitTitles {
            'Fix: Fix foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "v0.0.2"
    }

    It "Get next tag in semver according to previous commit titles (major, no 'v' prefix)" {
        function Get-TagMostRecent {
            '0.0.1'
        }
        function Get-CommitTitles {
            'Breaking: Change foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "1.0.0"
    }

    It "Get next tag in semver according to previous commit titles (minor, no 'v' prefix)" {
        function Get-TagMostRecent {
            '0.0.1'
        }
        function Get-CommitTitles {
            'Enhancement: Enhance foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "0.1.0"
    }

    It "Get next tag in semver according to previous commit titles (patch, no 'v' prefix)" {
        function Get-TagMostRecent {
            '0.0.1'
        }
        function Get-CommitTitles {
            'Fix: Fix foo'
        }

        $tag = Get-TagNext

        $tag | Should -Be "0.0.2"
    }

}
