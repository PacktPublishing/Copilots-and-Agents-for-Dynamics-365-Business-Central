codeunit 50403 "Create Event Project Impl"
{
    procedure GenerateEventProject(EventBrief: Text; var JobDescription: Text[100]; var JobFullDescription: Text; var CustomerName: Text[100]; var EventProjectProposal: Record "Event Project Proposal")
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ResponseText: Text;
        CopilotCapabilityDisabledErr: Label 'The Create Event Project copilot has been turned off by an administrator.';
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Create Event Project") then
            Error(CopilotCapabilityDisabledErr);

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Create Event Project");
        SetAzureOpenAIAuthorization(AzureOpenAI);

        AOAIChatCompletionParams.SetTemperature(0.7);
        AOAIChatCompletionParams.SetJsonMode(true);

        AOAIChatMessages.AddSystemMessage(GetSystemMessage());
        AOAIChatMessages.AddUserMessage(EventBrief);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if not AOAIOperationResponse.IsSuccess() then
            Error(AOAIOperationResponse.GetError());

        ResponseText := AOAIChatMessages.GetLastMessage();
        ResponseText := StripJsonMarkdownFence(ResponseText);
        ParseJsonToProposal(ResponseText, JobDescription, JobFullDescription, CustomerName, EventProjectProposal);
    end;

    local procedure SetAzureOpenAIAuthorization(var AzureOpenAI: Codeunit "Azure OpenAI")
    var
        CopilotSetup: Record "Event Copilot Setup";
        AOAIDeployments: Codeunit "AOAI Deployments";
    begin
        if CopilotSetup.IsConfigured() then
            AzureOpenAI.SetAuthorization(
                Enum::"AOAI Model Type"::"Chat Completions",
                CopilotSetup.GetEndpoint(),
                CopilotSetup.GetDeployment(),
                CopilotSetup.GetSecretKey())
        else
            AzureOpenAI.SetManagedResourceAuthorization(
                Enum::"AOAI Model Type"::"Chat Completions",
                AOAIDeployments.GetGPT41Latest());
    end;

    local procedure GetSystemMessage(): Text
    var
        SystemPrompt: Text;
    begin
        SystemPrompt := @'
You are an assistant that creates an event project plan for Microsoft Dynamics 365 Business Central based on an event brief.
Output ONLY valid JSON, no other text. Use this exact structure:
{
  "project": {
    "shortDescription": "Brief project title",
    "detailedDescription": "Full project description",
    "customerName": "Customer or company name. Empty string if unclear."
  },
  "tasks": [
    {
      "jobTaskNo": "1000",
      "description": "Task title",
      "detailedDescription": "Optional details (under 100 chars)",
      "startDate": "yyyy-mm-dd",
      "endDate": "yyyy-mm-dd",
      "type": "resource" | "item" | "both",
      "itemCategory": "Category if type is item or both",
      "resourceRole": "Role if type is resource or both"
    }
  ]
}
Use %1 as the project start date. Generate at least 4 tasks. Use yyyy-mm-dd for all dates. jobTaskNo must be numeric codes (e.g. 1000, 1010, 1020).';
        exit(StrSubstNo(SystemPrompt, Format(WorkDate(), 0, 9)));
    end;

    local procedure StripJsonMarkdownFence(ResponseText: Text): Text
    begin
        ResponseText := ResponseText.Trim();
        if ResponseText.StartsWith('```') then begin
            ResponseText := ResponseText.Remove(1, 3);
            if ResponseText.StartsWith('json') then
                ResponseText := ResponseText.Remove(1, 4);
            ResponseText := ResponseText.Trim();
        end;
        if ResponseText.EndsWith('```') then
            ResponseText := CopyStr(ResponseText, 1, StrLen(ResponseText) - 3);
        exit(ResponseText.Trim());
    end;

    local procedure ParseJsonToProposal(JsonText: Text; var JobDescription: Text[100]; var JobFullDescription: Text; var CustomerName: Text[100]; var EventProjectProposal: Record "Event Project Proposal")
    var
        Root: JsonObject;
        NextLineNo: Integer;
    begin
        if not Root.ReadFrom(JsonText) then
            Error(InvalidJsonErr);

        ClearProposal(EventProjectProposal);

        ReadProjectInfo(Root, JobDescription, JobFullDescription, CustomerName);
        InsertHeaderRow(EventProjectProposal, JobDescription, JobFullDescription, CustomerName, NextLineNo);
        InsertTaskRows(Root, EventProjectProposal, JobDescription, NextLineNo);
    end;

    local procedure ReadProjectInfo(Root: JsonObject; var JobDescription: Text[100]; var JobFullDescription: Text; var CustomerName: Text[100])
    var
        JsonManagement: Codeunit "Json Management";
        ProjectToken: JsonToken;
        ProjectObjText: Text;
        ShortDescText: Text;
        CustomerNameText: Text;
    begin
        if not Root.Get('project', ProjectToken) then
            Error(MissingProjectErr);

        ProjectToken.WriteTo(ProjectObjText);
        JsonManagement.InitializeObject(ProjectObjText);

        if not JsonManagement.GetStringPropertyValueByName('shortDescription', ShortDescText) then
            Error(MissingProjectErr);
        JobDescription := CopyStr(ShortDescText, 1, MaxStrLen(JobDescription));
        JsonManagement.GetStringPropertyValueByName('detailedDescription', JobFullDescription);
        if JsonManagement.GetStringPropertyValueByName('customerName', CustomerNameText) then
            CustomerName := CopyStr(CustomerNameText, 1, MaxStrLen(CustomerName));
    end;

    /// <summary>
    /// Finds a customer from the name suggested by Copilot.
    /// </summary>
    /// <param name="CustomerSearchKeyword">The customer name or search keyword.</param>
    /// <returns>The matching customer number, or an empty value when no customer is found.</returns>
    procedure FindCustomerBySearchKeyword(CustomerSearchKeyword: Text): Code[20]
    var
        Customer: Record Customer;
    begin
        if CustomerSearchKeyword = '' then
            exit('');

        Customer.SetFilter(Name, '&&' + CustomerSearchKeyword + '*');
        if Customer.FindFirst() then
            exit(Customer."No.");

        exit('');
    end;

    local procedure ClearProposal(var EventProjectProposal: Record "Event Project Proposal")
    begin
        EventProjectProposal.Reset();
        EventProjectProposal.DeleteAll();
    end;

    local procedure InsertTaskRows(Root: JsonObject; var EventProjectProposal: Record "Event Project Proposal"; JobDescription: Text[100]; var LineNo: Integer)
    var
        TaskElementToken: JsonToken;
        TasksArray: JsonArray;
        TaskObjText: Text;
    begin
        if not Root.Contains('tasks') then
            Error(MissingTasksErr);

        TasksArray := Root.GetArray('tasks');

        foreach TaskElementToken in TasksArray do begin
            if not TaskElementToken.IsObject() then
                continue;

            TaskElementToken.WriteTo(TaskObjText);
            InsertTask(EventProjectProposal, TaskObjText, JobDescription, LineNo);
            LineNo += 10;
        end;
    end;

    local procedure InsertTask(var EventProjectProposal: Record "Event Project Proposal"; TaskObjText: Text; JobDescription: Text[100]; LineNo: Integer)
    var
        JsonManagement: Codeunit "Json Management";
        RecRef: RecordRef;
        DetailText: Text;
        BlobOutStr: OutStream;
    begin
        JsonManagement.InitializeObject(TaskObjText);

        RecRef.GetTable(EventProjectProposal);
        RecRef.Init();

        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'jobTaskNo', EventProjectProposal.FieldNo("Job Task No."));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'description', EventProjectProposal.FieldNo("Task Description"));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'detailedDescription', EventProjectProposal.FieldNo("Action Description Preview"));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'startDate', EventProjectProposal.FieldNo("Start Date"));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'endDate', EventProjectProposal.FieldNo("End Date"));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'type', EventProjectProposal.FieldNo(Type));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'itemCategory', EventProjectProposal.FieldNo("Item Category"));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'resourceRole', EventProjectProposal.FieldNo("Resource Role Description"));

        RecRef.SetTable(EventProjectProposal);

        if EventProjectProposal."Job Task No." = '' then
            EventProjectProposal."Job Task No." := Format(LineNo);

        if JsonManagement.GetStringPropertyValueByName('detailedDescription', DetailText) then begin
            EventProjectProposal."Action Description".CreateOutStream(BlobOutStr);
            BlobOutStr.WriteText(DetailText);
        end;

        EventProjectProposal."Job Short Description" := JobDescription;
        EventProjectProposal."Job Task Type" := EventProjectProposal."Job Task Type"::Posting;
        EventProjectProposal.Indentation := 1;

        EventProjectProposal.Insert();
    end;

    local procedure InsertHeaderRow(var EventProjectProposal: Record "Event Project Proposal"; JobDescription: Text[100]; JobFullDescription: Text; CustomerName: Text[100]; var NextLineNo: Integer)
    var
        OutStr: OutStream;
        HeaderLineNo: Integer;
    begin
        HeaderLineNo := 10000;

        EventProjectProposal.Init();
        EventProjectProposal."Job Task No." := Format(HeaderLineNo);
        EventProjectProposal."Job Short Description" := JobDescription;
        EventProjectProposal."Extracted Customer" := CustomerName;
        EventProjectProposal."Task Description" := JobDescription;
        EventProjectProposal."Job Task Type" := EventProjectProposal."Job Task Type"::"Begin-Total";
        EventProjectProposal.Indentation := 0;
        EventProjectProposal."Job Full Description".CreateOutStream(OutStr);
        OutStr.WriteText(JobFullDescription);
        EventProjectProposal.Insert();

        EventProjectProposal.Init();
        EventProjectProposal."Job Task No." := Format(HeaderLineNo * 10 - 10);
        EventProjectProposal."Task Description" := CopyStr('Total ' + JobDescription, 1, MaxStrLen(EventProjectProposal."Task Description"));
        EventProjectProposal."Job Short Description" := JobDescription;
        EventProjectProposal."Extracted Customer" := CustomerName;
        EventProjectProposal."Job Task Type" := EventProjectProposal."Job Task Type"::"End-Total";
        EventProjectProposal.Indentation := 0;
        EventProjectProposal.Insert();

        NextLineNo := HeaderLineNo + 100;
    end;

    var
        InvalidJsonErr: Label 'Copilot returned invalid JSON. Please try again.';
        MissingProjectErr: Label 'Copilot response is missing project data. Please try again.';
        MissingTasksErr: Label 'Copilot response is missing tasks. Please try again.';
}
