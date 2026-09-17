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
            ToolTip = 'Specifies the room code you assign on Event Sessions. Pick an existing code; do not invent one.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the display name of the room. Use it to recognize the venue when Capacity alone is not enough.';
        }
        field(3; Capacity; Integer)
        {
            Caption = 'Capacity';
            MinValue = 0;
            ToolTip = 'Specifies how many seats the room has. Assign this room only when Estimated Attendees and Reserved Attendees are both at or below this number.';
        }
        field(4; Floor; Integer)
        {
            Caption = 'Floor';
            ToolTip = 'Specifies which floor the room is on. Optional when choosing a room for capacity and availability.';
        }
        field(5; "Has Recording"; Boolean)
        {
            Caption = 'Has Recording';
            ToolTip = 'Specifies whether the room can record the session. Optional for room planning; capacity and blocked status matter more.';
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether the room is unavailable. Never assign a blocked room; choose another room instead.';
        }
        field(7; "Blocked Reason"; Text[250])
        {
            Caption = 'Blocked Reason';
            ToolTip = 'Specifies why the room is blocked. Use the reason to decide whether another room is needed.';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, Capacity)
        {
        }
    }
}
