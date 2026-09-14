

// Custom API - attendees (read + write; used by attendee-registration).
// Endpoint: .../api/cronusEvents/conference/v1.0/companies({companyId})/attendees
page 98104 "CE Attendee API"
{
    PageType = API;
    Caption = 'attendee', Locked = true;
    APIPublisher = 'cronusEvents';
    APIGroup = 'conference';
    APIVersion = 'v1.0';
    EntityName = 'attendee';
    EntitySetName = 'attendees';
    SourceTable = "CE Conference Attendee";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'systemId', Locked = true;
                    Editable = false;
                }
                field(registrationNo; Rec."Registration No.")
                {
                    Caption = 'registrationNo', Locked = true;
                    Editable = false;
                }
                field(firstName; Rec."First Name")
                {
                    Caption = 'firstName', Locked = true;
                }
                field(lastName; Rec."Last Name")
                {
                    Caption = 'lastName', Locked = true;
                }
                field(email; Rec.Email)
                {
                    Caption = 'email', Locked = true;
                }
                field(company; Rec.Company)
                {
                    Caption = 'company', Locked = true;
                }
                field(ticketType; Rec."Ticket Type")
                {
                    Caption = 'ticketType', Locked = true;
                }
                field(status; Rec.Status)
                {
                    Caption = 'status', Locked = true;
                }
                field(registrationDate; Rec."Registration Date")
                {
                    Caption = 'registrationDate', Locked = true;
                    Editable = false;
                }
                field(paymentLinkSent; Rec."Payment Link Sent")
                {
                    Caption = 'paymentLinkSent', Locked = true;
                }
            }
        }
    }
}
