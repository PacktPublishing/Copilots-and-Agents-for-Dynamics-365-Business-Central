#Requires -Version 7.0
<#
.SYNOPSIS
    Single entry point: exported agent XML -> compiling AL agent app.

.DESCRIPTION
    Orchestrates, in order:
      1. Preflight: confirm PowerShell 7.0+.
      2. Resolve-AgentTemplate.ps1 (unless -TemplatePath is given directly).
      3. ConvertFrom-AgentExport.ps1.
      4. New-AgentAlApp.ps1.
      5. Test-AgentAlApp.ps1 (unless -SkipVerify).
    Each stage is invoked as a child process via the call operator, so it stays
    independently runnable and testable outside this orchestrator too.

    By default, nothing is written to disk except the generated AL app itself -- no
    template-resolution dump, no manifest, no scaffold/verify report. Everything is
    printed to the console and returned as the final object. Pass -ReportsFolder to
    additionally persist those four artifacts as JSON files.

.PARAMETER ReportsFolder
    Optional. When given, template resolution, the parsed manifest, and the scaffold and
    verify reports are written there as JSON. When omitted (the default), none of that is
    written to disk.

.PARAMETER ExistingAppFolder
    Path to the root of an existing AL app (a folder with an app.json) to add the agent to,
    instead of scaffolding a brand-new standalone app. See New-AgentAlApp.ps1's own
    -ExistingAppFolder doc and reference/mapping.md § 9 for the full behavior. Either
    -TargetFolder or -ExistingAppFolder is required.

.PARAMETER AgentFolderName
    Subfolder name under "<ExistingAppFolder>/src/" that owns the agent's objects. Only
    used with -ExistingAppFolder. Defaults to "Agent".

.EXAMPLE
    pwsh -NoProfile -File Convert-AgentExportToAl.ps1 `
        -ExportXml "./ROOM PLANNING AGENT-agent.xml" `
        -TargetFolder "./Room Planning Agent App" `
        -StartId 50900 -Publisher Packt

.EXAMPLE
    # Add the agent's objects into an existing app instead of a new standalone one.
    pwsh -NoProfile -File Convert-AgentExportToAl.ps1 `
        -ExportXml "./ROOM PLANNING AGENT-agent.xml" `
        -ExistingAppFolder "./Room Planning" -AgentFolderName Agent `
        -StartId 50828 -ReuseExistingProfile
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExportXml,
    [string]$AgentName,

    [string]$TargetFolder,
    [string]$ExistingAppFolder,
    [string]$AgentFolderName = 'Agent',
    [Parameter(Mandatory = $true)][int]$StartId,
    [int]$EndId,

    [string]$Publisher = 'Packt',
    [string]$RootNamespace,
    [string]$ProjectName,
    [string]$AppName,
    [string]$AppId,
    [string]$ApplicationVersion = '29.0.0.0',
    [string]$PlatformVersion = '29.0.0.0',
    [string]$AgentBaseName,

    [switch]$ReuseExistingProfile,
    [string]$DependencyAppId,
    [string]$DependencyAppName,
    [string]$DependencyAppPublisher,
    [string]$DependencyAppVersion,

    [string]$TaskTriggerPageName,
    [string]$TaskTriggerPageNamespace,
    [string]$TaskTriggerKeyField = 'No.',
    [string]$TaskTriggerCaptionField = 'Description',

    [string]$TemplatePath,
    [string]$MarketplaceVersion = 'latest',

    [string]$PackageCachePath,
    [switch]$SkipCompile,
    [switch]$SkipVerify,

    [string]$ReportsFolder
)

$ErrorActionPreference = 'Stop'
function Write-Info($Message) { Write-Host "[Convert-AgentExportToAl] $Message" -ForegroundColor Cyan }

# ---------------------------------------------------------------------------
# Stage 0: preflight
# ---------------------------------------------------------------------------

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "This skill requires PowerShell 7.0 or later (found $($PSVersionTable.PSVersion)). Windows PowerShell 5.1 has no `$IsWindows`/`$IsMacOS`, which template discovery needs. Install PowerShell 7 from https://aka.ms/powershell and re-run with 'pwsh' instead of 'powershell'."
}
Write-Info "PowerShell $($PSVersionTable.PSVersion) OK."

