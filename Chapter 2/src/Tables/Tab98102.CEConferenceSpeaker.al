



// ----------------------------------------------------------------------------
// Table 98102 - Conference speaker
// Read by the speaker-lookup skill and by the Speaker Portal agent.
// ----------------------------------------------------------------------------
table 98102 "CE Conference Speaker"
{
    Caption = 'Conference Speaker';
    DataClassification = CustomerContent;
    LookupPageId = "CE Conference Speakers";
    DrillDownPageId = "CE Conference Speakers";

    fields
    {
        field(1; "Speaker Code"; Code[20])
        {
            Caption = 'Speaker Code';
            DataClassification = CustomerContent;
        }
        field(10; "Full Name"; Text[100])
        {
            Caption = 'Full Name';
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
        field(40; "Job Title"; Text[100])
        {
            Caption = 'Job Title';
            DataClassification = CustomerContent;
        }
        field(50; Biography; Text[250])
        {
            Caption = 'Biography';
            DataClassification = CustomerContent;
        }
        field(60; "Presentation URL"; Text[250])
        {
            Caption = 'Presentation URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }
        field(70; "Presentation Uploaded On"; DateTime)
        {
            Caption = 'Presentation Uploaded On';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Speaker Code") { Clustered = true; }
        key(FullName; "Full Name") { }
        key(Email; Email) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Speaker Code", "Full Name", Company) { }
    }
}
