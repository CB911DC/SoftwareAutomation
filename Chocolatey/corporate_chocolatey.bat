@echo off
rem ----------------------------------------------------------------------------
rem 
rem corporate chocolatey installer
rem - sets PowerShell ExecutionPolicy to 'RemoteSigned'
rem - install company certificate to access https on chocolatey server
rem - installs choco package manager
rem 
rem ----------------------------------------------------------------------------

set mycd="~dp0"
rem CORP_CER is the relative location to the company Root-CA
set CORP_CER="\\some_share\theCertifacte.cer"
rem CHOCO_MIRRROR is the URL to the (modified) corporate_install.ps1
set CHOCO_MIRROR="https://choco-at-myorg.com/chocolatey/install.ps1"

rem admin rights check taken from https://stackoverflow.com/a/11995662/2279385
echo Administrative permissions required. Detecting permissions...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Failure: Current permissions inadequate.
    goto Failure
)

rem ----------------------------------------------------------------------------
rem --------------------------- SET EXECUTION POLICY ---------------------------
rem ----------------------------------------------------------------------------
powershell.exe -noprofile -Command "Set-ExecutionPolicy RemoteSigned"
if %errorLevel% == 0 (
    echo Success: ExecutionPolicy set.
) else (
    echo Failure: Failed to set ExecutionPolicy.
    goto Failure
)

rem ----------------------------------------------------------------------------
rem --------------------------- INSTALL CERTIFICATE ----------------------------
rem ----------------------------------------------------------------------------
powershell.exe -noprofile -executionpolicy bypass -Command "%mycd%..\PowerShell\Install-X509Certificate.ps1 %CORP_CER%"
if %errorLevel% == 0 (
    echo Success: Certificate installed.
) else (
    echo Failure: Failed to install certificate.
    goto Failure
)

rem ----------------------------------------------------------------------------
rem --------------------------- INSTALL CHOCOLATEY -----------------------------
rem ----------------------------------------------------------------------------
set TMP_PS_EXT=%username%.%computername%
set TMP_PS=getChoco_%TMP_PS_EXT%.ps1

@echo iex ((new-object net.webclient).DownloadString(%CHOCO_MIRROR%)) >  %TMP_PS%
powershell.exe -noprofile -executionpolicy bypass -file .\%TMP_PS%
if %errorLevel% == 0 (
    echo Success: Chocolatey installed.
) else (
    echo Failure: Failed to install Chocolatey.
    goto Failure
)
del %TMP_PS%

goto Success

:Failure
  echo FAILURE
  @echo on
  pause
  exit /b 1

:Success
  echo SUCCESS
  @echo on
  pause
  exit /b 0