page 50813 "Event Session Card"
{
    ApplicationArea = All;
    Caption = 'Event Session Card';
    PageType = Card;
    SourceTable = "Event Session";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the unique code for the session.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the session title.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies a short description of the session.';
                }
                field(Speaker1; Rec.Speaker1)
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the name of the first speaker.';
                }
                field(Speaker2; Rec.Speaker2)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the second speaker.';
                }
                field(Speaker3; Rec.Speaker3)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the third speaker.';
                }
                field(Speaker4; Rec.Speaker4)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the fourth speaker.';
                }
                field("Project Code"; Rec."Project Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the event project this session belongs to.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the current status of the session.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the scheduled date for the session.';
                }
                field("Track No."; Rec."Track No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the track number assigned to this session.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the scheduled start time.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the scheduled end time.';
                }
                field("Duration (min)"; Rec."Duration (min)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the duration of the session in minutes.';
                }
            }
            group(RoomAssignment)
            {
                Caption = 'Room Assignment';
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
        }
        area(FactBoxes)
        {
            part(SessionAttendeeReservationFactBox; "Session Attendee Res. FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Session Code" = field("Code");
            }
            part(RoomPlanningCue; "Room Planning Cue")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AssignRooms)
            {
                ApplicationArea = All;
                Caption = 'Assign Rooms';
                Image = Allocations;
                RunObject = Page "Assign Rooms";
                ToolTip = 'Opens a temporary list of upcoming sessions so you can assign or move rooms. This is the only place rooms are assigned. Changes are not saved until you finish.';
            }
        }
        area(Navigation)
        {
            action(SessionAttendeeReservations)
            {
                ApplicationArea = All;
                Caption = 'Attendee Reservations';
                Image = LedgerEntries;
                RunObject = Page "Session Attendee Res. Entries";
                RunPageLink = "Session Code" = field("Code");
                ToolTip = 'View attendee reservations from the conference app for this session.';
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
        area(Promoted)
        {
            actionref(AssignRooms_Promoted; AssignRooms)
            {
            }
            actionref(SessionAttendeeReservations_Promoted; SessionAttendeeReservations)
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
