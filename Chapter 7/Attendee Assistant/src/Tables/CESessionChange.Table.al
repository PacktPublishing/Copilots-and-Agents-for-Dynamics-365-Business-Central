// ----------------------------------------------------------------------------
// Table 98204 - Session change
// Log of the changes organizers make to sessions that are already in the
// program. Filled automatically by codeunit "CE Session Change Log" (event
// subscriber on the Chapter 3 "Event Session" table), read by the attendee
// assistant through the sessionChanges MCP tool.
// ----------------------------------------------------------------------------
table 98204 "CE Session Change"
{
    Caption = 'Session Change';
    DataClassification = CustomerContent;
    LookupPageId = "CE Session Changes";
    DrillDownPageId = "CE Session Changes";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(5; "Event Project No."; Code[20])
        {
            Caption = 'Event Project No.';
            DataClassification = CustomerContent;
            TableRelation = Job."No.";
        }
        field(10; "Session Code"; Code[20])
        {
            Caption = 'Session Code';
            DataClassification = CustomerContent;
            TableRelation = "Event Session"."Code";
        }
        field(11; "Session Name"; Text[100])
        {
            Caption = 'Session Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup("Event Session".Name where("Code" = field("Session Code")));
        }
        field(20; "Change Type"; Enum "CE Session Change Type")
        {
            Caption = 'Change Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies what changed: the room, the schedule, the speaker, or the session was cancelled.';
        }
        field(30; "Old Value"; Text[100])
        {
            Caption = 'Old Value';
            DataClassification = CustomerContent;
        }
        field(31; "New Value"; Text[100])
        {
            Caption = 'New Value';
            DataClassification = CustomerContent;
        }
        field(40; "Changed At"; DateTime)
        {
            Caption = 'Changed At';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; Note; Text[250])
        {
            Caption = 'Note';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an optional message from the organizers that the assistant can show to attendees.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Session; "Event Project No.", "Session Code", "Changed At") { }
        key(ChangedAt; "Changed At") { }
    }

    trigger OnInsert()
    begin
        if "Changed At" = 0DT then
            "Changed At" := CurrentDateTime();
    end;
}
