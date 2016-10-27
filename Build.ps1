[cmdletbinding()]
Param (
    $ModuleName          = "ScriptAsService",
    $ApiKey              = 'guid',
    $Gallery             = "Testing",
    $Credential          = 'CredentialPlaceHolder',
    $GalleryComputerName = '',
    $Clean               = $false
)
Import-Module Psake,Pester
Push-Location $PSScriptRoot
Write-Output "Retrieving Build Variables"
$Commit = (git log --format=%h -n 1).Trim()
$Branch = git branch -r -v | Where-Object {$_ -match $Commit} | ForEach-Object -Process {
    $_.Split(' ') | Where-Object {$_ -match '^origin'}
}

Write-Output "Determining whether or not deployment or publishing is required"
$FilesChanged = git diff-tree --no-commit-id --name-only -r $Commit
$DocumentsUpdated = $FilesChanged | Where-Object -FilterScript {$_ -match "^docs" -or $_ -eq "mkdocs.yml"}
$SourceFilesChanged = $FilesChanged | Where-Object -FilterScript {$_ -match "^(Source|Functions|Dependencies)" -or $_ -match "^Mits\.Remoting\.ps(m|d)1$"}

If( $Branch -eq 'origin/master'){
    $TaskList = @()
    If (-not [string]::IsNullOrEmpty($SourceFilesChanged)) {
        Write-Output "$($SourceFilesUpdated.Count) Source Files Updated on Master; Triggering Deployment"
        $TaskList += "Deploy"
    } 
    If (-not [string]::IsNullOrEmpty($DocumentsUpdated))   {
        Write-Output "$($DocumentsUpdated.Count) Documents Updated on Master; Triggering Publishing"
        $TaskList += "Publish"
    }
}

If ($TaskList.Count -gt 0) {
    Write-Output "Executing Tasks: $TaskList`r`n"
    Invoke-Psake -buildFile .\psake.ps1 -properties $PSBoundParameters -noLogo -taskList $TaskList
} Else {
    Write-Output "Executing Unit Tests Only`r`n"
    Invoke-Psake -buildFile .\psake.ps1 -properties $PSBoundParameters -nologo
}