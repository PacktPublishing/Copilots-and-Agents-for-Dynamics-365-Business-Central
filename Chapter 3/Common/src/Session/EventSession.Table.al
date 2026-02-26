table 50211 "Event Session"
{
    Caption = 'Event Session';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; Speaker1; Text[250])
        {
            Caption = 'Speaker 1';
            DataClassification = CustomerContent;
        }
        field(5; Speaker2; Text[250])
        {
            Caption = 'Speaker 2';
            DataClassification = CustomerContent;
        }
        field(6; Speaker3; Text[250])
        {
            Caption = 'Speaker 3';
            DataClassification = CustomerContent;
        }
        field(7; Speaker4; Text[250])
        {
            Caption = 'Speaker 4';
            DataClassification = CustomerContent;
        }
        field(8; "Date"; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(9; "Duration (min)"; Integer)
        {
            Caption = 'Duration (min)';
            DataClassification = CustomerContent;
        }
        field(10; Status; Enum "Event Session Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(11; "Project Code"; Code[20])
        {
            Caption = 'Project Code';
            DataClassification = CustomerContent;
            TableRelation = Job;
        }
        field(12; "Track No."; Integer)
        {
            Caption = 'Track No.';
            DataClassification = CustomerContent;
        }
        field(13; "Start Time"; Time)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;
        }
        field(14; "End Time"; Time)
        {
            Caption = 'End Time';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(SK; "Project Code", Status)
        {
        }
    }
}
