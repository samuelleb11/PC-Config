function Check($Path) {
    if (!$(Test-Path $Path -PathType leaf)) {
        throw "Variable file not found !"
        exit
    }
}
function Remove-FromStringInHashtable($Hashtable, $Value, $String) {
    $NewHashtable = @()
    foreach ($Entry in $Hashtable) {
        $Entry.$Value = $Entry.$Value.Replace($String, "")
        $NewHashtable += $Entry
    }
    return $NewHashtable
}
function Add-UniqueToArray ($Array, $Value) {
    if ($Array -notcontains $Value) {
        $Array += $Value
    }
    return $Array
}
function Test-ElevatedPermission () {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Test-PendingReboot () {
    $Result = $false
    if (![string]::IsNullOrEmpty((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').PendingFileRenameOperations) -and !$Result) {
        $Result = $true
    }
    if (![string]::IsNullOrEmpty((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update').RebootRequired) -and !$Result) {
        $Result = $true
    }
    if (![string]::IsNullOrEmpty((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing').RebootPending) -and !$Result) {
        $Result = $true
    }
    return $Result
}
function Get-MsiInformation {
    [CmdletBinding(SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    [Alias("gmsi")]
    #[OutputType([System.Management.Automation.PSCustomObject[]])]
    Param(
        [parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Provide the path to an MSI")]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo[]]$Path,
  
        [parameter(Mandatory = $false)]
        [ValidateSet( "ProductCode", "Manufacturer", "ProductName", "ProductVersion", "ProductLanguage" )]
        [string[]]$Property = ( "ProductCode", "Manufacturer", "ProductName", "ProductVersion", "ProductLanguage" )
    )
    ForEach ( $P in $Path ) {
        if ($pscmdlet.ShouldProcess($P, "Get MSI Properties")) {            
            try {
                Write-Verbose -Message "Resolving file information for $P"
                $MsiFile = Get-Item -Path $P
                Write-Verbose -Message "Executing on $P"
                     
                # Read property from MSI database
                $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
                $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($MsiFile.FullName, 0))
                     
                # Build hashtable for retruned objects properties
                $PSObjectPropHash = [ordered]@{File = $MsiFile.FullName }
                ForEach ( $Prop in $Property ) {
                    Write-Verbose -Message "Enumerating Property: $Prop"
                    $Query = "SELECT Value FROM Property WHERE Property = '$( $Prop )'"
                    $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
                    $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
                    $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
                    $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
  
                    # Return the value to the Property Hash
                    $PSObjectPropHash.Add($Prop, $Value)
 
                }
                     
                # Build the Object to Return
                $Object = @( New-Object -TypeName PSObject -Property $PSObjectPropHash )
                     
                # Commit database and close view
                $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
                $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
                $MSIDatabase = $null
                $View = $null
            }
            catch {
                Write-Error -Message $_.Exception.Message
            }
            finally {
                    
            }
        } # End of ShouldProcess If
    } # End For $P in $Path Loop
    return $Object
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
    [System.GC]::Collect()
}

Export-ModuleMember -Function *