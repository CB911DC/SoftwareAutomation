@echo off
rem ##################################################
rem (you need to have chocolatey & boxstarter installed before you can run this script!)
rem ##################################################

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""boxstarter_wrapper.ps1""' -Verb RunAs}"
