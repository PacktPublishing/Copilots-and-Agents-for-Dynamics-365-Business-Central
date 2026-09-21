#Requires -Version 7.0
<#
.SYNOPSIS
    Scaffolds a production-shaped AL agent app from the resolved Agent project template,
    filling every slot from an agent-manifest.json produced by ConvertFrom-AgentExport.ps1.

.DESCRIPTION
    Reimplements the AL extension's own template placeholder algorithm (see
    ../reference/mapping.md § 3), then applies a two-pass rename (MyAgent -> BaseName,
    "My Agent" -> DisplayName, see § 5), then fills the export -> AL slot map (§ 4).

    Two modes:
      - Fresh (default): the generated app owns a brand-new profile, role center, page
        customization, and permission set (copied from the template and renamed).
      - Reuse (-ReuseExistingProfile): those objects already exist in another app. The
        generated app takes a dependency on it instead of recreating them.

.PARAMETER ManifestFile
    Path to agent-manifest.json from ConvertFrom-AgentExport.ps1.

.PARAMETER TemplatePath
    Path to the resolved "agent" template folder (contains altemplate.json), from
    Resolve-AgentTemplate.ps1.

.PARAMETER TargetFolder
    Where to create the generated AL app. Created if it does not exist. Required unless
    -ExistingAppFolder is given.

.PARAMETER ExistingAppFolder
    Path to the root of an *existing* AL app (a folder with an app.json) to add the agent
    to, instead of scaffolding a brand-new standalone app. The agent's Metadata/, Setup/,
    TaskExecution/, Integration/, and Interaction/ folders (plus Permissions/ and Profile/
    when not reusing) are written under "<ExistingAppFolder>/src/<AgentFolderName>/", and
    the instructions resource under "<ExistingAppFolder>/.resources/". The existing app's
    own app.json, .gitignore, and README.md are never touched. -StartId must land on
    9 consecutive free object numbers inside one of the existing app's own idRanges (see
    reference/mapping.md § 9); the script errors out otherwise rather than guessing. When
    combined with -ReuseExistingProfile, -DependencyApp* are derived automatically from the
    existing app itself (it is its own dependency), and the generated Setup codeunit
    references it via CurrentModuleInfo.Id instead of a hardcoded foreign GUID.

.PARAMETER AgentFolderName
    Subfolder name under "<ExistingAppFolder>/src/" that owns the agent's objects. Only
    used with -ExistingAppFolder. Defaults to "Agent".

.PARAMETER StartId
    The "from" of the object ID range for this app (the value the reader reserved). With
    -ExistingAppFolder, this is instead validated against that app's own idRanges/used IDs.

.PARAMETER EndId
    The "to" of the object ID range. Defaults to StartId + 49, matching the template's own
    idRanges span.

.PARAMETER Publisher
    Publisher name for app.json. Defaults to "Packt".

.PARAMETER RootNamespace
    AL root namespace. Defaults to Publisher with whitespace stripped, matching the AL
    extension's own default when no explicit al.rootNamespace setting is configured.

.PARAMETER ProjectName
    Value used for the {{projectname}} placeholder. Defaults to the target folder's leaf
    name with hyphens and spaces stripped, matching the AL extension's own basename() rule.

.PARAMETER AppName
    Friendly "name" field for app.json, overriding the raw {{projectname}} substitution.
    Optional.

.PARAMETER AppId
    GUID for app.json "id". Defaults to a freshly generated GUID.

.PARAMETER ApplicationVersion
.PARAMETER PlatformVersion
    Override the template's default application/platform versions (27.4.0.0). This book's
    Chapter 6 apps target 29.0.0.0.

.PARAMETER AgentBaseName
    PascalCase identifier used for the "MyAgent" (no-space) rename pass. Defaults to the
    manifest DisplayName with all non-alphanumeric characters removed.

.PARAMETER ReuseExistingProfile
    When set, the generated app does not create its own profile / role center / page
    customization / permission set. Instead it depends on -DependencyApp* and reuses the
    named objects from there.

.PARAMETER DependencyAppId
.PARAMETER DependencyAppName
.PARAMETER DependencyAppPublisher
.PARAMETER DependencyAppVersion
    Identity of the app that owns the profile/page customizations/permission set when
    -ReuseExistingProfile is set. Also added to app.json "dependencies".

.PARAMETER TaskTriggerPageName
    The real page to extend with a "start agent task" action, replacing the template's
    "Customer Card" example. Optional; if omitted, the template's own Customer Card example
    is kept and flagged in the gap report.

.PARAMETER TaskTriggerKeyField
.PARAMETER TaskTriggerCaptionField
    Field names on the page's source record used to build the task message (defaults to
    "No." and "Description").

.PARAMETER OutFile
    Optional. Where to write the scaffold report JSON. When omitted, nothing is written
    to disk -- the generated AL project folder stays limited to app.json, .gitignore,
    README.md, .resources/, and src/. The report is still returned as a PSCustomObject
    and printed to the console.

.OUTPUTS
    PSCustomObject scaffold report: TargetFolder, FilesWritten, FilesSkipped, Gaps.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ManifestFile,
    [Parameter(Mandatory = $true)][string]$TemplatePath,
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
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'

function Write-Info($Message) { Write-Host "[New-AgentAlApp] $Message" }
function Write-Gap($Message) { Write-Host "[New-AgentAlApp][GAP] $Message" -ForegroundColor Yellow; $script:Gaps.Add($Message) | Out-Null }

$script:Gaps = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $ManifestFile -PathType Leaf)) { throw "Manifest file not found: $ManifestFile" }
if (-not (Test-Path -LiteralPath $TemplatePath -PathType Container)) { throw "Template path not found: $TemplatePath" }
if (-not (Test-Path -LiteralPath (Join-Path $TemplatePath 'altemplate.json'))) {
    throw "TemplatePath '$TemplatePath' does not look like the agent template (no altemplate.json)."
}

if (-not $TargetFolder -and -not $ExistingAppFolder) {
    throw "Either -TargetFolder (new standalone app) or -ExistingAppFolder (merge into an existing app) is required."
}

$manifest = Get-Content -LiteralPath $ManifestFile -Raw -Encoding utf8 | ConvertFrom-Json

# ---------------------------------------------------------------------------
# In-app mode pre-flight: when -ExistingAppFolder is given, everything from here down
# (Stage 1-10) still runs exactly like the fresh/reuse standalone-app flow, but against a
# throwaway scratch folder shaped like a brand-new app (its own app.json, .gitignore,
# README.md, src/, .resources/). Stage 11, at the very end, moves only what belongs to the
# agent (src/ and .resources/) into $RealTargetFolder and discards the scratch app-level
# files -- the existing app already owns those. See reference/mapping.md § 9.
# ---------------------------------------------------------------------------
$InAppMode = [bool]$ExistingAppFolder
$RealTargetFolder = $null
$stripNamespace = $false

if ($InAppMode) {
    if (-not (Test-Path -LiteralPath $ExistingAppFolder -PathType Container)) {
        throw "ExistingAppFolder not found: $ExistingAppFolder"
    }
    $ExistingAppFolder = (Resolve-Path $ExistingAppFolder).Path
    $existingAppJsonPath = Join-Path $ExistingAppFolder 'app.json'
    if (-not (Test-Path -LiteralPath $existingAppJsonPath -PathType Leaf)) {
        throw "ExistingAppFolder '$ExistingAppFolder' has no app.json; it does not look like an AL app root."
    }
    $existingAppJson = Get-Content -LiteralPath $existingAppJsonPath -Raw -Encoding utf8 | ConvertFrom-Json
    $RealTargetFolder = $ExistingAppFolder

    # --- Object IDs: the template + Stage 7's review dialog use nine consecutive numbers
    # ({{id+0}} .. {{id+8}}). They must fit inside one of the existing app's own idRanges,
    # and none of them may already be used by any object in that app -- AL only guarantees
    # a number is unique *within* an app, not per object type, so a page and a codeunit
    # sharing a number is just as real a collision here.
    $maxIdOffset = 8
    $blockEndId = $StartId + $maxIdOffset
    $fittingRange = @($existingAppJson.idRanges) | Where-Object { $_.from -le $StartId -and $blockEndId -le $_.to } | Select-Object -First 1
    if (-not $fittingRange) {
        $rangesText = (@($existingAppJson.idRanges) | ForEach-Object { "$($_.from)-$($_.to)" }) -join ', '
        throw "-StartId $StartId needs $StartId-$blockEndId free ($($maxIdOffset + 1) objects) inside one idRange, but that does not fit any range declared in $existingAppJsonPath ($rangesText). Pick a different -StartId, or add a new idRange to app.json yourself first."
    }

    $usedIds = [System.Collections.Generic.HashSet[int]]::new()
    $idDeclPattern = [regex]'(?m)^(?:codeunit|page|pageextension|table|tableextension|enum|enumextension|permissionset|query|report|xmlport)\s+(\d+)\b'
    Get-ChildItem -Path $ExistingAppFolder -Recurse -Force -Filter '*.al' | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8
        foreach ($m in $idDeclPattern.Matches($text)) { $usedIds.Add([int]$m.Groups[1].Value) | Out-Null }
    }
    $collisions = @($StartId..$blockEndId) | Where-Object { $usedIds.Contains($_) }
    if ($collisions.Count -gt 0) {
        throw "-StartId $StartId collides with object number(s) already used somewhere in $ExistingAppFolder`: $($collisions -join ', '). Pick a different -StartId with $($maxIdOffset + 1) consecutive free numbers."
    }

    # --- Root namespace: match whatever the existing app already does, including "none" --
    # older AL apps (this book's own Chapter 6 - Room Planning included) predate the
    # `namespace` keyword and declare none at all. Inventing one here would be inconsistent
    # with every other file the reader already has open.
    if (-not $RootNamespace) {
        $existingNamespace = $null
        $nsPattern = [regex]'(?m)^namespace\s+([^;]+);'
        foreach ($f in (Get-ChildItem -Path $ExistingAppFolder -Recurse -Force -Filter '*.al')) {
            $m = $nsPattern.Match((Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8))
            if ($m.Success) { $existingNamespace = $m.Groups[1].Value.Trim(); break }
        }
        if ($existingNamespace) {
            $RootNamespace = $existingNamespace
        } else {
            $RootNamespace = ''
            $stripNamespace = $true
            Write-Info "No 'namespace' declarations found under $ExistingAppFolder; generated files will not declare one either."
        }
    }

    if ($ReuseExistingProfile) {
        if (-not $DependencyAppId) { $DependencyAppId = [string]$existingAppJson.id }
        if (-not $DependencyAppName) { $DependencyAppName = [string]$existingAppJson.name }
        if (-not $DependencyAppPublisher) { $DependencyAppPublisher = [string]$existingAppJson.publisher }
    }

    # Stage 1-10 write into a scratch folder using the "new app" shape; Stage 11 relocates
    # src/ and .resources/ into $RealTargetFolder and throws the rest away.
    $TargetFolder = Join-Path ([System.IO.Path]::GetTempPath()) "bc-agent-export-to-al-$([guid]::NewGuid().ToString('N'))"
    Write-Info "In-app mode     : merging into $RealTargetFolder (under src/$AgentFolderName)"
}

