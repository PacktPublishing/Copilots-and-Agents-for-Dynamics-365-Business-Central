# Chapter 3 - Create Event Project and Tasks

Second copilot demo for **Chapter 3: Creating Copilots in AL with the AI Development Toolkit**. Event Brief in → structured JSON (project header + tasks) → real Job and Job Task records in Business Central.

## What this copilot does

- **Input:** Event Brief (text or Markdown), same as Copilot 1 (Plan Event).
- **Output:** Structured **JSON** from the LLM (project shortDescription, detailedDescription, and a tasks array).
- **Result:** Creates a **real project in Business Central** — a standard **Job** (event project) and **Job Task** lines (preparation tasks). Optionally creates **Job Planning Line** entries for posting tasks (Resource/Item/Both).
- **UI:** PromptDialog with Event Brief input; generated project and tasks shown in the Content area (short description, details, and a list of tasks). **Keep it** saves to BC; **Discard it** closes without saving.
- **Instructional text** on the prompt field; **Prompt Guide** action to prefill a sample event brief; **structured output** (JSON) parsed in AL and mapped to the temporary proposal table, then to Job and Job Task.

## How to run

1. Build and publish **Chapter 3 - Common** first; add its output to this project’s `.alpackages`.
2. Open this folder in VS Code.
3. Connect to Business Central 27.3 or later and publish.
4. In BC, open **Job List** and use the **Create Event Project** action (Prompting group, Sparkle icon).
5. Enter or paste an Event Brief, choose **Generate**, review the proposed project and tasks, then **Keep it** to create the Job and tasks in BC, or **Discard it** to close without saving.

## Requirements

- Business Central 27.3 or later.
- **Chapter 3 - Common** app (dependency; provides Event Copilot Setup).
- **Azure OpenAI** configured in **Event Copilot Setup** (Common app). Open Event Copilot Setup in BC and enter endpoint, deployment name, and secret key. The Create Event Project capability must be enabled for your environment.

## Implementation details

- **Capability:** Registered as “Create Event Project and Tasks” (Install codeunit).
- **Generate flow:** Reads Event Copilot Setup from Common, calls Azure OpenAI chat completion with a metaprompt that requests JSON (project + tasks). Response is parsed (JSON), optional markdown code fence stripped, and data written to the temporary **Event Project Proposal** table.
- **Save flow:** On **Keep it**, proposal records are passed to **Save Event Project Impl**, which creates one Job and Job Task lines (and Job Planning Line for Posting tasks with Type Resource/Item/Both).
