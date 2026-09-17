page 50814 "Room Card"
{
    ApplicationArea = All;
    Caption = 'Room Card';
    PageType = Card;
    SourceTable = Room;

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
                    ToolTip = 'Specifies the room code you assign on Event Sessions. Pick an existing code; do not invent one.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name of the room. Use it to recognize the venue when Capacity alone is not enough.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many seats the room has. Assign this room only when Estimated Attendees and Reserved Attendees are both at or below this number.';
                }
                field(Floor; Rec.Floor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which floor the room is on. Optional when choosing a room for capacity and availability.';
                }
                field("Has Recording"; Rec."Has Recording")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the room can record the session. Optional for room planning; capacity and blocked status matter more.';
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the room is unavailable. Never assign a blocked room; choose another room instead.';
                }
                field("Blocked Reason"; Rec."Blocked Reason")
                {
                    ApplicationArea = All;
                    Editable = Rec.Blocked;
                    ToolTip = 'Specifies why the room is blocked. Use the reason to decide whether another room is needed.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ScheduledSessions)
            {
                ApplicationArea = All;
                Caption = 'Scheduled Sessions';
                Image = Calendar;
                RunObject = Page "Event Sessions";
                RunPageLink = "Room Code" = field("Code"), Status = const(Scheduled);
                ToolTip = 'Opens scheduled sessions already using this room. Check for time overlaps before assigning the same room to another session.';
            }
        }
        area(Promoted)
        {
            actionref(ScheduledSessions_Promoted; ScheduledSessions)
            {
            }
        }
    }
}
