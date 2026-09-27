// ----------------------------------------------------------------------------
// Page 98207 - Attendee Agenda (custom API, read + create + delete + action)
// The attendee's personal agenda: the Chapter 6 reservations of one attendee
// email. Create and delete are allowed; modify is not, because a session is
// either in the agenda or it is not. The attendee rules run in
// OnInsertRecord (codeunit "CE Attendee Agenda Mgt").
// MCP tools (29.0): List_AgendaEntries_PAG98207, Create_AgendaEntry_PAG98207,
//            Delete_AgendaEntry_PAG98207, RateSession_AgendaEntries_PAG98207
// ----------------------------------------------------------------------------
page 98207 "Attendee Agenda"
{
    PageType = API;
    Caption = 'Agenda Entry';
    EntityCaption = 'Agenda Entry';
    EntitySetCaption = 'Personal agenda of an attendee: one entry per reserved session, filtered by attendee email';
    APIPublisher = 'cronusEvents';
    APIGroup = 'attendee';
    APIVersion = 'v1.0';
    EntityName = 'agendaEntry';
    EntitySetName = 'agendaEntries';
    SourceTable = "Session Attendee Res. Entry";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Caption = 'id', Locked = true; Editable = false; }
                field(attendeeEmail; Rec."Attendee Email") { Caption = 'attendeeEmail', Locked = true; }
                field(sessionCode; Rec."Session Code") { Caption = 'sessionCode', Locked = true; }
                field(sessionTitle; Rec."Session Name") { Caption = 'sessionTitle', Locked = true; Editable = false; }
                field(sessionDate; Rec."Session Date") { Caption = 'sessionDate', Locked = true; Editable = false; }
                field(startTime; Rec."Start Time") { Caption = 'startTime', Locked = true; Editable = false; }
                field(endTime; Rec."End Time") { Caption = 'endTime', Locked = true; Editable = false; }
                field(room; RoomName) { Caption = 'room', Locked = true; Editable = false; }
                field(sessionStatus; Rec."Session Status") { Caption = 'sessionStatus', Locked = true; Editable = false; }
                field(reservedAt; Rec."Reserved At") { Caption = 'reservedAt', Locked = true; Editable = false; }
                field(rating; Rec.Rating) { Caption = 'rating', Locked = true; Editable = false; }
            }
        }
    }

    /// <summary>
    /// Bound action: records the attendee's rating (1-5) for the session of this
    /// agenda entry and refreshes the Average Rating and Ratings Count of the
    /// event session.
    /// POST .../agendaEntries({id})/Microsoft.NAV.rateSession  { "rating": 5 }
    /// </summary>
    [ServiceEnabled]
    procedure rateSession(var ActionContext: WebServiceActionContext; rating: Integer)
    var
        AgendaMgt: Codeunit "CE Attendee Agenda Mgt";
    begin
        AgendaMgt.RateSession(Rec, rating);
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Attendee Agenda");
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    trigger OnOpenPage()
    var
        AttendeeSetup: Record "CE Attendee Setup";
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Event Project No.", AttendeeSetup.GetEventProjectNo());
        Rec.FilterGroup(0);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        AgendaMgt: Codeunit "CE Attendee Agenda Mgt";
    begin
        AgendaMgt.CheckCanReserve(Rec);
        Rec.Insert(false);
        RefreshDerivedValues();
        exit(false);
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshDerivedValues();
    end;

    // OnAfterGetRecord does not run for the record returned after an insert,
    // so OnInsertRecord calls this too.
    local procedure RefreshDerivedValues()
    var
        SessionRoom: Record Room;
    begin
        Rec.CalcFields("Session Name", "Session Date", "Start Time", "End Time", "Room Code", "Session Status");
        RoomName := '';
        if SessionRoom.Get(Rec."Room Code") then
            RoomName := SessionRoom.Name;
    end;

    var
        RoomName: Text[100];
}
