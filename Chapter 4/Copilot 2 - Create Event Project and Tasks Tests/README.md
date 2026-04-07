# Chapter 4 – Create Event Project and Tasks Tests

AI Test Toolkit test app for the **Create Event Project and Tasks** copilot (Chapter 3).

## Dependencies

- Chapter 3 - Common  
- Chapter 3 - Create Event Project and Tasks  
- AI Test Toolkit (Microsoft)

## Structure

- **test/Setup/CreateEventProjTestInstall.Codeunit.al** (50720) – Loads datasets and test suites from `.resources`.
- **test/CreateEventProjectAITests.Codeunit.al** (50721) – Data-driven tests for structured JSON output.
- **.resources/Datasets/** – JSONL input (e.g. `create_event_project_accuracy.jsonl`).
- **.resources/TestSuites/** – XML suite definition (e.g. `CreateEventProject-Tests.xml`).

## Build order

1. Publish Chapter 3 - Common and Chapter 3 - Create Event Project and Tasks.  
2. Publish this test app.  
3. Run the suite from the AI Test Tool in Business Central.