New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
$TargetFolder = (Resolve-Path $TargetFolder).Path

if (-not $EndId) { $EndId = $StartId + 49 }
if (-not $AppId) { $AppId = [guid]::NewGuid().ToString() }
# Note: in in-app mode, $RootNamespace was already resolved above (possibly to '' with
# $stripNamespace = $true for apps that declare no namespace at all) -- do not let the
# generic Publisher-based fallback below clobber an intentionally empty value.
if (-not $RootNamespace -and -not $InAppMode) { $RootNamespace = ($Publisher -replace '\s', '') }
if (-not $ProjectName) { $ProjectName = ((Split-Path -Leaf $TargetFolder) -replace '[-\s]', '') }
if (-not $AgentBaseName) { $AgentBaseName = (($manifest.DisplayName) -replace '[^A-Za-z0-9]', '') }

# Self-reference: in in-app mode with -ReuseExistingProfile, the "dependency" is this same
# app, so the generated Setup codeunit should say CurrentModuleInfo.Id, not a hardcoded
# foreign GUID label -- that's strictly more correct and matches how "Fresh" mode already
# resolves its own App ID.
$useSelfReferenceForDependency = $InAppMode -and $ReuseExistingProfile

$DisplayName = [string]$manifest.DisplayName
$AgentUserName = [string]$manifest.Name
$BaseName = $AgentBaseName

Write-Info "Base name       : $BaseName"
Write-Info "Display name    : $DisplayName"
Write-Info "Agent user name : $AgentUserName (kept verbatim, no company suffix)"
Write-Info "Mode            : $(if ($ReuseExistingProfile) { 'Reuse existing profile' } else { 'Fresh profile' })$(if ($InAppMode) { ' (in-app)' })"

if ($ReuseExistingProfile -and -not $InAppMode -and (-not $DependencyAppId -or -not $DependencyAppPublisher -or -not $DependencyAppName)) {
    throw "-ReuseExistingProfile requires -DependencyAppId, -DependencyAppName, and -DependencyAppPublisher (unless -ExistingAppFolder is given, in which case the existing app is its own dependency and these are derived automatically)."
}

if (-not $ReuseExistingProfile -and $manifest.Profile -and ($manifest.Profile.AppID -ne $AppId.Replace('{','').Replace('}',''))) {
    Write-Gap "Export profile '$($manifest.Profile.ProfileID)' belongs to app $($manifest.Profile.AppID), which is not the app being generated ($AppId). Generating a fresh, self-contained profile instead. Pass -ReuseExistingProfile with -DependencyApp* if you want to reuse the original profile/page customizations/permission set instead."
}

# --- Known app IDs, for readable comments on foreign access controls ---
$knownApps = @{
    '63ca2fa4-4f03-4f2b-a480-172fef340d3f' = 'System Application'
    '437dbf0e-84ff-417a-965d-ed2bb9650972' = 'Base Application'
}

function Get-AppLabel([string]$Guid) {
    $key = $Guid.ToLowerInvariant()
    if ($knownApps.ContainsKey($key)) { return $knownApps[$key] }
    return 'External app'
}

# In-app mode against an app with no `namespace` declarations ($stripNamespace = $true):
# drop the leading "namespace X;" line (and the blank line after it) from generated content
# instead of emitting an invalid empty one.
function Remove-NamespaceIfNeeded([string]$Content) {
    if (-not $stripNamespace) { return $Content }
    # (?m)^ instead of \A: some template files have leading comment lines before the
    # namespace declaration (for example MyAgentSetup.Table.al), so it is not always the
    # very first line. [^;]* (zero or more), not [^;]+: with $RootNamespace = '',
    # Convert-TemplateText has already substituted {{rootnamespace}} down to an empty
    # string, so the line to strip is the degenerate "namespace ;" (no characters between
    # the keyword and the semicolon).
    return [regex]::Replace($Content, '(?m)^namespace\s*[^;]*;\r?\n\r?\n?', '')
}

# ---------------------------------------------------------------------------
# Stage 1: template placeholder substitution (reimplements the AL extension's
# own algorithm, see reference/mapping.md § 3)
# ---------------------------------------------------------------------------

$placeholders = [ordered]@{
    publishername = $Publisher
    projectname   = $ProjectName
    rootnamespace = $RootNamespace
}
for ($i = 0; $i -lt 10; $i++) { $placeholders["guid$i"] = [guid]::NewGuid().ToString() }
$placeholders['guid0'] = $AppId  # app.json "id" must be the AppId we settled on above

function Convert-TemplateText([string]$Text) {
    $result = $Text
    foreach ($key in $placeholders.Keys) {
        $result = $result.Replace("{{$key}}", [string]$placeholders[$key])
    }
    $result = [regex]::Replace($result, '\{\{id\+(\d+)\}\}', { param($m) ($StartId + [int]$m.Groups[1].Value).ToString() })
    return $result
}

# ---------------------------------------------------------------------------
# Stage 2: two-pass rename (see reference/mapping.md § 5)
# ---------------------------------------------------------------------------

function Rename-AgentText([string]$Text) {
    $result = $Text.Replace('MyAgent', $BaseName)
    $result = $result.Replace('My Agent', $DisplayName)
    return $result
}

function Rename-AgentFileName([string]$Name) {
    return $Name.Replace('MyAgent', $BaseName)
}

# ---------------------------------------------------------------------------
# Stage 3: targeted slot fill (see reference/mapping.md § 4)
# ---------------------------------------------------------------------------

function Set-LabelValue([string]$Content, [string]$LabelName, [string]$NewValue) {
    $escaped = $NewValue.Replace("'", "''")
    $pattern = "(?m)^(\s*$LabelName\s*:\s*Label\s*)'[^']*'"
    return [regex]::Replace($Content, $pattern, { param($m) $m.Groups[1].Value + "'" + $escaped + "'" })
}

# Files that belong to the profile/permission-set surface. Skipped entirely in reuse mode.
# NOTE: these paths are relative to the *template's own* source tree (Microsoft's Agent
# project template names its source folder "app"), which is what Copy-TemplateTree below
# walks. They are unrelated to Stage 2.5's "app" -> "src" rename of the *destination*
# folder further down -- that rename runs after Copy-TemplateTree has already finished
# comparing against these template-relative paths.
$profileOwnedRelativePaths = @(
    'app/Setup/Permissions/MyAgent.permissionset.al',
    'app/Setup/Profile/MyAgentProfile.Profile.al',
    'app/Setup/Profile/MyAgentRoleCenter.Page.al',
    'app/Setup/Profile/MyAgentCustomerList.PageCustomization.al'
) | ForEach-Object { $_ -replace '/', [System.IO.Path]::DirectorySeparatorChar }

$skipFileNames = @('altemplate.json', '.DS_Store')

$filesWritten = [System.Collections.Generic.List[string]]::new()
$filesSkipped = [System.Collections.Generic.List[string]]::new()

