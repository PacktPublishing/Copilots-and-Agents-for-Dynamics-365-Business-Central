# Chapter 3 - Plan Event

First copilot demo for **Chapter 3: Creating AI solutions with AL and Copilot Toolkit**. Event Brief in → plain-text planning steps/tasks out (text-to-text).

## What this copilot does

- User provides the **Event Brief** (from Chapter 2) as text or Markdown in the Prompt area.
- The copilot calls **Azure OpenAI** chat completion and returns **plain text** proposing steps or tasks for how to plan and organize the event.
- **Implemented:** PromptDialog page (`Plan Event`), capability registration (`Plan Event`), implementation codeunit calling Azure OpenAI, and **Plan Event** action on the **Job List** page (Copilot Actions / Prompting group).

## How to run

1. Build and publish the **Chapter 3 - Common** app first; place its output in this project's `.alpackages` folder (or configure a shared package cache).
2. Open this folder in VS Code and build (Ctrl+Shift+B), then publish.
3. In Business Central, open **Event Copilot Setup** (search for it) and enter your **Azure OpenAI** endpoint, deployment name, and secret key. This setup is provided by the Common app.
4. Ensure the **Plan Event** capability is enabled in your environment (tenant/admin settings for Copilot capabilities).
5. Go to **Jobs** → **Job List** and use the **Plan Event** action (Sparkle icon in the Prompting group), or search for "Plan Event" in Copilot.

## Requirements

- Business Central 27.x.
- **Chapter 3 - Common** app (dependency; provides Event Copilot Setup table and page).
- Azure OpenAI configured in Event Copilot Setup (Common app).
