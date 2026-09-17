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
                ToolTip = 'Specifies how many attendees you expect. If Reserved Attendees is greater than zero, use it as the demand signal; otherwise estimate from Actual Attendees on similar past sessions (Find Similar). Set this before assigning a room.';
            }
            field("Reserved Attendees"; Rec."Reserved Attendees")
            {
                ApplicationArea = All;
                StyleExpr = SessionStyle;
                ToolTip = 'Specifies how many attendees reserved this session in the conference app. When greater than zero, treat it as the demand signal for room size. The room Capacity must be at least this number.';
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
                ToolTip = 'Specifies how many attendees were in the room after the session. On past sessions, use this value to estimate attendance for similar upcoming sessions.';
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
                ToolTip = 'Finds other sessions by meaning of name, description, and speakers. Use Actual Attendees on similar past sessions to set Estimated Attendees for this session.';

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
                ToolTip = 'Opens the Room Card for the assigned room so you can check Capacity, Blocked, and scheduled sessions before keeping or changing the assignment.';
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
        SimilarEventSessions.SetBuffer(SimilarSessionBuffer, Rec);
        SimilarEventSessions.Run();
    end;

    var
        SessionStyle: Text;
        NoSimilarSessionsMsg: Label 'No similar sessions were found. Try another session, or enrich Name, Description, or speakers, then run Find Similar again.';
}
