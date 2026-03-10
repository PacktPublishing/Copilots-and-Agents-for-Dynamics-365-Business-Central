table 50502 "Field Mapping Proposal"
{
    Caption = 'Field Mapping Proposal';
    TableType = Temporary;

    fields
    {
        field(1; "Generation Id"; Integer)
        {
            Caption = 'Generation ID';
        }
        field(2; "Target Field No."; Integer)
        {
            Caption = 'Target Field No.';
        }
        field(3; "Target Field Name"; Text[100])
        {
            Caption = 'Target Field Name';
        }
        field(4; "Source Column Name"; Text[100])
        {
            Caption = 'Excel Column Name';
        }
        field(5; "Source Column No."; Integer)
        {
            Caption = 'Excel Column No.';
        }
    }

    keys
    {
        key(PK; "Generation Id", "Target Field No.")
        {
            Clustered = true;
        }
    }
}
