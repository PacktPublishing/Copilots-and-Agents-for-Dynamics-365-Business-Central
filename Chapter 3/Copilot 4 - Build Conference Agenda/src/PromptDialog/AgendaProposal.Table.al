table 50603 "Agenda Proposal"
{
    Caption = 'Agenda Proposal';
    TableType = Temporary;

    fields
    {
        field(1; "Session Code"; Code[20])
        {
            Caption = 'Session Code';
            DataClassification = CustomerContent;
        }
        field(2; "Session Date"; Date)
        {
            Caption = 'Session Date';
            DataClassification = CustomerContent;
        }
        field(3; "Track No."; Integer)
        {
            Caption = 'Track No.';
            DataClassification = CustomerContent;
        }
        field(4; "Start Time"; Time)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;
        }
        field(5; "End Time"; Time)
        {
            Caption = 'End Time';
            DataClassification = CustomerContent;
        }
        field(6; Description; Text[250])
        {
            Caption = 'Description';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session".Description where("Code" = field("Session Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Session Code")
        {
            Clustered = true;
        }
        key(SK; "Session Date", "Start Time")
        {
        }
    }
}
