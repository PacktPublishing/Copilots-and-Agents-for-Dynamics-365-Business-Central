# Chapter 6 - Room Planning

Stage app for **Chapter 6: Custom Agents**. Rooms, attendee figures, and editable **Room Code** on Event Sessions live here. There is no Copilot capability registration and no agent profile — a human can assign rooms without the Room Planning Agent app.

## Contents

- **Room** (table 50800, **Room List** 50811, **Room Card** 50814): venue rooms with capacity, floor, recording, and blocked.
- **Session Attendee Reservation Entry** (table 50802, **Session Attendee Res. Entries** 50812, FactBox 50815): append-only log of conference-app reservations. Counted as **Reserved Attendees** on the session. Past conferences carry reservations too, so a show-up ratio can be read off history.
- **Event Session Room Ext** (table extension 50808): **Room Code**, **Estimated Attendees**, **Reserved Attendees** (FlowField), **Actual Attendees**. Room Code validates capacity, blocked rooms, and double-booking.
- **Event Sessions Room Ext** (page extension 50817): estimates, reserved, room, and actuals on the list; **Find Similar** for semantic lookalikes; future scheduled rows turn yellow when reserved demand beats the estimate, and red when reserved attendees exceed the assigned room's capacity.
- **Room Assignment Check** (codeunit 50821): capacity, blocked, and double-booking. Called from **Room Code** OnValidate.
- **Find Similar Sessions** (codeunit 50823, buffer 50804, page **Similar Event Sessions** 50819): ranks other sessions by meaning of name, description, and speakers.
- **Room Planning Cue** (table 50807, page 50816): sessions without a room, and future sessions over capacity. On **Event Sessions** it follows the **Project Code** of the selected row.
- **Room Planning Role Center** (page 50810) and **Room Planning Agent** profile: empty role center for the agent — **Projects** (Job List) and the Room Planning cue.
- **Event Demo Data** (codeunit 50827, page 50818): phased generators — venue and schedule, reservations, cancel a session, fill day-one actuals. Never on install.
- **Room Planning - Admin** (permission set 50841).

## Build order

1. Build and publish **Chapter 3 - Common** first.
2. Open this folder in VS Code, restore symbols, build, and publish.
3. Search for **Event Demo Data** → **Set up venue and schedule**.
4. Set the work date to a day before **11 June 2027** (for example 1 May 2027).
5. Open **Event Sessions** (filter **Project Code** = TECH2027). Fill **Estimated Attendees**, then set **Room Code** on each session.

## Requirements

- Business Central 29.x (platform and application 29.0.0.0).
- **Chapter 3 - Common** app (dependency; provides Event Session).
