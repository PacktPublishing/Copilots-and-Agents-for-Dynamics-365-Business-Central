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
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this room is blocked and cannot be assigned.';
                }
                field("Blocked Reason"; Rec."Blocked Reason")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies why this room is blocked.';
                }
            }
        }
    }
}
