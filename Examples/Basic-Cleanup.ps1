#requires -Modules ScriptAsService
#requires -RunAsAdministrator
Uninstall-ScriptAsService -Name "basic_example"
Remove-Item -Path "$env:USERPROFILE\Temp-Basic-Example-Script-As-Service" -Recurse -Force