function Get-GitBranchSlug {
    [CmdletBinding(DefaultParameterSetName='Default',SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,ParameterSetName='Default',Position=0)]
        [ValidateNotNull()]
        [string]$CommitMessage
    ,
        [Parameter(ValueFromPipeline,ParameterSetName='Pipeline')]
        [object]$InputObject
    )

    process {
        try {
            if ($InputObject) {
                $CommitMessage = $InputObject
            }

            $commitMessageConventionRegex = '^(Breaking|Change|Chore|Docs|Enhancement|Feature|Fix|Hotfix|Refactor|Style)(:| \(\w+\):) [A-Z].+'
            if (!($CommitMessage -cmatch $commitMessageConventionRegex)) {
                throw "Check your commit message convention. Commit '$CommitMessage' does not match regex: $commitMessageConventionRegex"
            }

            # Shell one-liner: BRANCH=$( echo "$MSG" | awk '{print tolower($0)}' | sed 's/^\s*\|\s*$//g' | sed 's/[^a-zA-Z0-9.*]/-/g' | sed 's/[*]/x/g' | sed 's/-\+/-/g' | sed 's/-/\//' | sed 's/-$//' )
            $slug = $CommitMessage.ToLower()  # Lowercase
            $slug = $slug -replace '^\s*|\s*$', '' # Strip preceding and trailing spaces
            $slug = $slug -replace '[^a-zA-Z0-9.*]', '-' # Replace characters which are not words or '.' with '-'
            $slug = $slug -replace '[*]', 'x' # Replace '*' with 'x'
            $slug = $slug -replace '-+', '-' # Replace contiguous '-' with single '-'
            $slug = $slug -replace '^(\w+)-', '$1/' # Replace first '-' with '/'
            $slug = $slug -replace '-$', '' # Strip trailing '-'

            $slug
        }catch {
            if ($ErrorActionPreference -eq 'Stop') {
                throw
            }
            if ($ErrorActionPreference -eq 'Continue') {
                $_ | Write-Error -ErrorAction Continue
            }
        }
    }
}
