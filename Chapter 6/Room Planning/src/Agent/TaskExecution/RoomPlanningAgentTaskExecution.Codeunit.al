using System.Agents;
using System.Email;

/// <summary>
/// Defines the contract for executing agent tasks which includes includes additional validation,
/// user intervention suggestions, and contextual data retrieval.
/// </summary>
/// <remarks>
/// These procedures are executed in the context of the agent user and help fine-tuning
/// how agents interact with the system during task execution.
/// </remarks>
codeunit 50832 RoomPlanningAgentTaskExecution implements IAgentTaskExecution
{
    Access = Internal;

    /// <summary>
    /// Analyzes the content of an agent task message and its attachments.
    /// Returns the list of annotations to be displayed for the message.
    /// Annotations whose severity is set to Error will stop the execution of the related task.
    /// Annotations whose severity is set to Warning will enforce a review of the message.
    /// </summary>
    /// <remarks>
    /// These annotations are persisted on the message. The server asks once for the message-level annotations.
    /// </remarks>
    /// <param name="AgentTaskMessage">The agent task message.</param>
    /// <param name="Annotations">The list of annotations for the message.</param>
    procedure AnalyzeAgentTaskMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    begin
        if AgentTaskMessage.Type = AgentTaskMessage.Type::Output then
            PostProcessOutputMessage(AgentTaskMessage, Annotations)
        else
            ValidateInputMessage(AgentTaskMessage, Annotations);
    end;

    /// <summary>
    /// Returns all agent task user intervention suggestions applicable to the specified agent task, page, and record.
    /// </summary>
    /// <param name="AgentTaskUserInterventionRequestDetails">The agent user intervention request details.</param>
    /// <param name="Suggestions">The agent task user intervention suggestions.</param>
    procedure GetAgentTaskUserInterventionSuggestions(AgentTaskUserInterventionRequestDetails: Record "Agent User Int Request Details"; var Suggestions: Record "Agent Task User Int Suggestion")
    var
        SuggestionInstructionsLbl: Label 'Follow these steps to achieve your purpose ...', Locked = true;
        SummaryLocalizedLbl: Label 'User friendly summary of the instructions';
        DescriptionLocalizedLbl: Label 'Description of the conditions or context where the suggestion would apply. Used by the system to decide on relevance of the suggestion.';
    begin
        if AgentTaskUserInterventionRequestDetails.Type = AgentTaskUserInterventionRequestDetails.Type::Assistance then begin
            // TODO: Add suggestions for assistance
            Suggestions.Summary := SummaryLocalizedLbl;
            Suggestions.Description := DescriptionLocalizedLbl;
            Suggestions.Instructions := SuggestionInstructionsLbl;
            Suggestions.Insert();
            exit;
        end;
    end;

    /// <summary>
    /// Gets the current page context for the specified agent task, page, and record.
    /// This context is provided to the agent when interacting with the pages.
    /// </summary>
    /// <param name="AgentTaskPageContextRequest">The agent task page context request.</param>
    /// <param name="AgentTaskPageContext">The agent task page context.</param>
    procedure GetAgentTaskPageContext(AgentTaskPageContextRequest: Record "Agent Task Page Context Req."; var AgentTaskPageContext: Record "Agent Task Page Context")
    begin
        // TODO: Populate page context based on the request
        if AgentTaskPageContextRequest."Page ID" = Page::"Email Attachments" then
            AgentTaskPageContext."Currency Code" := 'USD';
    end;

    local procedure IsValidMessage(AgentTaskMessage: Record "Agent Task Message"): Boolean
    begin
        // TODO: Implement validation logic here
        exit(true);
    end;

    local procedure ValidateInputMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation"): Boolean
    var
        ErrorMessageLbl: Label 'The message content is invalid.';
        ErrorDetailsLbl: Label 'Please check the message format and try again.';
    begin
        // Validate and add annotations
        if IsValidMessage(AgentTaskMessage) then
            exit;

        // Add error or warning annotations
        // Error annotations will stop the task from being processed further.
        // Warning annotations will trigger an ask for assistance.
        // This processing will only happen once per message, before it is shown to the user.
        Annotations.Code := 'INV001';
        Annotations.Severity := Annotations.Severity::Error;
        Annotations.Message := ErrorMessageLbl;
        Annotations.Details := ErrorDetailsLbl;
        Annotations.Insert();
    end;

    local procedure PostProcessOutputMessage(var AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    var
        AgentMessage: Codeunit "Agent Message";
        OldText: Text;
    begin
        OldText := AgentMessage.GetText(AgentTaskMessage);
        AgentMessage.UpdateText(AgentTaskMessage, UpdateOutputText(OldText));
    end;

    local procedure UpdateOutputText(OldText: Text): Text
    begin
        // TODO: Add your logic here, eg. add an email signature to an email.
        exit(OldText);
    end;
}