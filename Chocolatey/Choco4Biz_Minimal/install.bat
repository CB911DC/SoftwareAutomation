@echo off
rem ----------------------------------------------------------------------------
rem 
rem corporate minimal chocolatey installer
rem - sets PowerShell ExecutionPolicy to 'RemoteSigned'
rem - installs choco package manager
rem 
rem ----------------------------------------------------------------------------

set CHOCO_MIRROR="\\myorg-server\Choco\install\install.ps1"
set CHOCO_InstallPackageSource="\\myorg-server\Choco\install\Chocolatey.0.10.8.nupkg"
set CHOCO_NetFx4FullUrl="\\myorg-server\Choco\install\dotNetFx40_Full_x86_x64.exe"
set CHOCO_CustomRepositories="@{'myorg-choco' = '\\myorg-server\Choco\Packages'}"

powershell.exe -noprofile -executionpolicy bypass -command " & %CHOCO_MIRROR% -ChocoInstallPackageSource %CHOCO_InstallPackageSource% -NetFx4FullUrl %CHOCO_NetFx4FullUrl% -CustomRepositories %CHOCO_CustomRepositories% "
if %errorLevel% == 0 (
    echo Success: Chocolatey installed.
) else (
    echo Failure: Failed to install Chocolatey.
    goto Failure
)

goto Success

:Failure
  echo FAILURE
  @echo on
  pause
  exit /b 1

:Success
  echo SUCCESS
  @echo on
  exit /b 0