# Chapter03 Common

Shared AL app for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. This app holds common tables (and optional enums/codeunits) used by the four copilot demos.

## Contents

- **Tables:** Shared by two or more copilots (e.g. event/session setup, session master, agenda/schedule). Tables will be added when implementing the copilots.
- **Enums:** Shared across copilots (e.g. session status, conference duration) when applicable.
- No PromptDialog pages, no Azure OpenAI calls, no capability registration—only the shared data model.

## Build order

Build and publish this app **first** so that the copilot apps (Plan the Event, Event Project and Tasks, Import Session Proposals, Build Conference Agenda) can reference it. Place the built `.app` or symbols in each copilot project's `.alpackages` folder (or use a shared package cache path).

## Requirements

- Business Central 27.x (platform and application 27.0.0.0 or later).
- AL extension for VS Code.

## How to run

1. Open this folder in VS Code.
2. Restore symbol references (or ensure BC 27.x base application symbols are available).
3. Build (Ctrl+Shift+B) and publish to your BC server/sandbox.
4. Use the same server when building the copilot apps that depend on Common.
