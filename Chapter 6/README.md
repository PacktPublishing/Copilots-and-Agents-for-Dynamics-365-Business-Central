# Chapter 6 – Custom Agents (Book Code)

This folder contains the AL apps for **Chapter 6**.

| App | Folder | ID range | Status |
|-----|--------|----------|--------|
| **Chapter 6 - Room Planning** | `Room Planning/` | 50800–50849 | Implemented |
| **Chapter 6 - Room Planning Agent** | `Room Planning Agent App/` | 50850–50869 | Implemented |
| **Chapter 6 - Room Planning Agent Tests** | `Room Planning Agent Tests/` | 50870–50899 | Implemented |

**Room Planning** is a human product: rooms, reservations, session attendee figures, cues, and Contoso demo data. Humans can assign rooms without installing the agent app.

**Room Planning Agent** is the AL agent converted from the designed-agent export. It depends on Room Planning for the profile, page customizations, and permission set.

## Build order

1. Publish **Chapter 3 - Common**.
2. Publish **Chapter 6 - Room Planning**.
3. In Business Central, search for **Room Planning Demo Data** and run **Set up venue and schedule**. Set the work date to a day before 11 June 2027 (for example 1 May 2027).
4. Publish **Chapter 6 - Room Planning Agent**, enable it on **Copilot & agent capabilities**, and create an instance.
5. Publish **Chapter 6 - Room Planning Agent Tests** when you want to run the evaluation suite.
