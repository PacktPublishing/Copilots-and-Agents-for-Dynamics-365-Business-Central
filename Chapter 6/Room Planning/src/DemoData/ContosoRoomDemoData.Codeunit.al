codeunit 50827 "Contoso Room Demo Data"
{
    /// <summary>
    /// Creates rooms, jobs, last year's completed sessions with reservations, and the 2027 schedule.
    /// This year's rooms stay unassigned and this year's reservations stay empty.
    /// </summary>
    procedure GenerateVenueAndSchedule()
    begin
        CreateRooms();
        CreateJobs();
        CreateHistory2024();
        CreateHistory2025();
        CreateHistory2026();
        GenerateHistoryReservations();
        CreateScheduled2027();
    end;

    /// <summary>
    /// Adds conference-app reservations on the 2027 sessions. Idempotent.
    /// </summary>
    procedure GenerateReservations()
    begin
        CreateReservationCount('T27-AI1', 200);
        CreateReservationCount('T27-OPS1', 90);
        CreateReservationCount('T27-LAB', 45);
        CreateReservationCount('T27-FIN2', 55);
        CreateReservationCount('T27-KEY', 320);
        CreateReservationCount('T27-AI2', 100);
        CreateReservationCount('T27-AI3', 110);
        CreateReservationCount('T27-FIN1', 28);
        CreateReservationCount('T27-DEV1', 55);
        CreateReservationCount('T27-DEV2', 40);
        CreateReservationCount('T27-OPS2', 35);
        CreateReservationCount('T27-NEW', 50);
    end;

    /// <summary>
    /// Cancels the opening keynote. Does not clear Room Code.
    /// </summary>
    procedure CancelKeynoteSession()
    var
        EventSession: Record "Event Session";
    begin
        if not EventSession.Get('T27-KEY') then
            exit;
        EventSession.Status := EventSession.Status::Cancelled;
        EventSession.Modify(true);
    end;

    /// <summary>
    /// Writes Actual Attendees on TECH2027 day-one sessions that still have zero.
    /// </summary>
    procedure FillDayOneActuals()
    var
        EventSession: Record "Event Session";
        Demand: Integer;
    begin
        EventSession.SetRange("Project Code", 'TECH2027');
        EventSession.SetRange("Date", DMY2Date(11, 6, 2027));
        EventSession.SetRange("Actual Attendees", 0);
        if EventSession.FindSet() then
            repeat
                EventSession.CalcFields("Reserved Attendees");
                if EventSession."Reserved Attendees" > 0 then
                    Demand := EventSession."Reserved Attendees"
                else
                    Demand := EventSession."Estimated Attendees";
                EventSession."Actual Attendees" := Round(Demand * ShowUpRatio(EventSession."Start Time"), 1);
                EventSession.Modify(true);
            until EventSession.Next() = 0;
    end;

    /// <summary>
    /// Deletes rooms, demo sessions, reservation entries, and the TECH20xx jobs when nothing else holds them.
    /// </summary>
    procedure DeleteDemoData()
    begin
        DeleteDemoReservations();
        DeleteDemoSessions();
        DeleteDemoRooms();
        DeleteDemoJob('TECH2024');
        DeleteDemoJob('TECH2025');
        DeleteDemoJob('TECH2026');
        DeleteDemoJob('TECH2027');
    end;

    local procedure DeleteDemoReservations()
    var
        EventSession: Record "Event Session";
        ReservationEntry: Record "Session Attendee Res. Entry";
    begin
        SetDemoSessionFilter(EventSession);
        if EventSession.FindSet() then
            repeat
                ReservationEntry.SetRange("Session Code", EventSession."Code");
                ReservationEntry.DeleteAll();
            until EventSession.Next() = 0;
    end;

    local procedure DeleteDemoSessions()
    var
        EventSession: Record "Event Session";
    begin
        SetDemoSessionFilter(EventSession);
        EventSession.DeleteAll();
    end;

    local procedure DeleteDemoRooms()
    begin
        DeleteDemoRoom('HALL-A');
        DeleteDemoRoom('HALL-B');
        DeleteDemoRoom('ROOM-101');
        DeleteDemoRoom('ROOM-102');
        DeleteDemoRoom('ROOM-201');
        DeleteDemoRoom('LAB');
    end;

    local procedure DeleteDemoRoom(RoomCode: Code[20])
    var
        Room: Record Room;
    begin
        if Room.Get(RoomCode) then
            Room.Delete(true);
    end;

    local procedure DeleteDemoJob(JobNo: Code[20])
    var
        Job: Record Job;
    begin
        if not Job.Get(JobNo) then
            exit;
        if not TryDeleteJob(Job) then
            exit;
    end;

    [TryFunction]
    local procedure TryDeleteJob(var Job: Record Job)
    begin
        Job.Delete(true);
    end;

    local procedure SetDemoSessionFilter(var EventSession: Record "Event Session")
    begin
        EventSession.SetFilter("Project Code", '%1|%2|%3|%4', 'TECH2024', 'TECH2025', 'TECH2026', 'TECH2027');
    end;

    local procedure CreateRooms()
    begin
        CreateRoom('HALL-A', 'Auditorium A', 400, 0, true);
        CreateRoom('HALL-B', 'Auditorium B', 250, 0, true);
        CreateRoom('ROOM-101', 'Room 101', 120, 1, true);
        CreateRoom('ROOM-102', 'Room 102', 60, 1, false);
        CreateRoom('ROOM-201', 'Room 201', 60, 2, false);
        CreateRoom('LAB', 'Workshop Lab', 30, 2, false);
    end;

    local procedure CreateRoom(RoomCode: Code[20]; RoomName: Text[100]; Capacity: Integer; FloorNo: Integer; HasRecording: Boolean)
    var
        Room: Record Room;
    begin
        if Room.Get(RoomCode) then
            exit;
        Room.Init();
        Room."Code" := RoomCode;
        Room.Name := RoomName;
        Room.Capacity := Capacity;
        Room.Floor := FloorNo;
        Room."Has Recording" := HasRecording;
        Room.Insert(true);
    end;

    local procedure CreateJobs()
    begin
        CreateJob('TECH2024', 'BC Tech Summit 2024', DMY2Date(13, 6, 2024), DMY2Date(14, 6, 2024));
        CreateJob('TECH2025', 'BC Tech Summit 2025', DMY2Date(12, 6, 2025), DMY2Date(13, 6, 2025));
        CreateJob('TECH2026', 'BC Tech Summit 2026', DMY2Date(11, 6, 2026), DMY2Date(12, 6, 2026));
        CreateJob('TECH2027', 'BC Tech Summit 2027', DMY2Date(11, 6, 2027), DMY2Date(12, 6, 2027));
    end;

    local procedure CreateJob(JobNo: Code[20]; JobDescription: Text[100]; StartingDate: Date; EndingDate: Date)
    var
        Job: Record Job;
    begin
        if Job.Get(JobNo) then
            exit;
        Job.Init();
        Job."No." := JobNo;
        Job.Description := JobDescription;
        Job."Starting Date" := StartingDate;
        Job."Ending Date" := EndingDate;
        Job.Insert(true);
    end;

    local procedure CreateHistory2024()
    var
        EventSession: Record "Event Session";
        DayOne: Date;
        DayTwo: Date;
    begin
        DayOne := DMY2Date(13, 6, 2024);
        DayTwo := DMY2Date(14, 6, 2024);

        InitHistorySession(EventSession, 'T24-AI1', DayOne, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 110, 105, 'ROOM-101');
        InitHistorySession(EventSession, 'T24-FIN1', DayOne, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 50, 35, 'ROOM-102');
        InitHistorySession(EventSession, 'T24-DEV1', DayOne, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 80, 56, 'HALL-B');

        InitHistorySession(EventSession, 'T24-KEY', DayOne, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 400, 350, 'HALL-A');
        InitHistorySession(EventSession, 'T24-AI2', DayOne, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 220, 154, 'HALL-B');
        InitHistorySession(EventSession, 'T24-OPS1', DayOne, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 90, 63, 'ROOM-101');

        InitHistorySession(EventSession, 'T24-AI3', DayOne, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 250, 150, 'HALL-B');
        InitHistorySession(EventSession, 'T24-FIN2', DayOne, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 60, 36, 'ROOM-102');
        InitHistorySession(EventSession, 'T24-LAB', DayOne, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 30, 18, 'LAB');

        InitHistorySession(EventSession, 'T24-DEV2', DayOne, 143000T, 'TECH2024');
        CreateHistorySession(EventSession, 70, 35, 'ROOM-101');
        InitHistorySession(EventSession, 'T24-OPS2', DayOne, 143000T, 'TECH2024');
        CreateHistorySession(EventSession, 60, 30, 'ROOM-201');

        InitHistorySession(EventSession, 'T24-AI4', DayTwo, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 220, 154, 'HALL-B');
        InitHistorySession(EventSession, 'T24-OPS3', DayTwo, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 80, 56, 'ROOM-101');
        InitHistorySession(EventSession, 'T24-KEY2', DayTwo, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 400, 360, 'HALL-A');
        InitHistorySession(EventSession, 'T24-FIN3', DayTwo, 143000T, 'TECH2024');
        CreateHistorySession(EventSession, 80, 40, 'ROOM-101');
    end;

    local procedure CreateHistory2025()
    var
        EventSession: Record "Event Session";
        DayOne: Date;
        DayTwo: Date;
    begin
        DayOne := DMY2Date(12, 6, 2025);
        DayTwo := DMY2Date(13, 6, 2025);

        InitHistorySession(EventSession, 'T25-AI1', DayOne, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 115, 112, 'ROOM-101');
        InitHistorySession(EventSession, 'T25-FIN1', DayOne, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 52, 37, 'ROOM-102');
        InitHistorySession(EventSession, 'T25-DEV1', DayOne, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 85, 60, 'HALL-B');

        InitHistorySession(EventSession, 'T25-KEY', DayOne, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 400, 380, 'HALL-A');
        InitHistorySession(EventSession, 'T25-AI2', DayOne, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 220, 160, 'HALL-B');
        InitHistorySession(EventSession, 'T25-OPS1', DayOne, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 95, 67, 'ROOM-101');

        InitHistorySession(EventSession, 'T25-AI3', DayOne, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 250, 155, 'HALL-B');
        InitHistorySession(EventSession, 'T25-FIN2', DayOne, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 60, 36, 'ROOM-102');
        InitHistorySession(EventSession, 'T25-LAB', DayOne, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 30, 18, 'LAB');

        InitHistorySession(EventSession, 'T25-DEV2', DayOne, 143000T, 'TECH2025');
        CreateHistorySession(EventSession, 72, 36, 'ROOM-101');
        InitHistorySession(EventSession, 'T25-OPS2', DayOne, 143000T, 'TECH2025');
        CreateHistorySession(EventSession, 60, 30, 'ROOM-201');

        InitHistorySession(EventSession, 'T25-AI4', DayTwo, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 230, 161, 'HALL-B');
        InitHistorySession(EventSession, 'T25-OPS3', DayTwo, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 85, 60, 'ROOM-101');
        InitHistorySession(EventSession, 'T25-KEY2', DayTwo, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 400, 370, 'HALL-A');
        InitHistorySession(EventSession, 'T25-FIN3', DayTwo, 143000T, 'TECH2025');
        CreateHistorySession(EventSession, 82, 41, 'ROOM-101');
    end;

    local procedure CreateHistory2026()
    var
        EventSession: Record "Event Session";
        DayOne: Date;
        DayTwo: Date;
    begin
        DayOne := DMY2Date(11, 6, 2026);
        DayTwo := DMY2Date(12, 6, 2026);

        InitHistorySession(EventSession, 'T26-AI1', DayOne, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 120, 118, 'ROOM-101');
        InitHistorySession(EventSession, 'T26-FIN1', DayOne, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 54, 38, 'ROOM-102');
        InitHistorySession(EventSession, 'T26-DEV1', DayOne, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 88, 62, 'HALL-B');

        InitHistorySession(EventSession, 'T26-KEY', DayOne, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 400, 375, 'HALL-A');
        InitHistorySession(EventSession, 'T26-AI2', DayOne, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 230, 165, 'HALL-B');
        InitHistorySession(EventSession, 'T26-OPS1', DayOne, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 98, 70, 'ROOM-101');

        InitHistorySession(EventSession, 'T26-AI3', DayOne, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 250, 150, 'HALL-B');
        InitHistorySession(EventSession, 'T26-FIN2', DayOne, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 60, 36, 'ROOM-102');
        InitHistorySession(EventSession, 'T26-LAB', DayOne, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 30, 18, 'LAB');

        InitHistorySession(EventSession, 'T26-DEV2', DayOne, 143000T, 'TECH2026');
        CreateHistorySession(EventSession, 74, 37, 'ROOM-101');
        InitHistorySession(EventSession, 'T26-OPS2', DayOne, 143000T, 'TECH2026');
        CreateHistorySession(EventSession, 60, 30, 'ROOM-201');

        InitHistorySession(EventSession, 'T26-AI4', DayTwo, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 235, 164, 'HALL-B');
        InitHistorySession(EventSession, 'T26-OPS3', DayTwo, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 88, 62, 'ROOM-101');
        InitHistorySession(EventSession, 'T26-KEY2', DayTwo, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 400, 372, 'HALL-A');
        InitHistorySession(EventSession, 'T26-FIN3', DayTwo, 143000T, 'TECH2026');
        CreateHistorySession(EventSession, 84, 42, 'ROOM-101');
    end;

    local procedure CreateScheduled2027()
    var
        DayOne: Date;
    begin
        DayOne := DMY2Date(11, 6, 2027);
        CreateScheduledSession('T27-AI1', DayOne, 090000T);
        CreateScheduledSession('T27-FIN1', DayOne, 090000T);
        CreateScheduledSession('T27-DEV1', DayOne, 090000T);
        CreateScheduledSession('T27-KEY', DayOne, 103000T);
        CreateScheduledSession('T27-AI2', DayOne, 103000T);
        CreateScheduledSession('T27-OPS1', DayOne, 103000T);
        CreateScheduledSession('T27-AI3', DayOne, 130000T);
        CreateScheduledSession('T27-FIN2', DayOne, 130000T);
        CreateScheduledSession('T27-LAB', DayOne, 130000T);
        CreateScheduledSession('T27-NEW', DayOne, 143000T);
        CreateScheduledSession('T27-DEV2', DayOne, 143000T);
        CreateScheduledSession('T27-OPS2', DayOne, 143000T);
    end;

    local procedure InitHistorySession(var EventSession: Record "Event Session"; SessionCode: Code[20]; EventDate: Date; StartTime: Time; ProjectCode: Code[20])
    begin
        EventSession.Init();
        EventSession."Code" := SessionCode;
        EventSession."Date" := EventDate;
        EventSession."Start Time" := StartTime;
        EventSession."End Time" := SlotEnd(StartTime);
        EventSession."Duration (min)" := 60;
        EventSession.Status := EventSession.Status::Completed;
        EventSession."Project Code" := ProjectCode;
        ApplyCatalog(EventSession);
    end;

    local procedure CreateHistorySession(var EventSession: Record "Event Session"; EstimatedAttendees: Integer; ActualAttendees: Integer; RoomCode: Code[20])
    begin
        EventSession."Estimated Attendees" := EstimatedAttendees;
        EventSession."Actual Attendees" := ActualAttendees;
        EventSession."Room Code" := RoomCode;
        CreateSession(EventSession);
    end;

    local procedure CreateScheduledSession(SessionCode: Code[20]; EventDate: Date; StartTime: Time)
    var
        EventSession: Record "Event Session";
    begin
        EventSession.Init();
        EventSession."Code" := SessionCode;
        EventSession."Date" := EventDate;
        EventSession."Start Time" := StartTime;
        EventSession."End Time" := SlotEnd(StartTime);
        EventSession."Duration (min)" := 60;
        EventSession.Status := EventSession.Status::Scheduled;
        EventSession."Project Code" := 'TECH2027';
        ApplyCatalog(EventSession);
        CreateSession(EventSession);
    end;

    local procedure CreateSession(var EventSession: Record "Event Session")
    var
        ExistingSession: Record "Event Session";
    begin
        if ExistingSession.Get(EventSession."Code") then
            exit;
        EventSession.Insert(true);
    end;

    local procedure ApplyCatalog(var EventSession: Record "Event Session")
    var
        SessionSuffix: Code[20];
    begin
        SessionSuffix := CopyStr(EventSession."Code", 5);
        case SessionSuffix of
            'AI1':
                SetCatalog(EventSession, 'Copilot in AL: Patterns That Ship', 'Maya Chen', 1);
            'FIN1':
                SetCatalog(EventSession, 'Month-End Close in Business Central', 'Priya Nair', 2);
            'DEV1':
                SetCatalog(EventSession, 'Extending Base App Without Breaking Upgrades', 'Sam Okonkwo', 3);
            'KEY':
                SetCatalog(EventSession, 'Opening Keynote: The Next Decade of Business Central', 'Alex Rivera', 1);
            'AI2':
                SetCatalog(EventSession, 'Building Custom Agents', 'Maya Chen', 2);
            'OPS1':
                SetCatalog(EventSession, 'Go-Live Playbook', 'Chris Berg', 3);
            'AI3':
                SetCatalog(EventSession, 'PromptDialog vs Agents', 'Maya Chen', 1);
            'FIN2':
                SetCatalog(EventSession, 'Financial Reporting Layouts', 'Priya Nair', 2);
            'LAB':
                SetCatalog(EventSession, 'Hands-on: Build Your First Agent', 'Taylor Ng', 3);
            'NEW':
                SetCatalog(EventSession, 'Industry Cloud for ISVs', 'Jordan Blake', 1);
            'DEV2':
                SetCatalog(EventSession, 'Testing AL with AI Test Toolkit', 'Sam Okonkwo', 2);
            'OPS2':
                SetCatalog(EventSession, 'Support After Go-Live', 'Chris Berg', 3);
            'AI4':
                SetCatalog(EventSession, 'Copilot Studio for BC Consultants', 'Maya Chen', 1);
            'OPS3':
                SetCatalog(EventSession, 'Cutover Weekend Checklist', 'Chris Berg', 2);
            'KEY2':
                SetCatalog(EventSession, 'Closing Keynote: What We Learned', 'Alex Rivera', 1);
            'FIN3':
                SetCatalog(EventSession, 'Dimensional Analysis for Controllers', 'Priya Nair', 3);
        end;
    end;

    local procedure SetCatalog(var EventSession: Record "Event Session"; SessionName: Text[100]; SpeakerName: Text[250]; TrackNo: Integer)
    begin
        EventSession.Name := SessionName;
        EventSession.Description := SessionName;
        EventSession.Speaker1 := SpeakerName;
        EventSession."Track No." := TrackNo;
    end;

    local procedure GenerateHistoryReservations()
    var
        EventSession: Record "Event Session";
    begin
        EventSession.SetFilter("Project Code", '%1|%2|%3', 'TECH2024', 'TECH2025', 'TECH2026');
        EventSession.SetRange(Status, EventSession.Status::Completed);
        if EventSession.FindSet() then
            repeat
                CreateReservationCount(EventSession."Code", HistoryReservationCount(EventSession));
            until EventSession.Next() = 0;
    end;

    local procedure HistoryReservationCount(EventSession: Record "Event Session"): Integer
    var
        ReservedCount: Integer;
    begin
        if EventSession."Actual Attendees" <= 0 then
            exit(EventSession."Estimated Attendees");

        ReservedCount := Round(EventSession."Actual Attendees" / ShowUpRatio(EventSession."Start Time"), 1);
        if ReservedCount < EventSession."Actual Attendees" then
            exit(EventSession."Actual Attendees");
        exit(ReservedCount);
    end;

    local procedure CreateReservationCount(SessionCode: Code[20]; ReservationCount: Integer)
    var
        EventSession: Record "Event Session";
        Index: Integer;
        Email: Text[80];
        ReservedAt: DateTime;
    begin
        if ReservationCount <= 0 then
            exit;

        ReservedAt := CurrentDateTime();
        if EventSession.Get(SessionCode) then
            if (EventSession.Date <> 0D) and (EventSession.Date < WorkDate()) then
                ReservedAt := CreateDateTime(CalcDate('<-2W>', EventSession.Date), 100000T);

        for Index := 1 to ReservationCount do begin
            Email := AttendeeEmail(Index);
            if not ReservationExists(SessionCode, Email) then
                InsertReservation(SessionCode, Email, ReservedAt);
        end;
    end;

    local procedure ReservationExists(SessionCode: Code[20]; Email: Text[80]): Boolean
    var
        ReservationEntry: Record "Session Attendee Res. Entry";
    begin
        ReservationEntry.SetCurrentKey("Attendee Email", "Session Code");
        ReservationEntry.SetRange("Attendee Email", Email);
        ReservationEntry.SetRange("Session Code", SessionCode);
        exit(not ReservationEntry.IsEmpty());
    end;

    local procedure InsertReservation(SessionCode: Code[20]; Email: Text[80]; ReservedAt: DateTime)
    var
        ReservationEntry: Record "Session Attendee Res. Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := ReservationEntry.GetLastEntryNo() + 1;
        ReservationEntry."Session Code" := SessionCode;
        ReservationEntry."Attendee Email" := Email;
        ReservationEntry."Reserved At" := ReservedAt;
        ReservationEntry.Insert(true);
    end;

    local procedure AttendeeEmail(Index: Integer): Text[80]
    var
        NumberText: Text;
    begin
        NumberText := Format(Index);
        while StrLen(NumberText) < 3 do
            NumberText := '0' + NumberText;
        exit(CopyStr('attendee' + NumberText + '@contoso.com', 1, 80));
    end;

    local procedure SlotEnd(StartTime: Time): Time
    begin
        exit(StartTime + (60 * 60 * 1000));
    end;

    local procedure ShowUpRatio(StartTime: Time): Decimal
    begin
        if StartTime < 120000T then
            exit(0.7);
        if StartTime >= 143000T then
            exit(0.5);
        exit(0.6);
    end;
}
