page 50815 "Session Attendee Res. FactBox"
{
    ApplicationArea = All;
    Caption = 'Reservation Entries';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = ListPart;
    SourceTable = "Session Attendee Res. Entry";
    SourceTableView = sorting("Entry No.");

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Attendee Email"; Rec."Attendee Email")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address of the attendee who reserved the session.';
                }
                field("Reserved At"; Rec."Reserved At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the attendee reserved the session.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the entry, as assigned when the entry was created.';
                    Visible = false;
                }
            }
        }
    }
}
