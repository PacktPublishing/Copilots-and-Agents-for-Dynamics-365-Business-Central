codeunit 50827 "Event Demo Data"
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
    /// Creates a room when it does not already exist.
    /// </summary>
    procedure CreateRoom(RoomCode: Code[20]; Capacity: Integer)
    begin
        CreateRoom(RoomCode, CopyStr(RoomCode, 1, 100), Capacity, 0, false);
    end;

    /// <summary>
    /// Creates the job when missing, otherwise updates description and dates.
    /// </summary>
    procedure CreateJob(JobNo: Code[20]; JobDescription: Text[100]; StartingDate: Date; EndingDate: Date)
    var
        Job: Record Job;
    begin
        if Job.Get(JobNo) then begin
            Job.Description := JobDescription;
            Job."Starting Date" := StartingDate;
            Job."Ending Date" := EndingDate;
            Job.Modify(true);
            exit;
        end;

        Job.Init();
        Job."No." := JobNo;
        Job.Description := JobDescription;
        Job."Starting Date" := StartingDate;
        Job."Ending Date" := EndingDate;
        Job.Insert(true);
    end;

    /// <summary>
    /// Creates a scheduled session, or resets an existing one to blank room and estimate.
    /// </summary>
    procedure CreateScheduledSession(SessionCode: Code[20]; SessionName: Text[100]; ProjectCode: Code[20]; SessionDate: Date; StartTime: Time)
    var
        EventSession: Record "Event Session";
    begin
        if EventSession.Get(SessionCode) then begin
            EventSession.Name := SessionName;
            EventSession."Project Code" := ProjectCode;
            EventSession."Date" := SessionDate;
            EventSession."Start Time" := StartTime;
            EventSession."End Time" := SlotEnd(StartTime);
            EventSession."Duration (min)" := 60;
            EventSession.Status := EventSession.Status::Scheduled;
            EventSession."Room Code" := '';
            EventSession."Estimated Attendees" := 0;
            EventSession.Modify(true);
            exit;
        end;

        EventSession.Init();
        EventSession."Code" := SessionCode;
        EventSession.Name := SessionName;
        EventSession."Project Code" := ProjectCode;
        EventSession."Date" := SessionDate;
        EventSession."Start Time" := StartTime;
        EventSession."End Time" := SlotEnd(StartTime);
        EventSession."Duration (min)" := 60;
        EventSession.Status := EventSession.Status::Scheduled;
        EventSession.Insert(true);
    end;

    /// <summary>
    /// Adds reservations up to ReservationCount. Idempotent per attendee email.
    /// </summary>
    procedure CreateReservationCount(SessionCode: Code[20]; ReservationCount: Integer)
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

    /// <summary>
    /// Inserts one reservation row. Assigns Entry No. the same way as demo data.
    /// </summary>
    procedure CreateReservation(SessionCode: Code[20]; AttendeeEmail: Text[80])
    begin
        InsertReservation(SessionCode, AttendeeEmail, CurrentDateTime());
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

    local procedure CreateHistory2024()
    var
        EventSession: Record "Event Session";
        DayOne: Date;
        DayTwo: Date;
    begin
        // Copilot year: PromptDialog and Copilot Studio take the largest share of breakout seats.
        // Agent-style talks are still early and draw a small share.
        DayOne := DMY2Date(13, 6, 2024);
        DayTwo := DMY2Date(14, 6, 2024);

        InitHistorySession(EventSession, 'T24-AI1', DayOne, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 120, 110, 'ROOM-101');
        InitHistorySession(EventSession, 'T24-FIN1', DayOne, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 45, 36, 'ROOM-102');
        InitHistorySession(EventSession, 'T24-DEV1', DayOne, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 85, 58, 'HALL-B');

        InitHistorySession(EventSession, 'T24-KEY', DayOne, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 400, 355, 'HALL-A');
        InitHistorySession(EventSession, 'T24-AI2', DayOne, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 100, 88, 'HALL-B');
        InitHistorySession(EventSession, 'T24-OPS1', DayOne, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 90, 68, 'ROOM-101');

        InitHistorySession(EventSession, 'T24-AI3', DayOne, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 230, 205, 'HALL-B');
        InitHistorySession(EventSession, 'T24-FIN2', DayOne, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 55, 38, 'ROOM-102');
        InitHistorySession(EventSession, 'T24-LAB', DayOne, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 30, 28, 'LAB');

        InitHistorySession(EventSession, 'T24-DEV2', DayOne, 143000T, 'TECH2024');
        CreateHistorySession(EventSession, 70, 38, 'ROOM-101');
        InitHistorySession(EventSession, 'T24-OPS2', DayOne, 143000T, 'TECH2024');
        CreateHistorySession(EventSession, 55, 32, 'ROOM-201');

        InitHistorySession(EventSession, 'T24-AI4', DayTwo, 090000T, 'TECH2024');
        CreateHistorySession(EventSession, 240, 218, 'HALL-B');
        InitHistorySession(EventSession, 'T24-OPS3', DayTwo, 103000T, 'TECH2024');
        CreateHistorySession(EventSession, 75, 52, 'ROOM-101');
        InitHistorySession(EventSession, 'T24-KEY2', DayTwo, 130000T, 'TECH2024');
        CreateHistorySession(EventSession, 400, 360, 'HALL-A');
        InitHistorySession(EventSession, 'T24-FIN3', DayTwo, 143000T, 'TECH2024');
        CreateHistorySession(EventSession, 70, 40, 'ROOM-101');
    end;

    local procedure CreateHistory2025()
    var
        EventSession: Record "Event Session";
        DayOne: Date;
        DayTwo: Date;
    begin
        // Transition year: Copilot still strong, early agent talks climb toward hall size.
        DayOne := DMY2Date(12, 6, 2025);
        DayTwo := DMY2Date(13, 6, 2025);

        InitHistorySession(EventSession, 'T25-AI1', DayOne, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 120, 112, 'ROOM-101');
        InitHistorySession(EventSession, 'T25-FIN1', DayOne, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 50, 38, 'ROOM-102');
        InitHistorySession(EventSession, 'T25-DEV1', DayOne, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 90, 60, 'HALL-B');

        InitHistorySession(EventSession, 'T25-KEY', DayOne, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 400, 372, 'HALL-A');
        InitHistorySession(EventSession, 'T25-AI2', DayOne, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 170, 155, 'HALL-B');
        InitHistorySession(EventSession, 'T25-OPS1', DayOne, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 95, 70, 'ROOM-101');

        InitHistorySession(EventSession, 'T25-AI3', DayOne, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 180, 162, 'HALL-B');
        InitHistorySession(EventSession, 'T25-FIN2', DayOne, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 55, 37, 'ROOM-102');
        InitHistorySession(EventSession, 'T25-LAB', DayOne, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 30, 28, 'LAB');

        InitHistorySession(EventSession, 'T25-DEV2', DayOne, 143000T, 'TECH2025');
        CreateHistorySession(EventSession, 75, 40, 'ROOM-101');
        InitHistorySession(EventSession, 'T25-OPS2', DayOne, 143000T, 'TECH2025');
        CreateHistorySession(EventSession, 55, 33, 'ROOM-201');

        InitHistorySession(EventSession, 'T25-AI4', DayTwo, 090000T, 'TECH2025');
        CreateHistorySession(EventSession, 190, 168, 'HALL-B');
        InitHistorySession(EventSession, 'T25-OPS3', DayTwo, 103000T, 'TECH2025');
        CreateHistorySession(EventSession, 80, 55, 'ROOM-101');
        InitHistorySession(EventSession, 'T25-KEY2', DayTwo, 130000T, 'TECH2025');
        CreateHistorySession(EventSession, 400, 368, 'HALL-A');
        InitHistorySession(EventSession, 'T25-FIN3', DayTwo, 143000T, 'TECH2025');
        CreateHistorySession(EventSession, 75, 42, 'ROOM-101');
    end;

    local procedure CreateHistory2026()
    var
        EventSession: Record "Event Session";
        DayOne: Date;
        DayTwo: Date;
    begin
        // Agent year: custom-agent talks take the largest share; Copilot holds ROOM-101 but no longer fills halls.
        DayOne := DMY2Date(11, 6, 2026);
        DayTwo := DMY2Date(12, 6, 2026);

        InitHistorySession(EventSession, 'T26-AI1', DayOne, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 120, 115, 'ROOM-101');
        InitHistorySession(EventSession, 'T26-FIN1', DayOne, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 55, 40, 'ROOM-102');
        InitHistorySession(EventSession, 'T26-DEV1', DayOne, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 95, 62, 'HALL-B');

        InitHistorySession(EventSession, 'T26-KEY', DayOne, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 400, 378, 'HALL-A');
        InitHistorySession(EventSession, 'T26-AI2', DayOne, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 250, 228, 'HALL-B');
        InitHistorySession(EventSession, 'T26-OPS1', DayOne, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 100, 72, 'ROOM-101');

        InitHistorySession(EventSession, 'T26-AI3', DayOne, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 230, 198, 'HALL-B');
        InitHistorySession(EventSession, 'T26-FIN2', DayOne, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 55, 38, 'ROOM-102');
        InitHistorySession(EventSession, 'T26-LAB', DayOne, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 30, 29, 'LAB');

        InitHistorySession(EventSession, 'T26-DEV2', DayOne, 143000T, 'TECH2026');
        CreateHistorySession(EventSession, 80, 42, 'ROOM-101');
        InitHistorySession(EventSession, 'T26-OPS2', DayOne, 143000T, 'TECH2026');
        CreateHistorySession(EventSession, 55, 34, 'ROOM-201');

        InitHistorySession(EventSession, 'T26-AI4', DayTwo, 090000T, 'TECH2026');
        CreateHistorySession(EventSession, 150, 128, 'HALL-B');
        InitHistorySession(EventSession, 'T26-OPS3', DayTwo, 103000T, 'TECH2026');
        CreateHistorySession(EventSession, 90, 58, 'ROOM-101');
        InitHistorySession(EventSession, 'T26-KEY2', DayTwo, 130000T, 'TECH2026');
        CreateHistorySession(EventSession, 400, 370, 'HALL-A');
        InitHistorySession(EventSession, 'T26-FIN3', DayTwo, 143000T, 'TECH2026');
        CreateHistorySession(EventSession, 80, 44, 'ROOM-101');
    end;

    local procedure CreateScheduled2027()
    var
        DayOne: Date;
    begin
        DayOne := DMY2Date(11, 6, 2027);
        CreateCatalogScheduledSession('T27-AI1', DayOne, 090000T);
        CreateCatalogScheduledSession('T27-FIN1', DayOne, 090000T);
        CreateCatalogScheduledSession('T27-DEV1', DayOne, 090000T);
        CreateCatalogScheduledSession('T27-KEY', DayOne, 103000T);
        CreateCatalogScheduledSession('T27-AI2', DayOne, 103000T);
        CreateCatalogScheduledSession('T27-OPS1', DayOne, 103000T);
        CreateCatalogScheduledSession('T27-AI3', DayOne, 130000T);
        CreateCatalogScheduledSession('T27-FIN2', DayOne, 130000T);
        CreateCatalogScheduledSession('T27-LAB', DayOne, 130000T);
        CreateCatalogScheduledSession('T27-NEW', DayOne, 143000T);
        CreateCatalogScheduledSession('T27-DEV2', DayOne, 143000T);
        CreateCatalogScheduledSession('T27-OPS2', DayOne, 143000T);
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

    local procedure CreateCatalogScheduledSession(SessionCode: Code[20]; EventDate: Date; StartTime: Time)
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
        YearPrefix: Code[10];
    begin
        YearPrefix := CopyStr(EventSession."Code", 1, 3);
        SessionSuffix := CopyStr(EventSession."Code", 5);
        case SessionSuffix of
            'AI1':
                ApplyAI1Catalog(EventSession, YearPrefix);
            'AI2':
                ApplyAI2Catalog(EventSession, YearPrefix);
            'AI3':
                ApplyAI3Catalog(EventSession, YearPrefix);
            'AI4':
                ApplyAI4Catalog(EventSession, YearPrefix);
            'FIN1':
                ApplyFIN1Catalog(EventSession, YearPrefix);
            'FIN2':
                ApplyFIN2Catalog(EventSession, YearPrefix);
            'FIN3':
                ApplyFIN3Catalog(EventSession, YearPrefix);
            'DEV1':
                ApplyDEV1Catalog(EventSession, YearPrefix);
            'DEV2':
                ApplyDEV2Catalog(EventSession, YearPrefix);
            'OPS1':
                ApplyOPS1Catalog(EventSession, YearPrefix);
            'OPS2':
                ApplyOPS2Catalog(EventSession, YearPrefix);
            'OPS3':
                ApplyOPS3Catalog(EventSession, YearPrefix);
            'KEY':
                ApplyKEYCatalog(EventSession, YearPrefix);
            'KEY2':
                ApplyKEY2Catalog(EventSession, YearPrefix);
            'LAB':
                ApplyLABCatalog(EventSession, YearPrefix);
            'NEW':
                SetCatalog(EventSession, 'Industry Cloud for ISVs', 'How ISVs package industry solutions on Business Central without forking the base app.', 'Jordan Blake', 1);
        end;
    end;

    local procedure ApplyAI1Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'First Copilot Features in AL', 'Ship a PromptDialog and Azure OpenAI call from an AL extension without rewriting the page model.', 'Maya Chen', 1);
            'T25':
                SetCatalog(EventSession, 'Copilot Toolkit Patterns for Partners', 'Reusable AL patterns for authorizing Azure OpenAI and grounding Copilot answers in Business Central data.', 'Maya Chen', 1);
            'T26':
                SetCatalog(EventSession, 'Production Copilot: What Actually Shipped', 'Which Copilot AL patterns survived real Cronus go-lives, and which ones were rewritten.', 'Maya Chen', 1);
            else
                SetCatalog(EventSession, 'Copilot in AL: Patterns That Ship', 'Proven AL patterns for Copilot features that make it past preview into Cronus production.', 'Maya Chen', 1);
        end;
    end;

    local procedure ApplyAI2Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Tool Calling from Copilot Actions', 'Let a Copilot invoke AL procedures as tools while a consultant stays in the loop.', 'Maya Chen', 2);
            'T25':
                SetCatalog(EventSession, 'From Copilot Tools to Guided Agents', 'Move from one-shot tool calls to multi-step agents that open pages and finish a task.', 'Maya Chen', 2);
            'T26':
                SetCatalog(EventSession, 'Designing Custom Agents for Cronus', 'Use the agent design experience to plan rooms and demand without writing AL first.', 'Maya Chen', 2);
            else
                SetCatalog(EventSession, 'Building Custom Agents', 'Design and run a custom Business Central agent that assigns rooms from comparable past sessions.', 'Maya Chen', 2);
        end;
    end;

    local procedure ApplyAI3Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'PromptDialog Pages for Business Users', 'When a PromptDialog is enough for Cronus planners — and when it is not.', 'Maya Chen', 1);
            'T25':
                SetCatalog(EventSession, 'When PromptDialog Is Enough', 'Keep the interaction on one page when the user only needs a proposal, not a full agent loop.', 'Maya Chen', 1);
            'T26':
                SetCatalog(EventSession, 'PromptDialog or an Agent?', 'Choose between a PromptDialog Copilot and a custom agent for the same Cronus planning job.', 'Maya Chen', 1);
            else
                SetCatalog(EventSession, 'PromptDialog vs Agents', 'Compare PromptDialog copilots with custom agents so Cronus picks the right shape of AI.', 'Maya Chen', 1);
        end;
    end;

    local procedure ApplyAI4Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Power Virtual Agents for BC Consultants', 'Build a low-code bot that answers Cronus questions with Business Central data.', 'Maya Chen', 1);
            'T25':
                SetCatalog(EventSession, 'Copilot Studio Meets Business Central', 'Connect Copilot Studio topics to Cronus tenants without duplicating AL business logic.', 'Maya Chen', 1);
            else
                SetCatalog(EventSession, 'Copilot Studio for BC Consultants', 'Use Copilot Studio beside AL copilots when Cronus needs a channel outside the web client.', 'Maya Chen', 1);
        end;
    end;

    local procedure ApplyFIN1Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Closing the Books in Business Central', 'A Cronus month-end close that stays inside Business Central instead of a spreadsheet maze.', 'Priya Nair', 2);
            'T25':
                SetCatalog(EventSession, 'Faster Month-End Close', 'Cut Cronus close time with checklists, dimensions, and fewer manual journals.', 'Priya Nair', 2);
            'T26':
                SetCatalog(EventSession, 'Month-End Close Without Spreadsheets', 'Replace Cronus offline close workbooks with account schedules and task lists.', 'Priya Nair', 2);
            else
                SetCatalog(EventSession, 'Month-End Close in Business Central', 'Run Cronus month-end close in Business Central with clear ownership and fewer hand-offs.', 'Priya Nair', 2);
        end;
    end;

    local procedure ApplyFIN2Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Custom Financial Report Layouts', 'Design Cronus financial layouts controllers can read without exporting to Excel.', 'Priya Nair', 2);
            'T25':
                SetCatalog(EventSession, 'Account Schedules Controllers Trust', 'Build Cronus account schedules that match how finance already talks about the P&L.', 'Priya Nair', 2);
            'T26':
                SetCatalog(EventSession, 'Financial Reporting That Reads Well', 'Layouts and column definitions Cronus controllers reuse across companies.', 'Priya Nair', 2);
            else
                SetCatalog(EventSession, 'Financial Reporting Layouts', 'Ship Cronus financial report layouts that stay correct after chart-of-accounts changes.', 'Priya Nair', 2);
        end;
    end;

    local procedure ApplyFIN3Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Analysis by Dimension for Controllers', 'Teach Cronus controllers to slice G/L by dimension without breaking close.', 'Priya Nair', 3);
            'T25':
                SetCatalog(EventSession, 'Dimension Sets Controllers Trust', 'Clean Cronus dimension combinations so analysis matches how the business is run.', 'Priya Nair', 3);
            else
                SetCatalog(EventSession, 'Dimensional Analysis for Controllers', 'Use dimensions for Cronus profitability views that finance will actually open.', 'Priya Nair', 3);
        end;
    end;

    local procedure ApplyDEV1Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Safe Extensions of the Base App', 'Extend Cronus without forking tables Microsoft will keep changing.', 'Sam Okonkwo', 3);
            'T25':
                SetCatalog(EventSession, 'Upgrade-Safe Extension Patterns', 'AL patterns that keep Cronus extensions installable across major Business Central versions.', 'Sam Okonkwo', 3);
            'T26':
                SetCatalog(EventSession, 'Keeping Base App Extensions Upgradeable', 'Practical Cronus rules for table extensions, events, and AppSource upgrades.', 'Sam Okonkwo', 3);
            else
                SetCatalog(EventSession, 'Extending Base App Without Breaking Upgrades', 'Extend Cronus on the base app so major version upgrades stay boring.', 'Sam Okonkwo', 3);
        end;
    end;

    local procedure ApplyDEV2Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Automated Testing for AL', 'Build Cronus AL tests that catch regressions before the next Cronus go-live.', 'Sam Okonkwo', 2);
            'T25':
                SetCatalog(EventSession, 'Writing Better AL Tests with AI', 'Use AI to draft Cronus test cases while you still own the assertions.', 'Sam Okonkwo', 2);
            'T26':
                SetCatalog(EventSession, 'Evaluating Extensions with AI Tests', 'Apply the AI Test Toolkit so Cronus copilots and agents get repeatable evals.', 'Sam Okonkwo', 2);
            else
                SetCatalog(EventSession, 'Testing AL with AI Test Toolkit', 'Evaluate Cronus AI features with the AI Test Toolkit instead of one-off demos.', 'Sam Okonkwo', 2);
        end;
    end;

    local procedure ApplyOPS1Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Your First BC Go-Live Checklist', 'A Cronus go-live checklist that covers data, training, and who owns each cutover task.', 'Chris Berg', 3);
            'T25':
                SetCatalog(EventSession, 'Go-Live Without Surprises', 'Rehearse Cronus cutover so opening day is a procedure, not a hero story.', 'Chris Berg', 3);
            'T26':
                SetCatalog(EventSession, 'The Cronus Go-Live Playbook', 'The Cronus playbook for partners who run the same go-live more than once.', 'Chris Berg', 3);
            else
                SetCatalog(EventSession, 'Go-Live Playbook', 'A reusable Cronus go-live playbook covering cutover, hypercare, and ownership.', 'Chris Berg', 3);
        end;
    end;

    local procedure ApplyOPS2Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'What Happens After Go-Live', 'Plan Cronus hypercare so support tickets do not bury the project team.', 'Chris Berg', 3);
            'T25':
                SetCatalog(EventSession, 'Hypercare That Actually Helps', 'Staff Cronus hypercare with clear SLAs and a path back to BAU support.', 'Chris Berg', 3);
            'T26':
                SetCatalog(EventSession, 'Keeping Cronus Running After Go-Live', 'Hand Cronus from project to support without losing the knowledge that made go-live work.', 'Chris Berg', 3);
            else
                SetCatalog(EventSession, 'Support After Go-Live', 'Move Cronus from hypercare into steady support with the right tickets and owners.', 'Chris Berg', 3);
        end;
    end;

    local procedure ApplyOPS3Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Cutover Weekend: Lessons Learned', 'What Cronus cutover weekends taught partners the hard way.', 'Chris Berg', 2);
            'T25':
                SetCatalog(EventSession, 'Planning the Cutover Weekend', 'Hour-by-hour Cronus cutover plans that survive contact with reality.', 'Chris Berg', 2);
            else
                SetCatalog(EventSession, 'Cutover Weekend Checklist', 'A Cronus cutover weekend checklist covering freeze, load, and smoke tests.', 'Chris Berg', 2);
        end;
    end;

    local procedure ApplyKEYCatalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Opening Keynote: Business Central in the Age of Copilot', 'How Cronus will use Copilot across finance and operations in the coming year.', 'Alex Rivera', 1);
            'T25':
                SetCatalog(EventSession, 'Opening Keynote: From Copilot to Agents', 'Why Cronus is moving from answering questions with Copilot to agents that finish work.', 'Alex Rivera', 1);
            'T26':
                SetCatalog(EventSession, 'Opening Keynote: Agents That Run Your Work', 'What Cronus learned when agents started assigning rooms, not just drafting text.', 'Alex Rivera', 1);
            else
                SetCatalog(EventSession, 'Opening Keynote: The Next Decade of Business Central', 'Where Cronus sees Business Central, Copilot, and agents heading over the next decade.', 'Alex Rivera', 1);
        end;
    end;

    local procedure ApplyKEY2Catalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Closing Keynote: What We Learned This Year', 'Cronus takeaways from a year of shipping Copilot features with partners.', 'Alex Rivera', 1);
            'T25':
                SetCatalog(EventSession, 'Closing Keynote: What Partners Built', 'Partner demos Cronus wants every consultant to steal for next year.', 'Alex Rivera', 1);
            else
                SetCatalog(EventSession, 'Closing Keynote: What We Learned', 'Cronus lessons from agents, copilots, and the rooms they filled this year.', 'Alex Rivera', 1);
        end;
    end;

    local procedure ApplyLABCatalog(var EventSession: Record "Event Session"; YearPrefix: Code[10])
    begin
        case YearPrefix of
            'T24':
                SetCatalog(EventSession, 'Hands-on: Build a Copilot PromptDialog', 'Build a Cronus PromptDialog that calls Azure OpenAI and keeps the result on the page.', 'Taylor Ng', 3);
            'T25':
                SetCatalog(EventSession, 'Hands-on: Add Tools to Your Copilot', 'Wire Cronus AL procedures as Copilot tools and watch the model choose when to call them.', 'Taylor Ng', 3);
            'T26':
                SetCatalog(EventSession, 'Hands-on: Prototype Your First Agent', 'Sketch a Cronus custom agent that estimates demand from past sessions before you write AL.', 'Taylor Ng', 3);
            else
                SetCatalog(EventSession, 'Hands-on: Build Your First Agent', 'Build a Cronus agent that finds similar past sessions and proposes attendee estimates.', 'Taylor Ng', 3);
        end;
    end;

    local procedure SetCatalog(var EventSession: Record "Event Session"; SessionName: Text[100]; SessionDescription: Text[250]; SpeakerName: Text[250]; TrackNo: Integer)
    begin
        EventSession.Name := SessionName;
        EventSession.Description := SessionDescription;
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
        exit(CopyStr('attendee' + NumberText + '@Cronus.com', 1, 80));
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
