# Chapter 6 – Custom Agents (Book Code)

This folder contains the AL apps for **Chapter 6**. Three apps are planned; this drop ships the stage app only.

| App | Folder | ID range | Status |
|-----|--------|----------|--------|
| **Chapter 6 - Room Planning** | `Room Planning/` | 50800–50849 | Implemented |
| **Chapter 6 - Room Planning Agent** | `Room Planning Agent/` | 50850–50869 | Not in this drop |
| **Chapter 6 - Room Planning Agent Tests** | `Room Planning Agent Tests/` | 50870–50899 | Not in this drop |

**Room Planning** is a human product: rooms, reservations, session attendee figures, the **Assign Rooms** wizard, cues, and Contoso demo data. It has no agent objects and no preview dependency. Publish **Chapter 3 - Common** first, then this app.

## Build order

1. Publish **Chapter 3 - Common**.
2. Publish **Chapter 6 - Room Planning**.
3. In Business Central, search for **Room Planning Demo Data** and run **Set up venue and schedule**. Set the work date to a day before 11 June 2027 (for example 1 May 2027).
4. Open **Event Sessions** (filter **Project Code** = TECH2027). Fill **Estimated Attendees**, then **Assign Rooms**. Changes are not saved until **Finish**.
