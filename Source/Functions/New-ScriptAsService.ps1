Function New-ScriptAsService {
    <#
        .SYNOPSIS
        Creates a Windows Service via .ps1 script.

        .DESCRIPTION
        This script is designed to convert at .ps1 looping script into a Windows Service legible binary file (aka .exe).

        The script **must** include the looping logic inside itself or the service will fail to run properly.

        You _must_ include the path to the script which is to be turned into a service, the destination path for the binary,
        the name of the service, and the display name of the service.

        You _can_, optionally, sign your binaries with a code-signing cert and timestamp url.
        You can also give the new binary an icon.

        .PARAMETER Path
         The full or relative path to the script file which should be run as a service.

        .PARAMETER Destination
         The full or relative path you want the binary to be output to.
         Note that this must include the name and extension of the binary (`C:\Some\Path\foo.exe`) whether you specify a full or relative path.

        .PARAMETER Name
         The short, terse, unique name of the service - this **CAN NOT** have any spaces in it.

        .PARAMETER DisplayName
         The display name of the service - something human readable and friendly.
         This _can_ include spaces.

        .PARAMETER Description
         The description of the service you are creating. You can, optionally, leave this null.

        .PARAMETER IconFilePath
         The full or relative path to the icon you want to set for the new service.
         This is optional.

        .PARAMETER Version
         The version you want the binary output to have - if you do not specify one, the version defaults to 1.0.0.
         Must be a valid [Semantic Version](semver.org).

        .EXAMPLE
         New-ScriptAsService -Path .\Project\project.ps1 -Name Project -DisplayName 'Looping Project'

         This will create a script-as-service binary, called `project.exe`, which when installed as a service
         will have a name of `Project` and a display name of `Looping Project`. The description will be empty
         and the version will be `1.0.0`.

        .PARAMETER SigningCertificatePath
         The full or relative path to the certificate you want to use for signing your binary.
         Must be a cert valid for code signing.
         This is an optional parameter.

        .PARAMETER TimeStampUrl
         If you are signing your binary, you probably also want to provide a timestamp url.
         Otherwise, do not include this parameter.

    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
        HelpMessage="Type the path (full or relative) to the Script you want to turn into a service; make sure to include the file name and extension.")]
        [ValidateScript({Test-Path -Path $_})]
        [Alias("FilePath","SourceFilePath","ScriptPath")]
        [string]$Path,

        [Parameter(Mandatory=$true,
        HelpMessage="Type the path (full or relative) to where you want the service executable to be placed; make sure to include the file name and '.exe' extension.")]
        [Alias("OutputFilePath","DestinationPath","BinaryPath")]
        [string]$Destination,

        [Parameter(Mandatory=$true,
        HelpMessage="Type the desired SERVICE NAME [[ this is NOT the display name! ]] `r`nService Name must not contain spaces!")]
        [Alias("SvcName","ServiceName")]
        [string]$Name,

        [Parameter(Mandatory=$true,
        HelpMessage="Type the desired service DISPLAY name.")]
        [Alias("SvcDisplayName","ServiceDisplayName")]
        [string]$DisplayName,

        [Alias("SvcDescription","ServiceDescription")]
        [string]$Description = " ",

        [ValidateScript({Test-Path -Path $_})]
        [Alias("IconPath","Icon")]
        [string]$IconFilePath,

        [version]$Version = "1.0.0",

        [ValidateScript({Test-Path -Path $_})]
        [Alias("CertificatePath","Certificate","CertPath","Cert")]
        [string]$SigningCertificatePath,

        [string]$TimeStampUrl
    )

    $ServiceParameters = @{
        SourceFile         = $Path
        DestinationFile    = $Destination
        Service            = $true
        ServiceDescription = $Description
        ServiceName        = $Name
        ServiceDisplayName = $DisplayName
        Version            = [string]$Version
    }
    
    If (-not [string]::IsNullOrEmpty($SigningCertificatePath)){
        $null = $ServiceParameters.Add("Sign",$true)
        $null = $ServiceParameters.Add("Certificate",$SigningCertificatePath)
        If (-not [string]::IsNullOrEmpty($TimeStampUrl)){
            $null = $ServiceParameters.Add("TimeStampURL",$TimeStampUrl)
        }
    }
    If (-not [string]::IsNullOrEmpty($IconFilePath)){
        $null = $ServiceParameters.Add("IconPath",$IconFilePath)
    }
    New-SelfHostedPS @ServiceParameters
}
