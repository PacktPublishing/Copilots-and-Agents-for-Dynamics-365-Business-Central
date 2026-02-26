table 50402 "Event Project Proposal"
{
    Caption = 'Event Project Proposal';
    TableType = Temporary;

    fields
    {
        field(1; "Job Task No."; Code[10])
        {
            Caption = 'Job Task No.';
            Editable = false;
        }
        field(2; "Job Short Description"; Text[100])
        {
            Caption = 'Job Short Description';
        }
        field(4; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(3; "Job Full Description"; Blob)
        {
            Caption = 'Job Full Description';
        }
        field(100; "Task Description"; Text[100])
        {
            Caption = 'Task Description';
        }
        field(101; "Action Description Preview"; Text[100])
        {
            Caption = 'Action Description';
        }
        field(102; "Action Description"; Blob)
        {
            Caption = 'Action Description';
        }
        field(103; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(104; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(105; Type; Option)
        {
            Caption = 'Type';
            OptionMembers = Resource,Item,Both;
        }
        field(106; "Item Category"; Text[50])
        {
            Caption = 'Item Category';
        }
        field(107; "Resource Role Description"; Text[50])
        {
            Caption = 'Resource Role Description';
        }
        field(108; Indentation; Integer)
        {
            Editable = false;
        }
        field(109; "Job Task Type"; Enum "Job Task Type")
        {
            Caption = 'Job Task Type';
        }
    }

    keys
    {
        key(Key1; "Job Task No.")
        {
            Clustered = true;
        }
    }
}
