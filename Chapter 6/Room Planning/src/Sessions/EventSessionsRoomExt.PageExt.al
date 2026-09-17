pageextension 50817 "Event Sessions Room Ext" extends "Event Sessions"
{
    layout
    {
        modify("Code")
        {
            StyleExpr = SessionStyle;
        }
        modify(Name)
        {
            StyleExpr = SessionStyle;
        }
        modify(Description)
        {
            StyleExpr = SessionStyle;
        }
        modify(Speaker1)
        {
            StyleExpr = SessionStyle;
        }
        modify(Status)
        {
            StyleExpr = SessionStyle;
        }
        modify("Date")
        {
            StyleExpr = SessionStyle;
        }
        modify("Start Time")
        {
            StyleExpr = SessionStyle;
        }
        modify("End Time")
        {
            StyleExpr = SessionStyle;
        }
        addlast(General)
        {
            field("Estimated Attendees"; Rec."Estimated Attendees")
            {
                ApplicationArea = All;
                StyleExpr = SessionStyle;
                ToolTip = 'Specifies how many attendees you expect at this session. Fill this in from comparable sessions at previous conferences. It is your estimate, not a counted figure.';
            }
            field("Reserved Attendees"; Rec."Reserved Attendees")
            {
                ApplicationArea = All;
                StyleExpr = SessionStyle;
                ToolTip = 'Specifies how many attendees have reserved this session in the conference app. It is zero until attendees start planning their schedule, and not every attendee who reserves a session turns up.';
            }
            field("Room Code"; Rec."Room Code")
            {
                ApplicationArea = All;
                StyleExpr = SessionStyle;
                ToolTip = 'Specifies the room assigned to this session. The room must exist, must not be blocked, must seat the estimated and reserved attendees, and must be free in this time slot.';
            }
            field("Actual Attendees"; Rec."Actual Attendees")
            {
                ApplicationArea = All;
                StyleExpr = SessionStyle;
                ToolTip = 'Specifies how many attendees were in the room. Fill this in after the session. Last year''s actuals are how you judge an estimate.';
            }
        }
        addfirst(FactBoxes)
        {
            part(RoomPlanningCue; "Room Planning Cue")
            {
                ApplicationArea = All;
                SubPageLink = "Project Code Filter" = field("Project Code");
            }
        }
    }

    actions
    {
        addfirst(Processing)
        {
            action(FindSimilar)
            {
                ApplicationArea = All;
                Caption = 'Find Similar';
                Image = Find;
                ToolTip = 'Ranks other sessions by meaning of name, description, and speakers using semantic search.';

                trigger OnAction()
                begin
                    FindAndShowSimilarSessions();
                end;
            }
            action(Room)
            {
                ApplicationArea = All;
                Caption = 'Room';
                Enabled = Rec."Room Code" <> '';
                Image = Warehouse;
                RunObject = Page "Room Card";
                RunPageLink = "Code" = field("Room Code");
                ToolTip = 'Open the card for the room assigned to this session.';
            }
        }
        addfirst(Promoted)
        {
            actionref(FindSimilar_Promoted; FindSimilar)
            {
            }
            actionref(Room_Promoted; Room)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Reserved Attendees");
    end;

    trigger OnAfterGetRecord()
    begin
        SessionStyle := Rec.GetAttendeeDemandStyle();
    end;

    local procedure FindAndShowSimilarSessions()
    var
        SimilarSessionBuffer: Record "Similar Session Buffer" temporary;
        FindSimilarSessions: Codeunit "Find Similar Sessions";
        SimilarEventSessions: Page "Similar Event Sessions";
    begin
        FindSimilarSessions.FindSimilar(Rec, SimilarSessionBuffer);
        if SimilarSessionBuffer.IsEmpty() then begin
            Message(NoSimilarSessionsMsg);
            exit;
        end;
        SimilarEventSessions.SetBuffer(SimilarSessionBuffer);
        SimilarEventSessions.Run();
    end;

    var
        SessionStyle: Text;
        NoSimilarSessionsMsg: Label 'No similar sessions were found.';
}
