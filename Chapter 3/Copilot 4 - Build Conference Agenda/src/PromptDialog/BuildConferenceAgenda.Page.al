page 50610 "Build Conference Agenda"
{
    PageType = PromptDialog;
    Caption = 'Build Conference Agenda';
    IsPreview = true;
    Extensible = false;
    DataCaptionExpression = CaptionText;

    layout
    {
        area(Prompt)
        {
            field(UserInput; UserInput)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
                InstructionalText = 'Describe what you want: build the agenda, show the current schedule, or specify preferences such as number of days or track limits. Use the Prompt Guide for ready-made examples.';
                ToolTip = 'Type your agenda request here, or choose a template from the Prompt Guide.';
            }
        }
        area(Content)
        {
            field(LastResponseText; LastResponseText)
            {
                ApplicationArea = All;
                Caption = 'Response';
                Editable = false;
                MultiLine = true;
                ShowCaption = false;
                ToolTip = 'Shows the last response from Copilot after building or reviewing the agenda.';
            }
            part(AgendaProposalSubpart; "Agenda Proposal Subpart")
            {
                ApplicationArea = All;
                ShowFilter = false;
                Editable = false;
                Visible = ShowAgendaProposalSubpart;
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';
                ToolTip = 'Let Copilot build or review the conference agenda using tool calling.';

                trigger OnAction()
                begin
                    GenerateAgendaProposal();
                end;
            }
            systemaction(Ok)
            {
                Caption = 'Apply';
                ToolTip = 'Apply the proposed agenda to the event sessions, setting their date, track, start time, and end time.';
            }
            systemaction(Cancel)
            {
                Caption = 'Discard';
                ToolTip = 'Discard the proposed agenda without saving.';
            }
        }
        area(PromptGuide)
        {
            // --- Build agenda (triggers GetSessions + GetEventSchedule + SaveAgenda) ---
            group(Build)
            {
                Caption = 'Build agenda';

                action(BuildAgenda)
                {
                    Caption = 'Build the conference agenda';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to build a full conference agenda from all draft sessions.';

                    trigger OnAction()
                    begin
                        UserInput := 'Build the conference agenda for this event project.';
                    end;
                }
                action(BuildMinimizeTracks)
                {
                    Caption = 'Build agenda with minimum tracks';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to schedule all sessions using as few parallel tracks as possible.';

                    trigger OnAction()
                    begin
                        UserInput := 'Build the conference agenda using as few parallel tracks as possible.';
                    end;
                }
                action(BuildPrioritizeMornings)
                {
                    Caption = 'Schedule shorter sessions in the morning';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to place shorter sessions in the morning and longer sessions in the afternoon.';

                    trigger OnAction()
                    begin
                        UserInput := 'Build the conference agenda. Schedule shorter sessions in the morning and longer sessions in the afternoon.';
                    end;
                }
            }
            // --- Review agenda (triggers GetCurrentAgenda) ---
            group(Review)
            {
                Caption = 'Review agenda';

                action(ShowCurrentAgenda)
                {
                    Caption = 'Show the current agenda';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to summarize the currently scheduled sessions.';

                    trigger OnAction()
                    begin
                        UserInput := 'Show the current conference agenda.';
                    end;
                }
                action(ShowAgendaForDay)
                {
                    Caption = 'Show agenda for day [number]';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to show the schedule for a specific day. Append the day number to complete the prompt.';

                    trigger OnAction()
                    begin
                        UserInput := 'Show the agenda for day ';
                    end;
                }
            }
            // --- Adjust agenda (triggers all tools to rebuild with new constraints) ---
            group(Adjust)
            {
                Caption = 'Adjust agenda';

                action(RescheduleAll)
                {
                    Caption = 'Reschedule all sessions';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to discard the current schedule and build a completely new one.';

                    trigger OnAction()
                    begin
                        UserInput := 'Reschedule all sessions. Build a completely new agenda from scratch.';
                    end;
                }
                action(AvoidOverlap)
                {
                    Caption = 'Rebuild avoiding speaker overlap';
                    ApplicationArea = All;
                    ToolTip = 'Ask Copilot to rebuild the agenda ensuring no speaker has overlapping sessions.';

                    trigger OnAction()
                    begin
                        UserInput := 'Rebuild the conference agenda ensuring no speaker has overlapping sessions.';
                    end;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then
            ApplyAgenda();
    end;

    var
        TempAgendaProposal: Record "Agenda Proposal" temporary;
        BuildAgendaImpl: Codeunit "Build Agenda Impl";
        ProjectCode: Code[20];
        UserInput: Text;
        CaptionText: Text;
        LastResponseText: Text;
        ShowAgendaProposalSubpart: Boolean;

    procedure SetProject(FromProjectCode: Code[20])
    begin
        ProjectCode := FromProjectCode;
    end;

    local procedure GenerateAgendaProposal()
    begin
        CaptionText := UserInput;
        TempAgendaProposal.Reset();
        TempAgendaProposal.DeleteAll();
        ShowAgendaProposalSubpart := false;
        LastResponseText := BuildAgendaImpl.Generate(ProjectCode, UserInput, TempAgendaProposal);
        CurrPage.AgendaProposalSubpart.Page.Load(TempAgendaProposal);
        ShowAgendaProposalSubpart := not TempAgendaProposal.IsEmpty();
    end;

    local procedure ApplyAgenda()
    var
        TempApplyProposal: Record "Agenda Proposal" temporary;
    begin
        CurrPage.AgendaProposalSubpart.Page.GetRecords(TempApplyProposal);
        BuildAgendaImpl.Apply(TempApplyProposal);
    end;
}
