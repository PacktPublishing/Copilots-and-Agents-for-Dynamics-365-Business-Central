table 50804 "Similar Session Buffer"
{
    Caption = 'Similar Session Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; Rank; Integer)
        {
            Caption = 'Rank';
            ToolTip = 'Specifies the similarity rank. Lower numbers are closer matches.';
        }
        field(2; Similarity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Similarity';
            DecimalPlaces = 2 : 2;
            ToolTip = 'Specifies the relative similarity score for this result set. Higher is closer.';
        }
        field(3; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the unique code for the session.';
        }
        field(4; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the session title.';
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a short description of the session.';
        }
        field(6; Speaker1; Text[250])
        {
            Caption = 'Speaker 1';
            ToolTip = 'Specifies the name of the first speaker.';
        }
        field(7; Speaker2; Text[250])
        {
            Caption = 'Speaker 2';
            ToolTip = 'Specifies the name of the second speaker.';
        }
        field(8; Speaker3; Text[250])
        {
            Caption = 'Speaker 3';
            ToolTip = 'Specifies the name of the third speaker.';
        }
        field(9; Speaker4; Text[250])
        {
            Caption = 'Speaker 4';
            ToolTip = 'Specifies the name of the fourth speaker.';
        }
        field(10; "Project Code"; Code[20])
        {
            Caption = 'Project Code';
            ToolTip = 'Specifies the event project this session belongs to.';
        }
        field(11; "Date"; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the scheduled date for the session.';
        }
        field(12; Status; Enum "Event Session Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the current status of the session.';
        }
        field(13; "Estimated Attendees"; Integer)
        {
            Caption = 'Estimated Attendees';
            ToolTip = 'Specifies how many attendees you expect at this session.';
        }
        field(14; "Actual Attendees"; Integer)
        {
            Caption = 'Actual Attendees';
            ToolTip = 'Specifies how many attendees were in the room.';
        }
        field(15; "Room Code"; Code[20])
        {
            Caption = 'Room Code';
            ToolTip = 'Specifies the room assigned to this session.';
        }
    }

    keys
    {
        key(PK; Rank)
        {
            Clustered = true;
        }
    }
}
