param (
  [Parameter(Mandatory = $False)]
  [switch]$CreateSystemRestorePoint,

  [Parameter(Mandatory = $False)]
  [bool]$RemoveCommunityRepo = $True,

  [Parameter(Mandatory = $False)]
  [string]$ChocoInstallPackageSource = "./Chocolatey.0.10.8.nupkg",

  [Parameter(Mandatory = $False)]
  [string]$NetFx4FullUrl = './dotNetFx40_Full_x86_x64.exe',
	
  [Parameter(Mandatory = $False)]
  $CustomRepositories = @{"myorg-choco" = "./Packages"},

  [Parameter(Mandatory = $False)]
  [bool]$RequireBoxstarter = $False,

  [Parameter(Mandatory = $False)]
  [string[]]$AdditonalPackages
)

# chocolatey install script (minimal lan-only setup)
# by mwallner

# original disclaimer:
# =====================================================================
# Copyright 2011 - Present RealDimensions Software, LLC, and the
# original authors/contributors from ChocolateyGallery
# at https://github.com/chocolatey/chocolatey.org
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =====================================================================


if ($CreateSystemRestorePoint) {
  try {
    Write-Output "creating system restore-point ..."
    powershell.exe -Command Checkpoint-Computer -Description "myorg-choco-install"
  }
  catch {
    Write-Output "failed to create system restore point ..."
    exit 1
  }
}


if ($env:TEMP -eq $null) {
  $env:TEMP = Join-Path $env:SystemDrive 'temp'
}
$chocTempDir = Join-Path $env:TEMP "chocolatey"
$tempDir = Join-Path $chocTempDir "chocInstall"
if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
$file = Join-Path $tempDir "chocolatey.zip"

# PowerShell v2/3 caches the output stream. Then it throws errors due
# to the FileStream not being what is expected. Fixes "The OS handle's
# position is not what FileStream expected. Do not use a handle
# simultaneously in one FileStream and in Win32 code or another
# FileStream."
function Fix-PowerShellOutputRedirectionBug {
  $poshMajorVerion = $PSVersionTable.PSVersion.Major
  
  if ($poshMajorVerion -lt 4) {
    try {
      # http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/ plus comments
      $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
      $objectRef = $host.GetType().GetField("externalHostRef", $bindingFlags).GetValue($host)
      $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetProperty"
      $consoleHost = $objectRef.GetType().GetProperty("Value", $bindingFlags).GetValue($objectRef, @())
      [void] $consoleHost.GetType().GetProperty("IsStandardOutputRedirected", $bindingFlags).GetValue($consoleHost, @())
      $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
      $field = $consoleHost.GetType().GetField("standardOutputWriter", $bindingFlags)
      $field.SetValue($consoleHost, [Console]::Out)
      [void] $consoleHost.GetType().GetProperty("IsStandardErrorRedirected", $bindingFlags).GetValue($consoleHost, @())
      $field2 = $consoleHost.GetType().GetField("standardErrorWriter", $bindingFlags)
      $field2.SetValue($consoleHost, [Console]::Error)
    }
    catch {
      Write-Output "Unable to apply redirection fix."
    }
  }
}

Fix-PowerShellOutputRedirectionBug

$file = $ChocoInstallPackageSource

# unzip the package
Write-Output "Extracting $file to $tempDir..."
$shellApplication = new-object -com shell.application
$zipPackage = $shellApplication.NameSpace($file)
$destinationFolder = $shellApplication.NameSpace($tempDir)
$destinationFolder.CopyHere($zipPackage.Items(), 0x10)


