<#
.SYNOPSIS
Creates a new PFX certificate file that includes the complete certificate chain.

.DESCRIPTION
This script uses a graphical file picker to select:

1. The OpenSSL executable.
2. The source PFX certificate.
3. The CA Bundle.

The script extracts the public certificate and private key from the source PFX,
creates a full certificate chain by appending the CA Bundle, and generates a new
PFX file with the suffix "-fullchain".

All generated files are stored in the same directory as the source PFX.

.REQUIREMENTS
- Windows PowerShell 5.1 or later
- OpenSSL for Windows

.EXAMPLE
.\Convert-PfxWithCABundle.ps1

.OUTPUTS
<OriginalName>-cert.pem
<OriginalName>-key.pem
<OriginalName>-fullchain.pem
<OriginalName>-fullchain.pfx

.NOTES
Author      : Juan Ortiz
Company     : To Connect, LLC
Created     : July 2, 2026
Version     : 1.0.0

Version History
---------------
1.0.0
- Initial release.
- GUI-based file selection.
- Creates a fullchain PFX.
- Preserves PEM and key files for troubleshooting.
#>

$ScriptName    = "Convert-PfxWithCABundle"
$ScriptVersion = "1.0.0"
$Author        = "Juan Ortiz"
$Company       = "To Connect, LLC"
$ReleaseDate   = "2026-07-02"

Write-Host "$ScriptName v$ScriptVersion"
Write-Host "Author: $Author"
Write-Host "Company: $Company"
Write-Host "Release Date: $ReleaseDate"
Write-Host ""

Add-Type -AssemblyName System.Windows.Forms

function Select-File {
    param(
        [string]$Title,
        [string]$Filter
    )

    $Dialog = New-Object System.Windows.Forms.OpenFileDialog
    $Dialog.Title = $Title
    $Dialog.Filter = $Filter
    $Dialog.Multiselect = $false

    if ($Dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $Dialog.FileName
    }

    throw "No file selected for: $Title"
}

$OpenSSLExe = Select-File `
    -Title "Select openssl.exe" `
    -Filter "OpenSSL executable (openssl.exe)|openssl.exe|Executable files (*.exe)|*.exe|All files (*.*)|*.*"

$PfxPath = Select-File `
    -Title "Select the source PFX file" `
    -Filter "PFX files (*.pfx)|*.pfx|All files (*.*)|*.*"

$CaBundlePath = Select-File `
    -Title "Select the CA bundle file" `
    -Filter "CA Bundle (*.ca-bundle)|*.ca-bundle|PEM/CER/CRT files (*.pem;*.cer;*.crt)|*.pem;*.cer;*.crt|All files (*.*)|*.*"

$OutputFolder = Split-Path $PfxPath -Parent
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($PfxPath)

$CertPem = Join-Path $OutputFolder "$BaseName-cert.pem"
$KeyPem = Join-Path $OutputFolder "$BaseName-key.pem"
$FullChain = Join-Path $OutputFolder "$BaseName-fullchain.pem"
$NewPfx = Join-Path $OutputFolder "$BaseName-fullchain.pfx"

Write-Host "`n[1/4] Extracting certificate from source PFX..."
cmd /c "`"$OpenSSLExe`" pkcs12 -in `"$PfxPath`" -out `"$CertPem`" -clcerts -nokeys"

Write-Host "`n[2/4] Extracting private key from source PFX..."
cmd /c "`"$OpenSSLExe`" pkcs12 -in `"$PfxPath`" -out `"$KeyPem`" -nocerts -nodes"

Write-Host "`n[3/4] Creating fullchain PEM..."
cmd /c "copy /b `"$CertPem`" + `"$CaBundlePath`" `"$FullChain`""

Write-Host "`n[4/4] Creating new fullchain PFX..."
cmd /c "`"$OpenSSLExe`" pkcs12 -export -out `"$NewPfx`" -inkey `"$KeyPem`" -in `"$FullChain`" -certfile `"$CaBundlePath`""

Write-Host "`nProcess completed."
Write-Host "New PFX: $NewPfx"
Write-Host "Certificate PEM: $CertPem"
Write-Host "Private Key PEM: $KeyPem"
Write-Host "Fullchain PEM: $FullChain"

pause