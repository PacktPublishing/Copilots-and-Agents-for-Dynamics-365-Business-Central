# Installing this skill

This skill uses the [Agent Skills](https://docs.cursor.com) format: a `SKILL.md` with YAML
frontmatter (`name`, `description`) plus reference docs and scripts next to it. That format
works unchanged in Cursor and Claude Code, and the scripts themselves are plain PowerShell 7
so any coding agent (or a human) can run them directly.

## Option 1 — Cursor

Copy (or symlink) the whole `bc-agent-export-to-al/` folder into `.cursor/skills/` at the
root of your workspace:

```bash
cp -R bc-agent-export-to-al "/path/to/your/workspace/.cursor/skills/bc-agent-export-to-al"
```

Cursor discovers `SKILL.md` files under `.cursor/skills/**` automatically.

## Option 2 — Claude Code

Copy the same folder into `.claude/skills/`:

```bash
cp -R bc-agent-export-to-al "/path/to/your/workspace/.claude/skills/bc-agent-export-to-al"
```

## Option 3 — VS Code Copilot / any agent that reads repo instructions

There is no dedicated skills folder convention yet. Reference the skill from
`AGENTS.md` or `.github/copilot-instructions.md` instead:

```markdown
## Converting a designed agent to AL

When asked to convert an exported Business Central agent XML into an AL app, read and
follow `path/to/bc-agent-export-to-al/SKILL.md` before writing any code.
```

## Running it standalone (no coding agent at all)

The scripts don't require an agent host. A developer can run the pipeline directly from a
terminal:

```bash
pwsh -NoProfile -File "bc-agent-export-to-al/scripts/Convert-AgentExportToAl.ps1" \
  -ExportXml "./AGENT-agent.xml" \
  -TargetFolder "./Agent App" \
  -StartId 50900 \
  -Publisher "Packt"
```

Requires PowerShell 7.0 or later (`pwsh`). Windows PowerShell 5.1 is not supported — the
scripts use `$IsWindows`/`$IsMacOS`/`$IsLinux`, which only exist in PowerShell 7+. Install
PowerShell 7 from <https://aka.ms/powershell> if `pwsh -v` fails or reports an older version.

No other dependency is required: XML parsing uses the built-in `[xml]` accelerator, the
manifest is plain `ConvertTo-Json`/`ConvertFrom-Json`, and the VSIX download/unzip fallback
uses `Invoke-WebRequest` and `[System.IO.Compression.ZipFile]` from the .NET base class
library that ships with PowerShell 7.
