table 50800 Room
{
    Caption = 'Room';
    DataCaptionFields = "Code", Name;
    DataClassification = CustomerContent;
    LookupPageId = "Room List";
    DrillDownPageId = "Room List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code of the room.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the room.';
        }
        field(3; Capacity; Integer)
        {
            Caption = 'Capacity';
            MinValue = 0;
            ToolTip = 'Specifies how many seats this room has.';
        }
        field(4; Floor; Integer)
        {
            Caption = 'Floor';
            ToolTip = 'Specifies the floor this room is on.';
        }
        field(5; "Has Recording"; Boolean)
        {
            Caption = 'Has Recording';
            ToolTip = 'Specifies whether this room can record the session.';
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether this room is blocked and cannot be assigned.';
        }
        field(7; "Blocked Reason"; Text[250])
        {
            Caption = 'Blocked Reason';
            ToolTip = 'Specifies why this room is blocked.';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