function Copy-TemplateTree([string]$SourceDir, [string]$DestDir, [string]$RelativeRoot) {
    Get-ChildItem -LiteralPath $SourceDir -Force | ForEach-Object {
        $item = $_
        $relPath = if ($RelativeRoot) { Join-Path $RelativeRoot $item.Name } else { $item.Name }

        if ($skipFileNames -contains $item.Name) {
            $filesSkipped.Add($relPath) | Out-Null
            return
        }

        if ($item.PSIsContainer) {
            $newDestDir = Join-Path $DestDir $item.Name
            New-Item -ItemType Directory -Path $newDestDir -Force | Out-Null
            Copy-TemplateTree -SourceDir $item.FullName -DestDir $newDestDir -RelativeRoot $relPath
            return
        }

        if ($ReuseExistingProfile -and ($profileOwnedRelativePaths -contains $relPath)) {
            $filesSkipped.Add("$relPath (profile-owned, reused from dependency app)") | Out-Null
            return
        }

        $raw = Get-Content -LiteralPath $item.FullName -Raw -Encoding utf8
        $raw = $raw.Replace("`r`n", "`n")
        $content = Convert-TemplateText $raw
        $content = Rename-AgentText $content
        $content = Remove-NamespaceIfNeeded $content
        $newFileName = Rename-AgentFileName $item.Name
        $destPath = Join-Path $DestDir $newFileName

        Set-Content -LiteralPath $destPath -Value $content -Encoding utf8 -NoNewline
        $destRelPath = if ($RelativeRoot) { Join-Path $RelativeRoot $newFileName } else { $newFileName }
        $filesWritten.Add($destRelPath) | Out-Null
    }
}

Write-Info "Copying template tree (skip: $($skipFileNames -join ', '))..."
Copy-TemplateTree -SourceDir $TemplatePath -DestDir $TargetFolder -RelativeRoot ''

# ---------------------------------------------------------------------------
# Stage 2.5: rename the template's top-level "app" source folder to "src"
# ---------------------------------------------------------------------------
# Microsoft's Agent project template names its source folder "app". Once this project is
# renamed to something like "Room Planning Agent App", every AL source path then reads
# "Room Planning Agent App/app/Setup/...", which is confusing and does not match this
# repo's own AL project convention (see Chapter 6/Room Planning, which uses "src/" for the
# same purpose). Every stage before this point matched the *template's* own "app/..."
# relative paths during the copy above, so renaming the destination folder now is safe --
# every stage after this point locates files with Get-ChildItem -Recurse, which does not
# care what the intermediate folder is called.
$srcSourceFolder = Join-Path $TargetFolder 'app'
$srcTargetFolder = Join-Path $TargetFolder 'src'
if (Test-Path -LiteralPath $srcSourceFolder) {
    Move-Item -LiteralPath $srcSourceFolder -Destination $srcTargetFolder
    $appPrefix = "app$([System.IO.Path]::DirectorySeparatorChar)"
    $srcPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)"
    for ($i = 0; $i -lt $filesWritten.Count; $i++) {
        if ($filesWritten[$i].StartsWith($appPrefix)) {
            $filesWritten[$i] = $srcPrefix + $filesWritten[$i].Substring($appPrefix.Length)
        }
    }
    for ($i = 0; $i -lt $filesSkipped.Count; $i++) {
        if ($filesSkipped[$i].StartsWith($appPrefix)) {
            $filesSkipped[$i] = $srcPrefix + $filesSkipped[$i].Substring($appPrefix.Length)
        }
    }

    # The template's own README.md documents its "app/" folder in a "Project Structure"
    # ASCII tree. Rewrite just that folder line so the shipped README matches reality.
    $readmePath = Join-Path $TargetFolder 'README.md'
    if (Test-Path -LiteralPath $readmePath) {
        $readmeContent = Get-Content -LiteralPath $readmePath -Raw -Encoding utf8
        if ($readmeContent.Contains("`n├── app/`n")) {
            $readmeContent = $readmeContent.Replace("`n├── app/`n", "`n├── src/`n")
            Set-Content -LiteralPath $readmePath -Value $readmeContent -Encoding utf8 -NoNewline
        } else {
            Write-Gap "Could not find the expected '├── app/' line in README.md's Project Structure tree to rename it to 'src/'. Review the tree manually."
        }
    }
}

# ---------------------------------------------------------------------------
# Stage 2.6: rename the template's "Example" folder to "Interaction"
# ---------------------------------------------------------------------------
# The template calls this folder "Example" because its contents (a page extension that
# assigns a task, plus a public API codeunit pair) are meant to be adapted, not left as
# sample code. Microsoft's own hand-built agents don't ship an "Example" folder at all --
# see samples/BCAgents/SalesValidationAgent/app/Interaction, which holds the equivalent
# real page extension (extending "Sales Order List", not a placeholder page) under
# "Interaction". Renaming the folder now gets the shape right; it does NOT make the
# *content* domain-specific -- see reference/gotchas.md gotcha 7 for the manual pass
# every reader/agent still owes the generated task-trigger page extension.
$exampleSourceFolder = Join-Path $srcTargetFolder 'Example'
$interactionTargetFolder = Join-Path $srcTargetFolder 'Interaction'
if (Test-Path -LiteralPath $exampleSourceFolder) {
    Move-Item -LiteralPath $exampleSourceFolder -Destination $interactionTargetFolder
    $examplePrefix = "src$([System.IO.Path]::DirectorySeparatorChar)Example$([System.IO.Path]::DirectorySeparatorChar)"
    $interactionPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)Interaction$([System.IO.Path]::DirectorySeparatorChar)"
    for ($i = 0; $i -lt $filesWritten.Count; $i++) {
        if ($filesWritten[$i].StartsWith($examplePrefix)) {
            $filesWritten[$i] = $interactionPrefix + $filesWritten[$i].Substring($examplePrefix.Length)
        }
    }
    for ($i = 0; $i -lt $filesSkipped.Count; $i++) {
        if ($filesSkipped[$i].StartsWith($examplePrefix)) {
            $filesSkipped[$i] = $interactionPrefix + $filesSkipped[$i].Substring($examplePrefix.Length)
        }
    }
    if ($readmeContent -and $readmeContent.Contains("`n│   ├── Example/`n")) {
        $readmeContent = $readmeContent.Replace("`n│   ├── Example/`n", "`n│   ├── Interaction/`n")
        Set-Content -LiteralPath $readmePath -Value $readmeContent -Encoding utf8 -NoNewline
    }
    Write-Gap "Renamed the 'Example' folder to 'Interaction' to match Microsoft's own hand-built agent samples (see SalesValidationAgent). The page extension and public API codeunit inside still speak in generic 'record'/'task' language -- rewrite the action's Caption, ToolTip, and message labels to your agent's real business verb before shipping (reference/gotchas.md gotcha 7)."
}

# ---------------------------------------------------------------------------
# Stage 2.8: flatten Setup/{KPI,Metadata,Permissions,Profile,TaskExecution} to
# top-level src/ folders, matching Microsoft's own real, shipped agent apps
# ---------------------------------------------------------------------------
# The template nests KPI, Metadata, Permissions, Profile, and TaskExecution under
# Setup/, which reads like "everything configuration-related lives in one place". But
# Microsoft's own production agent (03-bc-system-app/BCApps/src/Apps/W1/SalesOrderAgent/
# app/src) does not do this: Permissions/, Profile/, RoleCenter/, and Validation/ (this
# template's TaskExecution/) are flat top-level siblings of Setup/, and Setup/ itself
# holds only the setup table/page/codeunit. Flatten the same way here. Room Planning's
# own src/Agent/Profile additionally splits page customizations into
# Profile/Customizations/ and groups the profile object with the role center page (and,
# since the KPI page is embedded on that role center, the KPI table/page too) under
# Profile/RoleCenter/ -- mirror that split as well. Metadata stays its own top-level
# folder rather than merging into Setup/, since its content (agent factory + metadata
# provider) is a distinct concern from setup configuration.
function Move-TemplateSubfolder([string]$FromRelative, [string]$ToRelative) {
    $from = Join-Path $srcTargetFolder ($FromRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $from)) { return }
    $items = @(Get-ChildItem -LiteralPath $from -Force -File)
    if ($items.Count -gt 0) {
        $to = Join-Path $srcTargetFolder ($ToRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        New-Item -ItemType Directory -Path $to -Force | Out-Null
        foreach ($it in $items) { Move-Item -LiteralPath $it.FullName -Destination (Join-Path $to $it.Name) -Force }
    }
    Remove-Item -LiteralPath $from -Recurse -Force -ErrorAction SilentlyContinue

    $fromPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)$($FromRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)$([System.IO.Path]::DirectorySeparatorChar)"
    $toPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)$($ToRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar)$([System.IO.Path]::DirectorySeparatorChar)"
    for ($i = 0; $i -lt $filesWritten.Count; $i++) {
        if ($filesWritten[$i].StartsWith($fromPrefix)) { $filesWritten[$i] = $toPrefix + $filesWritten[$i].Substring($fromPrefix.Length) }
    }
    for ($i = 0; $i -lt $filesSkipped.Count; $i++) {
        if ($filesSkipped[$i].StartsWith($fromPrefix)) { $filesSkipped[$i] = $toPrefix + $filesSkipped[$i].Substring($fromPrefix.Length) }
    }
}

