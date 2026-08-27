# Chapter 4 – Build Conference Agenda Tests

AI Test Toolkit test app for the **Build Conference Agenda** copilot (Chapter 3).

## Dependencies

- Chapter 3 - Common  
- Chapter 3 - Build Conference Agenda  
- AI Test Toolkit (Microsoft)

## Structure

- **test/Setup/BuildConferenceAgendaTestInstall.Codeunit.al** (50760) – Loads datasets and test suites from `.resources`.
- **test/BuildConferenceAgendaAITests.Codeunit.al** (50761) – Data-driven tests for tool-calling (GetSessions, GetEventInfo, SaveAgenda).
- **.resources/Datasets/** – JSONL with `question` and `test_setup` (e.g. `project_code`).
- **.resources/TestSuites/** – XML suite definition (e.g. `BuildConferenceAgenda-Tests.xml`).

## Build order

1. Publish Chapter 3 - Common and Chapter 3 - Build Conference Agenda.  
2. Publish this test app.  
3. Run the suite from the AI Test Tool in Business Central.
