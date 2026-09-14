

// Custom API - speakers (read; write limited to the presentation URL).
// Used by speaker-lookup, speaker-authentication and presentation-upload.
page 98105 "CE Speaker API"
{
    PageType = API;
    Caption = 'speaker', Locked = true;
    APIPublisher = 'cronusEvents';
    APIGroup = 'conference';
    APIVersion = 'v1.0';
    EntityName = 'speaker';
    EntitySetName = 'speakers';
    SourceTable = "CE Conference Speaker";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = true;
    InsertAllowed = false;
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
                field(speakerCode; Rec."Speaker Code")
                {
                    Caption = 'speakerCode', Locked = true;
                    Editable = false;
                }
                field(fullName; Rec."Full Name")
                {
                    Caption = 'fullName', Locked = true;
                    Editable = false;
                }
                field(email; Rec.Email)
                {
                    Caption = 'email', Locked = true;
                    Editable = false;
                }
                field(company; Rec.Company)
                {
                    Caption = 'company', Locked = true;
                    Editable = false;
                }
                field(jobTitle; Rec."Job Title")
                {
                    Caption = 'jobTitle', Locked = true;
                    Editable = false;
                }
                field(biography; Rec.Biography)
                {
                    Caption = 'biography', Locked = true;
                    Editable = false;
                }
                field(presentationUrl; Rec."Presentation URL")
                {
                    Caption = 'presentationUrl', Locked = true;
                }
                field(presentationUploadedOn; Rec."Presentation Uploaded On")
                {
                    Caption = 'presentationUploadedOn', Locked = true;
                }
            }
        }
    }
}
