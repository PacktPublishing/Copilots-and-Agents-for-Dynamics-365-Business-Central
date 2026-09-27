// ----------------------------------------------------------------------------
// Codeunit 98206 - Attendee agenda management
// The rules of the attendee channel. They run when the assistant inserts a
// reservation through the agendaEntries API page, not on every insert into
// the Chapter 6 table, because that table also receives bulk reservations
// (demo data, imports) that must not be blocked by attendee rules.
// A rejected insert returns an error message the agent can relay.
// ----------------------------------------------------------------------------
codeunit 98206 "CE Attendee Agenda Mgt"
{
    procedure CheckCanReserve(var ReservationEntry: Record "Session Attendee Res. Entry")
    var
        Session: Record "Event Session";
    begin
        NormalizeEmail(ReservationEntry);
        ReservationEntry.TestField("Session Code");
        if not GetEventSession(ReservationEntry."Session Code", Session) then
            Error(SessionNotFoundErr, ReservationEntry."Session Code");
        case Session.Status of
            Session.Status::Draft:
                Error(SessionNotScheduledErr, Session.Name);
            Session.Status::Cancelled:
                Error(SessionCancelledErr, Session.Name);
            Session.Status::Completed:
                Error(SessionCompletedErr, Session.Name);
        end;
        CheckNotAlreadyInAgenda(ReservationEntry);
        CheckNoOverlap(ReservationEntry, Session);
        CheckRoomNotFull(Session);
        if ReservationEntry."Reserved At" = 0DT then
            ReservationEntry."Reserved At" := CurrentDateTime();
    end;

    /// <summary>
    /// Records the attendee's rating and refreshes the session's average.
    /// Called by the rateSession bound action of the agendaEntries API page.
    /// </summary>
    procedure RateSession(var ReservationEntry: Record "Session Attendee Res. Entry"; NewRating: Integer)
    var
        Session: Record "Event Session";
    begin
        if (NewRating < 1) or (NewRating > 5) then
            Error(RatingRangeErr);
        Session.Get(ReservationEntry."Session Code");
        if not SessionHasStarted(Session) then
            Error(NotStartedErr, Session.Name);
        ReservationEntry.Rating := NewRating;
        ReservationEntry."Rated At" := CurrentDateTime();
        ReservationEntry.Modify(true);
        RecalculateSessionRating(Session);
    end;

    /// <summary>
    /// Business Central work date and time, consistent with Chapter 6, which
    /// treats sessions before the work date as past.
    /// </summary>
    procedure SessionHasStarted(Session: Record "Event Session"): Boolean
    begin
        exit(CreateDateTime(Session."Date", Session."Start Time") <= CreateDateTime(WorkDate(), Time()));
    end;

    local procedure GetEventSession(SessionCode: Code[20]; var Session: Record "Event Session"): Boolean
    var
        AttendeeSetup: Record "CE Attendee Setup";
    begin
        if not Session.Get(SessionCode) then
            exit(false);
        exit(Session."Project Code" = AttendeeSetup.GetEventProjectNo());
    end;

    local procedure NormalizeEmail(var ReservationEntry: Record "Session Attendee Res. Entry")
    var
        Email: Text;
    begin
        Email := LowerCase(DelChr(ReservationEntry."Attendee Email", '<>', ' '));
        if (StrPos(Email, '@') < 2) or (StrPos(Email, '.') = 0) then
            Error(InvalidEmailErr, ReservationEntry."Attendee Email");
        ReservationEntry."Attendee Email" := CopyStr(Email, 1, MaxStrLen(ReservationEntry."Attendee Email"));
    end;

    local procedure CheckNotAlreadyInAgenda(ReservationEntry: Record "Session Attendee Res. Entry")
    var
        OtherEntry: Record "Session Attendee Res. Entry";
    begin
        OtherEntry.SetCurrentKey("Attendee Email", "Session Code");
        OtherEntry.SetRange("Attendee Email", ReservationEntry."Attendee Email");
        OtherEntry.SetRange("Session Code", ReservationEntry."Session Code");
        if not OtherEntry.IsEmpty() then
            Error(AlreadyInAgendaErr, ReservationEntry."Session Code");
    end;

    local procedure CheckNoOverlap(ReservationEntry: Record "Session Attendee Res. Entry"; Session: Record "Event Session")
    var
        OtherEntry: Record "Session Attendee Res. Entry";
        OtherSession: Record "Event Session";
    begin
        OtherEntry.SetCurrentKey("Attendee Email", "Session Code");
        OtherEntry.SetRange("Attendee Email", ReservationEntry."Attendee Email");
        if OtherEntry.FindSet() then
            repeat
                if OtherSession.Get(OtherEntry."Session Code") then
                    if (OtherSession.Status <> OtherSession.Status::Cancelled) and
                       (OtherSession."Date" = Session."Date") and
                       (Session."Start Time" < OtherSession."End Time") and
                       (Session."End Time" > OtherSession."Start Time")
                    then begin
                        OtherSession.CalcFields("Room Name");
                        Error(OverlapErr, Session.Name, OtherSession.Name, OtherSession."Room Name",
                              Format(OtherSession."Start Time", 0, '<Hours24>:<Minutes,2>'));
                    end;
            until OtherEntry.Next() = 0;
    end;

    local procedure CheckRoomNotFull(Session: Record "Event Session")
    var
        Room: Record Room;
    begin
        if Session."Room Code" = '' then
            exit;
        if not Room.Get(Session."Room Code") then
            exit;
        Session.CalcFields("Reserved Attendees");
        if Session."Reserved Attendees" >= Room.Capacity then
            Error(SessionFullErr, Session.Name, Room.Capacity);
    end;

    local procedure RecalculateSessionRating(var Session: Record "Event Session")
    var
        ReservationEntry: Record "Session Attendee Res. Entry";
        Total: Integer;
        RatedCount: Integer;
    begin
        ReservationEntry.SetCurrentKey("Session Code", "Reserved At");
        ReservationEntry.SetRange("Session Code", Session."Code");
        ReservationEntry.SetFilter(Rating, '>0');
        if ReservationEntry.FindSet() then
            repeat
                Total += ReservationEntry.Rating;
                RatedCount += 1;
            until ReservationEntry.Next() = 0;
        Session."Ratings Count" := RatedCount;
        if RatedCount > 0 then
            Session."Average Rating" := Total / RatedCount
        else
            Session."Average Rating" := 0;
        Session.Modify(false);
    end;

    var
        InvalidEmailErr: Label '%1 does not look like a valid email address.', Comment = '%1 = the email typed by the attendee';
        SessionNotFoundErr: Label 'There is no session %1 in the program of this event.', Comment = '%1 = session code';
        SessionNotScheduledErr: Label 'The session "%1" is not in the published program yet.', Comment = '%1 = session name';
        SessionCancelledErr: Label 'The session "%1" has been cancelled and cannot be added to an agenda.', Comment = '%1 = session name';
        SessionCompletedErr: Label 'The session "%1" has already taken place.', Comment = '%1 = session name';
        AlreadyInAgendaErr: Label 'Session %1 is already in this attendee''s agenda.', Comment = '%1 = session code';
        OverlapErr: Label 'The session "%1" overlaps with "%2" (%3, starts at %4), which is already in the agenda. Remove one of them first.', Comment = '%1 = new session name, %2 = existing session name, %3 = room name, %4 = start time';
        SessionFullErr: Label 'The session "%1" is full: all %2 seats are reserved.', Comment = '%1 = session name, %2 = room capacity';
        RatingRangeErr: Label 'The rating must be a number between 1 and 5.';
        NotStartedErr: Label 'The session "%1" has not started yet and cannot be rated.', Comment = '%1 = session name';
}