$scriptDir = $PSScriptRoot

if (-not $TargetFolder -and -not $ExistingAppFolder) {
    throw "Either -TargetFolder (new standalone app) or -ExistingAppFolder (merge into an existing app) is required."
}
if ($TargetFolder) {
    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
    $TargetFolder = (Resolve-Path $TargetFolder).Path
}
if ($ExistingAppFolder) {
    if (-not (Test-Path -LiteralPath $ExistingAppFolder -PathType Container)) { throw "ExistingAppFolder not found: $ExistingAppFolder" }
    $ExistingAppFolder = (Resolve-Path $ExistingAppFolder).Path
}

# By default, this pipeline leaves zero files on disk other than the generated AL app
# itself: no template-resolution dump, no manifest, no scaffold/verify report JSON. All
# of that is printed to the console and returned as objects, which is enough for both a
# human reading the terminal and a caller capturing $result in PowerShell. Pass
# -ReportsFolder only if you explicitly want those four artifacts written to disk (for
# example to hand them to someone who cannot re-run the pipeline themselves).
if ($ReportsFolder) {
    New-Item -ItemType Directory -Path $ReportsFolder -Force | Out-Null
    $ReportsFolder = (Resolve-Path $ReportsFolder).Path
    Write-Info "Pipeline reports will be written to: $ReportsFolder"
}

# New-AgentAlApp.ps1 requires a real manifest *file* (it runs as a separate process, so
# it cannot receive the manifest object in-memory). When -ReportsFolder is not given,
# that handoff file goes to the system temp folder and is deleted once scaffolding is
# done -- it never becomes a permanent part of the repo.
$manifestFile = if ($ReportsFolder) { Join-Path $ReportsFolder 'agent-manifest.json' } else { Join-Path ([System.IO.Path]::GetTempPath()) "agent-manifest-$([guid]::NewGuid()).json" }
$manifestIsTemp = -not $ReportsFolder

try {

# ---------------------------------------------------------------------------
# Stage 1: resolve template
# ---------------------------------------------------------------------------

if (-not $TemplatePath) {
    Write-Info "Resolving Agent project template..."
    $templateParams = @{ MarketplaceVersion = $MarketplaceVersion }
    if ($ReportsFolder) { $templateParams['OutFile'] = Join-Path $ReportsFolder '_template-resolution.json' }
    $templateResult = & "$scriptDir/Resolve-AgentTemplate.ps1" @templateParams
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Resolve-AgentTemplate.ps1 failed." }
    $TemplatePath = $templateResult.TemplatePath
}
Write-Info "Using template at: $TemplatePath"

# ---------------------------------------------------------------------------
# Stage 2: parse export
# ---------------------------------------------------------------------------

Write-Info "Parsing export XML..."
$parseParams = @{ ExportXml = $ExportXml; OutFile = $manifestFile }
if ($AgentName) { $parseParams['AgentName'] = $AgentName }
$manifest = & "$scriptDir/ConvertFrom-AgentExport.ps1" @parseParams
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "ConvertFrom-AgentExport.ps1 failed." }

# ---------------------------------------------------------------------------
# Stage 3: scaffold
# ---------------------------------------------------------------------------

