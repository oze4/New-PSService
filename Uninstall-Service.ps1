function Uninstall-Service {
<#    
.SYNOPSIS
Function to uninstall Service

.INFO
Must use SERVICE NAME, not SERVICE DESCRIPTION! (service name is typically the .exe name)

#>    
    Param(
    [Parameter( Mandatory = $true )]
    $serviceName
    )

    $serv = Get-WmiObject -Class win32_service | where {$_.Name -eq $serviceName}
    $serv.StopService()
    $serv.Delete()
}