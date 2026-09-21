#Requires -Version 7.0
<#
.SYNOPSIS
    Parses an exported Business Central designed-agent XML file into a normalized
    agent-manifest.json.

.DESCRIPTION
    Reads the confirmed export schema (see ../reference/mapping.md § 1):
        <Agents><Agent><Name/><DisplayName/><Initials/><Description/><Version/>
          <Export Date="..."/><AccessControls><AccessControl RoleID Scope AppID/></AccessControls>
          <Profile ProfileID AppID/><UserSettings LocaleID LanguageID TimeZone/>
          <Instructions>...</Instructions>
        </Agent></Agents>

    The root can hold several <Agent> nodes. Pass -AgentName to pick one; if there is
    exactly one, it is used automatically.

    Also scans <Instructions> for Liquid-style page-scoped blocks such as
    "{% if page.id == 50212 %}" and lists every referenced object ID in the manifest, so the
    reader can confirm each one still resolves in the target app set.

.PARAMETER ExportXml
    Path to the exported agent XML file.

.PARAMETER AgentName
    The <Name> of the agent to extract, when the export holds more than one <Agent>.

.PARAMETER OutFile
    Optional. Where to write agent-manifest.json. When omitted, nothing is written to
    disk -- the manifest is only returned as a PSCustomObject, so a caller (including
    the orchestrator) can consume it in-memory without leaving a stray file behind.

.OUTPUTS
    PSCustomObject manifest, also written to -OutFile as JSON when -OutFile is given.

.EXAMPLE
    pwsh -NoProfile -File ConvertFrom-AgentExport.ps1 -ExportXml "./ROOM PLANNING AGENT-agent.xml"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExportXml,

    [string]$AgentName,

    [string]$OutFile
)

$ErrorActionPreference = 'Stop'

function Write-Info($Message) { Write-Host "[ConvertFrom-AgentExport] $Message" }

if (-not (Test-Path -LiteralPath $ExportXml -PathType Leaf)) {
    throw "Export file not found: $ExportXml"
}

[xml]$xmlDoc = Get-Content -LiteralPath $ExportXml -Raw -Encoding utf8

$agentNodes = @($xmlDoc.Agents.Agent)
if ($agentNodes.Count -eq 0) {
    throw "No <Agent> nodes found under <Agents> in $ExportXml. Confirm this is a designed-agent export."
}

$selected = $null
if ($agentNodes.Count -eq 1) {
    $selected = $agentNodes[0]
    if ($AgentName -and ($selected.Name -ne $AgentName)) {
        throw "The export has exactly one agent named '$($selected.Name)', which does not match -AgentName '$AgentName'."
    }
} else {
    if (-not $AgentName) {
        $names = ($agentNodes | ForEach-Object { $_.Name }) -join ', '
        throw "The export contains $($agentNodes.Count) agents ($names). Pass -AgentName to select one."
    }
    $selected = $agentNodes | Where-Object { $_.Name -eq $AgentName } | Select-Object -First 1
    if ($null -eq $selected) {
        $names = ($agentNodes | ForEach-Object { $_.Name }) -join ', '
        throw "-AgentName '$AgentName' not found in export. Available agents: $names"
    }
}

Write-Info "Selected agent: $($selected.Name)"

# --- Access controls ---
$accessControls = @()
if ($selected.AccessControls -and $selected.AccessControls.AccessControl) {
    foreach ($ac in @($selected.AccessControls.AccessControl)) {
        $accessControls += [PSCustomObject]@{
            RoleID = $ac.RoleID
            Scope  = $ac.Scope
            AppID  = ($ac.AppID -replace '[{}]', '')
        }
    }
}

# --- Profile ---
$profile = $null
if ($selected.Profile) {
    $profile = [PSCustomObject]@{
        ProfileID = $selected.Profile.ProfileID
        AppID     = ($selected.Profile.AppID -replace '[{}]', '')
    }
}

# --- User settings ---
$userSettings = $null
if ($selected.UserSettings) {
    $userSettings = [PSCustomObject]@{
        LocaleID   = $selected.UserSettings.LocaleID
        LanguageID = $selected.UserSettings.LanguageID
        TimeZone   = $selected.UserSettings.TimeZone
    }
}

# --- Export metadata ---
$exportDate = $null
if ($selected.Export) { $exportDate = $selected.Export.Date }

# --- Instructions + referenced object IDs ---
$instructions = [string]$selected.Instructions

$referencedObjectIds = @()
$blockPattern = [regex]'\{%\s*if\s+(?<kind>\w+)\.id\s*==\s*(?<id>\d+)\s*%\}'
foreach ($m in $blockPattern.Matches($instructions)) {
    $referencedObjectIds += [PSCustomObject]@{
        Kind    = $m.Groups['kind'].Value
        Id      = [int]$m.Groups['id'].Value
        Context = $m.Value
    }
}
# Fallback: any other {% ... id == N ... %} shape the primary pattern didn't catch.
$genericPattern = [regex]'\{%[^%]*?\bid\s*==\s*(?<id>\d+)[^%]*?%\}'
foreach ($m in $genericPattern.Matches($instructions)) {
    $id = [int]$m.Groups['id'].Value
    if (-not ($referencedObjectIds | Where-Object { $_.Id -eq $id })) {
        $referencedObjectIds += [PSCustomObject]@{ Kind = 'unknown'; Id = $id; Context = $m.Value }
    }
}

$manifest = [PSCustomObject]@{
    SourceFile           = (Resolve-Path $ExportXml).Path
    ExportDate           = $exportDate
    Name                 = $selected.Name
    DisplayName          = $selected.DisplayName
    Initials             = $selected.Initials
    Description          = $selected.Description
    Version              = $selected.Version
    AccessControls       = $accessControls
    Profile              = $profile
    UserSettings         = $userSettings
    Instructions         = $instructions
    ReferencedObjectIds  = $referencedObjectIds
}

if ($OutFile) {
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutFile -Encoding utf8
    Write-Info "Wrote manifest to $OutFile"
}

Write-Host ""
Write-Host "Agent            : $($manifest.Name)"
Write-Host "Display name     : $($manifest.DisplayName)"
Write-Host "Initials         : $($manifest.Initials)"
Write-Host "Description      : $($manifest.Description)"
Write-Host "Access controls  : $($accessControls.Count)"
foreach ($ac in $accessControls) {
    Write-Host "  - $($ac.RoleID) [$($ac.Scope)] app $($ac.AppID)"
}
if ($profile) {
    Write-Host "Profile          : $($profile.ProfileID) (app $($profile.AppID))"
}
if ($userSettings) {
    Write-Host "Locale/Language  : $($userSettings.LocaleID) / $($userSettings.LanguageID) ($($userSettings.TimeZone))"
}
if ($referencedObjectIds.Count -gt 0) {
    Write-Host "Referenced object IDs in instructions (confirm these resolve in the target app set):"
    foreach ($r in $referencedObjectIds) {
        Write-Host "  - $($r.Kind).id == $($r.Id)"
    }
}
Write-Host ""

$manifest
