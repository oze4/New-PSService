<#
        .SYNOPSIS
        Test .ps1 script to be used as a Windows Service.

        .DESCRIPTION
        Save as .ps1 and run.
        Script creates a file "%USERPROFILE%\Downloads\_TestService.txt" in the current users Downloads Folder
        Every 10 seconds from the time it is started, it will add the date to the above file.

#>
Remove-Variable -Name firstLoop -Force -EA SilentlyContinue -WA SilentlyContinue | Out-Null
for($go = 1; $go -lt 2) # $go will always be less than 2, so this script will run until user intervention
{
    $d = Get-Date
    $p = "C:\users\_ENVUSERNAME_\Temp-Basic-Example-Script-As-Service\_TestService.txt"
    if(Test-Path $p)
    {
        if($firstLoop -ne $false)
        {
            Add-Content -Value "$($d) - Script Started" -Path $p -EA SilentlyContinue -WA SilentlyContinue
            $firstLoop = $false
        }
        else
        {
            Add-Content -Value $d -Path $p -EA SilentlyContinue -WA SilentlyContinue
        }
    }

    if(!(Test-Path $p))
    {
        New-Item -Path $p -ItemType File -EA SilentlyContinue -WA SilentlyContinue | Out-Null
        if($firstLoop -ne $false)
        {
            Add-Content -Value "$($d) - Script Started" -Path $p -EA SilentlyContinue -WA SilentlyContinue
            $firstLoop = $false
        }
        else
        {
            Add-Content -Value $d -Path $p -EA SilentlyContinue -WA SilentlyContinue
        }
    }
    Start-Sleep -Seconds 10
}