# mw: we need to ensure dotnetFx40Client is present during chocolatey install, otherwise chocolatey installer will reach out to microsoft.com 
# 		(which we do not allow in lan-only setups, so the setup would fail!)
# original Install-DotNet4IfMissing taken from chocolateyseup.psm1
function Install-DotNet4IfMissingPreChocoInstall {
  param(
    $forceFxInstall = $false
  )
  Write-Output "installing .Net Framework 4 if not already present..."

  # we can't take advantage of any chocolatey module functions, because they
  # haven't been unpacked because they require .NET Framework 4.0

  Write-Debug "Install-DotNet4IfMissing called with `$forceFxInstall=$forceFxInstall"
  $NetFxArch = "Framework"
  if ([IntPtr]::Size -eq 8) {$NetFxArch = "Framework64" }

  $NetFx4Url = $NetFx4FullUrl
  $NetFx4Path = "$tempDir"
  $NetFx4InstallerFile = 'dotNetFx40_Full_x86_x64.exe'
  $NetFx4Installer = Join-Path $NetFx4Path $NetFx4InstallerFile
	
  if ((!(Test-Path "$env:SystemRoot\Microsoft.Net\$NetFxArch\v4.0.30319") -and !(Test-Path "C:\Windows\Microsoft.Net\$NetFxArch\v4.0.30319")) -or $forceFxInstall) {
    Write-Output "'$env:SystemRoot\Microsoft.Net\$NetFxArch\v4.0.30319' was not found or this is forced"
    if (!(Test-Path $NetFx4Path)) {
      Write-Output "Creating folder `'$NetFx4Path`'"
      $null = New-Item -Path "$NetFx4Path" -ItemType Directory
    }

    $netFx4InstallTries += 1

    if (!(Test-Path $NetFx4Installer)) {
      Write-Output "Copying `'$NetFx4Url`' to `'$NetFx4Installer`'."
      Copy-Item $NetFx4Url $NetFx4Installer -Verbose -ErrorAction "Stop"
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.WorkingDirectory = "$NetFx4Path"
    $psi.FileName = "$NetFx4InstallerFile"
    # https://msdn.microsoft.com/library/ee942965(v=VS.100).aspx#command_line_options
    # http://blogs.msdn.com/b/astebner/archive/2010/05/12/10011664.aspx
    # For the actual setup.exe (if you want to unpack first) - /repair /x86 /x64 /ia64 /parameterfolder Client /q /norestart
    $psi.Arguments = "/q /norestart /repair"

    Write-Output "Installing `'$NetFx4Installer`' - this may take awhile with no output."
    $s = [System.Diagnostics.Process]::Start($psi);
    $s.WaitForExit();
    if ($s.ExitCode -ne 0 -and $s.ExitCode -ne 3010) {
      if ($netFx4InstallTries -ge 2) {
        Write-ChocolateyError ".NET Framework install failed with exit code `'$($s.ExitCode)`'. `n This will cause the rest of the install to fail."
        throw "Error installing .NET Framework 4.0 (exit code $($s.ExitCode)). `n Please install the .NET Framework 4.0 manually and then try to install Chocolatey again. `n Download at `'$NetFx4Url`'"
      }
      else {
        Write-ChocolateyWarning "Try #$netFx4InstallTries of .NET framework install failed with exit code `'$($s.ExitCode)`'. Trying again."
        Install-DotNet4IfMissing $true
      }
    }
  }
}
Install-DotNet4IfMissingPreChocoInstall

# Call chocolatey install
Write-Output "Installing chocolatey on this machine"
$toolsFolder = Join-Path $tempDir "tools"
$chocInstallPS1 = Join-Path $toolsFolder "chocolateyInstall.ps1"

& $chocInstallPS1

Write-Output 'Ensuring chocolatey commands are on the path'
$chocInstallVariableName = "ChocolateyInstall"
$chocoPath = [Environment]::GetEnvironmentVariable($chocInstallVariableName)
if ($chocoPath -eq $null -or $chocoPath -eq '') {
  $chocoPath = 'C:\ProgramData\Chocolatey'
}

$chocoExePath = Join-Path $chocoPath 'bin'

if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine);
}

Write-Output 'Ensuring chocolatey.nupkg is in the lib folder'
$chocoPkgDir = Join-Path $chocoPath 'lib\chocolatey'
$nupkg = Join-Path $chocoPkgDir 'chocolatey.nupkg'
if (![System.IO.Directory]::Exists($chocoPkgDir)) { [System.IO.Directory]::CreateDirectory($chocoPkgDir); }
Copy-Item "$file" "$nupkg" -Force -ErrorAction SilentlyContinue

if ($RemoveCommunityRepo) {
  powershell.exe -Command choco source remove -name chocolatey
}

if ($CustomRepositories) {
  foreach ($repo in $CustomRepositories.Keys) {
    powershell.exe -Command choco source add -name $repo -s "$($CustomRepositories[$repo])"	
  }
}

if ($RequireBoxstarter) {
  powershell.exe -Command choco install boxstarter -y	
}

if ($AdditonalPackages) {
  $pkgstring = $AdditonalPackages -join " "
  if (-Not $RequireBoxstarter) {
    powershell.exe -Command choco install $pkgstring -y
  }
  else {
    $boxstarterScript = Join-Path $tempDir "chocosetup_boxstarter.ps1"
    $boxstarterPackage = Join-Path $tempDir "chocosetup_boxstarter_install.ps1"
    $tmpPkgName = "ChocolateySetup_Boxstarter_Helper"
    @"
Import-Module `$env:APPDATA\Boxstarter\Boxstarter.Bootstrapper
Import-Module `$env:APPDATA\Boxstarter\Boxstarter.Chocolatey
New-PackageFromScript $boxstarterPackage $tmpPkgName
`$Boxstarter.RebootOk=`$true
`$Boxstarter.NoPassword=`$false
`$Boxstarter.AutoLogin=`$true

`$user=[System.Environment]::UserName
`$domain=[System.Environment]::UserDomainName

`$_cred=Get-Credential "`$domain\`$user"
Install-BoxstarterPackage $tmpPkgName -Credential `$_cred
"@ | Out-File $boxstarterScript -Encoding default

    @"
`$Boxstarter.RebootOk=`$true
`$Boxstarter.NoPassword=`$false
`$Boxstarter.AutoLogin=`$true
"@ | Out-File $boxstarterPackage -Encoding default

    foreach ($pkg in $AdditonalPackages) {
      @"
choco install $pkg -y
if (Test-PendingReboot) { Invoke-Reboot }
"@ | Out-File $boxstarterPackage -Encoding default -Append
    }
    powershell.exe -Command "refreshenv; $boxstarterScript"
  }
}
