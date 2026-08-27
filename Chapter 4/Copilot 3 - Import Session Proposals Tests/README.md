# Chapter 4 – Import Session Proposals Tests

AI Test Toolkit test app for the **Import Session Proposals** copilot (Chapter 3).

## Dependencies

- Chapter 3 - Common  
- Chapter 3 - Import Session Proposals from Excel  
- AI Test Toolkit (Microsoft)

## Structure

- **test/Setup/ImportSessionProposalsTestInstall.Codeunit.al** (50740) – Loads datasets and test suites from `.resources`.
- **test/ImportSessionProposalsAITests.Codeunit.al** (50741) – Quality-evaluation tests; output can be exported for Azure AI Foundry (groundedness, relevance, fluency).
- **.resources/Datasets/** – JSONL input (e.g. `import_session_proposals_quality.jsonl`).
- **.resources/TestSuites/** – XML suite definition (e.g. `ImportSessionProposals-Tests.xml`).

## Build order

1. Publish Chapter 3 - Common and Chapter 3 - Import Session Proposals from Excel.  
2. Publish this test app.  
3. Run the suite and optionally download output for external evaluation in Azure AI Foundry.
