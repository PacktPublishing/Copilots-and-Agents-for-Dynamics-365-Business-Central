# Chapter03 Build Conference Agenda

Fourth copilot demo for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. Build the conference agenda using **tool calling** (function calling) with tools that read BC data and write the schedule.

## What this copilot does

- **Tool calling:** Tools that read existing Business Central data and run AL logic.
- **GetSessions** — read from the custom session table (data from the Import Session Proposals copilot).
- **GetEventSchedule** — read event constraints (start/end time, lunch, breaks, tracks).
- **SaveAgenda** — write the schedule to BC (sessionId, startTime, endTime, track/room).
- **GetCurrentAgenda** (optional) — read current agenda for intent-based flow.
- User says e.g. "Build the agenda" → model calls GetSessions + GetEventSchedule → reasons over constraints → calls SaveAgenda.

## How to run

1. Build and publish **Chapter03 Common** (session and agenda tables).
2. Publish **Chapter03 Import Session Proposals** so session data exists (or seed data manually).
3. Open this folder in VS Code and publish to BC 27.x.
4. Run the copilot and ask to build or show the agenda.

## Requirements

- Business Central 27.x.
- Chapter03 Common app (dependency).
- Azure OpenAI configured; tool calling supported (27.2+).
