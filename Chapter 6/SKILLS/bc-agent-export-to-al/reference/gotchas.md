# Operational gotchas

Practical checklist to consult while running the skill. For the schema and the reasoning
behind each rule, see `mapping.md`.

## Before you start

- [ ] PowerShell 7.0+ (`pwsh`). Windows PowerShell 5.1 has no `$IsWindows` / `$IsMacOS`,
      which template discovery needs. `Convert-AgentExportToAl.ps1` checks this and stops
      with a clear message instead of failing obscurely deep inside template discovery.
- [ ] You have the exported agent XML from **Agents → (your agent) → Export**, or from the
      Test Agent's export action. One file, one or more `<Agent>` nodes inside.
- [ ] You know which existing AL app (if any) already contains the profile, page
      customizations, and permission set referenced by the export. If they live in a
      different app than the one you're generating, decide up front whether the new agent
      app takes a dependency on it, or whether those objects move into the new app.
- [ ] Decide standalone vs. in-app now. If that same app is the one that owns the business
      logic the agent operates on (Room Planning's `src/Agent/Permissions`/`Profile` were
      hand-built there, not exported into their own app), pass `-ExistingAppFolder` instead
      of `-TargetFolder` and add the agent directly into it — see `mapping.md` § 9. Do not
      default to a new standalone app just because that's the more common path; it adds an
      app, a dependency edge, and a foreign-GUID label for no benefit when the objects
      already live together.

## During template resolution

- [ ] If the local AL extension scan and the Marketplace VSIX download both fail (offline,
      corporate proxy, VS Code not installed), pass `-TemplatePath` yourself. Point it at
      any `templates/agent` folder from a `ms-dynamics-smb.al-*` VSIX you already have.
- [ ] VSIX files are ZIPs with a renamed extension. `Expand-Archive` refuses the `.vsix`
      extension outright — the resolver uses `[System.IO.Compression.ZipFile]::OpenRead()`
      directly. Don't "fix" this by renaming to `.zip` inside the script; it works as-is.

## During parsing

- [ ] If the export has more than one `<Agent>`, pass `-AgentName` explicitly. The parser
      refuses to guess.
- [ ] Object IDs referenced inside `{% if page.id == NNNNN %}` blocks in the instructions
      are extracted and listed in the manifest and the report. Confirm each one resolves in
      your target app set before you publish — the parser cannot verify this itself, it can
      only flag the numbers.
- [ ] `<AccessControl>` entries can carry an `AppID` that is neither the source app nor the
      new agent app (a foreign system app, most often `LOGIN` from the System Application).
      These are captured verbatim, never rewritten to `CurrentModuleInfo.Id`.

## During scaffolding

- [ ] Two independent rename passes, always `MyAgent` (no space) before `My Agent` (one
      space). Never introduce a third ad hoc rename pass — it will double-replace text the
      first two passes already touched.
- [ ] `UpdateLocalizationSettings(AgentUserSecurityId, LanguageID, LocaleID, TimeZone)` —
      language before locale. The XML has them the other way around. Bind by parameter name,
      never by the XML attribute order.
- [ ] Do not let `GetAgentUserName()` append `- CompanyName()` unless you also update every
      place downstream that matches the agent by exact user name (evaluation suites,
      `FindAgentByUserName` lookups). If in doubt, keep the name verbatim.
