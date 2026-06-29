@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0install-latest.ps1" -RevitYear 2025 -VersionJsonUrl "https://raw.githubusercontent.com/kdg200121-hash/revit-mcp-bridge-updates/main/version.json"
pause
