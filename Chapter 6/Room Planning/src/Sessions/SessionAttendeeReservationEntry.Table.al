table 50802 "Session Attendee Res. Entry"
{
    Caption = 'Session Attendee Reservation Entry';
    DataCaptionFields = "Entry No.", "Session Code";
    DataClassification = CustomerContent;
    DrillDownPageId = "Session Attendee Res. Entries";
    LookupPageId = "Session Attendee Res. Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned when the entry was created.';
        }
        field(2; "Session Code"; Code[20])
        {
            Caption = 'Session Code';
            NotBlank = true;
            TableRelation = "Event Session";
            ToolTip = 'Specifies the session the attendee reserved.';
        }
        field(3; "Attendee Email"; Text[80])
        {
            Caption = 'Attendee Email';
            NotBlank = true;
            ToolTip = 'Specifies the email address of the attendee who reserved the session.';
        }
        field(4; "Reserved At"; DateTime)
        {
            Caption = 'Reserved At';
            ToolTip = 'Specifies when the attendee reserved the session.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Session; "Session Code", "Reserved At")
        {
        }
        key(Attendee; "Attendee Email", "Session Code")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec.TestField("Session Code");
        Rec.TestField("Attendee Email");
        if Rec."Reserved At" = 0DT then
            Rec."Reserved At" := CurrentDateTime();
    end;

    procedure GetLastEntryNo(): Integer
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")));
    end;
}
