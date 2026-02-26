table 50503 "Mapping Generation History"
{
    Caption = 'Mapping Generation History';
    TableType = Temporary;

    fields
    {
        field(1; "Generation Id"; Integer)
        {
            Caption = 'Generation ID';
        }
        field(2; "Data Exposure"; Enum "Data Exposure")
        {
            Caption = 'Data Exposure';
        }
    }

    keys
    {
        key(PK; "Generation Id")
        {
            Clustered = true;
        }
    }
}
