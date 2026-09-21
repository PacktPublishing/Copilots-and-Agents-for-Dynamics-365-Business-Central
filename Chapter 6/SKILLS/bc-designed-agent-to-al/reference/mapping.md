# Export → AL mapping reference

Fixture used to confirm every rule in this document: `ROOM PLANNING AGENT-agent.xml`
(the designed-agent export for the Room Planning app), shipped in the same book repo at
`07-my-chapters/Chapter06/Draft/ROOM PLANNING AGENT-agent.xml`.

## 1. Export schema (confirmed against the fixture)

UTF-8, no BOM required but tolerated. Root element is a collection:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<Agents>
  <Agent>
    <Name>ROOM PLANNING AGENT</Name>
    <DisplayName>Room Planning Agent</DisplayName>
    <Initials>RPA</Initials>
    <Description>Assigns rooms to conference sessions based on expected attendees</Description>
    <Version>1.0</Version>
    <Export Date="2026-09-21T04:13:01.397Z" />
    <AccessControls>
      <AccessControl RoleID="LOGIN" Scope="System" AppID="{63CA2FA4-4F03-4F2B-A480-172FEF340D3F}" />
      <AccessControl RoleID="ROOM PLANNING AGENT" Scope="System" AppID="{46E6E597-366B-4ED8-B9AA-DDB98540578C}" />
    </AccessControls>
    <Profile ProfileID="ROOM PLANNING AGENT" AppID="{46E6E597-366B-4ED8-B9AA-DDB98540578C}" />
    <UserSettings LocaleID="1033" LanguageID="1033" TimeZone="SE Asia Standard Time" />
    <Instructions>...</Instructions>
  </Agent>
