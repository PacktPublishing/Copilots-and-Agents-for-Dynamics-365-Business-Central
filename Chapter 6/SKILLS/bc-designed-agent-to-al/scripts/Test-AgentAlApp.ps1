#Requires -Version 7.0
<#
.SYNOPSIS
    Verifies a generated AL agent app: scans for leftover placeholders, leftover TODOs,
    leftover MyAgent/My Agent rename residue, and (when possible) attempts a real compile.

.DESCRIPTION
    Static checks (always run, no dependencies):
      - No `{{...}}` template tokens survived substitution.
      - No literal `MyAgent` / `My Agent` residue survived the rename pass.
      - `TODO:` markers are reported, split into "known template TODOs" (harmless, the
        reader's own business logic to fill in) versus ones inside files the skill claims
        to have fully generated (worth a second look).
      - app.json is valid JSON with a non-placeholder id/name/publisher.

    Compile step (best-effort):
      - Prefers a cross-platform `alc` on PATH.
      - Falls back to reporting that a usable compiler was not found, and recommends the
        AL MCP server (`al_build` / `al_compile`) or VS Code instead of failing silently.
      - Never claims a compile succeeded when it did not actually run one.

.PARAMETER AppFolder
    The generated AL app folder (contains app.json).

.PARAMETER PackageCachePath
    Optional. Folder containing dependency .app files (.alpackages), passed to alc if a
    compile is attempted.

.PARAMETER SkipCompile
    Skip the compile step entirely and only run the static checks.

.PARAMETER OutFile
    Optional. Where to write the verification report JSON. When omitted, nothing is
    written to disk -- the report is only returned as a PSCustomObject and printed to
    the console, so the generated AL project folder is not touched by verification.

.OUTPUTS
    PSCustomObject: AppFolder, StaticChecks, CompileAttempted, CompileSucceeded,
    CompileOutput, Gaps.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AppFolder,
    [string]$PackageCachePath,
    [switch]$SkipCompile,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'

function Write-Info($Message) { Write-Host "[Test-AgentAlApp] $Message" }
function Write-Finding($Level, $Message) {
    $color = switch ($Level) { 'Error' { 'Red' }; 'Warning' { 'Yellow' }; default { 'Gray' } }
    Write-Host "[Test-AgentAlApp][$Level] $Message" -ForegroundColor $color
}

if (-not (Test-Path -LiteralPath $AppFolder -PathType Container)) { throw "AppFolder not found: $AppFolder" }
$AppFolder = (Resolve-Path $AppFolder).Path

$appJsonPath = Join-Path $AppFolder 'app.json'
if (-not (Test-Path -LiteralPath $appJsonPath -PathType Leaf)) { throw "app.json not found under $AppFolder" }

$findings = [System.Collections.Generic.List[PSCustomObject]]::new()
function Add-Finding([string]$Level, [string]$Category, [string]$Message) {
    $findings.Add([PSCustomObject]@{ Level = $Level; Category = $Category; Message = $Message }) | Out-Null
    Write-Finding $Level "$Category`: $Message"
}

$alFiles = Get-ChildItem -Path $AppFolder -Recurse -Force -Include '*.al','*.json','*.txt','*.md' -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.alpackages[\\/]' }

# --- Check 1: leftover {{...}} placeholder tokens ---
$placeholderPattern = [regex]'\{\{[a-zA-Z0-9+_]+\}\}'
foreach ($f in $alFiles) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8
    $m = $placeholderPattern.Matches($text)
    if ($m.Count -gt 0) {
        $tokens = ($m | ForEach-Object { $_.Value } | Select-Object -Unique) -join ', '
        Add-Finding 'Error' 'LeftoverPlaceholder' "$($f.FullName.Substring($AppFolder.Length + 1)) still contains: $tokens"
    }
}

# --- Check 2: leftover MyAgent / "My Agent" rename residue ---
foreach ($f in $alFiles) {
    if ($f.Extension -eq '.al') {
        $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8
        if ($text.Contains('MyAgent')) {
            Add-Finding 'Error' 'RenameResidue' "$($f.FullName.Substring($AppFolder.Length + 1)) still contains the literal 'MyAgent' — the pass-1 rename likely missed this file (see mapping.md § 5)."
        }
        if ($text.Contains('My Agent')) {
            Add-Finding 'Error' 'RenameResidue' "$($f.FullName.Substring($AppFolder.Length + 1)) still contains the literal 'My Agent' — the pass-2 rename likely missed this file (see mapping.md § 5)."
        }
    }
    if ($f.Name -match 'MyAgent') {
        Add-Finding 'Error' 'RenameResidue' "File name $($f.Name) still contains 'MyAgent'."
    }
}

