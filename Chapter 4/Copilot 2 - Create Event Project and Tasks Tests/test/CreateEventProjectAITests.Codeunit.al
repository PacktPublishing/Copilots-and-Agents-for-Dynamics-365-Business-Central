codeunit 50721 "Create Event Project AI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AITTestContext: Codeunit "AIT Test Context";

    [Test]
    procedure TestCreateEventProjectStructuredOutput()
    var
        CreateEventProjectImpl: Codeunit "Create Event Project Impl";
        EventProjectProposal: Record "Event Project Proposal";
        Assert: Codeunit "Library Assert";
        TestInputJsonAnswer: Codeunit "Test Input Json";
        ExpectedMinJson: Codeunit "Test Input Json";
        ExpectedMaxJson: Codeunit "Test Input Json";
        ExpectedFlagJson: Codeunit "Test Input Json";
        JobDescription: Text[100];
        JobFullDescription: Text;
        CustomerName: Text[100];
        Question: Text;
        TaskCount: Integer;
        Found: Boolean;
    begin
        Question := AITTestContext.GetQuery().ValueAsText();
        Clear(EventProjectProposal);

        if not TryGenerateEventProject(CreateEventProjectImpl, Question, JobDescription, JobFullDescription, CustomerName, EventProjectProposal) then begin
            AITTestContext.SetAccuracy(0.0);
            AITTestContext.SetTestOutput(GetLastErrorText());
            exit;
        end;

        TaskCount := CountAllTasks(EventProjectProposal);
        TestInputJsonAnswer := AITTestContext.GetExpectedData();

        ExpectedMinJson := TestInputJsonAnswer.ElementExists('min_tasks', Found);
        if not Found then
            Assert.Fail('Expected "min_tasks" field not found in expected_data.');

        Assert.IsTrue(TaskCount >= ExpectedMinJson.ValueAsInteger(), StrSubstNo('Task line count %1 is below expected_data min_tasks %2.', TaskCount, ExpectedMinJson.ValueAsInteger()));

        ExpectedMaxJson := TestInputJsonAnswer.ElementExists('max_tasks', Found);
        if Found then
            Assert.IsTrue(TaskCount <= ExpectedMaxJson.ValueAsInteger(), StrSubstNo('Task line count %1 is above expected_data max_tasks %2.', TaskCount, ExpectedMaxJson.ValueAsInteger()));

        ExpectedFlagJson := TestInputJsonAnswer.ElementExists('job_short_description_mandatory', Found);
        if Found and ExpectedFlagJson.ValueAsBoolean() then
            Assert.IsTrue(JobDescription <> '', 'Create Event Project returned an empty job short description but expected_data requires job_short_description_mandatory.');

        ExpectedFlagJson := TestInputJsonAnswer.ElementExists('job_full_description_mandatory', Found);
        if Found and ExpectedFlagJson.ValueAsBoolean() then
            Assert.IsTrue(JobFullDescription <> '', 'Create Event Project returned an empty job full description but expected_data requires job_full_description_mandatory.');

        AITTestContext.SetAccuracy(1.0);
        AITTestContext.SetTestOutput(BuildSuccessOutputJsonArray(JobDescription, JobFullDescription, CustomerName, TaskCount));
    end;

    local procedure BuildSuccessOutputJsonArray(JobDescription: Text[100]; JobFullDescription: Text; CustomerName: Text[100]; TaskCount: Integer): Text
    var
        OutputArray: JsonArray;
        OutputText: Text;
    begin
        AppendPropertyText(OutputArray, 'status', 'succeeded');
        AppendPropertyText(OutputArray, 'job_short_description', JobDescription);
        AppendPropertyText(OutputArray, 'job_full_description', JobFullDescription);
        AppendPropertyText(OutputArray, 'customer_name', CustomerName);
        AppendPropertyInteger(OutputArray, 'task_line_count', TaskCount);
        OutputArray.WriteTo(OutputText);
        exit(OutputText);
    end;

    local procedure AppendPropertyText(var TargetArray: JsonArray; PropertyName: Text; PropertyValue: Text)
    var
        Row: JsonObject;
    begin
        Row.Add('property', PropertyName);
        Row.Add('value', PropertyValue);
        TargetArray.Add(Row.AsToken());
    end;

    local procedure AppendPropertyInteger(var TargetArray: JsonArray; PropertyName: Text; PropertyValue: Integer)
    var
        Row: JsonObject;
    begin
        Row.Add('property', PropertyName);
        Row.Add('value', PropertyValue);
        TargetArray.Add(Row.AsToken());
    end;

    local procedure CountAllTasks(var EventProjectProposal: Record "Event Project Proposal"): Integer
    begin
        EventProjectProposal.Reset();
        exit(EventProjectProposal.Count());
    end;

    [TryFunction]
    local procedure TryGenerateEventProject(CreateEventProjectImpl: Codeunit "Create Event Project Impl"; Question: Text; var JobDescription: Text[100]; var JobFullDescription: Text; var CustomerName: Text[100]; var EventProjectProposal: Record "Event Project Proposal")
    begin
        CreateEventProjectImpl.GenerateEventProject(Question, JobDescription, JobFullDescription, CustomerName, EventProjectProposal);
    end;
}
