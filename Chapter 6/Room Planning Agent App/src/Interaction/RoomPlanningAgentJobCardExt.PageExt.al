namespace Packt;

using Microsoft.Projects.Project.Job;
using System.Agents;

/// <summary>
/// Extends the Project Card with an action that asks the Room Planning Agent to assign rooms
/// for the event's conference sessions. The user reviews the message before the task is created.
/// </summary>
pageextension 50851 "RPA Job Card Ext" extends "Job Card"
{
    actions
    {
        addlast(processing)
        {
            action(AssignRoomsWithAgent)
            {
                ApplicationArea = All;
                Caption = 'Assign Rooms with Agent';
                Image = Task;
                ToolTip = 'Asks the Room Planning Agent to estimate attendance and assign rooms for the sessions on this event.';

                trigger OnAction()
                var
                    AgentTask: Record "Agent Task";
                    AgentSetup: Codeunit "Agent Setup";
                    AgentTaskBuilder: Codeunit "Agent Task Builder";
                    AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
                    AssignTaskDialog: Page "RPA Assign Task Dialog";
                    AgentUserSecurityId: Guid;
                    From: Text[250];
                    TaskTitle: Text[150];
                    MessageTemplateTxt: Label 'Assign rooms for the conference sessions on %1 (project %2).', Locked = true;
                begin
                    if not AgentSetup.OpenAgentLookup(Enum::"Agent Metadata Provider"::"Room Planning Agent", AgentUserSecurityId) then
                        exit;

                    AssignTaskDialog.SetSuggestedMessage(StrSubstNo(MessageTemplateTxt, Rec.Description, Rec."No."));
                    if AssignTaskDialog.RunModal() <> Action::OK then
                        exit;

                    TaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, Rec.Description), 1, MaxStrLen(TaskTitle));
                    From := CopyStr(UserId(), 1, MaxStrLen(From));

                    AgentTaskMessageBuilder.Initialize(From, AssignTaskDialog.GetMessage());
                    AgentTaskMessageBuilder.SetRequiresReview(false);

                    AgentTask := AgentTaskBuilder
                        .Initialize(AgentUserSecurityId, TaskTitle)
                        .AddTaskMessage(AgentTaskMessageBuilder)
                        .Create();

                    Message(TaskAssignedMsg, AgentTask.ID, Rec.Description);
                end;
            }
        }
        addfirst(Category_Process)
        {
            actionref(AssignRoomsWithAgent_Promoted; AssignRoomsWithAgent)
            {
            }
        }
    }

    var
        TaskTitleLbl: Label 'Assign rooms for %1', Comment = '%1 = Event / project description';
        TaskAssignedMsg: Label 'Room planning task %1 was assigned to the agent for %2.', Comment = '%1 = Task ID, %2 = Event / project description';
}
