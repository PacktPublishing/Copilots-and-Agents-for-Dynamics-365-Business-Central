

page 98111 "CE Events Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Cronus Events Setup';
    SourceTable = "CE Events Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Attendee Nos."; Rec."Attendee Nos.") { ApplicationArea = All; }
            }
            group(Speakers)
            {
                Caption = 'Speakers';
                field("Speaker Presentation Folder"; Rec."Speaker Presentation Folder") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InitSetup();
    end;
}
