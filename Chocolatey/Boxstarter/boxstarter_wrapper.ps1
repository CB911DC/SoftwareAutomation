$tmpPkgName = ChocoPkg_WrappedWithBoxstarter

Checkpoint-Computer -Description "before install $tmpPkgName"
New-PackageFromScript .\choco_chocolateyinstall.ps1 $tmpPkgName

$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

$user=[System.Environment]::UserName
$domain=[System.Environment]::UserDomainName

$_cred=Get-Credential "$domain\$user"
Install-BoxstarterPackage $tmpPkgName -Credential $_cred