</Agents>
```

Notes:

- `<Agents>` can hold more than one `<Agent>`. A workspace can export several agents at once.
- `<Name>` is the agent user name exactly as it exists in the platform (uppercased in this
  export because that is how the agent user record stores it). This is also the string
  `FindAgentByUserName` and evaluation suites match against.
- `<Version>` and `<Export Date>` are export metadata only. They do not map to any AL slot.
- `<Instructions>` is CDATA-free plain text/markdown, written verbatim.

## 2. Object ID map inside the Agent project template

The template reuses one offset (`{{id+N}}`) across different AL object types, because
Business Central IDs are scoped per object type, not globally:

| Offset | Table | Page | Codeunit | Page ext / enum ext / permission set |
|---|---|---|---|---|
| `{{id+0}}` | `My Agent Setup` | `My Agent Setup` | `MyAgentFactory` | `permissionset "My Agent"`, `enumextension "My Agent Copilot Capability"` |
| `{{id+1}}` | `My Agent KPI` | | `My Agent Install` | `enumextension "My Agent Metadata Provider"`, `pageextension "My Agent Customer Card Ext"` |
| `{{id+2}}` | | `My Agent KPI` | `MyAgentMetadata` | |
| `{{id+3}}` | | `My Agent Role Center` | `My Agent Setup` | |
| `{{id+4}}` | | | `MyAgentTaskExecution` | |
| `{{id+5}}` | | | `My Agent Upgrade` | |
| `{{id+6}}` | | | `My Agent Public API` | |
| `{{id+7}}` | | | `My Agent Public API Impl.` | |
| `{{id+8}}` | | `My Agent Assign Task Dialog` | | |

`app.json` itself reserves the full range with `"idRanges": [{ "from": {{id+0}}, "to": {{id+49}} }]`,
so offsets 9–49 are free for objects the skill or the reader adds later (a bigger permission
set split, extra KPI fields, and so on). `profile "My Agent Profile"` and the
`pagecustomization` object have no numeric ID — profiles and page customizations are named
objects in AL.

`{{id+8}}` is not part of the raw template — the template's own `MyAgentCustomerCardExt.
PageExt.al` only ever declares `{{id+1}}`. `New-AgentAlApp.ps1` authors the dialog page
fresh (see § 8) when `-TaskTriggerPageName` is given, and assigns it `$StartId + 8` directly
in PowerShell rather than through a `{{id+N}}` token, since Stage 7 runs after the
template's own two-pass placeholder substitution has already completed.

## 3. Confirmed template placeholder algorithm

Decompiled from `ms-dynamics-smb.al` extension's `dist/extension.js`
(`TemplateParameters.FillFromConfiguration` and `replaceWithParameters`), not guessed:

```js
publishername = workspaceSetting("al.publisher") ?? "DefaultPublisher"
rootnamespace  = workspaceSetting("al.rootNamespace") ?? publishername.replace(/\s/g, "")
projectname    = basename(targetFolder).replace(/[-\s]/g, "")
guid0..guid9   = ten fresh v4 GUIDs (only guid0 is used by this template, in app.json "id")
```

Substitution runs in two passes over file **content** only, never over file names:

1. Every named placeholder (`{{publishername}}`, `{{projectname}}`, `{{rootnamespace}}`,
   `{{guid0}}`…`{{guid9}}`) is replaced with a plain, non-regex string replace.
2. Then every `{{id+N}}` is replaced with `StartId + N` as a plain integer, where `StartId`
   is the "from" value of the ID range the developer picks when starting the template
   (the template's `altemplate.json` sets `"requiresIdRange": true`).

`altemplate.json` itself is skipped during copy. Every other file, including the template's
own `app.json`, is copied through the same two-pass substitution — `app.json` is a normal
template file here because this template's manifest sets `"generateAppJson": false`, so VS
Code does not run its usual interactive app.json generator for it.

`Convert-AgentExportToAl.ps1` reimplements exactly this algorithm in PowerShell so the
generated app is byte-for-byte what "AL: Go!" would have produced, plus the export-driven
slot fill-in described below.

## 4. Export element → AL slot map

| Export element | AL slot |
|---|---|
| `<Name>` | `AgentNameLbl` in `MyAgentSetup.Codeunit.al` (kept verbatim — see gotcha 6) |
| `<DisplayName>` | `DefaultDisplayNameLbl` |
| `<Initials>` | `AgentInitialsLbl`, `Text[4]` |
| `<Description>` | `AgentSummaryLbl` |
| `<Instructions>` | written verbatim to `.resources/Instructions/InstructionsV1.txt` |
| each `<AccessControl RoleID Scope AppID>` | one insert into `GetDefaultAccessControls` in `MyAgentSetup.Codeunit.al` |
| `<Profile ProfileID AppID>` | `Agent.PopulateDefaultProfile(ProfileID, AppID, TempAllProfile)` in `GetDefaultProfile` |
| `<UserSettings LocaleID LanguageID TimeZone>` | `Agent.UpdateLocalizationSettings(...)` — see gotcha 5 for argument order |

## 5. Rename strategy: `MyAgent` → the real agent

The template never renames itself — VS Code's own tool only substitutes `{{...}}` tokens,
it does not touch the literal word `MyAgent` anywhere. The skill has to do that renaming
itself, over both file content and file names.

Two independent, non-overlapping passes make this safe:

1. Replace the literal substring `MyAgent` (no space, case-sensitive) with a PascalCase
   base name, for example `RoomPlanningAgent`. This substring only ever appears inside the
   template's own unquoted identifiers (`MyAgentFactory`, `MyAgentSetup`, `MyAgentKPI`, and
   so on) and inside file names. It never appears inside a platform type name — `Agent Setup
   Buffer`, `Agent Task`, `IAgentFactory`, `Agent Metadata Provider` all contain `Agent` but
   never the exact substring `MyAgent`, so this pass cannot collide with system objects.
2. Replace the literal substring `My Agent` (exactly one space, case-sensitive) with the
   human-facing display phrase, for example `Room Planning Agent`. This covers the quoted,
   multi-word object names (`"My Agent Setup"`, `"My Agent KPI"`, `"My Agent Customer
   List"`, `"My Agent Public API"`, `"My Agent Profile"`, `"My Agent Role Center"`, the bare
   `"My Agent"` permission set) and every caption/label string that reads `'My Agent ...'`.

