# Chapter 7 – Using the standard Business Central MCP server (Book Code)

This folder contains the code for **Chapter 7: Using the Standard Business Central MCP Server**. It publishes the BC Tech Summit program to an attendee assistant through the Business Central MCP server, on top of the data model the book has already built:

- **Chapter 3 – Common**: the event is a project (`Job`) and its sessions live in `Event Session` (Draft → Scheduled by the Build Conference Agenda copilot).
- **Chapter 6 – Room Planning**: rooms, `Room Code` on the session with capacity and double-booking checks, and `Session Attendee Res. Entry`, the reservations "made in the conference app". The attendee assistant is that app: its personal agenda is this table, so every agenda entry raises **Reserved Attendees**, the demand signal of the Room Planning Agent.

Copilot Studio is the example MCP client; the tools work from any MCP-compliant client.

| Folder | What it is | ID range |
| --- | --- | --- |
| `Attendee Assistant/` | AL app: attendee-facing API pages, agenda rules, change log, ratings, setup, permission sets, demo helpers | 98200–98249 |
| `Attendee Assistant/src/MCP/` | The `CronusEventsAttendee` MCP server configuration | |
| `website/` | Static logistics page used as the agent's knowledge source | |

## Design in one picture

```
Attendee (website chat)
        │
        ▼
Copilot Studio agent "Tech Summit Assistant"
   ├── Knowledge: BC Tech Summit website (venue, transport, Wi-Fi, catering, badges, code of conduct)
   └── Tool: Dynamics 365 Business Central MCP Server  ──  configuration CronusEventsAttendee
              │
              ▼
   Business Central MCP server (https://mcp.businesscentral.dynamics.com)
              │  tools generated from the API pages of the Chapter 7 app
              ▼
   attendeeSessions (R) · agendaEntries (R/C/D + rateSession) · sessionChanges (R)
              │
              ▼
   Event Session (Ch3) + Room / Room Code / Session Attendee Res. Entry (Ch6) + CE Session Change (Ch7)
```

## Objects

| ID | Type | Name | Role |
| --- | --- | --- | --- |
| 98201 | Enum | CE Session Change Type | Room / Schedule / Speaker / Cancelled / Other |
| 98202 | Table extension | CE Event Session Ext | `Room Name`, `Room Floor` (FlowFields), `Last Changed At`, `Average Rating`, `Ratings Count` on `Event Session` |
| 98203 | Table extension | CE Attendee Res. Entry Ext | Session views (FlowFields), `Rating`, `Rated At` on `Session Attendee Res. Entry` |
| 98204 | Table | CE Session Change | Change log written automatically |
| 98205 | Page (API) | Attendee Sessions | `attendeeSessions`, read only |
| 98206 | Codeunit | CE Attendee Agenda Mgt | Attendee rules (draft, cancelled, completed, duplicate, overlap, room full) and ratings |
| 98207 | Page (API) | Attendee Agenda | `agendaEntries`, read/create/delete + bound action `rateSession` |
| 98208 | Page (API) | Session Changes | `sessionChanges`, read only |
| 98209 | Codeunit | CE Session Change Log | `OnBeforeModifyEvent` subscriber on `Event Session`; compares with the stored record |
| 98211 | Page | CE Session Changes | Organizer list, editable `Note` |
| 98212 | Permission set | CE Attendee MCP | For the identity behind the MCP connection |
| 98213 | Codeunit | CE Attendee Demo Data | `PrepareDemoEvent`, `SimulateChanges`, `ResetProgramChanges` |
| 98214 | Table | CE Attendee Setup | The event project the assistant serves |
| 98215 | Page | CE Attendee Setup | Setup card with the demo actions |
| 98216 | Permission set | CE Attendee Admin | For the organizers |

The attendee rules run in `OnInsertRecord` of the agenda API page, not in a table event: the Chapter 6 table also receives bulk reservations (its demo data reserves parallel sessions for the same generated emails), and those must not be blocked by attendee rules.

## Build order

1. Publish **Chapter 3 – Common** and **Chapter 6 – Room Planning** (see their READMEs). The app declares both as dependencies because it uses objects from each.
2. On **Event Demo Data** (Chapter 6), run **Set up venue and schedule**. Optionally assign rooms with the Room Planning Agent.
3. Publish **Chapter 7 – Attendee Assistant**.
4. Assign **CE Attendee MCP** to the user behind the MCP connection, and **CE Attendee Admin** plus **Room Planning Admin** to the organizers.
5. Open **Attendee Assistant Setup** and run **Prepare Demo Event** (selects TECH2027 and assigns a room to every session that has none).
6. Create the MCP server configuration `CronusEventsAttendee` as described in `Attendee Assistant/src/MCP/CronusEventsAttendee.mcpconfig.md`. Optionally create `CronusEventsDiscover`.
7. Publish `website/index.html` on a public host (GitHub Pages is enough), add it to the agent as **Public website** knowledge, and paste the iframe from **Channels > Web app > Embed code** into the page (see `website/README.md`).

To test **rateSession**, set the work date of the connection user to 11 June 2027 in the afternoon (a session can be rated once it has started, measured against the work date, as Chapter 6 does).

## Testing the tools before building the agent

- "Which sessions about agents are there after lunch?" → `List_AttendeeSessions_PAG98205`; the model chooses the arguments (in our runs, a filter on `title`, or no filter at all) and applies the time itself
- "Add T27-AI2 to the agenda of ana@example.com" → `Create_AgendaEntry_PAG98207`
- "Add T27-OPS1 to the same agenda" → rejected: it overlaps with "Building Custom Agents" at 10:30
- "Create a new session" → not possible: no create tool exists for sessions

Then run **Simulate Program Changes** (and **Reset Program Changes** to repeat the scenario) and ask "Has anything changed for me today?" → `List_SessionChanges_PAG98208` shows the move of T27-DEV2 to Auditorium B, with the organizers' note, and the cancellation of the keynote.

## Identity and security notes

- The website agent runs with **No authentication** and its MCP tool with **Maker-provided credentials** (formerly *Agent author authentication*): tool calls run under the identity of the Copilot Studio connection. The attendee is identified by email inside the data; the permission set of that identity is the real security boundary.
- Keep **Discover Read-Only Objects** off and always select the configuration in the Copilot Studio tool.
- Non-Microsoft MCP clients need an application registered in Microsoft Entra ID; Visual Studio Code and Copilot Studio use a preregistered one.

## Requirements

- Business Central online 29.0 or later (required by Chapter 6) with the MCP server available.
- Chapter 3 – Common and Chapter 6 – Room Planning published.
- Copilot Studio with Copilot Credits capacity, or any other MCP client.

## Build check

Version 1.2.0.3 compiles without errors or CodeCop/UICop warnings (except AA0245 on the `rating` parameter of `rateSession`, kept because the parameter name is the JSON key of the bound action) against Business Central 29.0 with Chapter 3 – Common and Chapter 6 – Room Planning, and was tested end to end with Copilot Studio.
