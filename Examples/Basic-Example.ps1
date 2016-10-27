#requires -Modules ScriptAsService
#requires -RunAsAdministrator

$SourceFile = "$PSScriptRoot\Basic-Script.ps1"
$BaseFolder = "$env:USERPROFILE\Temp-Basic-Example-Script-As-Service"
$ScriptFile = "$BaseFolder\Basic.ps1"
$OutputFile = "$BaseFolder\basic.exe"
$ServiceName = "basic_example"
$ServiceDisplayName = "Basic Example of a Script As Service"
$ServiceDescription = "A basic example of PowerShell script as service; simply creates a file in your downloads file and updates it continuously."

Try {
    If (-not (Test-Path $BaseFolder)){
        New-Item -Path $BaseFolder -ItemType Directory -Force
        (Get-Content -Path $SourceFile).Replace("_ENVUSERNAME_",$env:USERNAME) | Out-File -FilePath $ScriptFile
    }
    New-ScriptAsService -Path $ScriptFile -Destination $OutputFile -Name $ServiceName -DisplayName $ServiceDisplayName -Description $ServiceDescription -ErrorAction Stop
    Install-ScriptAsService -Path $OutputFile -Name $ServiceName -Description $ServiceDescription -ErrorAction Stop
    Do {
        Start-Sleep -Seconds 10
        Get-Content -Path "$BaseFolder\_TestService.txt"
        Write-Host "`r`nYou've just checked the file. It should write a new log every ten seconds."
        $Response = Read-Host "Do you want to continue checking the file? (y)es or (n)o?"
        If($Response -in @('n','N','no','No')){
            $Continue = $false
        } Else {
            $Continue = $true
        }
    } While ($Continue -eq $true)
} Catch {
    Throw $_
}