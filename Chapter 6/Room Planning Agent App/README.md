# Chapter 6 – Room Planning Agent

Standalone AL app for the **Room Planning Agent**, converted from the designed-agent export. It depends on **Chapter 6 - Room Planning** for the profile, page customizations, and permission set the agent runs with.

The agent estimates attendance and assigns rooms to conference sessions. Users start a task from **Project Card** with **Assign Rooms with Agent**.

## Dependencies

- Chapter 3 - Common
- Chapter 6 - Room Planning

## Build order

1. Publish **Chapter 3 - Common**.
2. Publish **Chapter 6 - Room Planning**.
3. Publish this app.
4. Open **Copilot & agent capabilities**, enable **Room Planning Agent**, then create and activate an instance.

The agent user name is `ROOM PLANNING AGENT` (no company suffix), which is what the Chapter 6 evaluation suite looks up.

## Project Structure

```
Room Planning Agent App/
├── .resources/
│   └── Instructions/
│       └── InstructionsV1.txt                    # Instructions from the designed-agent export
├── src/
│   ├── Integration/
│   │   ├── RoomPlanningAgentCopilotCapability.EnumExt.al
│   │   ├── RoomPlanningAgentInstall.Codeunit.al
│   │   └── RoomPlanningAgentUpgrade.Codeunit.al
│   ├── Interaction/
│   │   ├── RoomPlanningAgentAssignTaskDialog.Page.al
│   │   └── RoomPlanningAgentJobCardExt.PageExt.al
│   ├── Metadata/
│   │   ├── RoomPlanningAgentFactory.Codeunit.al
│   │   ├── RoomPlanningAgentMetadata.Codeunit.al
│   │   └── RoomPlanningAgentMetadataProvider.EnumExt.al
│   ├── Profile/
│   │   └── RoleCenter/
│   │       ├── RoomPlanningAgentKPI.Page.al
│   │       ├── RoomPlanningAgentKPI.Table.al
│   │       └── RoomPlanningAgentKPILogging.Codeunit.al
│   ├── Setup/
│   │   ├── RoomPlanningAgentSetup.Codeunit.al
│   │   ├── RoomPlanningAgentSetup.Page.al
│   │   └── RoomPlanningAgentSetup.Table.al
│   └── TaskExecution/
│       └── RoomPlanningAgentTaskExecution.Codeunit.al
├── app.json
└── README.md
```

## How a task is created

`RoomPlanningAgentJobCardExt.PageExt.al` adds **Assign Rooms with Agent** on **Job Card**. The action opens the agent lookup, then `RPA Assign Task Dialog` so the user can edit the message. Confirmed messages are sent with `Agent Task Builder` and `SetRequiresReview(false)` so the same text is not approved twice.

## KPI

**Sessions Assigned** counts Event Session rows where this agent set **Room Code** from blank to a value. `RoomPlanningAgentKPILogging.Codeunit.al` subscribes to `Event Session.OnAfterModifyEvent` and increments the KPI only in a Room Planning Agent session.
