// ----------------------------------------------------------------------------
// Table 98103 - Conference session
// Read by the session-browsing-by-track and speaker-lookup skills.
// Rating fields are read by the Speaker Portal agent.
// ----------------------------------------------------------------------------
table 98103 "CE Conference Session"
{
    Caption = 'Conference Session';
    DataClassification = CustomerContent;
    LookupPageId = "CE Conference Sessions";
    DrillDownPageId = "CE Conference Sessions";

    fields
    {
        field(1; "Session Code"; Code[20])
        {
            Caption = 'Session Code';
            DataClassification = CustomerContent;
        }
        field(10; Title; Text[150])
        {
            Caption = 'Title';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(20; Track; Enum "CE Session Track")
        {
            Caption = 'Track';
            DataClassification = CustomerContent;
        }
        field(30; "Speaker Code"; Code[20])
        {
            Caption = 'Speaker Code';
            DataClassification = CustomerContent;
            TableRelation = "CE Conference Speaker"."Speaker Code";
        }
        field(31; "Speaker Name"; Text[100])
        {
            Caption = 'Speaker Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup("CE Conference Speaker"."Full Name" where("Speaker Code" = field("Speaker Code")));
        }
        field(40; "Start Date Time"; DateTime)
        {
            Caption = 'Start Date Time';
            DataClassification = CustomerContent;
        }
        field(41; "End Date Time"; DateTime)
        {
            Caption = 'End Date Time';
            DataClassification = CustomerContent;
        }
        field(50; Room; Text[50])
        {
            Caption = 'Room';
            DataClassification = CustomerContent;
        }
        field(60; "Conference Day"; Integer)
        {
            Caption = 'Conference Day';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(70; Abstract; Text[250])
        {
            Caption = 'Abstract';
            DataClassification = CustomerContent;
        }
        field(80; "Average Rating"; Decimal)
        {
            Caption = 'Average Rating';
            DataClassification = CustomerContent;
            DecimalPlaces = 1 : 2;
            MinValue = 0;
            MaxValue = 5;
        }
        field(81; "Ratings Count"; Integer)
        {
            Caption = 'Ratings Count';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Session Code") { Clustered = true; }
        key(Track; Track, "Start Date Time") { }
        key(Speaker; "Speaker Code") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Session Code", Title, Room) { }
    }

    trigger OnInsert()
    begin
        TestField(Title);
    end;
}