Run pass 1 before pass 2. File names get the same pass-1 substring replace
(`MyAgentSetup.Table.al` → `RoomPlanningAgentSetup.Table.al`). None of the template's
folder names (`Setup`, `Metadata`, `Profile`, `KPI`, `TaskExecution`, `Integration`,
`Example`) contain the word "Agent", so this two-pass rename never touches a folder name.

Two folders *are* renamed, but by a separate, unconditional step, not by the `MyAgent`/
`My Agent` passes above:

- The template's top-level source folder, `app`, becomes `src` — matching this repo's own
  AL project convention (see `Room Planning`), and avoiding a confusing
  `<agent app name>/app/Setup/...` path once the project itself is renamed to something
  like "Room Planning Agent App".
- `app/Example` becomes `src/Interaction` — matching Microsoft's own hand-built agent
  samples, which don't ship an "Example" folder at all. See
  `samples/BCAgents/SalesValidationAgent/app/Interaction` for the real-world equivalent:
  a page extension wired to the agent's actual entry page (`Sales Order List`), not a
  placeholder. See gotcha 7 below for what the folder rename does *not* fix.
- `src/Setup/{KPI,Metadata,Permissions,Profile,TaskExecution}` are flattened to top-level
  `src/` siblings of `Setup`. The template nests all five under `Setup/`, but Microsoft's
  own real, currently-shipping agent (`03-bc-system-app/BCApps/src/Apps/W1/SalesOrderAgent/
  app/src`) keeps `Permissions/`, `Profile/`, `RoleCenter/`, and `Validation/` (that app's
  name for `TaskExecution`) as flat top-level folders, and limits `Setup/` to just the setup
  table/page/codeunit. `Metadata` also becomes a top-level folder here (kept separate rather
  than merged into `Setup/`, since agent factory/metadata-provider code is a distinct
  concern from setup configuration). `Profile/` is further split the way this book's own
  `Room Planning/src/Agent/Profile` splits it: page customizations move to
  `Profile/Customizations/`, and the profile object, the role center page, and the KPI
  table/page (since the KPI page is embedded on that role center) move together into
  `Profile/RoleCenter/`. In `-ReuseExistingProfile` mode, `Permissions/` and
  `Profile/Customizations/` simply don't exist in the generated app (those files are
  skipped, not written — they live in the dependency app instead); only `Profile/RoleCenter/`
  survives, holding this app's own KPI table/page. This flatten runs once, after the
  `Example`/`Interaction` rename, and the README's "Project Structure" tree is then
  regenerated wholesale from what is actually on disk rather than patched line-by-line.

## 6. Seven things a naive hand-translation gets wrong

1. **Root is a collection.** `<Agents>` can hold several `<Agent>` nodes, so the parser
   needs `-AgentName` to select one, defaulting to the only agent when there is exactly one.
2. **Access controls can point at a foreign app.** The fixture carries `LOGIN` from the
   System Application (`{63CA2FA4-4F03-4F2B-A480-172FEF340D3F}`, verified against `src/System
   Application/App/app.json`) and `ROOM PLANNING AGENT` from the Room Planning app
   (`{46E6E597-366B-4ED8-B9AA-DDB98540578C}`). The template's `GetDefaultAccessControls`
   hardcodes `CurrentModuleInfo.Id` for every row. The generated code must emit the literal
   App ID captured from each `<AccessControl>` element instead, the same way Microsoft's own
   `Sales Val. Agent Setup` codeunit does with `BaseApplicationAppIdTok`.
