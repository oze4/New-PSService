# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot         = $PSScriptRoot
    $ModuleName          = "ScriptAsService"
    $ModuleVersion       = Get-Module -ListAvailable "$PSScriptRoot\Source\$ModuleName.psd1" | Select-Object -ExpandProperty Version
    $BuildFolder         = "$ProjectRoot\$ModuleName\$ModuleVersion"
    $Timestamp           = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion           = $PSVersionTable.PSVersion.Major
    $TestFile            = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $ApiKey              = 'guid'
    $Gallery             = "Testing"
    $DeploymentFile      = "$ModuleName.$ModuleVersion.PSDeploy.ps1"
    $Credential          = 'CredentialPlaceHolder'
    $GalleryComputerName = ''
    $Clean               = $false
}

Task Default -Depends Test

Task Test {
    $TestResults = Invoke-Pester -Path $PSScriptRoot -OutputFile "$PSScriptRoot\$TestFile" -OutputFormat NUnitXml  -PassThru -Verbose
    if($TestResults[0].FailedCount -gt 0)
    {
        Write-Error "Failed '$($TestResults[0].FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -depends Test {
    Write-Host "Building Module Structure"  -ForegroundColor Blue
    $Functions = Get-ChildItem -Path $ProjectRoot\Source\Functions -Recurse -Exclude *.Tests.* -File | ForEach-Object -Process {Get-Content -Path $_.FullName; "`r`n"}
    If (-not (Test-Path $BuildFolder)) {
        $Null = New-Item -Path $BuildFolder -Type Directory -Force
    } Else {
        $Null = Remove-Item -Path $BuildFolder\* -Recurse -Force
    }
    Write-Host "Placing Dependencies"  -ForegroundColor Blue
    $Null = Copy-Item   -Path "$ProjectRoot\Libraries"     -Container -Recurse -Destination $BuildFolder -Force
    Write-Host "Copying Module Manifest"  -ForegroundColor Blue
    $Null = Copy-Item   -Path "$ProjectRoot\Source\$ModuleName.psd1" -Destination $BuildFolder -Force
    Write-Host "Creating and compiling Module file"  -ForegroundColor Blue
    $Null = New-Item    -Path "$BuildFolder\$ModuleName.psm1" -Type File -Force
    $Null = Get-Content -Path "$ProjectRoot\Source\$ModuleName.psm1" | Select-Object -First 5 | Add-Content -Path $BuildFolder\$ModuleName.psm1
    $Null = Add-Content -Path "$BuildFolder\$ModuleName.psm1" -Value $Functions,"`r`n"
    $Null = Get-Content -Path "$ProjectRoot\Source\$ModuleName.psm1" | Select-Object -Last 1 | Add-Content -Path $BuildFolder\$ModuleName.psm1

    Write-Host "Module built, verifying module output" -ForegroundColor Blue 
    Get-Module -ListAvailable "$BuildFolder\$ModuleName.psd1" | ForEach-Object -Process {
        $ExportedFunctions = $_ | Select-Object -Property @{ Name = "ExportedFunctions" ; Expression = { [string[]]$_.ExportedFunctions.Keys } } | Select-Object -ExpandProperty ExportedFunctions
        $ExportedAliases   = $_ | Select-Object -Property @{ Name = "ExportedAliases"   ; Expression = { [string[]]$_.ExportedAliases.Keys   } } | Select-Object -ExpandProperty ExportedAliases
        $ExportedVariables = $_ | Select-Object -Property @{ Name = "ExportedVariables" ; Expression = { [string[]]$_.ExportedVariables.Keys } } | Select-Object -ExpandProperty ExportedVariables
        Write-Output "Name              : $($_.Name)"
        Write-Output "Description       : $($_.Description)"
        Write-Output "Guid              : $($_.Guid)"
        Write-Output "Version           : $($_.Version)"
        Write-Output "ModuleType        : $($_.ModuleType)"
        Write-Output "ExportedFunctions : $ExportedFunctions"
        Write-Output "ExportedAliases   : $ExportedAliases"
        Write-Output "ExportedVariables : $ExportedVariables"
    }
}

Task Deploy -depends Build {
    "Deploy $ModuleName {
        By PSGalleryModule To$Gallery {
            FromSource $BuildFolder
            To $Gallery
            Tagged master, Module
            WithOptions @{
                ApiKey = `'$ApiKey`'
            }
        }
    }" | Out-File $DeploymentFile
    Invoke-PSDeploy -Path $DeploymentFile -Verbose -Force
}

Task Publish {
    Push-Location $ProjectRoot
    mkdocs build --quiet --clean

    $SessionOptions = New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck
    $Session = New-PSSession -ComputerName $GalleryComputerName -Credential $Credential -UseSSL -SessionOption $SessionOptions -Verbose 

    If ($Clean -eq $True){
        Invoke-Command -Verbose -Session $Session -ArgumentList $ModuleName -ScriptBlock {
            Param ($ModuleName)
            Remove-Item -Path C:\Docs\$ModuleName\* -Recurse -Force -Verbose
        } 
    }

    Invoke-Command -Session $Session -ArgumentList C:\Docs\$ModuleName -ScriptBlock {
        Param ($Path)
        If(-not (Test-Path $Path)){
            New-Item -Path $Path -ItemType Directory -Force -Verbose
        }
    }
    
    # We've broken the file copy out here into two pieces (top level  files and recursive by directory) because there's
    # a bug in PowerShell when copying over a session; namely it copies the objects from the first source folder to the
    # top level folder in the destination instead of an appropriate subfolder. In this case, css files were being copied
    # to the C:\Docs\$ModuleName instead of C:\Docs\$ModuleName\css - this section is a fix for that behavior.
    Get-ChildItem -Path .\site -File | Copy-Item -ToSession $Session -Destination C:\Docs\$ModuleName -Force -Verbose
    Get-ChildItem -Path .\site -Directory | ForEach-Object {
        $Destination = "C:\Docs\$ModuleName\$(split-path $_.FullName -Leaf)"
        Copy-Item -ToSession $Session -Path $_.FullName -Destination $Destination -Recurse -Verbose -Force
    }

    Remove-PSSession -Session $Session
}