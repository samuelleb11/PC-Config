# Init
. $(Join-Path -Path $(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition) -ChildPath "Init.ps1") -SourcePath $MyInvocation.MyCommand.Path
if (!$Global:Live){exit}

$ChocolateyPackages = foreach ($Package in $State.packages.Keys) { if ($State.packages.$Package.provider -eq "chocolatey") { $State.packages.$Package } }
$MSIPackages = $State.packages.Keys | Where-Object { $State.packages.$_.provider -eq "msi" }

# Install MSI packages
if (![string]::IsNullOrEmpty($MSIPackages)) {
    $Installed = Get-CimInstance -Class Win32_Product
    foreach ($Package in $MSIPackages) {
        if ([string]::IsNullOrEmpty($($Installed | Where-Object { $_.Name -contains $State.packages.$Package.packageName }))) {
            if (![string]::IsNullOrEmpty($State.packages.$Package.path)) {
                $MsiPath = $State.packages.$Package.path
            }
            elseif (![string]::IsNullOrEmpty($State.packages.$Package.url)) {
                Invoke-WebRequest -Uri $State.packages.$Package.url -OutFile $(Join-Path -Path $TempFolder -ChildPath "$($State.packages.$Package.packageName).msi")
                $MsiPath = $(Join-Path -Path $TempFolder -ChildPath "$($State.packages.$Package.packageName).msi")
            }
            Write-Host "$($State.packages.$Package.packageName) is to be installed by MSI package"
            Start-Process -FilePath $(Join-Path -Path $(Join-Path -Path $env:windir -ChildPath "system32") -ChildPath "msiexec.exe") -ArgumentList "/I $MsiPath /quiet" -Wait
        }
    }
}

# Install Chocolatey packages
if (![string]::IsNullOrEmpty($ChocolateyPackages)) {
    Get-ChocolateyEXE
    $Installed = Get-ChocolateyPackages
    foreach ($Package in $ChocolateyPackages.packageName) {
        if ([string]::IsNullOrEmpty($($Installed | Where-Object { $_.Package -eq $Package }))) {
            Write-Host "$Package is to be installed by Choco"
            Install-ChocolateyPackage -Name $Package
        }
    }
}

# Setting Windows preferences
if (![string]::IsNullOrEmpty($State.WindowsExplorer.FolderOptions.Keys) -or ![string]::IsNullOrEmpty($State.WindowsExplorer.Taskbar.Keys) -or ![string]::IsNullOrEmpty($State.WindowsExplorer.Desktop.Keys)) {
    #Set Folder Options
    if (![string]::IsNullOrEmpty($State.WindowsExplorer.FolderOptions.Keys)) {
        foreach ($Item in $State.WindowsExplorer.FolderOptions.Keys) {
            if (![string]::IsNullOrEmpty($State.WindowsExplorer.FolderOptions.$Item)) {
                Write-Host -ForegroundColor Yellow "Setting Windows Explorer folder option $Item ..."
                WindowsExplorerFunctionHelper -Function "Set-WindowsExplorerFolder$Item" -Value $State.WindowsExplorer.FolderOptions.$Item
            }
        }
    }
    #Set Taskbar
    if (![string]::IsNullOrEmpty($State.WindowsExplorer.Taskbar.Keys)) {
        foreach ($Item in $State.WindowsExplorer.Taskbar.Keys) {
            if (![string]::IsNullOrEmpty($State.WindowsExplorer.Taskbar.$Item)) {
                Write-Host -ForegroundColor Yellow "Setting Windows Explorer taskbar $Item ..."
                WindowsExplorerFunctionHelper -Function "Set-WindowsExplorerTaskbar$Item" -Value $State.WindowsExplorer.Taskbar.$Item
            }
        }
    }
    #Set Desktop
    if (![string]::IsNullOrEmpty($State.WindowsExplorer.Desktop.Keys)) {
        if (![string]::IsNullOrEmpty($State.WindowsExplorer.Desktop.Wallpaper)) {
            Write-Host -ForegroundColor Yellow "Setting Windows Explorer desktop Wallpaper ..."
            Set-WindowsExplorerDesktopWallpaper -Wallpaper $State.WindowsExplorer.Desktop.Wallpaper -Type $State.WindowsExplorer.Desktop.WallpaperSource -Fit $State.WindowsExplorer.Desktop.WallpaperFit -Cleanup $(if ($State.WindowsExplorer.Desktop.WallpaperCleanup -eq "true") { $true }else { $false })
        }
    rundll32.exe user32.dll, UpdatePerUserSystemParameters
    }
    #Set Power
    if (![string]::IsNullOrEmpty($State.Power.Keys)) {
        if (![string]::IsNullOrEmpty($State.Power.PowerProfile)) {
            Write-Host -ForegroundColor Yellow "Setting Windows power profile ..."
            Set-WindowsPowerProfile -PowerProfile $State.Power.PowerProfile
        }
    }
    Restart-WindowsExplorer
}

#Cleanup
Write-Host -ForegroundColor Black -BackgroundColor Yellow "Cleaning temporary files ..."
$Cleaned = $false
while (!$Cleaned) {
    Start-Sleep -Seconds 1
    Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    if (!$(Test-Path $TempFolder)) {
        $Cleaned = $true
    }
}
Write-Host -ForegroundColor Black -BackgroundColor Green "Done !"
Read-Host "Press a key to exit ..."