@echo off
setlocal enableextensions enabledelayedexpansion
set psscript="path_to_your_script"
echo ==================================================
echo ============= WRAP POWERSHELL SCRIPT =============
echo ==================================================

echo calling %psscript% with args %*
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%psscript%' %*"

echo ==================================================
endlocal
