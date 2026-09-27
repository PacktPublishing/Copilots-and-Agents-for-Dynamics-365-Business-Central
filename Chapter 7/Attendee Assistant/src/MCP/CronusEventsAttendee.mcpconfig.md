# MCP server configuration: CronusEventsAttendee

Create this configuration in Business Central on the **Model Context Protocol (MCP) Server Configurations** page (list page 8350, card page 8351), or import `CronusEventsAttendee.json` (exported from BC 29.0 with **Export** on the list page, kept next to this file) with **Import** on the same page. Active and Default are not exported: the imported configuration arrives inactive.

## General

| Field | Value | Why |
| --- | --- | --- |
| Name | `CronusEventsAttendee` | Appears in Copilot Studio when the MCP server tool is configured |
| Default | Off | Keep the environment default (if any) separate from the attendee configuration; always select the configuration explicitly in the client |
| Description | Attendee-facing tools for the Tech Summit Assistant. | |
| Active | On | |
| Dynamic Tool Mode | Off | Six tools fit comfortably under the client limit; explicit tools can be reviewed one by one in the agent |
| Discover Read-Only Objects (Dynamic Tool Mode > Configure) | Off | Otherwise the agent gets read access to every API page, including standard APIs such as customers, contacts and employees |
| Unblock Edit Tools | On | Needed for the create/delete/bound action permissions on the agenda |

## Available APIs

Use **Add APIs by API Group** (the dialog is titled *Add Tools by API Group*) and pick the `attendee` group of the `cronusEvents` publisher to add the three pages in one step, then adjust the permissions. **Validate** checks the configuration before you save it.

| Object ID | Object name | Allow Read | Allow Create | Allow Modify | Allow Delete | Allow Bound Actions |
| --- | --- | --- | --- | --- | --- | --- |
| 98205 | Attendee Sessions | Yes | No | No | No | No |
| 98207 | Attendee Agenda | Yes | Yes | No | Yes | Yes |
| 98208 | Session Changes | Yes | No | No | No | No |

## Tools generated (Dynamic Tool Mode off)

| Tool | Used for |
| --- | --- |
| `List_AttendeeSessions_PAG98205` | Program browsing, building the day, speaker lookup (filter on `speakerName`) |
| `List_AgendaEntries_PAG98207` | "What is in my agenda?" (filtered by `attendeeEmail`) |
| `Create_AgendaEntry_PAG98207` | "Add this session to my agenda" |
| `Delete_AgendaEntry_PAG98207` | "Remove it from my agenda" |
| `RateSession_AgendaEntries_PAG98207` | "Rate the session I just attended" |
| `List_SessionChanges_PAG98208` | "Has anything changed?" (filtered by `changedAt` and the agenda's session codes) |

## Not published on purpose

- Standard APIs (customers, contacts, vendors, employees, projects): organizer and back-office data.
- Draft session proposals (Chapter 3): `attendeeSessions` filters them out, so only the published program reaches the agent.
- Attendee figures and room capacity (Chapter 6): planning data for the organizers and the Room Planning Agent.
- Ratings per session: stored in Business Central for the organizers, not exposed to attendees.

## Connection string (Advanced > Connection String, on the list page)

```json
"businesscentral": {
   "url": "https://mcp.businesscentral.dynamics.com",
   "type": "http",
   "headers": {
      "TenantId": "<tenant id>",
      "EnvironmentName": "Sandbox",
      "Company": "Cronus Events",
      "ConfigurationName": "CronusEventsAttendee"
   }
}
```

## Companion configuration for the demo: `CronusEventsDiscover`

Used once in the chapter to show the zero-setup mode: **Dynamic Tool Mode** on, **Discover Read-Only Objects** on, **Unblock Edit Tools** off, no tools added. The agent sees only `bc_actions_search`, `bc_actions_describe` and `bc_actions_invoke` and can read every API page in the environment. Never use it for the published attendee agent.

## Non-Microsoft hosts (Claude Code example)

Requires an app registered in Microsoft Entra ID (multi-tenant, redirect URI `http://localhost:<port>/callback`, delegated permission **Dynamics 365 Business Central / Financials.ReadWrite.All**, admin consent). The client ID can be recorded in Business Central under **Advanced > Entra Applications** on the configurations page.

```json
{
   "mcpServers": {
      "businesscentral": {
         "type": "http",
         "url": "https://mcp.businesscentral.dynamics.com",
         "headers": {
            "TenantId": "<tenant id>",
            "EnvironmentName": "Sandbox",
            "Company": "Cronus Events",
            "ConfigurationName": "CronusEventsAttendee"
         },
         "oauth": {
            "clientId": "<application (client) id>",
            "callbackPort": 33418
         }
      }
   }
}
```
