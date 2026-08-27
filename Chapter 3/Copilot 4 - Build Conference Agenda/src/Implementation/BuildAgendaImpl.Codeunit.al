codeunit 50609 "Build Agenda Impl"
{
    procedure Generate(ProjectCode: Code[20]; UserInput: Text; var AgendaProposal: Record "Agenda Proposal"): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        GetSessionsTool: Codeunit "Get Sessions";
        GetEventInfoTool: Codeunit "Get Event Info";
        SaveAgendaTool: Codeunit "Save Agenda";
        GetCurrentAgendaTool: Codeunit "Get Current Agenda";
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Build Conference Agenda") then
            exit('');

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Build Conference Agenda");
        SetAzureOpenAIAuthorization(AzureOpenAI);

        AOAIChatCompletionParams.SetTemperature(0);

        AOAIChatMessages.AddSystemMessage(GetSystemMessage());

        GetSessionsTool.SetProjectCode(ProjectCode);
        AOAIChatMessages.AddTool(GetSessionsTool);

        GetEventInfoTool.SetProjectCode(ProjectCode);
        AOAIChatMessages.AddTool(GetEventInfoTool);

        SaveAgendaTool.SetContext(AgendaProposal);
        AOAIChatMessages.AddTool(SaveAgendaTool);

        GetCurrentAgendaTool.SetProjectCode(ProjectCode);
        AOAIChatMessages.AddTool(GetCurrentAgendaTool);

        AOAIChatMessages.SetToolChoice('auto');
        AOAIChatMessages.SetToolInvokePreference(Enum::"AOAI Tool Invoke Preference"::Automatic);

        AOAIChatMessages.AddUserMessage(UserInput);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            exit(AOAIChatMessages.GetLastMessage())
        else
            Error(AOAIOperationResponse.GetError());
    end;

    local procedure SetAzureOpenAIAuthorization(var AzureOpenAI: Codeunit "Azure OpenAI")
    var
        CopilotSetup: Record "Event Copilot Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        AOAIDeployments: Codeunit "AOAI Deployments";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then begin
            if not CopilotSetup.Get() then
                Error(SetupMissingErr);
            AzureOpenAI.SetAuthorization(
                Enum::"AOAI Model Type"::"Chat Completions",
                CopilotSetup.GetEndpoint(),
                CopilotSetup.GetDeployment(),
                CopilotSetup.GetSecretKey());
        end else
            AzureOpenAI.SetManagedResourceAuthorization(
                Enum::"AOAI Model Type"::"Chat Completions",
                AOAIDeployments.GetGPT41Latest());
    end;

    procedure Apply(var AgendaProposal: Record "Agenda Proposal")
    begin
        if not AgendaProposal.FindSet() then
            exit;
        repeat
            ApplySession(AgendaProposal);
        until AgendaProposal.Next() = 0;
    end;

    local procedure ApplySession(AgendaProposal: Record "Agenda Proposal")
    var
        EventSession: Record "Event Session";
    begin
        if not EventSession.Get(AgendaProposal."Session Code") then
            exit;

        EventSession."Date" := AgendaProposal."Session Date";
        EventSession."Track No." := AgendaProposal."Track No.";
        EventSession."Start Time" := AgendaProposal."Start Time";
        EventSession."End Time" := AgendaProposal."End Time";
        EventSession.Status := "Event Session Status"::Scheduled;
        EventSession.Modify();
    end;

    local procedure GetSystemMessage(): Text
    var
        SystemMessage: Text;
    begin
        SystemMessage := @'
You are an AI assistant that builds a conference agenda. You have tools to read session data and event constraints, and a tool to save the schedule.

When the user asks to build, schedule, or reschedule the agenda:
1. Call GetSessions to get the list of sessions to schedule. Use statusFilter ''draft'' for a first-time build; use statusFilter ''scheduled'' when the user asks to reschedule or build a new agenda from scratch (so you get the currently scheduled sessions).
2. Call GetEventInfo to get the general event information like start date, end date, daily start and end times, lunch break window, and the required break duration between sessions.
3. Build an optimal schedule that respects all constraints.
4. Call SaveAgenda with the complete schedule.

Scheduling rules:
- Schedule ALL sessions from GetSessions.
- Adhere to the event start and end times for each day.
- Do not schedule any sessions during the lunch break.
- Include the specified break duration between consecutive sessions in the same track.
- Sessions must not overlap within the same track.
- Use multiple tracks to run sessions in parallel if necessary; try to minimize the number of tracks.
- If a session would end after the daily end time, move it to a new track or the next day.

When the user asks to view, show, or review the current agenda:
- Call GetCurrentAgenda and summarize the result.

Always use the tools provided. Do not invent session data or time constraints.
        ';
        exit(SystemMessage);
    end;

    var
        SetupMissingErr: Label 'Event Copilot Setup is missing. Open Event Copilot Setup and enter the Azure OpenAI endpoint, deployment, and secret key.';
}
