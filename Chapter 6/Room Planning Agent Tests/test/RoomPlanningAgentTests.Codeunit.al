// ------------------------------------------------------------------------------------------------
// Chapter 6 - Room Planning Agent Tests
// Agent evaluation test for the designed Room Planning Agent.
// Runs the RPA-AGENT.yaml dataset turn by turn through Library - Agent, and validates the
// resulting Event Session records instead of the text the agent writes in the task timeline.
// ------------------------------------------------------------------------------------------------
codeunit 50870 "Room Planning Agent Tests"
{
    Subtype = Test;
    TestType = AITest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure AssignRoomsFromDataset()
    var
        AgentTask: Record "Agent Task";
        TurnSuccessful: Boolean;
        ContinueWithNextTurn: Boolean;
        ErrorReason: Text;
    begin
        Initialize();

        repeat
            Clear(ErrorReason);

            ApplyTurnSetup();

            TurnSuccessful := LibraryAgent.RunTurnAndWait(AgentUserSecurityId, AgentTask);
            if TurnSuccessful then begin
                if not LibraryAgent.RequiresUserIntervention(AgentTask) then
                    TurnSuccessful := ValidateRoomPlan(ErrorReason);
            end else
                ErrorReason := StrSubstNo(AgentStatusErr, AgentTask.Status);

            ContinueWithNextTurn := LibraryAgent.FinalizeTurn(AgentTask, TurnSuccessful, ErrorReason);
        until not ContinueWithNextTurn;

        Assert.IsTrue(TurnSuccessful, ErrorReason);
    end;

    local procedure Initialize()
    begin
        if Initialized then
            exit;

        SetupPerSuiteTestData();

        LibraryAgent.GetAgentUnderTest(AgentUserSecurityId);
        if IsNullGuid(AgentUserSecurityId) then
            Error(NoAgentUnderTestErr);

        LibraryAgent.StopTasks(AgentUserSecurityId);
        LibraryAgent.EnsureAgentIsActive(AgentUserSecurityId);

        Initialized := true;
    end;

    #region Suite setup (runs once, gated by IsSuiteSetupDone)

    local procedure SetupPerSuiteTestData()
    var
        SuiteSetup: Codeunit "Test Input Json";
    begin
        if AITTestContext.IsSuiteSetupDone() then
            exit;

        SuiteSetup := AITTestContext.GetEvalSuiteSetupDataInput();
        ApplySuiteSetup(SuiteSetup);

        AITTestContext.SetEvalSuiteSetupCompleted();
    end;

    local procedure ApplySuiteSetup(SuiteSetup: Codeunit "Test Input Json")
    var
        SetupActions: Codeunit "Test Input Json";
        Action: Codeunit "Test Input Json";
        Index: Integer;
    begin
        SetupActions := SuiteSetup.Element('setup_actions');

        for Index := 0 to SetupActions.GetElementCount() - 1 do begin
            Action := SetupActions.ElementAt(Index);
            case Action.Element('action_type').ValueAsText() of
                'create_rooms':
                    CreateRoomsFromAction(Action);
                else
                    Error(UnknownSetupActionErr, Action.Element('action_type').ValueAsText());
            end;
        end;
    end;

    local procedure CreateRoomsFromAction(Action: Codeunit "Test Input Json")
    var
        RoomsData: Codeunit "Test Input Json";
        RoomData: Codeunit "Test Input Json";
        Index: Integer;
    begin
        RoomsData := Action.Element('action_data');

        for Index := 0 to RoomsData.GetElementCount() - 1 do begin
            RoomData := RoomsData.ElementAt(Index);
            CreateRoomIfNotExists(
                CopyStr(RoomData.Element('code').ValueAsText(), 1, 20),
                RoomData.Element('capacity').ValueAsInteger());
        end;
    end;

    local procedure CreateRoomIfNotExists(RoomCode: Code[20]; Capacity: Integer)
    var
        Room: Record Room;
    begin
        if Room.Get(RoomCode) then
            exit;

        Room.Init();
        Room."Code" := RoomCode;
        Room.Name := RoomCode;
        Room.Capacity := Capacity;
        Room.Insert(true);
    end;

    #endregion

    #region Turn setup (runs before every turn that declares one)

    local procedure ApplyTurnSetup()
    var
        TurnSetup: Codeunit "Test Input Json";
        Found: Boolean;
    begin
        Found := AITTestContext.GetTurnSetup(TurnSetup);
        if not Found then
            exit;

        PrepareRoomPlanningCase(TurnSetup);
    end;

    local procedure PrepareRoomPlanningCase(TurnSetup: Codeunit "Test Input Json")
    var
        SetupActions: Codeunit "Test Input Json";
        Action: Codeunit "Test Input Json";
        Index: Integer;
    begin
        SetupActions := TurnSetup.Element('setup_actions');

        for Index := 0 to SetupActions.GetElementCount() - 1 do begin
            Action := SetupActions.ElementAt(Index);
            case Action.Element('action_type').ValueAsText() of
                'prepare_room_planning_case':
                    CreateRoomPlanningCase(Action);
                else
                    Error(UnknownSetupActionErr, Action.Element('action_type').ValueAsText());
            end;
        end;
    end;

    /// <summary>
    /// Creates the project and three approved (Scheduled) sessions the agent must fill.
    /// Two sessions run at the same time and only one of them fits the small room, so a
    /// correct room plan must not double-book the large room to fit both. The third session
    /// runs later, so it can reuse either room without conflict.
    /// </summary>
    local procedure CreateRoomPlanningCase(Action: Codeunit "Test Input Json")
    var
        ActionData: Codeunit "Test Input Json";
        ProjectNo: Code[20];
        SessionDate: Date;
    begin
        ActionData := Action.Element('action_data').ElementAt(0);
        ProjectNo := CopyStr(ActionData.Element('project_no').ValueAsText(), 1, 20);

        // Relative to WorkDate so the dataset does not go stale.
        SessionDate := CalcDate('<+90D>', WorkDate());

        CreateApprovedProject(ProjectNo, SessionDate);

        CreateApprovedSession('RPA-KEY', ProjectNo, SessionDate, 103000T, 'Opening Keynote', 380);
        CreateApprovedSession('RPA-LAB', ProjectNo, SessionDate, 103000T, 'Hands-on Workshop', 25);
        CreateApprovedSession('RPA-DEV', ProjectNo, SessionDate, 130000T, 'Extending the Base App', 20);
    end;

    local procedure CreateApprovedProject(ProjectNo: Code[20]; SessionDate: Date)
    var
        Job: Record Job;
    begin
        if Job.Get(ProjectNo) then
            exit;

        Job.Init();
        Job."No." := ProjectNo;
        Job.Description := CopyStr('Room Planning Agent evaluation - ' + ProjectNo, 1, MaxStrLen(Job.Description));
        Job."Starting Date" := SessionDate;
        Job."Ending Date" := SessionDate;
        Job.Insert(true);
    end;

    local procedure CreateApprovedSession(SessionCode: Code[20]; ProjectNo: Code[20]; SessionDate: Date; StartTime: Time; SessionName: Text[100]; ReservedAttendees: Integer)
    var
        EventSession: Record "Event Session";
    begin
        if EventSession.Get(SessionCode) then
            exit;

        EventSession.Init();
        EventSession."Code" := SessionCode;
        EventSession.Name := SessionName;
        EventSession."Project Code" := ProjectNo;
        EventSession."Date" := SessionDate;
        EventSession."Start Time" := StartTime;
        EventSession."End Time" := StartTime + (60 * 60 * 1000);
        EventSession."Duration (min)" := 60;
        EventSession.Status := EventSession.Status::Scheduled;
        EventSession.Insert(true);

        CreateReservations(SessionCode, ReservedAttendees);
    end;

    local procedure CreateReservations(SessionCode: Code[20]; ReservationCount: Integer)
    var
        ReservationEntry: Record "Session Attendee Res. Entry";
        Index: Integer;
    begin
        for Index := 1 to ReservationCount do begin
            ReservationEntry.Init();
            ReservationEntry."Session Code" := SessionCode;
            ReservationEntry."Attendee Email" := CopyStr(StrSubstNo('attendee%1@rpa-agent-tests.local', Index), 1, 80);
            ReservationEntry.Insert(true);
        end;
    end;

    #endregion

    #region Outcome validation

    /// <summary>
    /// Checks the Business Central state after the agent finishes, instead of the text the
    /// agent wrote in the task timeline.
    /// </summary>
    local procedure ValidateRoomPlan(var ErrorReason: Text): Boolean
    var
        ExpectedData: Codeunit "Test Input Json";
    begin
        ExpectedData := AITTestContext.GetExpectedData();

        if ExpectedData.Element('all_scheduled_sessions_have_room').ValueAsBoolean() then
            if ScheduledSessionsWithoutRoomsExist() then begin
                ErrorReason := 'One or more scheduled sessions do not have a room.';
                exit(false);
            end;

        if ExpectedData.Element('no_room_over_capacity').ValueAsBoolean() then
            if RoomsOverCapacityExist() then begin
                ErrorReason := 'One or more sessions are assigned to rooms that are too small.';
                exit(false);
            end;

        if ExpectedData.Element('no_double_booking').ValueAsBoolean() then
            if DoubleBookedRoomsExist() then begin
                ErrorReason := 'One or more rooms are double-booked.';
                exit(false);
            end;

        exit(true);
    end;

    local procedure ScheduledSessionsWithoutRoomsExist(): Boolean
    var
        EventSession: Record "Event Session";
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetRange("Room Code", '');
        exit(not EventSession.IsEmpty());
    end;

    local procedure RoomsOverCapacityExist(): Boolean
    var
        EventSession: Record "Event Session";
        Room: Record Room;
        Demand: Integer;
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Room Code", '<>%1', '');
        if not EventSession.FindSet() then
            exit(false);

        repeat
            if Room.Get(EventSession."Room Code") then begin
                EventSession.CalcFields("Reserved Attendees");
                Demand := EventSession."Estimated Attendees";
                if EventSession."Reserved Attendees" > Demand then
                    Demand := EventSession."Reserved Attendees";

                if Demand > Room.Capacity then
                    exit(true);
            end;
        until EventSession.Next() = 0;

        exit(false);
    end;

    local procedure DoubleBookedRoomsExist(): Boolean
    var
        EventSession: Record "Event Session";
        OtherEventSession: Record "Event Session";
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Room Code", '<>%1', '');
        if not EventSession.FindSet() then
            exit(false);

        repeat
            OtherEventSession.SetFilter("Code", '<>%1', EventSession."Code");
            OtherEventSession.SetRange(Status, OtherEventSession.Status::Scheduled);
            OtherEventSession.SetRange("Room Code", EventSession."Room Code");
            OtherEventSession.SetRange("Date", EventSession.Date);
            if OtherEventSession.FindSet() then
                repeat
                    if TimesOverlap(EventSession."Start Time", EventSession."End Time", OtherEventSession."Start Time", OtherEventSession."End Time") then
                        exit(true);
                until OtherEventSession.Next() = 0;
        until EventSession.Next() = 0;

        exit(false);
    end;

    local procedure TimesOverlap(StartTime1: Time; EndTime1: Time; StartTime2: Time; EndTime2: Time): Boolean
    begin
        if (StartTime1 = 0T) or (EndTime1 = 0T) or (StartTime2 = 0T) or (EndTime2 = 0T) then
            exit(false);
        exit((StartTime1 < EndTime2) and (StartTime2 < EndTime1));
    end;

    #endregion

    var
        AITTestContext: Codeunit "AIT Test Context";
        LibraryAgent: Codeunit "Library - Agent";
        Assert: Codeunit "Library Assert";
        AgentUserSecurityId: Guid;
        Initialized: Boolean;
        NoAgentUnderTestErr: Label 'Select the agent under test on the evaluation suite.';
        UnknownSetupActionErr: Label 'Unknown setup action_type: %1.', Comment = '%1 = action_type value from the dataset';
        AgentStatusErr: Label 'The agent task did not complete successfully. Status: %1.', Comment = '%1 = task status';
}
