# Chapter03 Event Project and Tasks

Second copilot demo for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. Event Brief in → structured JSON (project header + lines) → real project in Business Central.

## What this copilot does

- Same input: **Event Brief** (text).
- Output: **structured JSON** (project header + project lines).
- Result: create a **real project in Business Central** (event project and preparation tasks).
- Uses instructional text, prompt guides, structured output from the LLM, and Keep/Discard to save or discard the suggestion.

## How to run

1. Build and publish **Chapter03 Common** first; add its output to this project's `.alpackages`.
2. Open this folder in VS Code.
3. Connect to Business Central 27.x and publish.
4. Run the copilot from BC and use the Event Brief to generate and save a project with tasks.

## Requirements

- Business Central 27.x.
- Chapter03 Common app (dependency).
- Azure OpenAI configured.
