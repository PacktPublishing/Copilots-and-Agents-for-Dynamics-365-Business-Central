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
    InherentEntitlements = X;
    InherentPermissions = X;

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
    var
        AgentTestContext: Codeunit "Agent Test Context";
        AgentSetup: Codeunit "Agent Setup";
    begin
        if Initialized then
            exit;

        SetupPerSuiteTestData();

        // Same pattern as Sales Validation Agent: suite Agent is optional.
        // Coded agents call CreateDefaultAgent() when blank; designed agents look up
        // the sandbox instance by user name (cannot invent instructions/profile in AL).
        AgentTestContext.GetAgentUserSecurityID(AgentUserSecurityId);
        if IsNullGuid(AgentUserSecurityId) then
            if not AgentSetup.FindAgentByUserName(DefaultAgentUserNameTok, AgentUserSecurityId) then
                Error(NoAgentUnderTestErr, DefaultAgentUserNameTok);

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
        EventDemoData: Codeunit "Event Demo Data";
        RoomsData: Codeunit "Test Input Json";
        RoomData: Codeunit "Test Input Json";
        Index: Integer;
    begin
        RoomsData := Action.Element('action_data');

        for Index := 0 to RoomsData.GetElementCount() - 1 do begin
            RoomData := RoomsData.ElementAt(Index);
            EventDemoData.CreateRoom(
                CopyStr(RoomData.Element('code').ValueAsText(), 1, 20),
                RoomData.Element('capacity').ValueAsInteger());
        end;
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
    /// Creates/resets an isolated project and three approved sessions the agent must fill.
    /// Two sessions run at the same time and only one fits the small room, so a correct
    /// plan must not double-book the large room. The third session runs later.
    /// Must not reuse demo project BC-TECH-2027 — the agent would plan T27-* instead.
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

        CreateEvalSession('RPA-KEY', ProjectNo, SessionDate, 103000T, 'Opening Keynote', 380);
        CreateEvalSession('RPA-LAB', ProjectNo, SessionDate, 103000T, 'Hands-on Workshop', 25);
        CreateEvalSession('RPA-DEV', ProjectNo, SessionDate, 130000T, 'Extending the Base App', 20);
    end;

    local procedure CreateApprovedProject(ProjectNo: Code[20]; SessionDate: Date)
    var
        EventDemoData: Codeunit "Event Demo Data";
        JobDescription: Text[100];
    begin
        JobDescription := CopyStr('Room Planning Agent evaluation - ' + ProjectNo, 1, MaxStrLen(JobDescription));
        EventDemoData.CreateJob(ProjectNo, JobDescription, SessionDate, SessionDate);
    end;

    /// <summary>
    /// Creates the session (blank room/estimate) and seeds reservations only when none exist yet.
    /// </summary>
    local procedure CreateEvalSession(SessionCode: Code[20]; ProjectNo: Code[20]; SessionDate: Date; StartTime: Time; SessionName: Text[100]; ReservedAttendees: Integer)
    var
        EventDemoData: Codeunit "Event Demo Data";
        ReservationEntry: Record "Session Attendee Res. Entry";
    begin
        EventDemoData.CreateScheduledSession(SessionCode, SessionName, ProjectNo, SessionDate, StartTime);

        ReservationEntry.SetRange("Session Code", SessionCode);
        if ReservationEntry.IsEmpty() then
            CreateReservations(SessionCode, ReservedAttendees);
    end;

    local procedure CreateReservations(SessionCode: Code[20]; ReservationCount: Integer)
    var
        EventDemoData: Codeunit "Event Demo Data";
        Index: Integer;
    begin
        for Index := 1 to ReservationCount do
            EventDemoData.CreateReservation(
                SessionCode,
                CopyStr(StrSubstNo('attendee%1@rpa-agent-tests.local', Index), 1, 80));
    end;

    #endregion

    #region Outcome validation

    /// <summary>
    /// Validates only the three RPA-* eval sessions — never company-wide scheduled
    /// sessions, which include demo data the agent was not asked to plan.
    /// </summary>
    local procedure ValidateRoomPlan(var ErrorReason: Text): Boolean
    var
        RoomAssignmentCheck: Codeunit "Room Assignment Check";
        EventSession: Record "Event Session";
        ExpectedData: Codeunit "Test Input Json";
        CheckElement: Codeunit "Test Input Json";
        SessionCode: Code[20];
        ConflictingSession: Record "Event Session";
        Found: Boolean;
    begin
        ExpectedData := AITTestContext.GetExpectedData();

        foreach SessionCode in EvalSessionCodes() do begin
            if not EventSession.Get(SessionCode) then begin
                ErrorReason := StrSubstNo('Eval session %1 is missing.', SessionCode);
                exit(false);
            end;

            CheckElement := ExpectedData.ElementExists('all_scheduled_sessions_have_estimate', Found);
            if Found and CheckElement.ValueAsBoolean() then
                if EventSession."Estimated Attendees" <= 0 then begin
                    ErrorReason := StrSubstNo('Session %1 has no Estimated Attendees. The agent must set estimates.', SessionCode);
                    exit(false);
                end;

            if ExpectedData.Element('all_scheduled_sessions_have_room').ValueAsBoolean() then
                if EventSession."Room Code" = '' then begin
                    ErrorReason := StrSubstNo('Session %1 does not have a room.', SessionCode);
                    exit(false);
                end;

            if ExpectedData.Element('no_room_over_capacity').ValueAsBoolean() then
                if RoomAssignmentCheck.SessionDemandExceedsCapacity(EventSession) then begin
                    ErrorReason := StrSubstNo('Session %1 is assigned to a room that is too small.', SessionCode);
                    exit(false);
                end;

            if ExpectedData.Element('no_double_booking').ValueAsBoolean() then
                if RoomAssignmentCheck.FindDoubleBookingConflict(EventSession, ConflictingSession) then begin
                    ErrorReason := StrSubstNo('Session %1 double-books room %2 with %3.', SessionCode, EventSession."Room Code", ConflictingSession."Code");
                    exit(false);
                end;
        end;

        exit(true);
    end;

    local procedure EvalSessionCodes(): List of [Code[20]]
    var
        SessionCodes: List of [Code[20]];
    begin
        SessionCodes.Add('RPA-KEY');
        SessionCodes.Add('RPA-LAB');
        SessionCodes.Add('RPA-DEV');
        exit(SessionCodes);
    end;

    #endregion

    var
        AITTestContext: Codeunit "AIT Test Context";
        LibraryAgent: Codeunit "Library - Agent";
        Assert: Codeunit "Library Assert";
        AgentUserSecurityId: Guid;
        Initialized: Boolean;
        DefaultAgentUserNameTok: Label 'ROOM PLANNING AGENT', Locked = true;
        NoAgentUnderTestErr: Label 'Could not find agent %1. Create the designed Room Planning Agent in the sandbox, or select it in the Agent field on the evaluation suite.', Comment = '%1 = agent user name';
        UnknownSetupActionErr: Label 'Unknown setup action_type: %1.', Comment = '%1 = action_type value from the dataset';
        AgentStatusErr: Label 'The agent task did not complete successfully. Status: %1.', Comment = '%1 = task status';
}
