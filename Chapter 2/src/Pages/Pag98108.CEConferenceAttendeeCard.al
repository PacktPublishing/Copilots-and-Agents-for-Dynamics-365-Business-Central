

page 98108 "CE Conference Attendee Card"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Conference Attendee';
    SourceTable = "CE Conference Attendee";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Registration No."; Rec."Registration No.") { ApplicationArea = All; }
                field("First Name"; Rec."First Name") { ApplicationArea = All; }
                field("Last Name"; Rec."Last Name") { ApplicationArea = All; }
                field(Email; Rec.Email) { ApplicationArea = All; }
                field(Company; Rec.Company) { ApplicationArea = All; }
            }
            group(Registration)
            {
                Caption = 'Registration';
                field("Ticket Type"; Rec."Ticket Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Payment Link Sent"; Rec."Payment Link Sent") { ApplicationArea = All; }
                field("Registration Date"; Rec."Registration Date") { ApplicationArea = All; }
            }
        }
    }
}
