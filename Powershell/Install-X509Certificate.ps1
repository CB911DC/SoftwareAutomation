<#
.SYNOPSIS
Install a X509 certificate

.DESCRIPTION
Installs a specific X509 certificate (*.cer file) into a specific certificate store

.OUTPUTS
None

.PARAMETER Path
The file path to the certificate

.PARAMETER CertStoreScope
The certificate store scope (default: 'LocalMachine')

.PARAMETER CertStoreName
The certificate store name (default: 'Root')

.Link
https://github.com/fwinkelbauer
https://github.com/mwallner/SoftwareAutomation
#>

param(
  [Parameter(Mandatory = $True)]
  [string] $Path,

  [Parameter(Mandatory = $False)]
  [string] $CertStoreScope = 'LocalMachine',

  [Parameter(Mandatory = $False)]
  [string] $CertStoreName = 'Root'
)

$ErrorActionPreference = "Stop"

Write-Host "Install-X509Certificate '$Path' to '$CertStoreScope/$CertStoreName'..." -ForegroundColor Magenta

# https://stackoverflow.com/questions/21278492/install-certificate-with-powershell-on-remote-server
$certFullLocation = (Get-Item $Path).FullName
$CertToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certFullLocation

$CertStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $CertStoreName, $CertStoreScope

$CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$CertStore.Add($CertToImport)
$CertStore.Close()

Write-Host "Install-X509Certificate successful" -ForegroundColor Green
