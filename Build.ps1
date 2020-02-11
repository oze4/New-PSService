[cmdletbinding()]
Param (
    [string]$ApiKey,
    [string[]]$TaskList
)

ForEach ($Module in @("Pester","Psake","BuildHelpers")) {
    If (!(Get-Module -ListAvailable $Module)) {
        Find-Module $Module | Install-Module -Force
    }
    Import-Module $Module
}

Push-Location $PSScriptRoot
Write-Output "Retrieving Build Variables"
Get-ChildItem -Path env:\bh* | Remove-Item
Set-BuildEnvironment
$null = New-Item -Path ENV:\APIKEY -Value $ApiKey

If ($TaskList.Count -gt 0) {
    Write-Output "Executing Tasks: $TaskList`r`n"
    Invoke-Psake -buildFile .\psake.ps1 -properties $PSBoundParameters -noLogo -taskList $TaskList
} Else {
    Write-Output "Executing Unit Tests Only`r`n"
    Invoke-Psake -buildFile .\psake.ps1 -properties $PSBoundParameters -nologo
}
