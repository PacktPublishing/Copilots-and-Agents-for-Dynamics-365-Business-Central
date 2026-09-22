# Chapter 6 – Custom Agents (Book Code)

This folder contains the AL apps for **Chapter 6**, plus the skill that turns a designed-agent export into an AL app.

| App | Folder | ID range | Status |
|-----|--------|----------|--------|
| **Chapter 6 - Room Planning** | `Room Planning/` | 50800–50849 | Implemented |
| **Chapter 6 - Room Planning Agent** | `Room Planning Agent App/` | 50850–50869 | Implemented |
| **Chapter 6 - Room Planning Agent Tests** | `Room Planning Agent Tests/` | 50870–50899 | Implemented |

**Room Planning** is the human product: rooms, reservations, session attendee figures, cues, and Contoso demo data. It also owns the **Room Planning Agent** profile, the page customizations that profile uses, and the **Room Planning - Agent** permission set. A human can set **Room Code** on Event Sessions without installing the agent app.

**Room Planning Agent** is a standalone app produced by the **bc-designed-agent-to-al** skill from the designed-agent export. It depends on Room Planning for that profile, those page customizations, and the permission set. It owns Copilot capability registration, the **Assign Rooms with Agent** action on **Job Card**, the agent instructions, and the **Sessions Assigned** KPI. The agent user name is `ROOM PLANNING AGENT`.

**Room Planning Agent Tests** runs the **RPA-AGENT** evaluation suite against that agent instance. The test app does not take a dependency on the agent app. Publish and activate the agent first so the test can find the user `ROOM PLANNING AGENT`.

## Build order

1. Publish **Chapter 3 - Common**.
2. Publish **Chapter 6 - Room Planning**.
3. In Business Central, search for **Room Planning Demo Data** and run **Set up venue and schedule**. Set the work date to a day before 11 June 2027 (for example 1 May 2027).
4. Publish **Chapter 6 - Room Planning Agent**. On **Copilot & agent capabilities**, enable **Room Planning Agent** and create an instance. Leave the user name as `ROOM PLANNING AGENT`.
5. Publish **Chapter 6 - Room Planning Agent Tests** when you want to run the evaluation suite.
6. Open **AI Eval Suites**, open **RPA-AGENT**, set **Room Planning Agent** as the agent under test, and start the suite.

Suite setup creates `HALL-A` (capacity 400) and `LAB-01` (capacity 30) once. Business Central skips that step when **Suite Setup Done** is already set on the suite. If those rooms are missing, open **AI Eval Suites**, run **Reset Suite Setup** on **RPA-AGENT**, then start the suite again.

## Skills

| Skill | Folder | What it does |
|-------|--------|----------------|
| **bc-designed-agent-to-al** | `SKILLS/bc-designed-agent-to-al/` | Converts an exported designed-agent XML into an AL agent app from the official Agent project template. |

`SKILL.md` is the workflow. `INSTALL.md` explains how to copy the folder into `.cursor/skills/` or `.claude/skills/`. The scripts need PowerShell 7.

The entry point is `scripts/Convert-AgentExportToAl.ps1`. Pass `-TargetFolder` for a new app, and `-DependencyAppId`, `-DependencyAppName`, `-DependencyAppPublisher`, and `-DependencyAppVersion` when the profile, page customizations, and permission set already live in another app. That is how **Room Planning Agent App** was generated: a new app that depends on **Chapter 6 - Room Planning**. Pass `-ExistingAppFolder` instead when those objects should stay inside an app you already have.

## Requirements

- Business Central 29.x (platform and application 29.0.0.0).
- **Chapter 3 - Common** published to the same environment.
