page 50811 "Room List"
{
    ApplicationArea = All;
    Caption = 'Rooms';
    CardPageId = "Room Card";
    Editable = false;
    PageType = List;
    SourceTable = Room;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
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
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the room is unavailable. Never assign a blocked room; choose another room instead.';
                }
                field("Blocked Reason"; Rec."Blocked Reason")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies why the room is blocked. Use the reason to decide whether another room is needed.';
                }
            }
        }
    }
}
