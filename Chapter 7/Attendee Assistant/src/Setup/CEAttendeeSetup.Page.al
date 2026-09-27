// ----------------------------------------------------------------------------
// Page 98215 - Attendee assistant setup (card, for organizers)
// Also hosts the two demo actions of the chapter.
// ----------------------------------------------------------------------------
page 98215 "CE Attendee Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Attendee Assistant Setup';
    SourceTable = "CE Attendee Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Event Project No."; Rec."Event Project No.") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PrepareDemoEvent)
            {
                ApplicationArea = All;
                Caption = 'Prepare Demo Event';
                Image = Setup;
                ToolTip = 'Selects the BC Tech Summit 2027 project (TECH2027) created by the Chapter 6 demo data and assigns a room to every 2027 session that has none yet, so you can follow Chapter 7 without running the Room Planning Agent.';

                trigger OnAction()
                var
                    AttendeeDemoData: Codeunit "CE Attendee Demo Data";
                begin
                    AttendeeDemoData.PrepareDemoEvent();
                    CurrPage.Update(false);
                    Message(DemoReadyMsg);
                end;
            }
            action(SimulateChanges)
            {
                ApplicationArea = All;
                Caption = 'Simulate Program Changes';
                Image = Change;
                ToolTip = 'Moves "Testing AL with AI Test Toolkit" to another room with a note from the organizers and cancels the opening keynote, so the "has anything changed?" scenario has data.';

                trigger OnAction()
                var
                    AttendeeDemoData: Codeunit "CE Attendee Demo Data";
                begin
                    Message(ChangesSimulatedMsg, AttendeeDemoData.SimulateChanges());
                end;
            }
            action(ResetChanges)
            {
                ApplicationArea = All;
                Caption = 'Reset Program Changes';
                Image = Undo;
                ToolTip = 'Puts "Testing AL with AI Test Toolkit" back in Room 101, reschedules the opening keynote and clears the program change log of the event, so the simulation can be repeated.';

                trigger OnAction()
                var
                    AttendeeDemoData: Codeunit "CE Attendee Demo Data";
                begin
                    AttendeeDemoData.ResetProgramChanges();
                    Message(ChangesResetMsg);
                end;
            }
        }
        area(Navigation)
        {
            action(SessionChanges)
            {
                ApplicationArea = All;
                Caption = 'Session Changes';
                Image = ChangeLog;
                RunObject = page "CE Session Changes";
                ToolTip = 'Opens the log of program changes, where the organizers add notes for the attendees.';
            }
        }
        area(Promoted)
        {
            actionref(PrepareDemoEvent_Promoted; PrepareDemoEvent) { }
            actionref(SimulateChanges_Promoted; SimulateChanges) { }
            actionref(ResetChanges_Promoted; ResetChanges) { }
            actionref(SessionChanges_Promoted; SessionChanges) { }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        DemoReadyMsg: Label 'TECH2027 is selected and every 2027 session has a room.';
        ChangesSimulatedMsg: Label '%1 program changes were recorded. Open Session Changes to review them.', Comment = '%1 = number of change log entries created by the simulation';
        ChangesResetMsg: Label 'Program changes were reset.';
}
