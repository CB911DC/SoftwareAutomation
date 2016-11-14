
# Boxstarter options
$Boxstarter.RebootOk=$true # Allow reboots?
$Boxstarter.NoPassword=$false # Is this a machine with no login password?
$Boxstarter.AutoLogin=$true # Save my password securely and auto-login after a reboot

Update-ExecutionPolicy RemoteSigned
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
try {
  Enable-RemoteDesktop
  Disable-BingSearch
  Enable-PSRemoting -Force
} catch {}

choco install 7z -y
choco install firefox
choco install VisualStudioCode -y
choco install notepadplusplus -y

if (Test-PendingReboot) { Invoke-Reboot }

choco install VirtualBox -y
if (Test-PendingReboot) { Invoke-Reboot }

# TODO ...