$setupDir = Join-Path $srcTargetFolder 'Setup'

Move-TemplateSubfolder -FromRelative 'Setup/Metadata' -ToRelative 'Metadata'
Move-TemplateSubfolder -FromRelative 'Setup/Permissions' -ToRelative 'Permissions'
Move-TemplateSubfolder -FromRelative 'Setup/TaskExecution' -ToRelative 'TaskExecution'
Move-TemplateSubfolder -FromRelative 'Setup/KPI' -ToRelative 'Profile/RoleCenter'
Move-TemplateSubfolder -FromRelative 'Setup/Profile' -ToRelative 'Profile/RoleCenter'

# Split the page-customization file(s) back out of Profile/RoleCenter into
# Profile/Customizations/, matching Room Planning's src/Agent/Profile split.
$roleCenterDir = Join-Path $srcTargetFolder (Join-Path 'Profile' 'RoleCenter')
if (Test-Path -LiteralPath $roleCenterDir) {
    $customizationsDir = Join-Path $srcTargetFolder (Join-Path 'Profile' 'Customizations')
    Get-ChildItem -LiteralPath $roleCenterDir -Force -File -Filter '*.PageCustomization.al' | ForEach-Object {
        New-Item -ItemType Directory -Path $customizationsDir -Force | Out-Null
        Move-Item -LiteralPath $_.FullName -Destination (Join-Path $customizationsDir $_.Name) -Force
        $oldRel = "src$([System.IO.Path]::DirectorySeparatorChar)Profile$([System.IO.Path]::DirectorySeparatorChar)RoleCenter$([System.IO.Path]::DirectorySeparatorChar)$($_.Name)"
        $newRel = "src$([System.IO.Path]::DirectorySeparatorChar)Profile$([System.IO.Path]::DirectorySeparatorChar)Customizations$([System.IO.Path]::DirectorySeparatorChar)$($_.Name)"
        for ($i = 0; $i -lt $filesWritten.Count; $i++) { if ($filesWritten[$i] -eq $oldRel) { $filesWritten[$i] = $newRel } }
    }
}
# In reuse mode the page-customization file was never written to disk (skipped, reused from
# the dependency app), so the loop above finds nothing to move. Fix up its report entry too,
# so FilesSkipped describes where the file *would* live rather than the pre-split location.
$roleCenterPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)Profile$([System.IO.Path]::DirectorySeparatorChar)RoleCenter$([System.IO.Path]::DirectorySeparatorChar)"
$customizationsPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)Profile$([System.IO.Path]::DirectorySeparatorChar)Customizations$([System.IO.Path]::DirectorySeparatorChar)"
for ($i = 0; $i -lt $filesSkipped.Count; $i++) {
    if ($filesSkipped[$i].StartsWith($roleCenterPrefix) -and $filesSkipped[$i] -match '\.PageCustomization\.al\b') {
        $filesSkipped[$i] = $customizationsPrefix + $filesSkipped[$i].Substring($roleCenterPrefix.Length)
    }
}

# Setup/ itself is left with only the setup table/page/codeunit; remove it if somehow empty
# (reuse mode never empties it, since MyAgentSetup.* always writes).
Get-ChildItem -LiteralPath $setupDir -Force -ErrorAction SilentlyContinue |
    Where-Object { (Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 -and $_.PSIsContainer } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Cosmetic: the template's Profile.Description uses lowercase "my agent" prose, which the
# case-sensitive rename passes intentionally do not touch (see mapping.md § 5).
if (-not $ReuseExistingProfile) {
    $profilePath = Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter "$($BaseName)Profile.Profile.al" | Select-Object -First 1
    if ($profilePath) {
        $profileContent = Get-Content -LiteralPath $profilePath.FullName -Raw -Encoding utf8
        $profileContent = $profileContent.Replace("Description = 'Profile for my agent';", "Description = 'Profile for $DisplayName';")
        Set-Content -LiteralPath $profilePath.FullName -Value $profileContent -Encoding utf8 -NoNewline
    }
}

# ---------------------------------------------------------------------------
# Stage 4: fill the Setup codeunit's labels and default-profile/access-control logic
# ---------------------------------------------------------------------------

$setupCodeunitPath = Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter "$($BaseName)Setup.Codeunit.al" | Select-Object -First 1
if (-not $setupCodeunitPath) { throw "Could not find the generated Setup codeunit ($($BaseName)Setup.Codeunit.al) after copy." }

$setupContent = Get-Content -LiteralPath $setupCodeunitPath.FullName -Raw -Encoding utf8

$setupContent = Set-LabelValue $setupContent 'AgentInitialsLbl' ([string]$manifest.Initials)
$setupContent = Set-LabelValue $setupContent 'AgentNameLbl' $AgentUserName
$setupContent = Set-LabelValue $setupContent 'DefaultDisplayNameLbl' $DisplayName
$setupContent = Set-LabelValue $setupContent 'AgentSummaryLbl' ([string]$manifest.Description)

# Gotcha 6: keep the agent user name verbatim. The template's own GetAgentUserName()
# appends ' - ' + CompanyName(), which would break exact-name lookups such as
# FindAgentByUserName used by evaluation suites.
$originalGetAgentUserName = @"
    procedure GetAgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentNameLbl + ' - ' + CompanyName(), 1, 50));
    end;
"@
$newGetAgentUserName = @"
    procedure GetAgentUserName(): Code[50]
    begin
        // Kept verbatim (no ' - ' + CompanyName() suffix): exact-name lookups such as
        // FindAgentByUserName depend on this matching the exported <Name> exactly.
        exit(AgentNameLbl);
    end;
"@
if ($setupContent.Contains($originalGetAgentUserName)) {
    $setupContent = $setupContent.Replace($originalGetAgentUserName, $newGetAgentUserName)
} else {
    Write-Gap "GetAgentUserName in $($setupCodeunitPath.Name) did not match the expected template text; the ' - ' + CompanyName() suffix may still be present. Review manually (see mapping.md gotcha 6)."
}

$ownPermissionSetName = "$DisplayName"
$ownProfileName = if ($ReuseExistingProfile) { [string]$manifest.Profile.ProfileID } else { "$DisplayName Profile" }

if ($ReuseExistingProfile) {
    # The reused permission set is referenced by its literal Role ID string in
    # GetDefaultAccessControls, so DefaultPermissionSetTok would otherwise be unused.
    $setupContent = [regex]::Replace($setupContent, "(?m)^\s*DefaultPermissionSetTok: Label '[^']*', Locked = true;\r?\n", '')
} else {
    $setupContent = Set-LabelValue $setupContent 'DefaultPermissionSetTok' $ownPermissionSetName
}
$setupContent = Set-LabelValue $setupContent 'DefaultProfileTok' $ownProfileName
$setupContent = $setupContent.Replace("        // TODO: Adjust default permission set`r`n", '')
$setupContent = $setupContent.Replace("        // TODO: Adjust default permission set`n", '')

# --- GetDefaultProfile ---
$originalGetDefaultProfile = @"
    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Agent.PopulateDefaultProfile(DefaultProfileTok, CurrentModuleInfo.Id, TempAllProfile);
    end;
"@

if ($ReuseExistingProfile -and $useSelfReferenceForDependency) {
    $newGetDefaultProfile = @"
    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        // Profile "$ownProfileName" is defined elsewhere in this same app (see
        // src/$AgentFolderName/Profile), not generated by this scaffold.
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Agent.PopulateDefaultProfile(DefaultProfileTok, CurrentModuleInfo.Id, TempAllProfile);
    end;
"@
} elseif ($ReuseExistingProfile) {
    $newGetDefaultProfile = @"
    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    begin
        // Profile "$ownProfileName" lives in $DependencyAppName ($DependencyAppId), not in this app.
        Agent.PopulateDefaultProfile(DefaultProfileTok, DependencyAppIdTok, TempAllProfile);
    end;
"@
} else {
    $newGetDefaultProfile = $originalGetDefaultProfile
}

if (-not $setupContent.Contains($originalGetDefaultProfile)) {
    Write-Gap "GetDefaultProfile in $($setupCodeunitPath.Name) did not match the expected template text; left unmodified. Review manually."
} else {
    $setupContent = $setupContent.Replace($originalGetDefaultProfile, $newGetDefaultProfile)
}

# --- GetDefaultAccessControls ---
$originalGetDefaultAccessControls = @"
    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Clear(TempAccessControlBuffer);
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := CurrentModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := DefaultPermissionSetTok;
        TempAccessControlBuffer.Insert();
    end;
"@

$sourceOwnAppId = if ($manifest.Profile) { $manifest.Profile.AppID } else { $null }

$acBlocks = [System.Collections.Generic.List[string]]::new()
$extraLabelDecls = [System.Collections.Generic.List[string]]::new()
$labelIndex = 0

