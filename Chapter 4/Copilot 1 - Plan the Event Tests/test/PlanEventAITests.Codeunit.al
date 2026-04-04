codeunit 50701 "Plan Event AI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;
    InherentEntitlements = X;
    InherentPermissions = X;

    [Test]
    procedure TestPlanEventSuggestions()
    var
        AITTestContext: Codeunit "AIT Test Context";
        PlanEventImpl: Codeunit "Plan Event Impl";
        ExpectedDataJson: Codeunit "Test Input Json";
        CheckElement: Codeunit "Test Input Json";
        Question: Text;
        Answer: Text;
        Accuracy: Decimal;
        Found: Boolean;
    begin
        // [GIVEN] A question from the dataset
        Question := AITTestContext.GetQuestion().ValueAsText();

        // [WHEN] The Plan Event copilot generates planning steps
        // Azure OpenAI may block some prompts (content management policy) and the impl calls Error() on failure.
        // A TryFunction turns that into text so the suite records a row instead of Status = Error.
        if not TryGeneratePlanningSteps(PlanEventImpl, Question, Answer) then
            Answer := GetLastErrorText();

        // [THEN] Score accuracy based on the check defined in expected_data
        ExpectedDataJson := AITTestContext.GetExpectedData();
        Accuracy := 1.0;

        // Check 1: "contains" — the answer must include this keyword
        CheckElement := ExpectedDataJson.ElementExists('contains', Found);
        if Found then
            if not Answer.ToLower().Contains(CheckElement.ValueAsText().ToLower()) then
                Accuracy := 0.0;

        // Check 2: "min_length" — the answer must be at least N characters
        CheckElement := ExpectedDataJson.ElementExists('min_length', Found);
        if Found then
            if StrLen(Answer) < CheckElement.ValueAsInteger() then
                Accuracy := 0.0;

        // Check 3: "must_not_contain" — the answer must NOT include this phrase
        CheckElement := ExpectedDataJson.ElementExists('must_not_contain', Found);
        if Found then
            if Answer.ToLower().Contains(CheckElement.ValueAsText().ToLower()) then
                Accuracy := 0.0;

        // Baseline: if no specific check was defined, any non-empty answer passes
        if Answer = '' then
            Accuracy := 0.0;

        AITTestContext.SetAccuracy(Accuracy);
        AITTestContext.SetTestOutput(Answer);
    end;

    [TryFunction]
    local procedure TryGeneratePlanningSteps(PlanEventImpl: Codeunit "Plan Event Impl"; Question: Text; var Answer: Text)
    begin
        Answer := PlanEventImpl.GeneratePlanningSteps(Question);
    end;
}
