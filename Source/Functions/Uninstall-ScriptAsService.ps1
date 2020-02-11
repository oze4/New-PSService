function Uninstall-ScriptAsService {
    <#
        .SYNOPSIS
         Uninstall a script-as-service binary

        .DESCRIPTION
         Uninstalls a script-as-service from one or more nodes.

        .PARAMETER Name
         The short, terse, unique name of the service - this **CAN NOT** have any spaces in it.

        .PARAMETER ComputerName
         The name of the computer or computers from which you want to uninstall the script-as-service
         binary. By default, the command targets the local machine.

        .EXAMPLE
         Uninstall-ScriptAsService -Name MyProject

         This command will uninstall the script-as-service binary whose service name is `MyProject`.
    #>
    Param(
        [Parameter( Mandatory = $true )]
        [string]$Name,
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Try {
        $Service = Get-WmiObject -Class win32_service -ComputerName $ComputerName -ErrorAction Stop `
        | Where-Object -FilterScript {$_.Name -eq $Name} -ErrorAction Stop
        $null = $Service.StopService()
        $null = $Service.Delete()
    } Catch {
        Throw $_
    }

    $Service = Get-WmiObject -Class win32_service -ComputerName $ComputerName `
    | Where-Object -FilterScript {$_.Name -eq $Name}

    If (-not [string]::IsNullOrEmpty($Service)){
        Throw "Service not uninstalled!"
    }
}
