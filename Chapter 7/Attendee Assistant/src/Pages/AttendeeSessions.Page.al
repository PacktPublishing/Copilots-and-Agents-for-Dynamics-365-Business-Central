// ----------------------------------------------------------------------------
// Page 98205 - Attendee Sessions (custom API, read only)
// The published program of one event over "Event Session" (Chapter 3) with
// the room of Chapter 6: only the project selected in "CE Attendee Setup",
// never Draft sessions, and only fields an attendee needs, named so a model
// can relate them to the attendee's question. Speaker1 is published as
// speakerName, the room by name and floor. Track No. (a scheduling column),
// attendee figures and ratings stay out.
// MCP tool (29.0): List_AttendeeSessions_PAG98205
// Endpoint: .../api/cronusEvents/attendee/v1.0/companies({id})/attendeeSessions
// ----------------------------------------------------------------------------
page 98205 "Attendee Sessions"
{
    PageType = API;
    Caption = 'Attendee Session';
    EntityCaption = 'Attendee Session';
    EntitySetCaption = 'Published program of the event: sessions with title, speaker, date, start and end time, and room';
    APIPublisher = 'cronusEvents';
    APIGroup = 'attendee';
    APIVersion = 'v1.0';
    EntityName = 'attendeeSession';
    EntitySetName = 'attendeeSessions';
    SourceTable = "Event Session";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'id', Locked = true; }
                field(sessionCode; Rec."Code") { Caption = 'sessionCode', Locked = true; }
                field(title; Rec.Name) { Caption = 'title', Locked = true; }
                field(speakerName; Rec.Speaker1) { Caption = 'speakerName', Locked = true; }
                field(sessionDate; Rec."Date") { Caption = 'sessionDate', Locked = true; }
                field(startTime; Rec."Start Time") { Caption = 'startTime', Locked = true; }
                field(endTime; Rec."End Time") { Caption = 'endTime', Locked = true; }
                field(room; Rec."Room Name") { Caption = 'room', Locked = true; }
                field(floor; Rec."Room Floor") { Caption = 'floor', Locked = true; }
                field(status; Rec.Status) { Caption = 'status', Locked = true; }
                field(lastChangedAt; Rec."Last Changed At") { Caption = 'lastChangedAt', Locked = true; }
                field(abstract; Rec.Description) { Caption = 'abstract', Locked = true; }
            }
        }
    }

    trigger OnOpenPage()
    var
        AttendeeSetup: Record "CE Attendee Setup";
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Project Code", AttendeeSetup.GetEventProjectNo());
        Rec.SetFilter(Status, '<>%1', Rec.Status::Draft);
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Room Name", "Room Floor");
    end;
}
