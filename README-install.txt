Seesum AI Revit Add-in Installer

Run this command in PowerShell:

powershell -ExecutionPolicy Bypass -File .\install-latest.ps1 -RevitYear 2025 -VersionJsonUrl "https://raw.githubusercontent.com/kdg200121-hash/revit-mcp-bridge-updates/main/version.json"

Default install scope is current Windows user:
%APPDATA%\Autodesk\Revit\Addins\2025
%LOCALAPPDATA%\SeesumAI\RevitMcpBridge\2025

To install for all users, run PowerShell as Administrator and add:
-AllUsers

The installer first uses the bundled RevitMcpBridge-package.zip in this folder.
If the bundled package is missing, it checks version.json and installs the latest zip package from installerPackageUrl, packageUrl, or downloadUrl.
