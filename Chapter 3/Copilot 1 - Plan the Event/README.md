# Chapter03 Plan the Event

First copilot demo for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. Event Brief in → plain-text planning steps/tasks out (text-to-text).

## What this copilot does

- User provides the **Event Brief** (from Chapter 2) as text or Markdown.
- The copilot calls Azure OpenAI and returns **plain text** proposing steps or tasks for how to plan and organize the event.
- Uses PromptDialog page, chat completion, capability registration, and Copilot Actions.

## How to run

1. Build and publish the **Chapter03 Common** app first; place its output in this project's `.alpackages` folder (or configure a shared package cache).
2. Open this folder in VS Code.
3. Connect to Business Central 27.x (launch.json: "Your own server" or "Cloud (Sandbox)").
4. Build (Ctrl+Shift+B) and publish.
5. In BC, use Copilot to find and run the Plan the Event action.

## Requirements

- Business Central 27.x.
- Chapter03 Common app (dependency).
- Azure OpenAI configured for the environment.