3. **The profile can live in a different app than the agent.** `ProfileID="ROOM PLANNING
   AGENT"` carries an `AppID` equal to the Room Planning app, not the new agent app. The
   generated app must either take a dependency on that app and reference its App ID, or the
   profile and page customizations need to move into the new agent app. The skill detects
   this (profile `AppID` differs from the generated app's own ID) and reports it instead of
   guessing — see `Add-AgentDependencyContext` in `New-AgentAlApp.ps1`.
4. **Instructions can embed page-scoped blocks with hardcoded object IDs**, for example
   `{% if page.id == 50212 %}`. The parser extracts every object ID referenced this way into
   the manifest so the reader (or reviewing agent) confirms it still resolves in the target
   app set before publishing.
5. **`UpdateLocalizationSettings` argument order is not the XML attribute order.** The XML
   lists `LocaleID` then `LanguageID`; the AL signature is
   `Agent.UpdateLocalizationSettings(AgentUserSecurityId, LanguageID, LocaleID, TimeZone)`.
   Both values are `1033` in the fixture, so a positional swap stays invisible there and only
   surfaces on the first non-English agent. `New-AgentAlApp.ps1` binds these by name, never
   by XML attribute position.
6. **Preserve the agent user name verbatim.** The template's own `GetAgentUserName()`
   appends `' - ' + CompanyName()` to the base name, the way `Sales Val. Agent Setup` does
   with `AgentNameTok + ' - ' + CompanyName()`. The evaluation suite in this book resolves
   the agent with `FindAgentByUserName('ROOM PLANNING AGENT')` — an exact match. Appending
   the company name would silently break that lookup and the suite that is supposed to prove
   the conversion worked. The generated code drops the suffix and returns `<Name>` exactly.
7. **Renaming the folder to `Interaction` does not make the *content* domain-specific.**
   `-TaskTriggerPageName` mechanically repoints the page extension at a real page and
   substitutes the key/caption field names, but it only ever produces generic wording:
   action `AssignAgentTask`, caption `'Assign Agent Task'`, tooltip `'Assign a task to the
   agent based on this record.'` Compare that with Microsoft's own hand-built
   `SalesValidationAgent`, whose `Interaction` folder has an action named `ValidateWithAgent`,
   caption `'Validate with Agent'`, a tooltip that names the real business action, and
   labels like `TaskTitleLbl: Label 'Validate Sales Orders for %1'` — every string speaks
   the agent's actual job, not "record"/"task" placeholders. After running the skill, the
   reader (or the coding agent driving it) still owes this app one more pass: read the
   agent's `<Description>`/instructions, decide the real business verb ("assign rooms",
   "validate orders", ...), and rewrite the action's identifier, `Caption`, `ToolTip`, and
   every `Lbl`/`Err`/`Msg` label in the task-trigger page extension to use it. This is a
   judgment call the script cannot make; it can only flag that the generic wording is still
   there (see the `-Gap` after "Renamed the 'Example' folder to 'Interaction'").

## 7. Known gaps the skill reports, and does not silently paper over

- Instruction *history* is not part of the export — only the current instruction text.
- The export carries only the profile *name*, never the profile object or the page
  customizations behind it. Those must be exported separately from **Profiles (Roles)**, or
  already exist as AL objects in a dependency app.
- Agent instances cannot be created from install, upgrade, or background sessions — the
  generated `CreateDefaultAgent` pattern only ever runs from a page or an explicit action.
- If the export still lists `LOGIN` while the target permission set already includes a
  broader set such as `D365 BASIC`, the report says so explicitly rather than copying the
  now-redundant `LOGIN` access control forward without comment.

## 8. Task creation: `Agent Task Builder` directly, with a user-reviewed message

The template's own `MyAgentCustomerCardExt.PageExt.al` is not a good model to copy verbatim
for the task-trigger action, for two separate reasons — one about *which API* it calls, one
about *where the message comes from*:

1. **It routes through `...PublicAPI`/`...PublicAPIImpl` for no reason.** That codeunit pair
   exists so *other* AL apps can create tasks for this agent (see § 6 gotcha 7's sibling
   discussion and gotcha 8 in `gotchas.md`) — a same-app page action has no reason to go
   through it. Microsoft's documented pattern for "create tasks from page actions"
   (`learn.microsoft.com/dynamics365/business-central/dev-itpro/ai/ai-agent-sdk-tasks`) calls
   `Agent Task Builder` directly:
   ```al
   AgentTask := AgentTaskBuilder
       .Initialize(AgentUserSecurityId, 'Review Sales Order')
       .AddTaskMessage('Sales Team', 'Please review sales order ' + Rec."No.")
       .Create();
   ```
