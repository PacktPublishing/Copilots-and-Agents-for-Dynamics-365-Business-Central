// ----------------------------------------------------------------------------
// Table 98100 - Events setup (No. Series for attendee registrations)
// ----------------------------------------------------------------------------

table 98100 "CE Events Setup"
{
    Caption = 'Cronus Events Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Attendee Nos."; Code[20])
        {
            Caption = 'Attendee Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(20; "Speaker Presentation Folder"; Text[250])
        {
            Caption = 'Speaker Presentation Folder';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure InitSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}
