namespace Packt;

using System.Agents;

codeunit 50854 RoomPlanningAgentTaskExecution implements IAgentTaskExecution
{
    Access = Internal;

    procedure AnalyzeAgentTaskMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    begin
        if AgentTaskMessage.Type = AgentTaskMessage.Type::Output then
            PostProcessOutputMessage(AgentTaskMessage, Annotations)
        else
            ValidateInputMessage(AgentTaskMessage, Annotations);
    end;

    procedure GetAgentTaskUserInterventionSuggestions(AgentTaskUserInterventionRequestDetails: Record "Agent User Int Request Details"; var Suggestions: Record "Agent Task User Int Suggestion")
    begin
        Clear(Suggestions);
    end;

    procedure GetAgentTaskPageContext(AgentTaskPageContextRequest: Record "Agent Task Page Context Req."; var AgentTaskPageContext: Record "Agent Task Page Context")
    begin
        Clear(AgentTaskPageContext);
    end;

    local procedure ValidateInputMessage(AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    begin
        Clear(Annotations);
    end;

    local procedure PostProcessOutputMessage(var AgentTaskMessage: Record "Agent Task Message"; var Annotations: Record "Agent Annotation")
    var
        AgentMessage: Codeunit "Agent Message";
        OldText: Text;
    begin
        OldText := AgentMessage.GetText(AgentTaskMessage);
        AgentMessage.UpdateText(AgentTaskMessage, OldText);
        Clear(Annotations);
    end;
}
