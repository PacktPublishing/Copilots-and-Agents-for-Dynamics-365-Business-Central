pageextension 50817 "Event Sessions Room Ext" extends "Event Sessions"
{
    CardPageId = "Event Session Card";

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
                Editable = false;
                StyleExpr = SessionStyle;
                ToolTip = 'Specifies the room assigned to this session. You cannot change it here. Use Assign Rooms to assign or move a session.';
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
            action(AssignRooms)
            {
                ApplicationArea = All;
                Caption = 'Assign Rooms';
                Image = Allocations;
                ToolTip = 'Opens a temporary list of upcoming sessions so you can assign or move rooms. This is the only place rooms are assigned. Changes are not saved until you finish.';

                trigger OnAction()
                var
                    AssignRooms: Page "Assign Rooms";
                begin
                    AssignRooms.SetProjectCode(Rec."Project Code");
                    AssignRooms.RunModal();
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
            actionref(AssignRooms_Promoted; AssignRooms)
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

    var
        SessionStyle: Text;
}
