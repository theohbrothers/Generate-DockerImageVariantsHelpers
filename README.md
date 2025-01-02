# Generate-DockerImageVariantsHelpers

[![github-actions](https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers/actions/workflows/ci-master-pr.yml/badge.svg?branch=master)](https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers/actions/workflows/ci-master-pr.yml)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/Generate-DockerImageVariantsHelpers?style=flat-square)](https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers/releases/)
[![powershell-gallery-release](https://img.shields.io/powershellgallery/v/Generate-DockerImageVariantsHelpers?logo=powershell&logoColor=white&label=PSGallery&labelColor=&style=flat-square)](https://www.powershellgallery.com/packages/Generate-DockerImageVariantsHelpers/)

Helpers to use with [Generate-DockerImageVariants](https://github.com/theohbrothers/Generate-DockerImageVariants).

## Install

Open [`powershell`](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-5.1) or [`pwsh`](https://github.com/powershell/powershell#-powershell) and type:

```powershell
Install-Module -Name Generate-DockerImageVariantsHelpers -Repository PSGallery -Scope CurrentUser -Verbose
```

If prompted to trust the repository, hit `Y` and `enter`.

All [required modules](src/Generate-DockerImageVariantsHelpers/Generate-DockerImageVariantsHelpers.psd1) are automatically installed:

- [Generate-DockerImageVariants](https://www.powershellgallery.com/packages/Generate-DockerImageVariants/)
- [PowerShellForGitHub](https://www.powershellgallery.com/packages/PowerShellForGitHub)

## Usage

Import the module, and the [cmdlets](src/Generate-DockerImageVariantsHelpers/public) will be available. For example:

```powershell
Import-Module Generate-DockerImageVariantsHelpers

# Clone the current repo to a temporary directory
$repo = Clone-TempRepo
cd $repo

# Create generate/definitions/versions.json
New-DockerImageVariantsVersions -Package coolpackage -VersionsChangeScope minor -VersionsNewScript { Invoke-RestMethod https://example.com/versions.json } #-Limit 1 -Whatif
New-DockerImageVariantsVersions -Package coolpackage -VersionsChangeScope patch -VersionsNewScript { Invoke-RestMethod https://example.com/versions.json } #-Limit 1 -Whatif

# Get generate/definitions/versions.json
$versionsConfig = Get-DockerImageVariantsVersions

# Set generate/definitions/versions.json
Set-DockerImageVariantsVersions @{
    coolpackage = @{
        versions = @(
            '0.1.0'
            '0.2.0'
        )
        versionsChangeScope = 'minor'
        versionsNewScript = 'Invoke-RestMethod https://example.com/versions.json'
        limit = 1 # optional
    }
} #-WhatIf

# Execute commands
{ git status } | Execute-Command -ErrorAction Stop #-WhatIf

# Get changed versions
$versionsChanged = Get-VersionsChanged -Versions @( '0.1.0' ) -VersionsNew @( '0.1.1', '0.2.0' ) -ChangeScope patch -AsObject
$versionsChanged = Get-VersionsChanged -Versions @( '0.1.0' ) -VersionsNew @( '0.1.1', '0.2.0' ) -ChangeScope minor -AsObject

# Open PR for each changed version
$env:GITHUB_TOKEN = 'xxx'
$prs = @(
    foreach ($c in $versionsChanged.Values) {
        if ($c['kind'] -eq 'new') {
            New-DockerImageVariantsPR -Package coolpackage -Version $c['to'] -Verb add #-WhatIf
        }
        if ($c['kind'] -eq 'update') {
            New-DockerImageVariantsPR -Package coolpackage -Version $c['from'] -VersionNew $c['to'] -Verb update #-WhatIf
        }
    }
)
# Merge each successful PR one after another
$env:GITHUB_TOKEN = 'xxx'
foreach ($pr in $prs) {
    $pr = Automerge-DockerImageVariantsPR -PR $pr #-WhatIf
}

# Update ./generate/definitions/versions.json and open a PR for each changed version, and merge successful PRs one after another (to prevent merge conflicts)
$env:GITHUB_TOKEN = 'xxx'
$autoMergeResults = Update-DockerImageVariantsVersions -PR -AutoMergeQueue #-WhatIf
# Update ./generate/definitions/versions.json and open a PR for each changed version, and merge successful PRs one after another (to prevent merge conflicts), and create a tagged release and close milestone
$autoMergeResults = Update-DockerImageVariantsVersions -PR -AutoMergeQueue -AutoRelease -AutoReleaseTagConvention calver #-WhatIf
$autoMergeResults = Update-DockerImageVariantsVersions -PR -AutoMergeQueue -AutoRelease -AutoReleaseTagConvention semver #-WhatIf

# Get next tag
$tag = Get-TagNext -TagConvention calver
$tag = Get-TagNext -TagConvention semver

# Tag <tag>, push new <tag>, rename milestone 'next-release' to <tag>, and close milestone
$env:GITHUB_TOKEN = 'xxx'
$tag = New-Release -TagConvention calver #-WhatIf
$tag = New-Release -TagConvention semver #-WhatIf
```