# --- Check 3: TODO markers ---
$todoPattern = [regex]'//\s*TODO:.*'
foreach ($f in $alFiles) {
    if ($f.Extension -ne '.al') { continue }
    $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8
    foreach ($m in $todoPattern.Matches($text)) {
        Add-Finding 'Info' 'Todo' "$($f.FullName.Substring($AppFolder.Length + 1)): $($m.Value.Trim())"
    }
}

# --- Check 4: app.json sanity ---
try {
    $appJson = Get-Content -LiteralPath $appJsonPath -Raw -Encoding utf8 | ConvertFrom-Json
    if (-not $appJson.id -or $appJson.id -match '\{\{') { Add-Finding 'Error' 'AppJson' "app.json 'id' is missing or still a placeholder." }
    if (-not $appJson.name -or $appJson.name -match '\{\{') { Add-Finding 'Error' 'AppJson' "app.json 'name' is missing or still a placeholder." }
    if (-not $appJson.publisher -or $appJson.publisher -eq 'DefaultPublisher') { Add-Finding 'Warning' 'AppJson' "app.json 'publisher' is the tool default ('DefaultPublisher') — confirm this is intended." }
    if ($appJson.idRanges.Count -eq 0) { Add-Finding 'Warning' 'AppJson' "app.json has no idRanges." }
} catch {
    Add-Finding 'Error' 'AppJson' "app.json is not valid JSON: $($_.Exception.Message)"
}

# --- Check 5: scaffold-report.json gaps, if present ---
$scaffoldReportPath = Join-Path $AppFolder 'scaffold-report.json'
if (Test-Path -LiteralPath $scaffoldReportPath) {
    $scaffoldReport = Get-Content -LiteralPath $scaffoldReportPath -Raw -Encoding utf8 | ConvertFrom-Json
    foreach ($g in @($scaffoldReport.Gaps)) {
        Add-Finding 'Warning' 'ScaffoldGap' $g
    }
}

$errorCount = @($findings | Where-Object { $_.Level -eq 'Error' }).Count
$warningCount = @($findings | Where-Object { $_.Level -eq 'Warning' }).Count
Write-Info "Static checks: $errorCount error(s), $warningCount warning(s), $(@($findings | Where-Object {$_.Level -eq 'Info'}).Count) info item(s)."

# ---------------------------------------------------------------------------
# Compile step (best-effort)
# ---------------------------------------------------------------------------

$compileAttempted = $false
$compileSucceeded = $null
$compileOutput = $null

if (-not $SkipCompile) {
    $alc = Get-Command 'alc' -ErrorAction SilentlyContinue
    if ($alc) {
        $compileAttempted = $true
        $outApp = Join-Path $AppFolder ((Split-Path -Leaf $AppFolder) + '.app')
        $alcArgs = @("/project:$AppFolder", "/out:$outApp")
        if ($PackageCachePath) { $alcArgs += "/packagecachepath:$PackageCachePath" }
        Write-Info "Compiling with alc: $($alc.Source) $($alcArgs -join ' ')"
        $compileOutput = & $alc.Source @alcArgs 2>&1 | Out-String
        $compileSucceeded = ($LASTEXITCODE -eq 0)
        if ($compileSucceeded) {
            Write-Info "Compile succeeded: $outApp"
        } else {
            Add-Finding 'Error' 'Compile' "alc exited with code $LASTEXITCODE. See CompileOutput in the report."
        }
    } else {
        Add-Finding 'Warning' 'Compile' "No usable 'alc' found on PATH — this run did not attempt a compile. The AL extension's bundled alc.exe can be a Windows-only build in some releases (verified for ms-dynamics-smb.al-18.0.2668733 on macOS/Linux — see reference/gotchas.md). Compile this app via the AL MCP server's al_build/al_compile tools, or via VS Code, before publishing."
    }
} else {
    Write-Info "Compile step skipped (-SkipCompile)."
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

$report = [PSCustomObject]@{
    AppFolder        = $AppFolder
    ErrorCount       = $errorCount
    WarningCount     = $warningCount
    Findings         = $findings
    CompileAttempted = $compileAttempted
    CompileSucceeded = $compileSucceeded
    CompileOutput    = $compileOutput
}

if ($OutFile) {
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutFile -Encoding utf8
    Write-Info "Wrote verification report to $OutFile"
}

if ($errorCount -gt 0) {
    Write-Host ""
    Write-Host "FAILED: $errorCount error(s) found. This app is not ready to publish." -ForegroundColor Red
} elseif ($compileAttempted -and -not $compileSucceeded) {
    Write-Host ""
    Write-Host "FAILED: static checks passed, but the compile did not succeed." -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host "OK: no leftover placeholders, no rename residue, app.json is sane$(if ($compileSucceeded) { ', and the app compiled.' } else { '. Compile not attempted or not verifiable in this environment — see warnings.' })" -ForegroundColor Green
}

$report
