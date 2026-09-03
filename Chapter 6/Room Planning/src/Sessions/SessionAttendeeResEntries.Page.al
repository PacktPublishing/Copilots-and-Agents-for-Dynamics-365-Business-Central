page 50812 "Session Attendee Res. Entries"
{
    ApplicationArea = All;
    Caption = 'Session Attendee Reservation Entries';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "Session Attendee Res. Entry";
    SourceTableView = sorting("Entry No.");
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Session Code"; Rec."Session Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the session the attendee reserved.';
                }
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
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }
}
