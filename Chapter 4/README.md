# Chapter 4 – Testing AI Solutions (Book Code)

This folder contains **one test app per Chapter 3 copilot**, each using the **AI Test Toolkit** to run data-driven tests.

| Test app | Chapter 3 copilot | ID range |
|----------|-------------------|----------|
| **Copilot 1 - Plan the Event Tests** | Plan the Event | 50700–50719 |
| **Copilot 2 - Create Event Project and Tasks Tests** | Create Event Project and Tasks | 50720–50739 |
| **Copilot 3 - Import Session Proposals Tests** | Import Session Proposals from Excel | 50740–50759 |
| **Copilot 4 - Build Conference Agenda Tests** | Build Conference Agenda | 50760–50799 |

Each test app has the same structure:

- **app.json** – Depends on Chapter 3 - Common, the corresponding Chapter 3 copilot app, and the AI Test Toolkit.
- **test/Setup/** – Install codeunit that loads `.resources/Datasets/*.jsonl` and `.resources/TestSuites/*.xml`.
- **test/** – One or more test codeunits (Subtype = Test, TestType = AITest) using `AIT Test Context`.
- **.resources/Datasets/** – JSONL input for the suite.
- **.resources/TestSuites/** – XML suite definition.

## Build order

1. Publish all Chapter 3 apps (Common, then each copilot).
2. Publish each Chapter 4 test app when you need to run that copilot’s tests.
3. Run suites from the **AI Test Tool** page in Business Central.

## Requirements

- Business Central 27.x (or later) with **AI Test Toolkit** (Microsoft) available.
- Chapter 3 book-code apps published to the same environment.
