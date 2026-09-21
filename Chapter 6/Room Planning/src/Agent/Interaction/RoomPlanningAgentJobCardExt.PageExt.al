using System.Agents;

/// <summary>
/// Extends the Job Card so a user can ask the Room Planning Agent to assign rooms
/// for this event project's sessions. The action opens a review dialog first, then
/// creates the task with Agent Task Builder.
/// </summary>
pageextension 50829 "RPA Job Card Ext" extends "Job Card"
{
    actions
    {
        addlast(processing)
        {
            action(AssignRoomsWithAgent)
            {
                Caption = 'Assign Rooms with Agent';
                ToolTip = 'Ask the Room Planning Agent to estimate attendance and assign rooms for this event project.';
                Image = Task;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    AgentSetup: Codeunit "Agent Setup";
                    AgentTaskBuilder: Codeunit "Agent Task Builder";
                    AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
                    AgentTask: Record "Agent Task";
                    AssignRoomsDialog: Page "RPA Assign Task Dialog";
                    AgentUserSecurityId: Guid;
                    TaskTitle: Text[150];
                    From: Text[250];
                    MessageTemplateTxt: Label 'Please assign rooms to the sessions of event %1 (%2).', Locked = true;
                begin
                    if not AgentSetup.OpenAgentLookup(Enum::"Agent Metadata Provider"::"Room Planning Agent", AgentUserSecurityId) then
                        exit;

                    AssignRoomsDialog.SetSuggestedMessage(StrSubstNo(MessageTemplateTxt, Rec.Description, Rec."No."));
                    if AssignRoomsDialog.RunModal() <> Action::OK then
                        exit;

                    TaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, Rec.Description), 1, MaxStrLen(TaskTitle));
                    From := CopyStr(UserId(), 1, MaxStrLen(From));

                    AgentTaskMessageBuilder.Initialize(From, AssignRoomsDialog.GetMessage());
                    AgentTaskMessageBuilder.SetRequiresReview(false);

                    AgentTask := AgentTaskBuilder
                        .Initialize(AgentUserSecurityId, TaskTitle)
                        .AddTaskMessage(AgentTaskMessageBuilder)
                        .Create();

                    Message(TaskAssignedMsg, AgentTask.ID, Rec.Description);
                end;
            }
        }
    }

    var
        TaskTitleLbl: Label 'Assign rooms for %1', Comment = '%1 = Event project description';
        TaskAssignedMsg: Label 'Task %1 assigned to the Room Planning Agent to assign rooms for %2.', Comment = '%1 = Task ID, %2 = Event project description';
}
