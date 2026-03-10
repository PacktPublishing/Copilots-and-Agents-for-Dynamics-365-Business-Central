# Chapter 3 – Copilot 4: Build Conference Agenda

Fourth copilot demo for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**.

This copilot introduces **tool calling** (function calling): the AI model calls AL codeunits to read existing Business Central data and write the proposed schedule — all from within a single `GenerateChatCompletion` call using the `Automatic` tool invoke preference.

## What this copilot teaches

- **AOAI Function interface** — each tool is an AL codeunit implementing `GetName`, `GetPrompt`, and `Execute`.
- **Multi-round tool calling** — the model reads data (round 1), reasons over it, then writes the schedule (round 2). The Copilot Toolkit handles this automatically via `SetToolInvokePreference(Automatic)`.
- **Intent detection** — the same copilot serves two intents: "build the agenda" (calls GetSessions + GetEventInfo + SaveAgenda) vs. "show the current agenda" (calls GetCurrentAgenda). The model decides which tools to call based on the natural language input.
- **Human-in-the-loop** — `SaveAgenda` fills a temporary `Agenda Proposal` table for the user to review. The actual `Event Session` records are only updated when the user clicks **Apply** (OK).
- **Prompt Guides** — ready-made `area(PromptGuide)` templates grouped by intent (Build / Review / Adjust) that prefill the free-text input.

## Tools

| Tool | ID | Intent | What it does |
|---|---|---|---|
| GetSessions | 50605 | Build | Returns all Draft Event Sessions for the project |
| GetEventInfo | 50606 | Build | Returns event dates and daily time constraints from the Job record |
| SaveAgenda | 50607 | Build | Parses the model's JSON schedule and inserts rows into the temp Agenda Proposal table |
| GetCurrentAgenda | 50608 | Review | Returns all Scheduled Event Sessions for the project |

## Objects

| ID | Type | Name |
|---|---|---|
| 50600 | Enum extension | Build Agenda Cap. (extends Copilot Capability) |
| 50601 | Codeunit | Build Agenda Install |
| 50603 | Table (temp) | Agenda Proposal |
| 50605 | Codeunit | Get Sessions |
| 50606 | Codeunit | Get Event Info |
| 50607 | Codeunit | Save Agenda |
| 50608 | Codeunit | Get Current Agenda |
| 50609 | Codeunit | Build Agenda Impl |
| 50610 | Page | Build Conference Agenda (PromptDialog) |
| 50611 | Page | Agenda Proposal Subpart (ListPart) |
| 50612 | Page extension | Build Agenda Job List Ext |

## Flow

1. Open the **Job List**, select an event project, choose **Build Conference Agenda** in the Prompting action group.
2. The **Build Conference Agenda** PromptDialog opens. Type a request or pick a Prompt Guide template.
3. Click **Build Agenda** → `Generate` is called → Azure OpenAI receives the system message and the four registered tools.
4. **Round 1 (automatic):** The model calls `GetSessions` and `GetEventInfo` → Toolkit executes both → appends results to the chat history → calls `GenerateChatCompletion` again.
5. **Round 2 (automatic):** The model reasons over sessions and constraints, then calls `SaveAgenda` with a JSON array of scheduled sessions → Toolkit executes `SaveAgenda` → sessions are inserted into the shared temporary `Agenda Proposal` table → appends the confirmation → calls `GenerateChatCompletion` again.
6. **Round 3:** The model returns a text summary (no more tool calls) — for example "Scheduled 12 sessions across 2 days and 3 tracks."
7. The proposed schedule is displayed in the **Agenda Proposal** list (Session Code, Description, Date, Track, Start/End Time).
8. Click **Apply** (OK) → `Apply` updates each matching `Event Session` record (sets Date, Track No., Start Time, End Time, Status = Scheduled).

## How to run

1. Build and publish **Chapter 3 – Common** (provides `Event Session`, `Event Session Status`, and `Event Copilot Setup`).
2. Optionally publish **Copilot 3 – Import Session Proposals from Excel** so session data exists in Draft status, or seed the `Event Session` table manually.
3. Open this folder in VS Code and publish to BC 27.x.
4. Open **Event Copilot Setup** and configure the Azure OpenAI endpoint, deployment, and secret key.
5. Open the **Job List**, select an event project that has start and end dates, and choose **Build Conference Agenda**.

## Requirements

- Business Central 27.2 or later (tool calling support in the Copilot Toolkit).
- **Chapter 3 – Common** app (dependency: provides Event Session, Event Session Status, Event Copilot Setup).
- Azure OpenAI resource with a model that supports function calling (e.g., GPT-4o).
