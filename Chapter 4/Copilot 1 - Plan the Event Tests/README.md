# Chapter 4 – Plan the Event Tests

AI Test Toolkit test app for the **Plan the Event** copilot (Chapter 3).

## Dependencies

- Chapter 3 - Common  
- Chapter 3 - Plan Event  
- AI Test Toolkit (Microsoft)

## Structure

- **test/Setup/PlanEventTestInstall.Codeunit.al** (50700) – Loads datasets and test suites from `.resources`.
- **test/PlanEventAITests.Codeunit.al** (50701) – Data-driven tests using `AIT Test Context`.
- **.resources/Datasets/** – JSONL input (e.g. `plan_event_accuracy.jsonl`).
- **.resources/TestSuites/** – XML suite definition (e.g. `PlanEvent-Tests.xml`).

## Build order

1. Publish Chapter 3 - Common and Chapter 3 - Plan Event.  
2. Publish this test app.  
3. Run the suite from the AI Test Tool in Business Central.
