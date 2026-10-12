table 50100 "CRONUS Events RAG Setup"
{
    Caption = 'CRONUS Events RAG Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "Web Page URL"; Text[2048])
        {
            Caption = 'Web Page URL';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
