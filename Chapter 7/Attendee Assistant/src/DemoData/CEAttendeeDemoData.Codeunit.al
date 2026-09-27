// ----------------------------------------------------------------------------
// Codeunit 98213 - Attendee demo data
// Chapter 7 reuses the Chapter 6 demo: run "Set up venue and schedule" on the
// Event Demo Data page first (BC Tech Summit 2027, project TECH2027,
// 12 sessions on 11 June 2027, rooms HALL-A to LAB). PrepareDemoEvent selects
// that project and, for sessions the Room Planning Agent has not handled,
// sets an estimate and a room through the Chapter 6 validation.
// SimulateChanges produces the two changes of the "has anything changed?"
// scenario: a room move with a note and the cancellation of the keynote
// (the Chapter 6 "Cancel a session" action).
// ----------------------------------------------------------------------------
codeunit 98213 "CE Attendee Demo Data"
{
    var
        EventProjectNoTok: Label 'TECH2027', Locked = true;
        MissingDemoErr: Label 'Project TECH2027 does not exist. Run Set up venue and schedule on the Event Demo Data page (Chapter 6) first.';

    procedure PrepareDemoEvent()
    var
        Job: Record Job;
    begin
        if not Job.Get(EventProjectNoTok) then
            Error(MissingDemoErr);
        SelectEventProject();
        AssignRoom('T27-AI1', 'HALL-A', 200);
        AssignRoom('T27-FIN1', 'ROOM-102', 30);
        AssignRoom('T27-DEV1', 'ROOM-101', 60);
        AssignRoom('T27-KEY', 'HALL-A', 320);
        AssignRoom('T27-AI2', 'HALL-B', 100);
        AssignRoom('T27-OPS1', 'ROOM-101', 90);
        AssignRoom('T27-AI3', 'HALL-B', 110);
        AssignRoom('T27-FIN2', 'ROOM-102', 55);
        AssignRoom('T27-LAB', 'ROOM-201', 45);
        AssignRoom('T27-NEW', 'ROOM-201', 50);
        AssignRoom('T27-DEV2', 'ROOM-101', 40);
        AssignRoom('T27-OPS2', 'ROOM-102', 35);
    end;

    procedure SimulateChanges(): Integer
    var
        Session: Record "Event Session";
        SessionChange: Record "CE Session Change";
        ChapterSixDemoData: Codeunit "Event Demo Data";
        SessionChangeLog: Codeunit "CE Session Change Log";
        CountBefore: Integer;
    begin
        CountBefore := SessionChange.Count();
        if Session.Get('T27-DEV2') then
            if Session."Room Code" <> 'HALL-B' then begin
                Session.Validate("Room Code", 'HALL-B');
                Session.Modify(true);
                SessionChangeLog.AddNoteToLastChange(Session."Code", 'Projector failure in Room 101. Same time, Auditorium B on the ground floor.');
            end;
        ChapterSixDemoData.CancelKeynoteSession();
        exit(SessionChange.Count() - CountBefore);
    end;

    procedure ResetProgramChanges()
    var
        Session: Record "Event Session";
        SessionChange: Record "CE Session Change";
        SessionChangeLog: Codeunit "CE Session Change Log";
    begin
        SessionChangeLog.SetSuppressLogging(true);
        if Session.Get('T27-DEV2') then
            if Session."Room Code" <> 'ROOM-101' then begin
                Session.Validate("Room Code", 'ROOM-101');
                Session.Modify(true);
            end;
        if Session.Get('T27-KEY') then
            if Session.Status <> Session.Status::Scheduled then begin
                Session.Status := Session.Status::Scheduled;
                Session.Modify(true);
            end;
        SessionChangeLog.SetSuppressLogging(false);
        SessionChange.SetRange("Event Project No.", EventProjectNoTok);
        SessionChange.DeleteAll();
    end;

    local procedure SelectEventProject()
    var
        AttendeeSetup: Record "CE Attendee Setup";
    begin
        if not AttendeeSetup.Get() then begin
            AttendeeSetup.Init();
            AttendeeSetup.Insert();
        end;
        AttendeeSetup."Event Project No." := EventProjectNoTok;
        AttendeeSetup.Modify();
    end;

    local procedure AssignRoom(SessionCode: Code[20]; RoomCode: Code[20]; Estimate: Integer)
    var
        Session: Record "Event Session";
    begin
        if not Session.Get(SessionCode) then
            exit;
        if Session."Room Code" <> '' then
            exit;
        if Session."Estimated Attendees" = 0 then
            Session."Estimated Attendees" := Estimate;
        Session.Validate("Room Code", RoomCode);
        Session.Modify(true);
    end;
}
