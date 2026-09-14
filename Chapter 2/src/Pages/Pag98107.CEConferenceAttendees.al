

page 98107 "CE Conference Attendees"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Conference Attendees';
    SourceTable = "CE Conference Attendee";
    CardPageId = "CE Conference Attendee Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Registration No."; Rec."Registration No.") { ApplicationArea = All; }
                field("First Name"; Rec."First Name") { ApplicationArea = All; }
                field("Last Name"; Rec."Last Name") { ApplicationArea = All; }
                field(Email; Rec.Email) { ApplicationArea = All; }
                field(Company; Rec.Company) { ApplicationArea = All; }
                field("Ticket Type"; Rec."Ticket Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Payment Link Sent"; Rec."Payment Link Sent") { ApplicationArea = All; }
                field("Registration Date"; Rec."Registration Date") { ApplicationArea = All; }
            }
        }
    }
}
