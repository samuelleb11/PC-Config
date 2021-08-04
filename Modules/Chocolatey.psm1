function Get-ChocolateyEXE {
    $ChocoEXEPath = $(Join-Path -Path $(Join-Path -Path $env:ProgramData -ChildPath "chocolatey") -ChildPath "choco.exe")
    if (!$(Test-Path $ChocoEXEPath)) {
        Write-Host -ForegroundColor Yellow "Installing Chocolatey ..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        if ($LASTEXITCODE -ne 0) {
            Throw "Install of Chocolatey has failed ..."
            exit
        }
    }
    else {
        Write-Host -ForegroundColor Green "Chocolatey is already installed !"
        $Global:ChocoEXE = $ChocoEXEPath
    }
}
function Install-ChocolateyPackage ($Name) {
    $Command = $Global:ChocoEXE + " install " + $Name + " -y -force"
    Write-Host -ForegroundColor Yellow "Installing $Name with Chocolatey ..."
    Invoke-Expression -Command $Command
    if ($LASTEXITCODE -ne 0) {
        Throw "Install failed for $Name with Chocolatey ..."
    }
}
function Get-ChocolateyPackages () {
    $List = choco list -lo
    $List = $List[1..($List.Length - 2)]
    $FinalList = @()
    foreach ($Item in $List) {
        $FinalList += [pscustomobject]@{
            Package = $Item.Split(' ')[0]
            Version = $Item.Split(' ')[1]
        }
    }
    return $FinalList
}

Export-ModuleMember -Function *