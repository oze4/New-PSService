function Set-ScriptAsServiceCredential {

    <#
        .SYNOPSIS
         Set the Credential of an installed service.

        .DESCRIPTION
         Set or update the credential of an installed service programmatically.
         Sometimes this is required because the username/password of the account has expired or because a new account should be used.

        .PARAMETER Name
         The short, terse, unique name of the service - this **CAN NOT** have any spaces in it.

        .PARAMETER Credential
         The credential under which the service is being set to run.

        .PARAMETER ComputerName
         The ComputerName on which the service is to be updated.
         By default, this command executes against the localmachine.
    #>
    [cmdletbinding()]
    param(
        [String[]]$Name,
        [Management.Automation.PSCredential]$Credential,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ServiceQueryParameters = @{
        "Namespace" = "root\CIMV2"
        "Class" = "Win32_Service"
        "ComputerName" = $ComputerName
        "Filter" = "Name='$Name' OR DisplayName='$Name'"
    }
    $service = Get-WmiObject @ServiceQueryParameters

    if ( -not $service ) {
        Write-Error "Unable to find service named '$serviceName' on '$computerName'."
    } else {
        # See https://msdn.microsoft.com/en-us/library/aa384901.aspx
        $returnValue = ($service.Change($null,                       # DisplayName
                $null,                                               # PathName
                $null,                                               # ServiceType
                $null,                                               # ErrorControl
                $null,                                               # StartMode
                $null,                                               # DesktopInteract
                $serviceCredential.UserName,                         # StartName
                $serviceCredential.GetNetworkCredential().Password,  # StartPassword
                $null,                                               # LoadOrderGroup
                $null,                                               # LoadOrderGroupDependencies
                $null)).ReturnValue                                  # ServiceDependencies
        $errorMessage = "Error setting credentials for service '$serviceName' on '$computerName'"
        switch ( $returnValue ) {
            0  { Write-Verbose "Set credentials for service '$serviceName' on '$computerName'" }
            1  { Write-Error "$errorMessage - Not Supported" }
            2  { Write-Error "$errorMessage - Access Denied" }
            3  { Write-Error "$errorMessage - Dependent Services Running" }
            4  { Write-Error "$errorMessage - Invalid Service Control" }
            5  { Write-Error "$errorMessage - Service Cannot Accept Control" }
            6  { Write-Error "$errorMessage - Service Not Active" }
            7  { Write-Error "$errorMessage - Service Request timeout" }
            8  { Write-Error "$errorMessage - Unknown Failure" }
            9  { Write-Error "$errorMessage - Path Not Found" }
            10 { Write-Error "$errorMessage - Service Already Stopped" }
            11 { Write-Error "$errorMessage - Service Database Locked" }
            12 { Write-Error "$errorMessage - Service Dependency Deleted" }
            13 { Write-Error "$errorMessage - Service Dependency Failure" }
            14 { Write-Error "$errorMessage - Service Disabled" }
            15 { Write-Error "$errorMessage - Service Logon Failed" }
            16 { Write-Error "$errorMessage - Service Marked For Deletion" }
            17 { Write-Error "$errorMessage - Service No Thread" }
            18 { Write-Error "$errorMessage - Status Circular Dependency" }
            19 { Write-Error "$errorMessage - Status Duplicate Name" }
            20 { Write-Error "$errorMessage - Status Invalid Name" }
            21 { Write-Error "$errorMessage - Status Invalid Parameter" }
            22 { Write-Error "$errorMessage - Status Invalid Service Account" }
            23 { Write-Error "$errorMessage - Status Service Exists" }
            24 { Write-Error "$errorMessage - Service Already Paused" }
        }
    }
}