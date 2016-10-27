# Import Dependency Libraries
$DependencyRoot = "$(Split-Path $PSScriptRoot -Parent)\Libraries\Sorlov.PowerShell"
Import-Module "$DependencyRoot\Sorlov.PowerShell.Core.psd1"
Import-Module "$DependencyRoot\Sorlov.PowerShell.SelfHosted.dll"

Get-ChildItem "$PSScriptRoot\Functions" -Recurse |
    Where-Object -FilterScript {$_.FullName -match "\.ps1$" -and $_.FullName -notmatch "\.Tests\."} |
        ForEach-Object -Process {
            . $_.FullName
        }

Export-ModuleMember -Function *