2. **It builds the message from `Rec` fields and sends it without asking anyone.**
   `MessageText := StrSubstNo(MessageTemplateTxt, Rec.Name, Rec."No.")` runs with no human in
   the loop at all — the user clicks the action and a fixed string goes straight to the
   agent. No real Business Central agent works this way. The Sales Order Agent's own
   "Try it out" → **Create task** page lets a person type the sender and the message body
   by hand (`SOACreateTask.Page.al`), and the real, shipped `SalesValidationAgent` sample
   opens a small `StandardDialog` page first
   (`Interaction/SalesValAgentDatePicker.Page.al`) so the user picks the shipment date
   before `Interaction/SalesValAgentSalesOrders.PageExt.al` builds the task — the date *is*
   the task's input, and it comes from the user, not from the record alone.

`New-AgentAlApp.ps1` reshapes the generated trigger to match both points, whenever
`-TaskTriggerPageName` is given:

- The `OnAction` body now declares `AgentSetup`, `AgentTaskBuilder`, `AgentTask`, and a
  freshly generated `AssignTaskDialog: Page "... Assign Task Dialog"` — no `...PublicAPI`
  variable, no `AgentCU: Codeunit Agent` display-name lookup.
- It still opens the agent lookup first (`AgentSetup.OpenAgentLookup`, unchanged — a real
  gap in the raw template's flow would be skipping this, since it is what lets one agent
  *type* have several running instances).
- It then calls `AssignTaskDialog.SetSuggestedMessage(...)` with the same `StrSubstNo`-built
  text the template used to send unseen, opens it with `.RunModal()`, and only proceeds if
  the user confirms (`Action::OK`). The suggested text is a starting point, not the final
  message — the user can edit or replace it before the dialog closes.
- `AgentTaskBuilder.Initialize(...).AddTaskMessage(From, AssignTaskDialog.GetMessage()).
  Create()` builds the task from what the user actually confirmed.
- The dialog page itself (`...AssignTaskDialog.Page.al`, `PageType = StandardDialog`) is
  modeled directly on `SalesValAgentDatePicker.Page.al`: `InherentEntitlements = X`,
  `InherentPermissions = X`, plain `GetMessage()`/`SetSuggestedMessage(...)` procedures. The
  one difference is `OnQueryClosePage` rejects a blank message — a date picker has no
  equivalent empty state to guard against, but a free-text message does.

This still leaves the generic "record"/"task"/"message" wording in place (step 7's job, not
this one — see § 6 gotcha 7) — only the *shape* of the trigger (which API, and asking the
user first) is fixed by the scaffold itself.

## 9. `-ExistingAppFolder`: adding the agent into an app that already exists

The default flow (§ 5-6) always scaffolds a brand-new standalone app, even in
`-ReuseExistingProfile` mode — the profile/permission set stay behind in another app, but the
*agent* (Metadata, Setup, TaskExecution, Integration, Interaction) still gets its own new app
with its own `app.json`. That is the right shape when the agent is a separate, independently
versioned extension. It is the wrong shape when the profile, role center, page customizations,
and permission set the export references were *already hand-built directly inside the app
that owns the business logic* — this book's own Chapter 6 – Room Planning app is exactly this
case: `src/Agent/Permissions/RoomPlanningAgent.PermissionSet.al` and
`src/Agent/Profile/RoleCenter/RoomPlanningAgent.Profile.al` exist there before this skill ever
runs, hand-written in an earlier chapter section, not exported. Forcing a second, separate
agent app to depend on it just to reuse those objects adds an app, a dependency edge, and a
`DependencyAppIdTok` GUID label for no real benefit.

