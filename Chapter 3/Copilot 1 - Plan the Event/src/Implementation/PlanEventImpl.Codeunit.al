codeunit 50303 "Plan Event Impl"
{
    procedure GeneratePlanningSteps(EventBrief: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Plan Event") then
            exit('');

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Plan Event");
        SetAzureOpenAIAuthorization(AzureOpenAI);

        AOAIChatMessages.AddSystemMessage(GetSystemMessage());
        AOAIChatMessages.AddUserMessage(EventBrief);

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

    local procedure GetSystemMessage(): Text
    var
        SystemPrompt: Text;
    begin
        SystemPrompt := @'
You are an assistant that proposes planning steps for an event based on the event brief.
Output a clear list of steps or tasks in plain text. Use numbered or bullet points.
Focus on how to plan and organize the event. Decline unrelated questions.';
        exit(SystemPrompt);
    end;

    var
        SetupMissingErr: Label 'Event Copilot Setup is missing. Open Event Copilot Setup and enter Azure OpenAI endpoint, deployment, and secret key.';
}
