# Purpose of the script: Collects BIOS details from HP/Dell desktops. Outputs to screen and saves CSV files.

$bios = Get-CimInstance Win32_BIOS
$cs = Get-CimInstance Win32_ComputerSystem
$prod = Get-CimInstance Win32_ComputerSystemProduct
$board = Get-CimInstance Win32_BaseBoard
$enc = Get-CimInstance Win32_SystemEnclosure
$os = Get-CimInstance Win32_OperatingSystem

# Ignore errors if missing
$tpm = Get-CimInstance -NameSpace root\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm -ErrorAction SilentlyContinue
$sb = Get-CimInstance -NameSpace root\Microsoft\Windows\SecureBoot -Class MS_SecureBoot -ErrorAction SilentlyContinue

$report = [PSCustomObject]@{ # BIOS details
    ComputerName = $env:COMPUTERNAME
    Manufacturer = $cs.Manufacturer
    Model        = $cs.Model
    SerialNumber = $prod.IdentifyingNumber
    UUID         = $prod.UUID
    AssetTag     = $enc.SMSBIOSAssetTag
    BIOS_Manufacturer = $bios.Manufacturer
    BIOS_Version = ($bios.SMBIOSBIOSVersion ?? ($bios.BIOSVersion -join ' '))
    BIOS_ReleaseDate  = [System.Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate)
    BaseBoard    = "$(board.Manufacturer) $(board.Product)"
    BaseBoard_Serial  = $board.SerialNumber
    SecureBootEnabled = sb.SecureBootEnabled
    TPM_Enabled  = $tpm.IsEnabled_InitialValue
    TPM_Ready    = $tpm.IsReady_InitialValue
    TimeStamp    = Get-Date
    OS_Name      = $os.Caption
    OS_Version   = $os.Version
    OS_InstallDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate)
    OS_Architecture = $os.OSArchitecture
}

$report | Format-List
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$base  = "BIOS-REPORT-$($report.ComputerName)-$stamp"
$report | ConvertTo-Json -Depth 4 | Out-File "$base.json" -Encoding UTF8
$report | Export-Csv "$base.csv" -NoTypeInformation -Encoding UTF8