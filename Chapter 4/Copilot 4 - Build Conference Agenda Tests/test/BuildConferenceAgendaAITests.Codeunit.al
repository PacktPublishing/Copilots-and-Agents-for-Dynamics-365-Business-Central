codeunit 50761 "Build Conf Agenda AI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;
    InherentEntitlements = X;
    InherentPermissions = X;

    [Test]
    procedure TestBuildConferenceAgendaOutcomes()
    var
        AITTestContext: Codeunit "AIT Test Context";
        BuildAgendaImpl: Codeunit "Build Agenda Impl";
        AgendaProposal: Record "Agenda Proposal";
        TestSetup: Codeunit "Test Input Json";
        ProjectEl: Codeunit "Test Input Json";
        IntentEl: Codeunit "Test Input Json";
        ProjectCode: Code[20];
        UserInput: Text;
        FinalMessage: Text;
        IntentFound: Boolean;
        ProjFound: Boolean;
        ShowIntent: Boolean;
    begin
        UserInput := AITTestContext.GetQuery().ValueAsText();
        TestSetup := AITTestContext.GetTestSetup();
        ProjectEl := TestSetup.ElementExists('project_code', ProjFound);
        if ProjFound then
            ProjectCode := CopyStr(ProjectEl.ValueAsText(), 1, MaxStrLen(ProjectCode));
        if ProjectCode = '' then
            ProjectCode := 'JOB-001';

        IntentEl := TestSetup.ElementExists('intent', IntentFound);
        ShowIntent := IntentFound and (IntentEl.ValueAsText().ToLower() = 'show');

        if not TryGenerateAgenda(BuildAgendaImpl, ProjectCode, UserInput, AgendaProposal, FinalMessage) then begin
            FinalMessage := GetLastErrorText();
            AITTestContext.SetAccuracy(0.0);
            AITTestContext.SetTestOutput(FinalMessage);
            exit;
        end;

        if ShowIntent then begin
            if ReplyLooksLikePlainText(FinalMessage) then
                AITTestContext.SetAccuracy(1.0)
            else
                AITTestContext.SetAccuracy(0.0);
        end else begin
            if RootIsJsonObjectOrArray(FinalMessage) then
                AITTestContext.SetAccuracy(1.0)
            else
                AITTestContext.SetAccuracy(0.0);
        end;

        AITTestContext.SetTestOutput(StrSubstNo('%1 | sessions in proposal: %2', FinalMessage, Format(AgendaProposal.Count())));
    end;

    /// <summary>
    /// True when the assistant message parses as a JSON object or array (typical for "build" summaries structured as JSON).
    /// </summary>
    local procedure RootIsJsonObjectOrArray(MessageText: Text): Boolean
    var
        Token: JsonToken;
        Trimmed: Text;
    begin
        Trimmed := MessageText.Trim();
        if Trimmed = '' then
            exit(false);
        if not Token.ReadFrom(Trimmed) then
            exit(false);
        exit(Token.IsObject() or Token.IsArray());
    end;

    /// <summary>
    /// True when the reply is not a JSON object/array at the root (typical natural-language "show" answers).
    /// </summary>
    local procedure ReplyLooksLikePlainText(MessageText: Text): Boolean
    begin
        exit(not RootIsJsonObjectOrArray(MessageText));
    end;

    [TryFunction]
    local procedure TryGenerateAgenda(BuildAgendaImpl: Codeunit "Build Agenda Impl"; ProjectCode: Code[20]; UserInput: Text; var AgendaProposal: Record "Agenda Proposal"; var FinalMessage: Text)
    begin
        FinalMessage := BuildAgendaImpl.Generate(ProjectCode, UserInput, AgendaProposal);
    end;
}