- [ ] `app.json`'s `"application"` / `"platform"` versions in the raw template default to an
      older release. Pass `-ApplicationVersion` / `-PlatformVersion` to match the rest of
      your app set (this book's Chapter 6 apps target `29.0.0.0`).
- [ ] The template's own `app.json` has `"dependencies": []`. If the profile, permission
      set, or page customizations stay in the source app, add that app as a dependency —
      `New-AgentAlApp.ps1 -DependencyAppId/-DependencyAppName/-DependencyAppPublisher/-DependencyAppVersion`.
- [ ] Pass `-TaskTriggerPageName` (and `-TaskTriggerPageNamespace`,
      `-TaskTriggerKeyField`, `-TaskTriggerCaptionField` if they differ from `No.` /
      `Description`). Figure out the *real* trigger page from the agent's `<Description>`
      and the object IDs referenced in its instructions — do not leave the task trigger
      wired to the template's sample `Customer Card`.
- [ ] `Setup/{KPI,Metadata,Permissions,Profile,TaskExecution}` are flattened automatically
      to top-level `src/` folders (`Profile/` splits further into `Profile/Customizations/`
      and `Profile/RoleCenter/`), matching Microsoft's real, shipped `SalesOrderAgent`
      structure instead of the template's own deeper nesting — see `mapping.md` § 5. This
      is a filesystem move only; it never changes AL object content, since every generated
      file declares a single flat `namespace Packt;` with no per-folder namespace to keep
      in sync.
- [ ] When `-TaskTriggerPageName` is given, the generated `OnAction` trigger no longer
      matches the raw template body. It calls `Agent Task Builder` directly (not the
      `...PublicAPI` wrapper) and opens a freshly generated `...AssignTaskDialog.Page.al`
      (`StandardDialog`) so the user reviews/edits the message before the task is created —
      the same shape as the real, shipped `SalesValidationAgent`'s date-picker dialog. See
      `mapping.md` § 8. `Test-AgentAlApp.ps1`'s `{{...}}`/`TODO:` scan does not (and cannot)
      check for this shape; verify it by reading the trigger, not just by a clean compile.
- [ ] With `-ExistingAppFolder`, `-StartId` is validated against that app's own `idRanges`
      and against every object number already used anywhere in it (any object type, not
      just the same one) — nine consecutive free numbers are needed for `{{id+0}}` ..
      `{{id+8}}`. The script errors out with the exact colliding numbers or range mismatch;
      do not retry with `-SkipVerify`-style workarounds, just pick a different `-StartId`.
      The generated files land under `<ExistingAppFolder>/src/<AgentFolderName>/` (default
      `Agent`), and the existing app's own `app.json`/`.gitignore`/`README.md` are left
      untouched — the skill never rewrites them.
- [ ] `-ExistingAppFolder` combined with `-ReuseExistingProfile` needs no `-DependencyApp*` —
      they're derived from the existing app's own `app.json`, and the generated
      `GetDefaultProfile`/`GetDefaultAccessControls` reference it via `CurrentModuleInfo.Id`
      instead of a hardcoded GUID label (see `mapping.md` § 9 point 3). `-ReuseExistingProfile`
      is still a required, explicit switch even here — the skill does not auto-detect that
      `Permissions`/`Profile` files already exist at the target and silently skip generating
      stand-ins; pass it yourself when they do.
- [ ] `-ExistingAppFolder` against an app with no `namespace` declarations at all (older AL
      apps, including this book's own Chapter 6 - Room Planning) makes every file this run
      generates omit the `namespace` line too, instead of emitting an invalid empty one —
      confirmed by scanning the existing app's `.al` files first. Pass `-RootNamespace`
      explicitly to override this detection if the existing app actually mixes namespaced
      and non-namespaced files.

## After scaffolding, before you ship

- [ ] `app/Example` is renamed to `src/Interaction` automatically, matching Microsoft's own
      hand-built agent samples (`SalesValidationAgent/app/Interaction`). But the rename is
      cosmetic — the action inside is still named `AssignAgentTask` with generic "record"/
      "task"/"message" wording (including on the review dialog itself). Read `mapping.md`
      gotcha 7, look at how `SalesValidationAgent`'s `ValidateWithAgent` action speaks the
      agent's real business verb in its `Caption`, `ToolTip`, and labels, and rewrite the
      generated action and dialog (identifier, `Caption`, `ToolTip`, every `Lbl`/`Err`/
      `Msg`) to match your agent's actual job before you ship it. The script flags this
      gap; it cannot resolve it for you.
- [ ] Decide whether the generated `...PublicAPI`/`...PublicAPIImpl` codeunit pair is even
      needed. `SalesValidationAgent` does not have one, and the scaffolded task-trigger
      action no longer calls it either (it calls `Agent Task Builder` directly — see
      `mapping.md` § 8) — the pair only exists if another AL app needs to create tasks for
      this agent. If nothing calls it, delete it rather than shipping unused boilerplate.

## Before you compile

- [ ] Run `Test-AgentAlApp.ps1` first. It scans for leftover `{{...}}` tokens, leftover
      `TODO:` markers in slots the skill was supposed to fill, and leftover literal
      `MyAgent` / `My Agent` occurrences the rename pass may have missed (for example inside
      a `.md` file the copy loop touched but the rename pass didn't reach).
- [ ] With `-ExistingAppFolder`, `Test-AgentAlApp.ps1 -AppFolder <the existing app>` scans
      the *whole* app, not just the agent's own subfolder — any `TODO:` markers that were
      already in the app's pre-existing code show up as `Info` findings too. That's expected
      noise, not a regression; only `Error`-level findings (leftover placeholders, rename
      residue, a broken `app.json`) indicate something this run actually did wrong.
- [ ] Download symbols for every dependency (including the app that now owns the profile,
      if any) before compiling. In this repo, use the `al_downloadsymbols` /
      `al_build` MCP tools, or VS Code's **AL: Download symbols**.
- [ ] If compiling from the CLI outside VS Code, the extension's `alc.exe`/`alc.dll` is a
      Windows-only build in some extension releases (verified: the bundled `alc.exe` in
      `ms-dynamics-smb.al-18.0.2668733` is a Windows PE binary, not runnable directly on
      macOS/Linux without a matching cross-platform build). `Test-AgentAlApp.ps1` reports
      this instead of pretending the compile step ran, and points at the AL MCP server or VS
      Code as the reliable compile path when no cross-platform `alc` is available.
