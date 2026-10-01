# Chapter 3 – Copilot 3: Import Session Proposals from Excel

Third copilot demo for **Chapter 3: Creating Copilots in AL with the AI Development Toolkit**.

## What this copilot does

1. **Attach Excel** — user attaches an Excel file (approved session proposals) via `systemaction(Attach)`.
2. **AI-assisted field mapping** — Copilot reads the Excel column headers and the Event Session table field list, then returns a JSON array mapping each Excel column to the best matching BC field.
3. **Review mapping proposal** — the PromptDialog shows the proposed mappings in an editable list. Navigate between mapping generations using Previous/Next on the history.
4. **Regenerate** — request a new mapping suggestion; each generation is stored with a `Generation Id` so you can scroll between suggestions.
5. **History of generations** — every Generate/Regenerate creates a new history record. Navigate to a previous generation to view and apply an older mapping.
6. **Import** — click **Import** (OK action) to insert Excel data rows as **Event Session** records in Business Central, linked to the current event project (Job).

## Prompt option: Data Exposure

In **area(PromptOptions)** the dialog shows a **Data Exposure** dropdown that controls how much data is sent to the AI when generating the field mapping:

| Option | What is sent to the AI |
|--------|------------------------|
| **None** (default) | Excel column headers (row 1) and Event Session field names only. |
| **Excel** | Same as None, plus up to 3 sample data rows from the attached Excel file (rows 2–4) as a pipe-separated table, so the AI can see example values. |
| **Excel and Business Central** | Same as Excel, plus: Event Session field types and lengths (from the `Field` system table), up to 5 existing Event Session records for the current project (live BC data), and key project info (Job No., Description, Start/End Date) so the AI understands the target schema, existing values, and project context. |

The selected value is stored on each **Mapping Generation History** record. When you scroll between generations (Previous/Next), the Data Exposure dropdown updates to show the level that was used for that generation. Choosing a higher level gives the model more context and can improve mapping quality, at the cost of a larger prompt.

## Entry point

Open the **Job List** page, select an event project, and choose **Import Session Proposals** from the **Prompting** action group. The Copilot dialog opens, pre-filled with the project details.

## Object structure

| Object | ID | Name |
|---|---|---|
| Enum | 50508 | Data Exposure |
| Enum ext | 50500 | Import Session Proposals Cap. |
| Codeunit | 50501 | Import Sess. Proposals Install |
| Table (temp) | 50502 | Field Mapping Proposal |
| Table (temp) | 50503 | Mapping Generation History |
| Codeunit | 50504 | Import Session Proposals Impl |
| Page | 50505 | Import Session Proposals |
| Page | 50506 | Field Mapping Proposal Subpart |
| Page ext | 50507 | Import Session Proposals Ext |

## Dependencies

- **Chapter 3 – Common** (required): provides `Event Session` table (50211), `Event Session Status` enum (50210), and `Event Copilot Setup` for Azure OpenAI credentials.

## How to run

You can use the [sample Excel file](https://github.com/PacktPublishing/AI-solutions-for-Dynamics-365-Business-Central/blob/main/Chapter%203/Copilot%203%20-%20Import%20Session%20Proposals%20from%20Excel/Examples/SessionProposals.xlsx) from the repository.

1. Build and publish **Chapter 3 – Common** first; add the `.app` file to `.alpackages`.
2. Open this folder in VS Code and publish to BC 27.x.
3. Open **Event Copilot Setup** (search in BC) and enter your Azure OpenAI Endpoint, Deployment, and Secret Key.
4. On the **Job List**, select a project and choose **Import Session Proposals** from the Prompting area.
5. Optionally set **Data Exposure** (None / Excel / Excel and Business Central) to control how much data is sent to the AI for mapping.
6. Click **Attach** to upload your Excel file, then **Map Fields** to let Copilot generate a mapping proposal.
7. Optionally click **Regenerate** to get a new suggestion. Use the Previous/Next navigation to scroll between mapping generations; the Data Exposure dropdown reflects the level used for each generation.
8. Click **Import** to insert all session rows from Excel (using the currently displayed mapping) into BC.

## Requirements

- Business Central 27.x / runtime 16.0
- Azure OpenAI resource with a chat completions deployment (e.g. `gpt-4o`)
- Chapter 3 – Common app published
