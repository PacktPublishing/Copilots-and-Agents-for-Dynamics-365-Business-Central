# Chapter03 Import Session Proposals from Excel

Third copilot demo for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. Attach Excel file, map headers to table fields, import approved session proposals; Regenerate and history of generations.

## What this copilot does

- User **attaches an Excel file** (approved session proposals) via systemaction(Attach).
- Copilot **maps Excel headers to custom table fields** (LLM-assisted mapping).
- Imports session proposals into **Business Central custom tables** (from Common or this app).
- **Regenerate** and **history of generations** — scroll between suggestions, change and regenerate, apply one.

## How to run

1. Build and publish **Chapter03 Common** first (shared session/agenda tables); add to `.alpackages`.
2. Open this folder in VS Code and publish to BC 27.x.
3. In BC, run the copilot, attach an Excel file with session data, and use the generated mapping to import.

## Requirements

- Business Central 27.x.
- Chapter03 Common app (dependency; shared tables for sessions).
- Azure OpenAI configured.
