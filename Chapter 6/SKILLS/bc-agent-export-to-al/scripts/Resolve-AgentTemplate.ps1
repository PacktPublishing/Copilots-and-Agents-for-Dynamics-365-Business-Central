#Requires -Version 7.0
<#
.SYNOPSIS
    Resolves a local copy of the AL "Agent" project template (templates/agent) from the
    ms-dynamics-smb.al VS Code / Cursor extension.

.DESCRIPTION
    Resolution order:
      1. -ManualPath, if given and it contains altemplate.json.
      2. The highest-version ms-dynamics-smb.al-* extension already installed locally
         (VS Code, VS Code Insiders, or Cursor, on Windows/macOS/Linux).
      3. The official Marketplace VSIX, downloaded and unzipped into a temp folder.
    Never vendors template files into this repo. The AL extension ships under Microsoft's
    proprietary Software License Terms, so this script only ever resolves a *path* to a
    template that already exists somewhere else, or that it downloads to a throwaway temp
    location for the current run.

.PARAMETER ManualPath
    A folder that directly contains altemplate.json (the "agent" template folder itself),
    or an extension root that contains templates/agent under it.

.PARAMETER MarketplaceVersion
    Version segment for the Marketplace VSIX URL. Defaults to "latest".

.PARAMETER OutFile
    Optional path to write the JSON result to, in addition to printing it and returning it
    as an object.

.OUTPUTS
    PSCustomObject with: TemplatePath, Source, ExtensionVersion, IsTemporary.

.EXAMPLE
    pwsh -NoProfile -File Resolve-AgentTemplate.ps1
.EXAMPLE
    pwsh -NoProfile -File Resolve-AgentTemplate.ps1 -ManualPath "C:\path\to\extracted\vsix"
#>
[CmdletBinding()]
param(
    [string]$ManualPath,
    [string]$MarketplaceVersion = "latest",
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'

function Write-Info($Message) { Write-Host "[Resolve-AgentTemplate] $Message" }

function Test-TemplateFolder([string]$Path) {
    if (-not $Path) { return $false }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path 'altemplate.json') -PathType Leaf)
}

function Find-TemplateUnder([string]$Root) {
    # An extension root looks like .../ms-dynamics-smb.al-18.0.2668733
    # The template we want lives at <root>/templates/agent
    $candidate = Join-Path $Root 'templates/agent'
    if (Test-TemplateFolder $candidate) { return $candidate }
    return $null
}

function Get-ExtensionVersion([string]$FolderName) {
    # FolderName like "ms-dynamics-smb.al-18.0.2668733"
    if ($FolderName -match 'ms-dynamics-smb\.al-(?<ver>[\d.]+)$') {
        try { return [version]$Matches['ver'] } catch { return [version]'0.0.0' }
    }
    return [version]'0.0.0'
}

function Get-LocalExtensionRoots {
    $roots = [System.Collections.Generic.List[string]]::new()

    $homeDirs = @($HOME)
    if ($env:USERPROFILE -and ($env:USERPROFILE -ne $HOME)) { $homeDirs += $env:USERPROFILE }

    $editorExtensionDirs = @(
        '.vscode/extensions',
        '.vscode-insiders/extensions',
        '.vscode-server/extensions',
        '.cursor/extensions',
        '.cursor-server/extensions'
    )

    foreach ($h in $homeDirs) {
        foreach ($rel in $editorExtensionDirs) {
            $dir = Join-Path $h $rel
            if (Test-Path -LiteralPath $dir -PathType Container) {
                $roots.Add($dir)
            }
        }
    }

    return $roots
}

function Find-BestLocalTemplate {
    $best = $null
    $bestVersion = [version]'0.0.0'

    foreach ($extRoot in (Get-LocalExtensionRoots)) {
        $matches = Get-ChildItem -LiteralPath $extRoot -Directory -Filter 'ms-dynamics-smb.al-*' -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            $tpl = Find-TemplateUnder $m.FullName
            if ($null -eq $tpl) { continue }
            $ver = Get-ExtensionVersion $m.Name
            if ($ver -gt $bestVersion) {
                $bestVersion = $ver
                $best = [PSCustomObject]@{ Path = $tpl; Version = $ver; ExtensionRoot = $m.FullName }
            }
        }
    }

    return $best
}

function Get-MarketplaceVsixUrl([string]$Version) {
    return "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-dynamics-smb/vsextensions/al/$Version/vspackage"
}

function Get-TemplateFromMarketplace([string]$Version) {
    $url = Get-MarketplaceVsixUrl $Version
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("bc-agent-al-template-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $vsixPath = Join-Path $tempRoot 'al.vsix'

    Write-Info "Downloading AL extension VSIX ($Version) from Marketplace..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $vsixPath -UseBasicParsing -Headers @{ Accept = 'application/octet-stream' }
    } catch {
        throw "Could not download the AL extension VSIX from the Marketplace ($url): $($_.Exception.Message). Pass -ManualPath instead."
    }

    Write-Info "Unzipping VSIX (a VSIX is a ZIP; Expand-Archive refuses the .vsix extension, so this uses ZipFile directly)..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $extractRoot = Join-Path $tempRoot 'extracted'
    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($vsixPath, $extractRoot)
    } catch {
        throw "Could not unzip the downloaded VSIX: $($_.Exception.Message)"
    }

    $tpl = Find-TemplateUnder (Join-Path $extractRoot 'extension')
    if ($null -eq $tpl) {
        throw "Downloaded VSIX did not contain templates/agent under extension/. Marketplace layout may have changed; pass -ManualPath instead."
    }

    return [PSCustomObject]@{ Path = $tpl; Version = $null; ExtensionRoot = (Join-Path $extractRoot 'extension') }
}

# --- main ---

$result = $null

if ($ManualPath) {
    if (Test-TemplateFolder $ManualPath) {
        $result = [PSCustomObject]@{ TemplatePath = (Resolve-Path $ManualPath).Path; Source = 'ManualPath'; ExtensionVersion = $null; IsTemporary = $false }
    } else {
        $under = Find-TemplateUnder $ManualPath
        if ($null -ne $under) {
            $result = [PSCustomObject]@{ TemplatePath = $under; Source = 'ManualPath (extension root)'; ExtensionVersion = $null; IsTemporary = $false }
        } else {
            throw "-ManualPath '$ManualPath' does not contain altemplate.json, nor templates/agent under it."
        }
    }
}

if ($null -eq $result) {
    Write-Info "Scanning local VS Code / Cursor extensions for ms-dynamics-smb.al..."
    $local = Find-BestLocalTemplate
    if ($null -ne $local) {
        Write-Info "Found local AL extension $($local.Version) at $($local.ExtensionRoot)"
        $result = [PSCustomObject]@{ TemplatePath = $local.Path; Source = 'LocalExtension'; ExtensionVersion = $local.Version.ToString(); IsTemporary = $false }
    }
}

if ($null -eq $result) {
    Write-Info "No local AL extension found. Falling back to the official Marketplace VSIX."
    $downloaded = Get-TemplateFromMarketplace -Version $MarketplaceVersion
    $result = [PSCustomObject]@{ TemplatePath = $downloaded.Path; Source = 'MarketplaceVsix'; ExtensionVersion = $MarketplaceVersion; IsTemporary = $true }
}

Write-Info "Resolved template: $($result.TemplatePath) (source: $($result.Source))"

if ($OutFile) {
    $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutFile -Encoding utf8
    Write-Info "Wrote result to $OutFile"
}

$result