`-ExistingAppFolder <path>` (instead of `-TargetFolder`) targets this case: it adds the
agent's own objects into the existing app's own `src/` tree, at
`<ExistingAppFolder>/src/<AgentFolderName>/` (default `AgentFolderName` is `Agent`), and its
instructions resource at `<ExistingAppFolder>/.resources/`. The existing app's own `app.json`,
`.gitignore`, and `README.md` are never touched — the skill has no business rewriting a
reader's real app metadata or documentation. Internally, Stage 1-10 of `New-AgentAlApp.ps1`
still run unchanged against a throwaway scratch folder shaped like a brand-new app; a final
stage moves only `src/` and `.resources/` into place and discards the rest. This means
everything in § 2-8 above (the placeholder algorithm, the two-pass rename, the flattening, the
task-trigger rewrite) behaves identically in this mode — only three things differ:

1. **Object IDs are validated against the existing app, not assumed free.** The template (plus
   Stage 7's review dialog) needs nine consecutive numbers (`{{id+0}}` .. `{{id+8}}`). The
   script checks that `-StartId` through `-StartId + 8` (a) fits inside one `idRanges` entry
   already declared in the existing app's `app.json`, and (b) does not collide with any object
   number *of any type* already declared anywhere in that app. Note that this is stricter than
   AL actually requires: object IDs are only required to be unique *per object type*
   (a `table` and a `codeunit` can legally share the same number — the template itself does
   this, reusing one offset for a table, a page, a codeunit, and an enum extension at once; see
   § 2's offset map). The script still treats any existing use of a number, by any type, as a
   conflict. That's a deliberate simplification, not a correctness requirement — the fixed
   offset-to-type map in § 2 changes across modes (fewer types are emitted when
   `-ReuseExistingProfile` skips the profile/permission-set/customization files), so checking
   "would this exact type collide" would mean duplicating that map in the validator and keeping
   both in sync. Checking "is this number used at all" is simpler and can only be too cautious,
   never too permissive — it will occasionally reject a `-StartId` that AL would have accepted,
   but it will never let a real collision through. It errors out with the specific colliding
   numbers or the specific range mismatch rather than guessing a value that would compile today
   and collide the next time someone adds an object by hand. For the Room Planning app
   (`idRanges: [{from: 50800, to: 50849}]`), the longest free run at the time this was written
   was `50828`-`50840` — pass `-StartId 50828`. (After a real run at that offset, `50828`
   ended up shared by a table, a page, a codeunit, and an enum extension, and `50829` by a
   codeunit, an enum extension, a page extension, and a table — exactly as designed, and it
   compiled with 0 errors.)
2. **The root namespace matches the existing app, including "none".** Older AL apps (this
   book's own Chapter 6 - Room Planning included) predate the `namespace` keyword and declare
   none anywhere. The script scans the existing app's `.al` files for the first `namespace X;`
   line; if it finds one, generated files use it; if it finds none, generated files (including
   the freshly authored review dialog) omit the `namespace` line entirely instead of emitting
   an invalid `namespace ;`.
3. **`-ReuseExistingProfile` needs no `-DependencyApp*` at all, and wires more precisely than
   the cross-app case.** The existing app is its own dependency, so `DependencyAppId/Name/
   Publisher` are derived automatically from its own `app.json`. More importantly, the
   generated `GetDefaultProfile`/`GetDefaultAccessControls` reference it via
   `CurrentModuleInfo.Id` (resolved at runtime, exactly like "Fresh" mode resolves its own App
   ID) instead of a hardcoded `DependencyAppIdTok: Label '<guid>'` — there is no reason to
   freeze a literal copy of an app's own ID in a string when the running module already knows
   it.

What does **not** change: `-ReuseExistingProfile` is still an explicit switch you must pass,
even in `-ExistingAppFolder` mode — the skill does not auto-detect that
`src/Agent/Permissions`/`Profile` already exist and silently skip generating stand-ins. If you
omit `-ReuseExistingProfile` against an existing app that already has hand-built
profile/permission-set files at the target location, the scaffold still writes its own fresh
stand-ins into `src/<AgentFolderName>/Permissions` and `src/<AgentFolderName>/Profile`, which
almost certainly is not what you want — pass the switch.
