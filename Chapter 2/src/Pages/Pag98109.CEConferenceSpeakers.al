

page 98109 "CE Conference Speakers"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Conference Speakers';
    SourceTable = "CE Conference Speaker";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Speaker Code"; Rec."Speaker Code") { ApplicationArea = All; }
                field("Full Name"; Rec."Full Name") { ApplicationArea = All; }
                field(Email; Rec.Email) { ApplicationArea = All; }
                field(Company; Rec.Company) { ApplicationArea = All; }
                field("Job Title"; Rec."Job Title") { ApplicationArea = All; }
                field("Presentation URL"; Rec."Presentation URL") { ApplicationArea = All; }
                field("Presentation Uploaded On"; Rec."Presentation Uploaded On") { ApplicationArea = All; }
            }
        }
    }
}
