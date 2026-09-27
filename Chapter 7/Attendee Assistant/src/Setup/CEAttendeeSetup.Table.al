// ----------------------------------------------------------------------------
// Table 98214 - Attendee assistant setup
// One record: the event project the attendee assistant serves. The attendee
// API pages filter on it, so the tools never need a project code argument and
// an agent published for one conference cannot read the sessions of another.
// ----------------------------------------------------------------------------
table 98214 "CE Attendee Setup"
{
    Caption = 'Attendee Assistant Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Event Project No."; Code[20])
        {
            Caption = 'Event Project No.';
            DataClassification = CustomerContent;
            TableRelation = Job."No.";
            ToolTip = 'Specifies the event project (Chapter 3 and Chapter 6) whose scheduled sessions the attendee assistant publishes.';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetEventProjectNo(): Code[20]
    begin
        if not Get() then
            Error(SetupMissingErr);
        TestField("Event Project No.");
        exit("Event Project No.");
    end;

    var
        SetupMissingErr: Label 'The attendee assistant is not set up yet. Ask the organizers to choose the event project on the Attendee Assistant Setup page.';
}
