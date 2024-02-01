# - Initial setup: Fill in the GUID value. Generate one by running the command 'New-GUID'. Then fill in all relevant details.
# - Ensure all relevant details are updated prior to publishing each version of the module.
# - To simulate generation of the manifest based on this definition, run the included development entrypoint script Invoke-PSModulePublisher.ps1.
# - To publish the module, tag the associated commit and push the tag.
@{
    RootModule = 'Generate-DockerImageVariantsHelpers.psm1'
    # ModuleVersion = ''                            # Value will be set for each publication based on the tag ref. Defaults to '0.0.0' in development environments and regular CI builds
    GUID = '2eb27449-9824-4626-aae6-eecfba7bb4d7'
    Author = 'The Oh Brothers'
    CompanyName = 'The Oh Brothers'
    Copyright = '(c) 2023 The Oh Brothers'
    Description = 'Helpers to use with Generate-DockerImageVariants.'
    PowerShellVersion = '3.0'
    # PowerShellHostName = ''
    # PowerShellHostVersion = ''
    # DotNetFrameworkVersion = ''
    # CLRVersion = ''
    # ProcessorArchitecture = ''
    RequiredModules = @(
        @{
            ModuleName = "Generate-DockerImageVariants"
            MaximumVersion = '0.999.0'
        }
        @{
            ModuleName = "PowerShellForGitHub"
            RequiredVersion = '0.17.0'
        }
    )
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    FunctionsToExport = @(
        Get-ChildItem $PSScriptRoot/../../src/Generate-DockerImageVariantsHelpers/public -Exclude *.Tests.ps1 | % { $_.BaseName }
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @(
    #     & {
    #         Set-Location $PSScriptRoot/../../../src/Generate-DockerImageVariants/
    #         Get-ChildItem  -File -Recurse -Force | Resolve-Path -Relative
    #         Set-Location -
    #     }
    # )
    PrivateData = @{
        # PSData = @{           # Properties within PSData will be correctly added to the manifest via Update-ModuleManifest without the PSData key. Leave the key commented out.
            Tags = @(
                'continuous-deployment'
                'continuous-integration'
                'docker'
                'generate-dockerimagevariants'
                'helpers'
            )
            LicenseUri = 'https://raw.githubusercontent.com/theohbrothers/Generate-DockerImageVariantsHelpers/master/LICENSE'
            ProjectUri = 'https://github.com/theohbrothers/Generate-DockerImageVariantsHelpers'
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @()
        # }
        # HelpInfoURI = ''
        # DefaultCommandPrefix = ''
    }
}