Write-Info "Scaffolding the AL agent app..."
$scaffoldParams = @{
    ManifestFile             = $manifestFile
    TemplatePath             = $TemplatePath
    StartId                  = $StartId
    Publisher                = $Publisher
    ApplicationVersion       = $ApplicationVersion
    PlatformVersion          = $PlatformVersion
    TaskTriggerKeyField      = $TaskTriggerKeyField
    TaskTriggerCaptionField  = $TaskTriggerCaptionField
}
if ($TargetFolder) { $scaffoldParams['TargetFolder'] = $TargetFolder }
if ($ExistingAppFolder) {
    $scaffoldParams['ExistingAppFolder'] = $ExistingAppFolder
    $scaffoldParams['AgentFolderName'] = $AgentFolderName
}
if ($ReportsFolder) { $scaffoldParams['OutFile'] = Join-Path $ReportsFolder 'scaffold-report.json' }
if ($EndId) { $scaffoldParams['EndId'] = $EndId }
if ($RootNamespace) { $scaffoldParams['RootNamespace'] = $RootNamespace }
if ($ProjectName) { $scaffoldParams['ProjectName'] = $ProjectName }
if ($AppName) { $scaffoldParams['AppName'] = $AppName }
if ($AppId) { $scaffoldParams['AppId'] = $AppId }
if ($AgentBaseName) { $scaffoldParams['AgentBaseName'] = $AgentBaseName }
if ($ReuseExistingProfile) {
    $scaffoldParams['ReuseExistingProfile'] = $true
    $scaffoldParams['DependencyAppId'] = $DependencyAppId
    $scaffoldParams['DependencyAppName'] = $DependencyAppName
    $scaffoldParams['DependencyAppPublisher'] = $DependencyAppPublisher
    if ($DependencyAppVersion) { $scaffoldParams['DependencyAppVersion'] = $DependencyAppVersion }
}
if ($TaskTriggerPageName) { $scaffoldParams['TaskTriggerPageName'] = $TaskTriggerPageName }
if ($TaskTriggerPageNamespace) { $scaffoldParams['TaskTriggerPageNamespace'] = $TaskTriggerPageNamespace }

$scaffoldReport = & "$scriptDir/New-AgentAlApp.ps1" @scaffoldParams
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "New-AgentAlApp.ps1 failed." }

# In -ExistingAppFolder mode, the scaffold's own $TargetFolder was a scratch folder that no
# longer exists by the time it returns (Stage 11 merges it into the existing app and
# deletes it). Re-anchor on the report's TargetFolder, which is the real, final location in
# both modes, for the verify step and the summary below.
$TargetFolder = $scaffoldReport.TargetFolder

# ---------------------------------------------------------------------------
# Stage 4: verify
# ---------------------------------------------------------------------------

$verifyReport = $null
if (-not $SkipVerify) {
    Write-Info "Verifying the generated app..."
    $verifyParams = @{ AppFolder = $TargetFolder }
    if ($ReportsFolder) { $verifyParams['OutFile'] = Join-Path $ReportsFolder 'verify-report.json' }
    if ($PackageCachePath) { $verifyParams['PackageCachePath'] = $PackageCachePath }
    if ($SkipCompile) { $verifyParams['SkipCompile'] = $true }
    $verifyReport = & "$scriptDir/Test-AgentAlApp.ps1" @verifyParams
} else {
    Write-Info "Verification skipped (-SkipVerify)."
}

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "==================== Summary ====================" -ForegroundColor Cyan
Write-Host "Generated app : $TargetFolder"
if ($ReportsFolder) { Write-Host "Reports       : $ReportsFolder" }
Write-Host "Agent         : $($manifest.Name) / $($manifest.DisplayName)"
Write-Host "Mode          : $($scaffoldReport.Mode)"
Write-Host "Files written : $(@($scaffoldReport.FilesWritten).Count)"
Write-Host "Scaffold gaps : $(@($scaffoldReport.Gaps).Count)"
if ($verifyReport) {
    Write-Host "Verify errors : $($verifyReport.ErrorCount)"
    Write-Host "Verify warns  : $($verifyReport.WarningCount)"
    Write-Host "Compiled      : $(if ($verifyReport.CompileAttempted) { $verifyReport.CompileSucceeded } else { 'not attempted' })"
}
Write-Host "Read the mapping report above and reference/gotchas.md before publishing." -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

[PSCustomObject]@{
    TargetFolder   = $TargetFolder
    Manifest       = $manifest
    ScaffoldReport = $scaffoldReport
    VerifyReport   = $verifyReport
}

} finally {
    if ($manifestIsTemp -and (Test-Path -LiteralPath $manifestFile)) {
        Remove-Item -LiteralPath $manifestFile -Force -ErrorAction SilentlyContinue
    }
}
