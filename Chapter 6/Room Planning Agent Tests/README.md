# Chapter 6 – Room Planning Agent Tests

Agent evaluation test app for the **Room Planning Agent** (Chapter 6). Uses `TestType = AITest` and `Library - Agent` to run the designed agent turn by turn, and validates the resulting **Event Session** records instead of the text the agent writes in the task timeline.

## Dependencies

- Chapter 3 - Common
- Chapter 6 - Room Planning
- AI Development Toolkit - Evaluation (Microsoft)

## Structure

- **test/Setup/RoomPlanningAgentTestsInstall.Codeunit.al** (50871) – Loads the dataset, suite setup, and suite configuration from `.resources` on install.
- **test/RoomPlanningAgentTests.Codeunit.al** (50870) – The agent test. `AssignRoomsFromDataset` drives a `repeat ... until` turn loop with `Library - Agent`, then validates the room plan with `ValidateRoomPlan`.
- **.resources/datasets/RPA-AGENT.yaml** – Two-turn dataset: turn 1 starts the task and expects a **Review** intervention; turn 2 answers the review and checks the outcome.
- **.resources/suite_setup/RPA-SETUP.yaml** – Creates the two rooms the suite shares (`HALL-A`, capacity 400; `LAB-01`, capacity 30).
- **.resources/configuration/RPA-AGENT.xml** – AI Eval Suite definition. `TestType="Agent"` and `TestRunnerId="130451"` (`Test Runner - Isol. Disabled`) are required for agent tests.

## What the dataset checks

The turn setup creates one project with three approved (`Scheduled`) sessions and resets their reservations:

- `RPA-KEY` and `RPA-LAB` run at the same time. `RPA-KEY` has 380 reserved attendees (only `HALL-A` fits), `RPA-LAB` has 25 (fits `LAB-01`, and technically `HALL-A` too — but `HALL-A` is taken at that time).
- `RPA-DEV` runs later with no reservations. The agent must estimate its attendance from similar completed sessions before assigning a room.

After the agent finishes, the test checks these outcomes directly on `Event Session`:

- Every scheduled session has an estimate (`all_scheduled_sessions_have_estimate`).
- Every session without reservations has an estimate (`sessions_without_reservations_have_estimate`).
- Every scheduled session has a room (`all_scheduled_sessions_have_room`).
- No room is smaller than its demand (`no_room_over_capacity`).
- No room is booked twice for an overlapping time slot (`no_double_booking`).

## Build order

1. Publish Chapter 3 - Common and Chapter 6 - Room Planning.
2. Design and activate the **Room Planning Agent** (no-code, in the design experience). No AL agent object is required to evaluate it.
3. Publish this test app.
4. Open **AI Eval Suites**, open **RPA-AGENT**, set the **Room Planning Agent** as the agent under test, and start the suite.