foreach ($ac in @($manifest.AccessControls)) {
    $isOwnPermissionSet = ($sourceOwnAppId -and ($ac.AppID -eq $sourceOwnAppId) -and ($ac.RoleID -eq $manifest.Profile.ProfileID))

    if ($isOwnPermissionSet -and (-not $ReuseExistingProfile)) {
        $acBlocks.Add(@"

        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := CurrentModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := DefaultPermissionSetTok;
        TempAccessControlBuffer.Insert();
"@) | Out-Null
        continue
    }

    $labelIndex++
    $labelName = "AccessControlAppId${labelIndex}Tok"
    $comment = Get-AppLabel $ac.AppID
    $appIdForLabel = if ($isOwnPermissionSet -and $ReuseExistingProfile -and $useSelfReferenceForDependency) { 'CurrentModuleInfo.Id' }
        elseif ($isOwnPermissionSet -and $ReuseExistingProfile) { 'DependencyAppIdTok' }
        else { $labelName }

    if (-not ($isOwnPermissionSet -and $ReuseExistingProfile)) {
        $extraLabelDecls.Add("        ${labelName}: Label '$($ac.AppID)', Locked = true; // $comment") | Out-Null
    }

    $roleIdLiteral = $ac.RoleID.Replace("'", "''")
    $acBlocks.Add(@"

        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := $appIdForLabel;
        TempAccessControlBuffer."Role ID" := '$roleIdLiteral';
        TempAccessControlBuffer.Insert();
"@) | Out-Null
}

$needsCurrentModuleInfo = (-not $ReuseExistingProfile) -or $useSelfReferenceForDependency
$varSection = if ($needsCurrentModuleInfo) { @"
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Clear(TempAccessControlBuffer);
"@ } else { @"
    begin
        Clear(TempAccessControlBuffer);
"@ }

$newGetDefaultAccessControls = @"
    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
$varSection$($acBlocks -join '')
    end;
"@

if (-not $setupContent.Contains($originalGetDefaultAccessControls)) {
    Write-Gap "GetDefaultAccessControls in $($setupCodeunitPath.Name) did not match the expected template text; left unmodified. Review manually."
} else {
    $setupContent = $setupContent.Replace($originalGetDefaultAccessControls, $newGetDefaultAccessControls)
}

# Insert Dependency App ID label + localization getter into the var section.
$varAnchor = '    var
        Agent: Codeunit Agent;'
$varReplacement = "    var`n        Agent: Codeunit Agent;"
if ($extraLabelDecls.Count -gt 0) {
    $varReplacement += "`n" + ($extraLabelDecls -join "`n")
}
if ($ReuseExistingProfile -and -not $useSelfReferenceForDependency) {
    $varReplacement += "`n        DependencyAppIdTok: Label '$DependencyAppId', Locked = true; // $DependencyAppName"
}
if ($setupContent.Contains($varAnchor)) {
    $setupContent = $setupContent.Replace($varAnchor, $varReplacement)
} else {
    Write-Gap "Could not find the 'var / Agent: Codeunit Agent;' anchor in $($setupCodeunitPath.Name) to insert extra labels. Review manually."
}

# Add a localization getter used by the Install codeunit.
$localizationGetter = @"

    procedure GetDefaultLocalizationSettings(var LanguageId: Integer; var LocaleId: Integer; var TimeZoneText: Text[180])
    begin
        // From the exported agent's <UserSettings LocaleID LanguageID TimeZone>.
        LanguageId := $($manifest.UserSettings.LanguageID);
        LocaleId := $($manifest.UserSettings.LocaleID);
        TimeZoneText := '$($manifest.UserSettings.TimeZone)';
    end;
"@
$anchorForLocalization = "    procedure InitializeSetupRecord"
if ($setupContent.Contains($anchorForLocalization)) {
    $setupContent = $setupContent.Replace($anchorForLocalization, ($localizationGetter.TrimStart("`r","`n") + "`n`n" + $anchorForLocalization))
} else {
    Write-Gap "Could not insert GetDefaultLocalizationSettings into $($setupCodeunitPath.Name). Review manually."
}

Set-Content -LiteralPath $setupCodeunitPath.FullName -Value $setupContent -Encoding utf8 -NoNewline

# ---------------------------------------------------------------------------
# Stage 5: write the instructions resource verbatim
# ---------------------------------------------------------------------------

$instructionsPath = Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter 'InstructionsV1.txt' | Select-Object -First 1
if ($instructionsPath) {
    Set-Content -LiteralPath $instructionsPath.FullName -Value ([string]$manifest.Instructions) -Encoding utf8 -NoNewline
    Write-Info "Wrote instructions verbatim to $($instructionsPath.FullName)"
} else {
    Write-Gap "InstructionsV1.txt not found after copy; instructions were not written."
}

if (@($manifest.ReferencedObjectIds).Count -gt 0) {
    foreach ($r in @($manifest.ReferencedObjectIds)) {
        Write-Gap "Instructions reference $($r.Kind).id == $($r.Id) — confirm this object ID resolves in the target app set."
    }
}

# ---------------------------------------------------------------------------
# Stage 6: Install codeunit - add localization call
# ---------------------------------------------------------------------------

$installPath = Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter "$($BaseName)Install.Codeunit.al" | Select-Object -First 1
if ($installPath) {
    $installContent = Get-Content -LiteralPath $installPath.FullName -Raw -Encoding utf8

    $callAnchorMatch = [regex]::Match($installContent, '(?m)^(\s*)InstallAgentSetup\((\w+)\);\s*$')
    if ($callAnchorMatch.Success) {
        $indent = $callAnchorMatch.Groups[1].Value
        $paramName = $callAnchorMatch.Groups[2].Value
        $newCall = "$($callAnchorMatch.Value)`n${indent}InstallAgentLocalization($paramName);"
        $installContent = $installContent.Replace($callAnchorMatch.Value, $newCall)

        $procAnchorMatch = [regex]::Match($installContent, "(?s)    local procedure InstallAgentSetup\(var ${paramName}: Record `"[^`"]+`"\)\r?\n    begin\r?\n(.*?)\r?\n    end;\r?\n")
        if ($procAnchorMatch.Success) {
            $newProc = @"

    local procedure InstallAgentLocalization(var ${paramName}: Record "$DisplayName Setup")
    var
        Agent: Codeunit Agent;
        ${BaseName}SetupCU: Codeunit "$DisplayName Setup";
        LanguageId: Integer;
        LocaleId: Integer;
        TimeZoneText: Text[180];
    begin
        ${BaseName}SetupCU.GetDefaultLocalizationSettings(LanguageId, LocaleId, TimeZoneText);
        Agent.UpdateLocalizationSettings($paramName."User Security ID", LanguageId, LocaleId, TimeZoneText);
    end;
"@
            $installContent = $installContent.Replace($procAnchorMatch.Value, $procAnchorMatch.Value + $newProc)
        } else {
            Write-Gap "Could not anchor InstallAgentLocalization procedure body next to InstallAgentSetup in $($installPath.Name). Added the call only; add the procedure body manually."
        }

        Set-Content -LiteralPath $installPath.FullName -Value $installContent -Encoding utf8 -NoNewline
        Write-Info "Added InstallAgentLocalization (UpdateLocalizationSettings: LanguageID=$($manifest.UserSettings.LanguageID), LocaleID=$($manifest.UserSettings.LocaleID)) to $($installPath.Name)"
    } else {
        Write-Gap "Could not find the InstallAgentSetup(...) call in $($installPath.Name) to anchor the localization call. Localization settings were NOT wired up — add Agent.UpdateLocalizationSettings manually."
    }
} else {
    Write-Gap "Install codeunit ($($BaseName)Install.Codeunit.al) not found after copy."
}

# ---------------------------------------------------------------------------
# Stage 7: task trigger page action
# ---------------------------------------------------------------------------

$pageExtPath = Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter "$($BaseName)CustomerCardExt.PageExt.al" | Select-Object -First 1
if ($pageExtPath -and $TaskTriggerPageName) {
    $peContent = Get-Content -LiteralPath $pageExtPath.FullName -Raw -Encoding utf8

    $peContent = [regex]::Replace($peContent, "pageextension (\d+) `"$([regex]::Escape($DisplayName)) Customer Card Ext`" extends `"Customer Card`"", "pageextension `$1 `"$DisplayName $TaskTriggerPageName Ext`" extends `"$TaskTriggerPageName`"")
    if ($TaskTriggerPageNamespace) {
        $peContent = $peContent.Replace('using Microsoft.Sales.Customer;', "using $TaskTriggerPageNamespace;")
    } else {
        Write-Gap "Pass -TaskTriggerPageNamespace to replace the leftover 'using Microsoft.Sales.Customer;' in the task trigger page extension with the real namespace of `"$TaskTriggerPageName`"."
    }

    $peContent = $peContent.Replace('Extends the Customer Card page to enable agent task assignment.', "Extends the `"$TaskTriggerPageName`" page to enable agent task assignment.")
    $peContent = $peContent.Replace('based on the current customer record.', 'based on the current record.')
    $peContent = $peContent.Replace("customer's number and name as context, enabling the agent to process", "record's key fields as context, enabling the agent to process")
    $peContent = $peContent.Replace('customer-specific operations.', 'record-specific operations.')
    $peContent = $peContent.Replace('Assign a task to the agent based on this customer.', 'Assign a task to the agent based on this record.')

    # The template's own OnAction body is a dead end as written: it builds a fixed message
    # string purely from Rec field values (no human ever sees or edits it) and routes through
    # the ...PublicAPI wrapper, a codeunit pair that exists so *other* AL apps can create tasks
    # for this agent (see gotcha 8), not something this same-app trigger needs to go through.
    # Microsoft's own documented pattern for "create tasks from page actions"
    # (learn.microsoft.com/dynamics365/business-central/dev-itpro/ai/ai-agent-sdk-tasks) calls
    # "Agent Task Builder" directly, and its real, shipped SalesValidationAgent sample
    # (Interaction/SalesValAgentSalesOrders.PageExt.al) goes one step further: it opens a small
    # StandardDialog page first so the user supplies the actual task input, then builds the task
    # from what the user confirmed. Replace the whole var/trigger block with that shape instead
    # of patching the template's version field-by-field.
    $oldTriggerBlock = @"
                trigger OnAction()
                var
                    ${BaseName}Setup: Record "$DisplayName Setup";
                    AgentTask: Record "Agent Task";
                    AgentSetup: Codeunit "Agent Setup";
                    AgentCU: Codeunit Agent;
                    ${BaseName}: Codeunit "$DisplayName Public API";
                    AgentUserSecurityId: Guid;
                    AgentName: Text;
                    TaskTitle: Text[150];
                    ExternalId: Text[2048];
                    From: Text[250];
                    MessageText: Text;
                    MessageTemplateTxt: Label 'Please process the customer with the name %1 and no. %2.', Locked = true;
                begin
                    // Select the agent to assign the task to
                    if not AgentSetup.OpenAgentLookup(Enum::"Agent Metadata Provider"::"$DisplayName", AgentUserSecurityId) then
                        exit;

                    if not ${BaseName}Setup.Get(AgentUserSecurityId) then
                        Error(SetupNotFoundErr);

                    // Populate message context with customer details
                    MessageText := StrSubstNo(MessageTemplateTxt, Rec.Name, Rec."No.");

                    // Set task properties based on customer
                    TaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, Rec.Name), 1, MaxStrLen(TaskTitle));
                    From := CopyStr(UserId(), 1, MaxStrLen(From));

                    // Assign the task to the agent
                    AgentTask := ${BaseName}.AssignTask(AgentUserSecurityId, TaskTitle, From, MessageText);

                    AgentName := AgentCU.GetDisplayName(AgentUserSecurityId);
                    Message(TaskAssignedMsg, AgentTask.ID, AgentName, Rec.Name);
                end;
"@.Replace("`r`n", "`n")

    $dialogPageName = "$DisplayName Assign Task Dialog"
    $newTriggerBlock = @"
                trigger OnAction()
                var
                    AgentSetup: Codeunit "Agent Setup";
                    AgentTaskBuilder: Codeunit "Agent Task Builder";
                    AgentTask: Record "Agent Task";
                    AssignTaskDialog: Page "$dialogPageName";
                    AgentUserSecurityId: Guid;
                    TaskTitle: Text[150];
                    From: Text[250];
                    MessageTemplateTxt: Label 'Please process the record with $TaskTriggerCaptionField %1 and $TaskTriggerKeyField %2.', Locked = true;
                begin
                    // Select the agent to assign the task to
                    if not AgentSetup.OpenAgentLookup(Enum::"Agent Metadata Provider"::"$DisplayName", AgentUserSecurityId) then
                        exit;

                    // Let the user review and edit the message before it goes to the agent, the
                    // same way a person composes a message for any other agent -- the dialog
                    // starts from a suggested message built from this record, but the agent
                    // only ever sees what the user actually confirms.
                    AssignTaskDialog.SetSuggestedMessage(StrSubstNo(MessageTemplateTxt, Rec."$TaskTriggerCaptionField", Rec."$TaskTriggerKeyField"));
                    if AssignTaskDialog.RunModal() <> Action::OK then
                        exit;

                    TaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, Rec."$TaskTriggerCaptionField"), 1, MaxStrLen(TaskTitle));
                    From := CopyStr(UserId(), 1, MaxStrLen(From));

                    // Assign the task to the agent
                    AgentTask := AgentTaskBuilder
                        .Initialize(AgentUserSecurityId, TaskTitle)
                        .AddTaskMessage(From, AssignTaskDialog.GetMessage())
                        .Create();

                    Message(TaskAssignedMsg, AgentTask.ID, Rec."$TaskTriggerCaptionField");
                end;
"@.Replace("`r`n", "`n")

    if ($peContent.Contains($oldTriggerBlock)) {
        $peContent = $peContent.Replace($oldTriggerBlock, $newTriggerBlock)
    } else {
        Write-Gap "Could not find the template's OnAction trigger block verbatim in $($pageExtPath.Name) to rewrite it onto Agent Task Builder + a review dialog. Review/rewrite the trigger manually."
    }

    $peContent = $peContent.Replace(
        "        SetupNotFoundErr: Label 'The setup could not be found for the selected agent.', Comment = 'Error message when agent setup record does not exist.';`n        TaskTitleLbl: Label 'Process Customer: %1', Comment = '%1 = Customer Name';`n        TaskAssignedMsg: Label 'Task %1 assigned successfully to agent %2 for customer %3.', Comment = '%1 = Task ID, %2 = Agent Name, %3 = Customer Name';",
        "        TaskTitleLbl: Label 'Process Record: %1', Comment = '%1 = Record identifier';`n        TaskAssignedMsg: Label 'Task %1 assigned successfully to the agent for record %2.', Comment = '%1 = Task ID, %2 = Record identifier';"
    )

    # Generate the review dialog the rewritten trigger now opens. Modeled directly on
    # SalesValidationAgent's own "Sales Val. Agent Date Picker" (StandardDialog, plain
    # Get/Set procedures, InherentEntitlements/Permissions = X) -- the only difference is a
    # free-text message field instead of a date, so it needs a not-blank check on close.
    $dialogFileName = Rename-AgentFileName "$($BaseName)AssignTaskDialog.Page.al"
    $dialogPath = Join-Path $pageExtPath.DirectoryName $dialogFileName
    $dialogObjectId = $StartId + 8
    $dialogContent = @"
namespace $RootNamespace;

/// <summary>
/// Lets the user review and edit the message before it is sent to the agent as a new task,
/// the same way Business Central's own agents (for example the Sales Order Agent's "Create
/// task" action) let a person compose the message by hand instead of sending it unseen.
/// </summary>
page $dialogObjectId "$dialogPageName"
{
    PageType = StandardDialog;
    Caption = 'Assign Agent Task';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(MessageText; MessageText)
            {
                Caption = 'Message';
                ToolTip = 'Specifies what you want the agent to do. Edit the suggested message, or replace it with your own.';
                ApplicationArea = All;
                MultiLine = true;
                ShowMandatory = true;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if MessageText = '' then
                Error(MessageRequiredErr);
        exit(true);
    end;

    procedure GetMessage(): Text
    begin
        exit(MessageText);
    end;

    procedure SetSuggestedMessage(SuggestedMessage: Text)
    begin
        MessageText := CopyStr(SuggestedMessage, 1, MaxStrLen(MessageText));
    end;

    var
        MessageText: Text;
        MessageRequiredErr: Label 'Enter a message for the agent before you continue.';
}
"@.Replace("`r`n", "`n")
    $dialogContent = Remove-NamespaceIfNeeded $dialogContent
    Set-Content -LiteralPath $dialogPath -Value $dialogContent -Encoding utf8 -NoNewline
    Write-Info "Generated $dialogFileName so the task-trigger action gets its input from a user-reviewed dialog, not a silently-built string."

    $safeTriggerName = ($TaskTriggerPageName -replace '[^A-Za-z0-9]', '') + 'Ext'
    $newBaseFileName = $pageExtPath.Name -replace 'CustomerCardExt', $safeTriggerName
    $newFileName = Rename-AgentFileName $newBaseFileName
    $newPath = Join-Path $pageExtPath.DirectoryName $newFileName
    Set-Content -LiteralPath $newPath -Value $peContent -Encoding utf8 -NoNewline
    if ($newPath -ne $pageExtPath.FullName) { Remove-Item -LiteralPath $pageExtPath.FullName -Force }
    Write-Info "Wired the task trigger action to page `"$TaskTriggerPageName`" ($newFileName)"

    # The README's "Example Integration" prose is static template text that still names the
    # old file and the old "Customer Card"/"customer" concept. The "Project Structure" tree
    # itself is regenerated wholesale in Stage 7.5 below, so it is not patched here.
    $readmePath2 = Join-Path $TargetFolder 'README.md'
    $oldExtName = $pageExtPath.Name
    if (Test-Path -LiteralPath $readmePath2) {
        $readme2 = Get-Content -LiteralPath $readmePath2 -Raw -Encoding utf8
        $readme2 = $readme2.Replace("### Example Integration`n`n``$oldExtName``", "### Task Trigger Integration`n`n``$newFileName``")
        $readme2 = $readme2.Replace("It extends the Customer Card page with an action that assigns tasks to an agent based on the current customer record.", "It extends the `"$TaskTriggerPageName`" page with an action that assigns tasks to an agent based on the current record.")
        $readme2 = $readme2.Replace('- Create a task with customer-specific context', "- Let the user review and edit the message in ``$dialogFileName`` before it is sent`n- Create a task with the record's key fields as context")
        $readme2 = $readme2.Replace("``$oldExtName`` demonstrates", "``$newFileName`` demonstrates")
        $readme2 = $readme2.Replace(
            "``${BaseName}PublicAPI.Codeunit.al`` provides the public API for creating agents, assigning tasks with external IDs and attachments, and managing agent lifecycle.",
            "``${BaseName}PublicAPI.Codeunit.al`` provides the public API for *other* AL apps that need to create tasks for this agent, with external IDs and attachments, and manage its lifecycle. This app's own task trigger (``$newFileName``) does not go through it -- it calls ``Agent Task Builder`` directly, matching Microsoft's own documented pattern for creating tasks from page actions."
        )
        # Two more static "Customer Card" mentions live outside the "Task Trigger Integration"
        # section this stage otherwise patches (in "Quick Start" and "What Happens When You
        # Publish"). Fix them too, so no leftover "Customer Card" wording survives once
        # -TaskTriggerPageName is given.
        $readme2 = $readme2.Replace('Assign tasks via the Customer Card page extension.', "Assign tasks via the `"$TaskTriggerPageName`" page extension.")
        $readme2 = $readme2.Replace('The Customer Card page extension demonstrates how to integrate agent tasks into your business processes', "The `"$TaskTriggerPageName`" page extension demonstrates how to integrate agent tasks into your business processes")
        Set-Content -LiteralPath $readmePath2 -Value $readme2 -Encoding utf8 -NoNewline
    }
} elseif ($pageExtPath) {
    Write-Gap "No -TaskTriggerPageName given: the task trigger action still extends the template's example 'Customer Card' page. Pass -TaskTriggerPageName to wire it to a real page."
}

# ---------------------------------------------------------------------------
# Stage 7.5: regenerate the README's "Project Structure" tree wholesale
# ---------------------------------------------------------------------------
# Stages 2.5, 2.6, 2.8, and 7 above each moved, split, merged, or renamed files that the
# template's static README.md tree describes. Patching that ASCII tree line-by-line for
# every possible combination of fresh/reuse mode and task-trigger renames is fragile.
# Instead, walk the actual generated tree now that it is final and rebuild the whole
# "## Project Structure" code block from what is really on disk, with a small lookup of
# known template-file comments (matched by filename pattern, not hardcoded literal names,
# since every filename is prefixed with $BaseName).
function Get-KnownFileComment([string]$FileName) {
    $b = [regex]::Escape($BaseName)
    $rules = [ordered]@{
        '^InstructionsV1\.txt$'                     = 'Agent instructions'
        "^${b}CopilotCapability\.EnumExt\.al$"       = 'Copilot capability registration'
        "^${b}Install\.Codeunit\.al$"                = 'Installation logic'
        "^${b}Upgrade\.Codeunit\.al$"                = 'Upgrade logic'
        "^${b}PublicAPIImpl\.Codeunit\.al$"          = 'Public API implementation'
        "^${b}PublicAPI\.Codeunit\.al$"              = 'Public API for agent operations'
        "^${b}AssignTaskDialog\.Page\.al$"            = 'Dialog where the user reviews/edits the task message before it is sent'
        '\.PageExt\.al$'                             = $(if ($TaskTriggerPageName) { "Task trigger: assigns a task to the agent from `"$TaskTriggerPageName`"" } else { 'Example customer card extension' })
        "^${b}Setup\.Codeunit\.al$"                  = 'Agent setup utilities'
        "^${b}Setup\.Page\.al$"                      = 'Setup page'
        "^${b}Setup\.Table\.al$"                     = 'Setup configuration table'
        "^${b}Factory\.Codeunit\.al$"                = 'Agent factory implementation'
        "^${b}MetadataProvider\.EnumExt\.al$"        = 'Agent metadata provider enum extension'
        "^${b}Metadata\.Codeunit\.al$"                = 'Agent metadata provider'
        '\.permissionset\.al$'                       = 'Agent permission set'
        '\.PageCustomization\.al$'                   = 'Page customization'
        "^${b}Profile\.Profile\.al$"                 = 'Agent profile'
        "^${b}RoleCenter\.Page\.al$"                 = 'Agent role center'
        "^${b}KPI\.Page\.al$"                        = 'Agent summary/dashboard, embedded on the role center'
        "^${b}KPI\.Table\.al$"                       = 'KPI tracking table'
        "^${b}TaskExecution\.Codeunit\.al$"          = 'Task execution logic'
        '^app\.json$'                                = 'Project manifest'
        '^README\.md$'                               = 'Readme for the template'
    }
    foreach ($pattern in $rules.Keys) {
        if ($FileName -match $pattern) { return $rules[$pattern] }
    }
    return $null
}

function New-TreeNode { [PSCustomObject]@{ Children = [ordered]@{}; IsFile = $false; Comment = $null } }

function Add-TreePath($RootNode, [string[]]$Segments) {
    $node = $RootNode
    $pathSoFar = ''
    for ($i = 0; $i -lt $Segments.Count; $i++) {
        $seg = $Segments[$i]
        $pathSoFar = if ($pathSoFar) { "$pathSoFar/$seg" } else { $seg }
        $isNew = -not $node.Children.Contains($seg)
        if ($isNew) { $node.Children[$seg] = New-TreeNode }
        $node = $node.Children[$seg]
        if ($i -eq $Segments.Count - 1) {
            $node.IsFile = $true
            $node.Comment = Get-KnownFileComment $seg
        } elseif ($isNew -and $pathSoFar -eq '.resources') {
            $node.Comment = 'Resource files (e.g., InstructionsV1.txt)'
        }
    }
}

function Format-TreeLines($Node, [string]$Prefix, [System.Collections.Generic.List[string]]$Lines) {
    # Directories before files, alphabetical within each group -- matches how tree tools
    # conventionally render, and keeps output stable regardless of filesystem enumeration order.
    $keys = @($Node.Children.Keys | Sort-Object -Property @{Expression = { $Node.Children[$_].IsFile } }, @{Expression = { $_ } })
    for ($i = 0; $i -lt $keys.Count; $i++) {
        $key = $keys[$i]
        $child = $Node.Children[$key]
        $isLast = ($i -eq $keys.Count - 1)
        $connector = if ($isLast) { '└── ' } else { '├── ' }
        $displayName = if ($child.IsFile) { $key } else { "$key/" }
        $line = "$Prefix$connector$displayName"
        if ($child.Comment) {
            $pad = [Math]::Max(1, 50 - $line.Length)
            $line += (' ' * $pad) + "# $($child.Comment)"
        }
        $Lines.Add($line) | Out-Null
        if ($child.Children.Count -gt 0) {
            $childPrefix = $Prefix + $(if ($isLast) { '    ' } else { '│   ' })
            Format-TreeLines $child $childPrefix $Lines
        }
    }
}

$treeRoot = New-TreeNode
Get-ChildItem -Path $TargetFolder -Recurse -Force -File | ForEach-Object {
    $relPath = $_.FullName.Substring($TargetFolder.Length + 1)
    $segments = $relPath.Split([System.IO.Path]::DirectorySeparatorChar)
    Add-TreePath $treeRoot $segments
}
$treeLines = [System.Collections.Generic.List[string]]::new()
Format-TreeLines $treeRoot '' $treeLines
$newTreeBlock = "agent/`n" + ($treeLines -join "`n")

$readmePathTree = Join-Path $TargetFolder 'README.md'
if (Test-Path -LiteralPath $readmePathTree) {
    $readmeTree = Get-Content -LiteralPath $readmePathTree -Raw -Encoding utf8
    $treeBlockPattern = '(?s)(## Project Structure\r?\n\r?\n```\r?\n).*?(\r?\n```)'
    if ($readmeTree -match $treeBlockPattern) {
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value + $newTreeBlock + $m.Groups[2].Value }
        $readmeTree = [regex]::Replace($readmeTree, $treeBlockPattern, $evaluator)
        Set-Content -LiteralPath $readmePathTree -Value $readmeTree -Encoding utf8 -NoNewline
    } else {
        Write-Gap "Could not find the '## Project Structure' code block in README.md to regenerate. Review the tree manually."
    }
}

# ---------------------------------------------------------------------------
# Stage 8: app.json finishing touches
# ---------------------------------------------------------------------------

$appJsonPath = Join-Path $TargetFolder 'app.json'
$appJson = Get-Content -LiteralPath $appJsonPath -Raw -Encoding utf8 | ConvertFrom-Json

if ($AppName) { $appJson.name = $AppName } else { $appJson.name = $DisplayName }
$appJson.publisher = $Publisher
$appJson.brief = [string]$manifest.Description
$appJson.description = [string]$manifest.Description
$appJson.application = $ApplicationVersion
$appJson.platform = $PlatformVersion

if ($ReuseExistingProfile -or $DependencyAppId) {
    $dep = [PSCustomObject]@{
        id        = $DependencyAppId
        name      = $DependencyAppName
        publisher = $DependencyAppPublisher
        version   = $(if ($DependencyAppVersion) { $DependencyAppVersion } else { '1.0.0.0' })
    }
    $appJson.dependencies = @($dep)
}

$appJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $appJsonPath -Encoding utf8

Write-Info "Generated app.json: id=$($appJson.id) name='$($appJson.name)' publisher='$($appJson.publisher)'"

# ---------------------------------------------------------------------------
# Stage 9: AL object-identifier length safety net (max 30 characters)
# ---------------------------------------------------------------------------
# Embedding a long DisplayName into every template suffix ("... Public API Impl.",
# "... Job Card Ext") can push some declared object names past AL's 30-character
# identifier limit (AL0305), even though none of that text is "MyAgent"/"My Agent"
# residue. Scan every generated object declaration and truncate any offender to 30
# characters everywhere it appears, so cross-file references stay consistent.

$declPattern = [regex]'(?m)^(codeunit|page|pageextension|table|tableextension|enum|enumextension|permissionset|query|report|xmlport)\s+(?:\d+\s+)?"([^"]{31,})"'
$allAlFiles = Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter '*.al'
$longNames = [System.Collections.Generic.HashSet[string]]::new()
foreach ($f in $allAlFiles) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8
    foreach ($m in $declPattern.Matches($text)) { $longNames.Add($m.Groups[2].Value) | Out-Null }
}

# "profile" objects declare their name unquoted-keyword-then-quoted too, same shape as the others,
# already covered by the pattern above (profile "Name" matches the alternation? "profile" not listed).
$profileDeclPattern = [regex]'(?m)^profile\s+"([^"]{31,})"'
foreach ($f in $allAlFiles) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8
    foreach ($m in $profileDeclPattern.Matches($text)) { $longNames.Add($m.Groups[1].Value) | Out-Null }
}

if ($longNames.Count -gt 0) {
    # Prefer swapping the "$DisplayName " prefix for the short agent initials instead of a
    # blind character-index truncation: blind truncation can collide with another real object
    # (for example "...Public API Impl." and "...Public API" can truncate to the same 30
    # characters). Initials are short (Text[4]) and specifically meant for this.
    $shortPrefix = if ($manifest.Initials) { [string]$manifest.Initials } else { ($DisplayName -split ' ')[0] }
    $usedNames = [System.Collections.Generic.HashSet[string]]::new([string[]]$longNames)
    Get-ChildItem -Path $TargetFolder -Recurse -Force -Filter '*.al' | ForEach-Object {
        $text = Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8
        foreach ($m in $declPattern.Matches($text)) { $usedNames.Add($m.Groups[2].Value) | Out-Null }
    }

    foreach ($longName in $longNames) {
        $candidate = $longName
        if ($candidate.StartsWith("$DisplayName ")) {
            $candidate = $shortPrefix + $candidate.Substring($DisplayName.Length)
        }
        if ($candidate.Length -gt 30) { $candidate = $candidate.Substring(0, 30).TrimEnd() }
        $suffixNum = 1
        while ($usedNames.Contains($candidate) -and ($candidate -ne $longName)) {
            $suffixNum++
            $candidate = ($candidate.Substring(0, [Math]::Min($candidate.Length, 28)).TrimEnd()) + " $suffixNum"
        }
        $usedNames.Add($candidate) | Out-Null

        Write-Gap "Object name `"$longName`" is $($longName.Length) characters, over AL's 30-character identifier limit. Renamed to `"$candidate`" everywhere it appears (using the agent's initials instead of the full display name). Review the shortened name for clarity."
        foreach ($f in $allAlFiles) {
            $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding utf8
            if ($text.Contains($longName)) {
                $text = $text.Replace($longName, $candidate)
                Set-Content -LiteralPath $f.FullName -Value $text -Encoding utf8 -NoNewline
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Stage 10: .gitignore
# ---------------------------------------------------------------------------
# Microsoft's own Agent template ships no .gitignore at all (verified: the raw template
# folder has only .resources/ and a stray macOS .DS_Store). Without one, every `alc` build
# artifact (.alpackages/, *.app, .vscode/) is one `git add -A` away from being committed.
# Write the same AL project .gitignore convention used elsewhere in this book's repo.

$gitignorePath = Join-Path $TargetFolder '.gitignore'
if (-not (Test-Path -LiteralPath $gitignorePath)) {
    $gitignoreContent = @"
### AL ###
# Template for AL projects for Dynamics 365 Business Central
# VS Code (local overrides)
.vscode/
# Cache folder
.alcache/
# Symbols folder
.alpackages/
# Snapshots folder
.snapshots/
# Testing Output folder
.output/
# Extension App-file
*.app
# Rapid Application Development File
rad.json
# Translation Base-file
*.g.xlf
# License-file
*.flf
# Test results file
TestResults.xml
"@
    Set-Content -LiteralPath $gitignorePath -Value $gitignoreContent -Encoding utf8 -NoNewline
    $filesWritten.Add('.gitignore') | Out-Null
}

# ---------------------------------------------------------------------------
# Stage 11: in-app mode -- move src/ and .resources/ out of the scratch folder and
# into the existing app, then discard the scratch app.json/.gitignore/README.md
# ---------------------------------------------------------------------------

if ($InAppMode) {
    function Copy-ScratchTree([string]$From, [string]$To) {
        Get-ChildItem -LiteralPath $From -Force | ForEach-Object {
            $dest = Join-Path $To $_.Name
            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                Copy-ScratchTree -From $_.FullName -To $dest
            } else {
                Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
            }
        }
    }

    $scratchSrc = Join-Path $TargetFolder 'src'
    $scratchResources = Join-Path $TargetFolder '.resources'
    $realSrcAgentRoot = Join-Path (Join-Path $RealTargetFolder 'src') $AgentFolderName
    New-Item -ItemType Directory -Path $realSrcAgentRoot -Force | Out-Null
    if (Test-Path -LiteralPath $scratchSrc) { Copy-ScratchTree -From $scratchSrc -To $realSrcAgentRoot }

    $realResources = Join-Path $RealTargetFolder '.resources'
    if (Test-Path -LiteralPath $scratchResources) {
        New-Item -ItemType Directory -Path $realResources -Force | Out-Null
        Copy-ScratchTree -From $scratchResources -To $realResources
    }

    Remove-Item -LiteralPath $TargetFolder -Recurse -Force -ErrorAction SilentlyContinue

    # Re-root the report onto the real app: src/... becomes src/<AgentFolderName>/..., and
    # the scratch app.json/.gitignore/README.md never existed as far as the caller is
    # concerned -- those belong to the existing app, untouched.
    $srcPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)"
    $srcAgentPrefix = "src$([System.IO.Path]::DirectorySeparatorChar)$AgentFolderName$([System.IO.Path]::DirectorySeparatorChar)"
    for ($i = 0; $i -lt $filesWritten.Count; $i++) {
        if ($filesWritten[$i].StartsWith($srcPrefix)) { $filesWritten[$i] = $srcAgentPrefix + $filesWritten[$i].Substring($srcPrefix.Length) }
    }
    for ($i = 0; $i -lt $filesSkipped.Count; $i++) {
        if ($filesSkipped[$i].StartsWith($srcPrefix)) { $filesSkipped[$i] = $srcAgentPrefix + $filesSkipped[$i].Substring($srcPrefix.Length) }
    }
    $filesWritten = [System.Collections.Generic.List[string]]($filesWritten | Where-Object { $_ -notin @('app.json', '.gitignore', 'README.md') })

    $TargetFolder = $RealTargetFolder
    Write-Info "Merged generated agent objects into $RealTargetFolder (under src/$AgentFolderName)."
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

$report = [PSCustomObject]@{
    TargetFolder = $TargetFolder
    AppId        = if ($InAppMode) { [string]$existingAppJson.id } else { $appJson.id }
    BaseName     = $BaseName
    DisplayName  = $DisplayName
    Mode         = "$(if ($InAppMode) { 'InApp' } else { 'Standalone' })/$(if ($ReuseExistingProfile) { 'Reuse' } else { 'Fresh' })"
    FilesWritten = $filesWritten
    FilesSkipped = $filesSkipped
    Gaps         = $script:Gaps
}

if ($OutFile) {
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutFile -Encoding utf8
    Write-Info "Wrote scaffold report to $OutFile"
}
Write-Host ""
Write-Host "Files written: $($filesWritten.Count), skipped: $($filesSkipped.Count), gaps: $($script:Gaps.Count)"
if ($script:Gaps.Count -gt 0) {
    Write-Host "Gaps:"
    $script:Gaps | ForEach-Object { Write-Host "  - $_" }
}

$report
