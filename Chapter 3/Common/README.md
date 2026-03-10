# Chapter 3 - Common

Shared AL app for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. This app holds common tables and pages used by the four copilot demos.

## Contents

- **Event Copilot Setup** (table 50200, page 50201): Azure OpenAI configuration (endpoint, deployment, secret key). Used by Plan Event and other copilots that call Azure OpenAI. Open "Event Copilot Setup" in BC to configure.
- **Event Copilot Admin** (permission set 50202): Assign to users who may open and edit Event Copilot Setup and Event Session data.
- **Event Session** (table 50211): Session proposals imported from Excel (Copilot 3) and used for agenda building (Copilot 4). Fields include Code, Name, Description, Speaker1–4, Date, Duration, Status, Project Code (Job), Track No., Start/End Time.
- **Event Session Status** (enum 50210): Draft, Scheduled, Cancelled, Completed.
- **Event Sessions** (page 50212): List page for Event Session records. Usage category: Lists.
- **Event Sessions Job List Ext** (page extension 50213): Adds an "Event Sessions" action on Job List that opens event sessions filtered by the current project.

No capability registration or AI logic in Common—only the shared data model and setup.

## Build order

Build and publish this app **first** so that the copilot apps (Plan Event, Event Project and Tasks, Import Session Proposals, Build Conference Agenda) can reference it. Place the built `.app` or symbols in each copilot project's `.alpackages` folder (or use a shared package cache path).

## Requirements

- Business Central 27.x (platform and application 27.0.0.0 or later).
- AL extension for VS Code.

## How to run

1. Open this folder in VS Code.
2. Restore symbol references (or ensure BC 27.x base application symbols are available).
3. Build (Ctrl+Shift+B) and publish to your BC server/sandbox.
4. Use the same server when building the copilot apps that depend on Common.
