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
                    ToolTip = 'Specifies the code of the room.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the room.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many seats this room has.';
                }
                field(Floor; Rec.Floor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the floor this room is on.';
                }
                field("Has Recording"; Rec."Has Recording")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this room can record the session.';
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this room is blocked and cannot be assigned.';
                }
                field("Blocked Reason"; Rec."Blocked Reason")
                {
                    ApplicationArea = All;
                    Editable = Rec.Blocked;
                    ToolTip = 'Specifies why this room is blocked.';
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
                ToolTip = 'View sessions assigned to this room that are still scheduled.';
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
