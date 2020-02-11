Function Install-ScriptAsService {
    <#
        .SYNOPSIS
         Installs a script-as-service binary to the local computer.

        .DESCRIPTION
         Installs a script-as-service binary to the local computer.

        .PARAMETER Path
         The full or relative path to the binary file which should be run as a service.

        .PARAMETER Name
         The short, terse, unique name of the service - this **CAN NOT** have any spaces in it.

        .PARAMETER Description
         The description of the service you are creating. You can, optionally, leave this null.

        .PARAMETER Credential
         The credential (username and password) under which the service should run.
         It is preferable to set this to an account with minimal required permissions or managed service account.

        .EXAMPLE
         Install-ScripptAsService -Path C:\Project\Out\project.exe -Name Project -DisplayName 'Scheduled Project' -Credential $Cred

         This command installs a looping scriptp as a service from the specified path and with the specified name and display name.

    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
        HelpMessage="Type the path (full or relative) to the script-as-service binary you want to install; make sure to include the file name and extension.")]
        [ValidateScript({Test-Path -Path $_})]
        [Alias("FilePath","SourceFilePath","ScriptPath")]
        [string]$Path,
        [Parameter(Mandatory=$true,
        HelpMessage="Type the SERVICE NAME [[ this is NOT the display name! ]] `r`nService Name must not contain spaces!")]
        [Alias("ServiceName")]
        [string]$Name,
        [Parameter(Mandatory=$true,
        HelpMessage="Type the desired service description.")]
        [Alias("SvcDescription","ServiceDescription")]
        [string]$Description,
        [Management.Automation.PSCredential]$Credential
    )

    [string]$RegistryPath  = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    [string]$RegistryName  = 'Description'
    [string]$RegistryValue = $Description

    Try {
        $ErrorActionPreferenceHolder = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        Start-Process -FilePath $Path -ArgumentList "/install" -Wait -WindowStyle Hidden
        $null = New-ItemProperty -Path $RegistryPath -Name $RegistryName -Value $RegistryValue -PropertyType String -Force
        If ($Credential) {
            $null = Set-ServiceCredential -ServiceName $Name -ServiceCredential $Credential
        }
        $null = Set-Service -Name $Name -StartupType Automatic
        $null = Start-Service -Name $Name
        Get-Service -Name $Name
        $ErrorActionPreference = $ErrorActionPreferenceHolder
    } Catch {
        Throw $_
    }
}
