
// ----------------------------------------------------------------------------
// Table 98101 - Conference attendee
// Written by the attendee-registration skill through the conference API.
// ----------------------------------------------------------------------------
table 98101 "CE Conference Attendee"
{
    Caption = 'Conference Attendee';
    DataClassification = CustomerContent;
    LookupPageId = "CE Conference Attendees";
    DrillDownPageId = "CE Conference Attendees";

    fields
    {
        field(1; "Registration No."; Code[20])
        {
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
        }
        field(10; "First Name"; Text[50])
        {
            Caption = 'First Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(11; "Last Name"; Text[50])
        {
            Caption = 'Last Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(20; Email; Text[80])
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
        field(30; Company; Text[100])
        {
            Caption = 'Company';
            DataClassification = CustomerContent;
        }
        field(40; Status; Enum "CE Registration Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(50; "Registration Date"; DateTime)
        {
            Caption = 'Registration Date';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(60; "Ticket Type"; Text[30])
        {
            Caption = 'Ticket Type';
            DataClassification = CustomerContent;
        }
        field(70; "Payment Link Sent"; Boolean)
        {
            Caption = 'Payment Link Sent';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Registration No.") { Clustered = true; }
        key(Email; Email) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Registration No.", "First Name", "Last Name", Company) { }
    }

    trigger OnInsert()
    var
        EventsSetup: Record "CE Events Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "Registration No." = '' then begin
            EventsSetup.Get();
            EventsSetup.TestField("Attendee Nos.");
            "Registration No." := NoSeries.GetNextNo(EventsSetup."Attendee Nos.");
        end;

        if "Registration Date" = 0DT then
            "Registration Date" := CurrentDateTime();
    end;
}