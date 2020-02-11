# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot   = $env:BHProjectPath
    $ModuleName    = $env:BHProjectName
    $ModuleVersion = (Get-Module -ListAvailable $env:BHPSModuleManifest).Version
    $SpecsFolder   = (Resolve-Path "$ProjectRoot\Specs")
    $TestsFolder   = (Resolve-Path "$ProjectRoot\Tests")
    $BuildFolder   = "$ProjectRoot\$ModuleName\$ModuleVersion"
    $Timestamp     = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion     = $PSVersionTable.PSVersion.Major
    $HelpOutput    = "Results_Help`_$TimeStamp.xml"
    $SpecOutput    = "Results_Specs_PS$PSVersion`_$TimeStamp.xml"
    $ApiKey        = $env:APIKEY
}

Task Default -Depends Test

Task Build {
    Write-Host "Building Module Structure"  -ForegroundColor Blue
    $Functions = Get-ChildItem -Path $ProjectRoot\Source\Functions -Recurse -Exclude *.Tests.* -File `
    | ForEach-Object -Process {Get-Content -Path $_.FullName; "`r`n"}
    If (-not (Test-Path $BuildFolder)) {
        Write-Host "Creating Output Folder"  -ForegroundColor Blue
        $Null = New-Item -Path $BuildFolder -Type Directory -Force
    } Else {
        Write-Host "Clearing Existing Output Folder"  -ForegroundColor Blue
        $Null = Remove-Item -Path $BuildFolder -Recurse -Force
    }
    Write-Host "Placing Dependencies"  -ForegroundColor Blue
    $Null = Copy-Item   -Path "$ProjectRoot\Source\libraries" -Container -Recurse -Destination $BuildFolder\Libraries -Force
    Write-Host "Copying Module Manifest"  -ForegroundColor Blue
    $Null = Copy-Item   -Path "$ProjectRoot\Source\$ModuleName.psd1" -Destination $BuildFolder -Force
    Write-Host "Creating and compiling Module file"  -ForegroundColor Blue
    $Null = New-Item    -Path "$BuildFolder\$ModuleName.psm1" -Type File -Force
    $Null = Add-Content -Path "$BuildFolder\$ModuleName.psm1" -Value $Functions,"`r`n"
    $Null = Get-Content -Path "$ProjectRoot\Source\$ModuleName.psm1" `
    | Select-Object -Last 1 `
    | Add-Content -Path $BuildFolder\$ModuleName.psm1

    Write-Host "Module built, verifying module output" -ForegroundColor Blue 
    Get-Module -ListAvailable "$BuildFolder\$ModuleName.psd1" `
    | ForEach-Object -Process {
        $ExportedFunctions = $_ `
        | Select-Object -Property @{ Name = "ExportedFunctions" ; Expression = { [string[]]$_.ExportedFunctions.Keys } } `
        | Select-Object -ExpandProperty ExportedFunctions
        $ExportedAliases   = $_ `
        | Select-Object -Property @{ Name = "ExportedAliases"   ; Expression = { [string[]]$_.ExportedAliases.Keys   } } `
        | Select-Object -ExpandProperty ExportedAliases
        $ExportedVariables = $_ `
        | Select-Object -Property @{ Name = "ExportedVariables" ; Expression = { [string[]]$_.ExportedVariables.Keys } } `
        | Select-Object -ExpandProperty ExportedVariables
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

Task Test -Depends Build {
    Write-Host "Testing Module Help"  -ForegroundColor Blue
    $HelpResults = Invoke-Pester $TestsFolder -OutputFormat NUnitXml -OutputFile $HelpOutput -PassThru
    If ($HelpResults.FailedCount -gt 0) {
        Exit $HelpResults.FailedCount
    }
    # This will be uncommented once we're ready to actually start using gherkin.
    #Write-Host "Testing Module Specifications"  -ForegroundColor Blue
    #$SpecResults = Invoke-Gherkin $SpecsFolder -OutputFormat NUnitXml -OutputFile $SpecOutput
}

Task Deploy -Depends Test {
    Write-Host "Deploying the module to the Gallery" -ForegroundColor Blue
    $GalleryModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue
    Try {
        If ([string]::IsNullOrEmpty($GalleryModule) -or ($GalleryModule.Version -lt $ModuleVersion)) {
            Publish-Module -Path "$BuildFolder" -NuGetApiKey $ApiKey -ErrorAction Stop -Verbose
        } Else {
            Throw "Version of the module being published is not higher than the version on the gallery!"
        }
    } Catch {
        Format-List -InputObject $Error[0] -Force -Property *
        exit 0
    }
}
