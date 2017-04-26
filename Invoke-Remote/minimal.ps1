# Boxstarter options
$Boxstarter.RebootOk=$true # Allow reboots?
$Boxstarter.NoPassword=$false # Is this a machine with no login password?
$Boxstarter.AutoLogin=$true # Save my password securely and auto-login after a reboot

Update-ExecutionPolicy RemoteSigned
Enable-RemoteDesktop
Disable-UAC

# required for usage of 'Invoke-Remote'
Enable-PSRemoting -Force
Set-WSManQuickConfig -SkipNetworkProfileCheck -Force
Set-Item wsman:\localhost\client\trustedhosts * -Force
Restart-Service WinRM -Force
