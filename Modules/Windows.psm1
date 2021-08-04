function Set-WindowsExplorerFolderShowHiddenFiles ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key Hidden 1 }
    if ($Disable) { Set-ItemProperty $key Hidden 0 }
}
function Set-WindowsExplorerFolderShowExtensions ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key HideFileExt 0 }
    if ($Disable) { Set-ItemProperty $key HideFileExt 1 }
}
function Set-WindowsExplorerFolderShowSystemFiles ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key ShowSuperHidden 1 }
    if ($Disable) { Set-ItemProperty $key ShowSuperHidden 0 }
}
function Set-WindowsExplorerTaskbarSmallIcons ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key TaskbarSmallIcons 1 }
    if ($Disable) { Set-ItemProperty $key TaskbarSmallIcons 0 }
}
function Set-WindowsExplorerTaskbarAlwaysCombine ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key TaskbarGlomLevel 0 }
    if ($Disable) { Set-ItemProperty $key TaskbarGlomLevel 1 }
}
function Set-WindowsExplorerTaskbarShowCortanaButton ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key ShowCortanaButton 1 }
    if ($Disable) { Set-ItemProperty $key ShowCortanaButton 0 }
}
function Set-WindowsExplorerTaskbarShowTaskViewButton ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key ShowTaskViewButton 1 }
    if ($Disable) { Set-ItemProperty $key ShowTaskViewButton 0 }
}
function Set-WindowsExplorerTaskbarShowPeopleBand ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    if ($Enable) { Set-ItemProperty $key PeopleBand 1 }
    if ($Disable) { Set-ItemProperty $key PeopleBand 0 }
}
function Set-WindowsExplorerTaskbarShowSearch ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    if ($Enable) { Set-ItemProperty $key SearchboxTaskbarMode 1 }
    if ($Disable) { Set-ItemProperty $key SearchboxTaskbarMode 0 }
}
function Set-WindowsExplorerTaskbarShowKeyboardButton ([switch]$Enable, [switch]$Disable) {
    $key = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
    if ($Enable) { Set-ItemProperty $key TipbandDesiredVisibility 1 }
    if ($Disable) { Set-ItemProperty $key TipbandDesiredVisibility 0 }
}
function Set-WindowsExplorerDesktopWallpaper ($Wallpaper,$Type,$Fit,$Cleanup) {
    if (![string]::IsNullOrEmpty($Fit)){
        $FitList = @{
            "Fill" = 10
            "Fit" = 6
            "Stretch" = 2
            "Tile" = 0
            "Center" = 0
            "Span" = 22
        }
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name WallpaperStyle -Value $FitList.$Fit -Force
        if ($Fit -eq "Tile"){
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name TileWallpaper -Value 1 -Force
        }
        elseif ($Fit -ne "Tile"){
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name TileWallpaper -Value 0 -Force
        }
    }
    if (![string]::IsNullOrEmpty($Wallpaper)){
        $setwallpapersrc = @"
using System.Runtime.InteropServices;

public class Wallpaper
{
  public const int SetDesktopWallpaper = 20;
  public const int UpdateIniFile = 0x01;
  public const int SendWinIniChange = 0x02;
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
  public static void SetWallpaper(string path)
  {
    SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
  }
}
"@
        Add-Type -TypeDefinition $setwallpapersrc
        $WallpaperDir = (New-Item -Path $(Join-Path -Path $env:USERPROFILE -ChildPath "PC-Config") -Name "Wallpaper" -ItemType Directory -Force).FullName
        $WallpaperPath = Join-Path -Path $WallpaperDir -ChildPath "Wallpaper$(Get-Date -Format "yyyy-MM-dd-hhmm").jpg"
        if ($Type -eq "url") {
            Invoke-WebRequest -Uri $Wallpaper -OutFile $WallpaperPath
        }
        elseif ($Type -eq "path") {
            Copy-Item -Path $Wallpaper -Destination $WallpaperPath -Force
        }
        [Wallpaper]::SetWallpaper($WallpaperPath)
    }
    if ($Cleanup){
        Get-ChildItem -Path $WallpaperDir | Where-Object {$_.Name -ne $(Split-Path -Path $WallpaperPath -Leaf)} | Remove-Item -Force
    }
}
function Set-WindowsPowerProfile ($PowerProfile){
    if ($PowerProfile -eq "Performance"){
        powercfg.exe -SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    }
}
function WindowsExplorerFunctionHelper ([string]$Function, [string]$Value) {
    if ($Value -eq $true) {
        Invoke-Expression -Command "$Function -Enable"
    }
    if ($Value -eq $false) {
        Invoke-Expression -Command "$Function -Disable"
    }
}
function Restart-WindowsExplorer () {
    Write-Host -ForegroundColor Yellow "Restarting Windows Explorer ..."
    Start-RestartManagerSession
    Register-RestartManagerResource -Process $(Get-Process explorer)
    Stop-RestartManagerProcess
    Restart-RestartManagerProcess
    Stop-RestartManagerSession
    if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor Red "Restart of Windows Explorer failed. Please logoff/login or restart explorer.exe manually."
    }
}
Export-ModuleMember -Function *