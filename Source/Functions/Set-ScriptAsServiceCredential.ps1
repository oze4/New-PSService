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

        .EXAMPLE
         Set-ScriptAsServiceCredential -Name MyProject -Credential (Get-Credential SomeAccount)

         This command will ask for the credentials for `SomeAccount` and then set the service `MyProject`
         to run under `SomeAccount` using the specified credentials.

    #>
    [cmdletbinding()]
    param(
        [String[]]$Name,
        [Management.Automation.PSCredential]$Credential,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $ServiceQueryParameters = @{
        "Namespace"    = "root\CIMV2"
        "Class"        = "Win32_Service"
        "ComputerName" = $ComputerName
        "Filter"       = "Name='$Name' OR DisplayName='$Name'"
    }
    $Service = Get-WmiObject @ServiceQueryParameters

    if ( -not $Service ) {
        Write-Error "Unable to find service named '$ServiceName' on '$ComputerName'."
    } else {
        # See https://msdn.microsoft.com/en-us/library/aa384901.aspx
        $returnValue = ($Service.Change($null,                       # DisplayName
                $null,                                               # PathName
                $null,                                               # ServiceType
                $null,                                               # ErrorControl
                $null,                                               # StartMode
                $null,                                               # DesktopInteract
                $ServiceCredential.UserName,                         # StartName
                $ServiceCredential.GetNetworkCredential().Password,  # StartPassword
                $null,                                               # LoadOrderGroup
                $null,                                               # LoadOrderGroupDependencies
                $null)).ReturnValue                                  # ServiceDependencies
        $ErrorMessage = "Error setting credentials for service '$ServiceName' on '$ComputerName'"
        switch ( $returnValue ) {
            0  { Write-Verbose "Set credentials for service '$ServiceName' on '$ComputerName'" }
            1  { Write-Error "$ErrorMessage - Not Supported" }
            2  { Write-Error "$ErrorMessage - Access Denied" }
            3  { Write-Error "$ErrorMessage - Dependent Services Running" }
            4  { Write-Error "$ErrorMessage - Invalid Service Control" }
            5  { Write-Error "$ErrorMessage - Service Cannot Accept Control" }
            6  { Write-Error "$ErrorMessage - Service Not Active" }
            7  { Write-Error "$ErrorMessage - Service Request timeout" }
            8  { Write-Error "$ErrorMessage - Unknown Failure" }
            9  { Write-Error "$ErrorMessage - Path Not Found" }
            10 { Write-Error "$ErrorMessage - Service Already Stopped" }
            11 { Write-Error "$ErrorMessage - Service Database Locked" }
            12 { Write-Error "$ErrorMessage - Service Dependency Deleted" }
            13 { Write-Error "$ErrorMessage - Service Dependency Failure" }
            14 { Write-Error "$ErrorMessage - Service Disabled" }
            15 { Write-Error "$ErrorMessage - Service Logon Failed" }
            16 { Write-Error "$ErrorMessage - Service Marked For Deletion" }
            17 { Write-Error "$ErrorMessage - Service No Thread" }
            18 { Write-Error "$ErrorMessage - Status Circular Dependency" }
            19 { Write-Error "$ErrorMessage - Status Duplicate Name" }
            20 { Write-Error "$ErrorMessage - Status Invalid Name" }
            21 { Write-Error "$ErrorMessage - Status Invalid Parameter" }
            22 { Write-Error "$ErrorMessage - Status Invalid Service Account" }
            23 { Write-Error "$ErrorMessage - Status Service Exists" }
            24 { Write-Error "$ErrorMessage - Service Already Paused" }
        }
    }
}
