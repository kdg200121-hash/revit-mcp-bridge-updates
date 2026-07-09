param(
    [string]$RevitYear = "2025",
    [string]$VersionJsonUrl = "https://raw.githubusercontent.com/kdg200121-hash/revit-mcp-bridge-updates/main/version.json",
    [string]$InstallRoot = "$env:LOCALAPPDATA\SeesumAI\RevitMcpBridge",
    [switch]$AllUsers
)

$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
    $OutputEncoding = [Console]::OutputEncoding
    chcp 65001 | Out-Null
}
catch {
}

function New-UnicodeText {
    param([int[]]$CodePoints)

    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

function Get-ScriptRoot {
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }

    return Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Read-VersionInfo {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $null
    }

    Write-Host "Checking latest version:"
    Write-Host $Url

    try {
        return Invoke-RestMethod -Uri $Url -UseBasicParsing -TimeoutSec 15
    }
    catch {
        throw "Could not read online version info: $($_.Exception.Message)"
    }
}

function Get-PackageFromVersionInfo {
    param($VersionInfo)

    if ($null -eq $VersionInfo) {
        return $null
    }

    if ($VersionInfo.PSObject.Properties.Name -contains "installerPackageUrl") {
        return [string]$VersionInfo.installerPackageUrl
    }

    if ($VersionInfo.PSObject.Properties.Name -contains "packageUrl") {
        return [string]$VersionInfo.packageUrl
    }

    if ($VersionInfo.PSObject.Properties.Name -contains "downloadUrl") {
        return [string]$VersionInfo.downloadUrl
    }

    return $null
}

function Expand-Package {
    param(
        [string]$PackagePath,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Expand-Archive -LiteralPath $PackagePath -DestinationPath $Destination -Force
}

function Download-Package {
    param([string]$PackageUrl)

    if ([string]::IsNullOrWhiteSpace($PackageUrl)) {
        throw "Latest package URL was not found in version info."
    }

    if ($PackageUrl -notmatch "\.zip($|\?)") {
        throw "Latest package URL is not a zip file: $PackageUrl"
    }

    $tempPackage = Join-Path $env:TEMP ("RevitMcpBridge-" + [Guid]::NewGuid().ToString("N") + ".zip")
    Write-Host "Downloading latest package:"
    Write-Host $PackageUrl
    Invoke-WebRequest -Uri $PackageUrl -OutFile $tempPackage -UseBasicParsing -TimeoutSec 60
    return $tempPackage
}

$scriptRoot = Get-ScriptRoot
$localPackagePath = Join-Path $scriptRoot "RevitMcpBridge-package.zip"
if (Test-Path -LiteralPath $localPackagePath) {
    Write-Host "Using bundled install package:"
    Write-Host $localPackagePath
    $packagePath = $localPackagePath
}
else {
    $versionInfo = Read-VersionInfo -Url $VersionJsonUrl
    $packageUrl = Get-PackageFromVersionInfo -VersionInfo $versionInfo
    $packagePath = Download-Package -PackageUrl $packageUrl
}

if (-not (Test-Path -LiteralPath $packagePath)) {
    throw "Install package was not found: $packagePath"
}

$installDir = Join-Path $InstallRoot $RevitYear
$payloadDir = Join-Path $installDir "payload"
Expand-Package -PackagePath $packagePath -Destination $payloadDir

$assemblyPath = Join-Path $payloadDir "SeesumAI.RevitMcpBridge.dll"
if (-not (Test-Path -LiteralPath $assemblyPath)) {
    throw "SeesumAI.RevitMcpBridge.dll was not found in package: $assemblyPath"
}

if ($AllUsers) {
    $manifestDir = "C:\ProgramData\Autodesk\Revit\Addins\$RevitYear"
}
else {
    $manifestDir = Join-Path $env:APPDATA "Autodesk\Revit\Addins\$RevitYear"
}

$manifestPath = Join-Path $manifestDir "RevitMcpBridge.addin"
New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null

$manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<RevitAddIns>
  <AddIn Type="Application">
    <Name>Seesum AI</Name>
    <Assembly>$assemblyPath</Assembly>
    <AddInId>8F5B7D60-7F24-41C2-9C99-7B6C8B7F0011</AddInId>
    <FullClassName>RevitMcpBridge.App</FullClassName>
    <VendorId>LOCAL</VendorId>
    <VendorDescription>Seesum AI tools for Revit</VendorDescription>
  </AddIn>
</RevitAddIns>
"@

Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding UTF8

Write-Host ""
Write-Host (New-UnicodeText @(0xC124, 0xCE58, 0xAC00, 0x20, 0xC644, 0xB8CC, 0xB418, 0xC5C8, 0xC2B5, 0xB2C8, 0xB2E4, 0x2E))
Write-Host "Installed Seesum AI Revit add-in."
Write-Host "Manifest: $manifestPath"
Write-Host "Assembly: $assemblyPath"
Write-Host "Restart Revit to load the add-in."
