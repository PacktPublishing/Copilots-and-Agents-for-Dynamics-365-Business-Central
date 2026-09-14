

page 98110 "CE Conference Sessions"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Conference Sessions';
    SourceTable = "CE Conference Session";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Session Code"; Rec."Session Code") { ApplicationArea = All; }
                field(Title; Rec.Title) { ApplicationArea = All; }
                field(Track; Rec.Track) { ApplicationArea = All; }
                field("Speaker Code"; Rec."Speaker Code") { ApplicationArea = All; }
                field("Speaker Name"; Rec."Speaker Name") { ApplicationArea = All; }
                field("Conference Day"; Rec."Conference Day") { ApplicationArea = All; }
                field("Start Date Time"; Rec."Start Date Time") { ApplicationArea = All; }
                field("End Date Time"; Rec."End Date Time") { ApplicationArea = All; }
                field(Room; Rec.Room) { ApplicationArea = All; }
                field("Average Rating"; Rec."Average Rating") { ApplicationArea = All; }
                field("Ratings Count"; Rec."Ratings Count") { ApplicationArea = All; }
            }
        }
    }
}
