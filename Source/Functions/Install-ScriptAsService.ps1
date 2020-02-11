Function Install-ScriptAsService {
    <#
        .SYNOPSIS
         Installs a script-as-service binary to the local computer.

        .DESCRIPTION

        .PARAMETER Path
         The full or relative path to the binary file which should be run as a service.

        .PARAMETER Name
         The short, terse, unique name of the service - this **CAN NOT** have any spaces in it.

        .PARAMETER Description
         The description of the service you are creating. You can, optionally, leave this null.

        .PARAMETER Credential
         The credential (username and password) under which the service should run.
         It is preferable to set this to an account with minimal required permissions or managed service account.

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
        [Alias("DisplayName","ServiceName")]
        [string]$Name,
        [Parameter(Mandatory=$true,
        HelpMessage="Type the desired service description.")]
        [Alias("SvcDescription","ServiceDescription")]
        [string]$Description,
        [Management.Automation.PSCredential]$Credential
    )

    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    $regName = 'Description'
    $regValue = "$Description"

    Try {
        $ErrorActionPreferenceHolder = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        $InstallProcess = Start-Process $Path -ArgumentList "/install" -PassThru -Wait -WindowStyle Hidden
        $null = New-ItemProperty -Path $registryPath -Name $regName -Value $regValue -PropertyType String -Force | Out-Null
        If ($Credential) {
            $null = Set-ServiceCredential -serviceName $Name -serviceCredential $Credential
        }
        $null = Set-Service $Name -StartupType Automatic
        $null = Start-Service $Name
        Get-Service $Name
        $ErrorActionPreference = $ErrorActionPreferenceHolder
    } Catch {
        Throw $_
    }

}