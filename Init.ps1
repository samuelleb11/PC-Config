[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $SourcePath
)

$RequiredModules = @('Helpers', 'Chocolatey', 'Windows')
foreach ($RequiredModule in $RequiredModules) {
    Import-Module -Name $(Join-Path -Path $(Join-Path -Path $PSScriptRoot -ChildPath "Modules") -ChildPath "$RequiredModule.psm1") -Force
}
Import-Module -Name $(Join-Path -Path $(Join-Path -Path $PSScriptRoot -ChildPath "Modules") -ChildPath "RestartManager") -Force

Write-Host -ForegroundColor Black -BackgroundColor Green "Initialising..."

if (!$(Test-ElevatedPermission)) {
    throw "Not running in an elevated process !"
    exit
}
if ($host.Version.Major -lt 7){
    if (Test-Path $(Join-Path -Path $(Join-Path -Path $(Join-Path -Path $env:ProgramFiles -ChildPath "Powershell") -ChildPath "7") -ChildPath "pwsh.exe")){
        Start-Process -FilePath $(Join-Path -Path $(Join-Path -Path $(Join-Path -Path $env:ProgramFiles -ChildPath "Powershell") -ChildPath "7") -ChildPath "pwsh.exe") -ArgumentList "-NoExit -File $SourcePath"
        throw "Relaunch in PowerShell 7"
        exit
    }
    elseif ($(Join-Path -Path $(Join-Path -Path $(Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Powershell") -ChildPath "7") -ChildPath "pwsh.exe")){
        Start-Process -FilePath $(Join-Path -Path $(Join-Path -Path $(Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Powershell") -ChildPath "7") -ChildPath "pwsh.exe") -ArgumentList "-NoExit -File $SourcePath"
        throw "Relaunch in PowerShell 7"
        exit
    }
    else {
        Invoke-Expression "& { $(Invoke-RestMethod "https://aka.ms/install-powershell.ps1") } -UseMSI -Quiet"
        if ($LASTEXITCODE -ne 0) {
            Throw "Install of PowerShell 7 has failed ..."
            exit
        }
        Start-Process pwsh.exe -ArgumentList "-NoExit -File $SourcePath"
        throw "Relaunch in PowerShell 7"
        exit
    }
}
if (Test-PendingReboot) {
    Write-Host -ForegroundColor Yellow "A reboot is pending"
    $Exit = $false
    while (!$Exit) {
        $Answer = Read-Host "Do you want to continue ? (Y/N)"
        if ($Answer -eq "N") {
            throw "There is a pending reboot."
            exit
        }
        elseif ($Answer -eq "Y") { $Exit = $true }
    }
}
$envFile = $(Join-Path -Path $(Join-Path -Path $(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition) -ChildPath "Config") -ChildPath "Vars.ps1")
$stateFile = $(Join-Path -Path $(Join-Path -Path $(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition) -ChildPath "Config") -ChildPath "State.json")
Check -Path $envFile
Check -Path $stateFile
. $envFile
$State = Get-Content -Path $stateFile | ConvertFrom-Json -AsHashtable
$TempFolder = (New-Item -Path $env:TEMP -Name "PC-Config" -ItemType Directory -Force).FullName