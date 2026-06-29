@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0install-latest.ps1" -RevitYear 2025
pause
