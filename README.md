# ScriptAsService
Turn any looping .ps1 script into a Windows Service With the help of the included Sorlov Assemblies (https://twitter.com/sorlov/status/515149451691044864).

THANK YOU DANIEL SORLOV!

## Installation 
To install this module, simply run:
```powershell
Install-Module -Name ScriptAsService
```

## Example
For an example of how to use the module, clone the project locally and open an elevated PowerShell Prompt in the cloned folder (or `cd` into the cloned folder once you've opened PowerShell):

```powershell
.\Examples\Basic-Example.ps1
```

This will create an executable, install it as a service, and verify the output.
Essentially, the service will just write the current time to a log file every ten seconds.

To clean up after the example, run the following from the same prompt:

```powershell
.\Examples\Basic-Cleanup.ps1
```

## Build Locally From Source
Once you've cloned this project, open a PowerShell prompt and set the root folder of this project as your current directory. Then:

```powershell
Invoke-Psake -buildFile .\psake.ps1 -taskList Build
```

This will build a folder, `ScriptAsService` in the current directory.
In that folder is a versioned folder containing the module.
You should be able to copy this folder to your Module Path if you want, or import the module via path.
