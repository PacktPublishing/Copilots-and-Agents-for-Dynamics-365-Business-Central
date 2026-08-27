codeunit 50504 "Import Session Proposals Impl"
{
    procedure Generate(
        var ExcelBuffer: Record "Excel Buffer";
        GenerationId: Integer;
        DataExposure: Enum "Data Exposure";
        Project: Record Job;
        var FieldMappingProposal: Record "Field Mapping Proposal")
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ResponseText: Text;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Import Session Proposals") then
            exit;

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Import Session Proposals");
        SetAzureOpenAIAuthorization(AzureOpenAI);

        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);

        AOAIChatMessages.AddSystemMessage(GetSystemMessage());
        AOAIChatMessages.AddUserMessage(GenerateUserMessage(ExcelBuffer, DataExposure, Project));

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if not AOAIOperationResponse.IsSuccess() then
            Error(AOAIOperationResponse.GetError());

        ResponseText := AOAIChatMessages.GetLastMessage();
        ResponseText := StripJsonMarkdownFence(ResponseText);
        ParseMappingResponseToProposal(ResponseText, GenerationId, FieldMappingProposal);
    end;

    local procedure SetAzureOpenAIAuthorization(var AzureOpenAI: Codeunit "Azure OpenAI")
    var
        CopilotSetup: Record "Event Copilot Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        AOAIDeployments: Codeunit "AOAI Deployments";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then begin
            if not CopilotSetup.FindFirst() then
                Error(SetupMissingErr);
            AzureOpenAI.SetAuthorization(
                Enum::"AOAI Model Type"::"Chat Completions",
                CopilotSetup.GetEndpoint(),
                CopilotSetup.GetDeployment(),
                CopilotSetup.GetSecretKey());
        end else
            AzureOpenAI.SetManagedResourceAuthorization(
                Enum::"AOAI Model Type"::"Chat Completions",
                AOAIDeployments.GetGPT41Latest());
    end;

    procedure ImportSessionsUsingMapping(var Job: Record Job; var ExcelBuffer: Record "Excel Buffer"; var FieldMappingProposal: Record "Field Mapping Proposal")
    var
        MaxRowNo: Integer;
        RowNo: Integer;
    begin
        ExcelBuffer.Reset();
        if not ExcelBuffer.FindLast() then
            exit;
        MaxRowNo := ExcelBuffer."Row No.";

        for RowNo := 2 to MaxRowNo do begin
            ExcelBuffer.SetRange("Row No.", RowNo);
            InsertSession(Job, ExcelBuffer, FieldMappingProposal);
        end;
    end;

    local procedure GetSystemMessage(): Text
    var
        SystemMessage: Text;
    begin
        SystemMessage := @'You are an AI assistant that maps Excel column headers to Dynamics 365 Business Central table fields.
Analyze the Excel headers and Event Session table fields provided, then return ONLY valid JSON — no other text.
Output a JSON object with a "mappings" array where each element contains the best match between an Excel header and an Event Session field.
Use this exact structure:
{
  "mappings": [
    {
      "SourceColumnNo": 1,
      "SourceColumnName": "Session Code",
      "TargetFieldNo": 1,
      "TargetFieldName": "Code"
    }
  ]
}
Rules:
- Map each Event Session table field to the best matching Excel header.
- Only include fields that have a reasonable match in the Excel headers.
- SourceColumnNo is the 1-based column number in the Excel file.
- TargetFieldNo is the BC field number from the Event Session table.
- No comments. No markdown. Return only the JSON object described above.';
        exit(SystemMessage);
    end;

    local procedure GenerateUserMessage(
        var ExcelBuffer: Record "Excel Buffer";
        DataExposure: Enum "Data Exposure";
        Project: Record Job): Text
    var
        UserMessage: TextBuilder;
    begin
        UserMessage.AppendLine('Excel headers provided by the user:');
        UserMessage.AppendLine('---');
        UserMessage.AppendLine(GetExcelHeaders(ExcelBuffer));
        UserMessage.AppendLine('---');

        case DataExposure of
            DataExposure::None:
                begin
                    UserMessage.AppendLine('Event Session table fields:');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetTableFields());
                end;
            DataExposure::Excel:
                begin
                    UserMessage.AppendLine('Event Session table fields:');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetTableFields());
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine('Excel sample rows (row 2):');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetExcelSampleRows(ExcelBuffer, 1));
                end;
            DataExposure::ExcelAndBC:
                begin
                    UserMessage.AppendLine('Event Session table fields (with types):');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetTableFieldsWithTypes());
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine('Excel sample rows (row 2):');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetExcelSampleRows(ExcelBuffer, 1));
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine('Existing Event Session records for this project:');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetBCSampleData(Project."No.", 2));
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine('Project info:');
                    UserMessage.AppendLine('---');
                    UserMessage.AppendLine(GetProjectInfo(Project));
                end;
        end;

        UserMessage.AppendLine('---');
        exit(UserMessage.ToText());
    end;

    local procedure GetExcelHeaders(var ExcelBuffer: Record "Excel Buffer"): Text
    var
        ExcelHeaders: TextBuilder;
    begin
        ExcelBuffer.SetRange("Row No.", 1);
        if not ExcelBuffer.FindSet() then
            exit('');
        repeat
            ExcelHeaders.Append(ExcelBuffer."Cell Value as Text");
            ExcelHeaders.AppendLine(',');
        until ExcelBuffer.Next() = 0;
        exit(ExcelHeaders.ToText());
    end;

    local procedure GetTableFields(): Text
    var
        Field: Record Field;
        FieldJsonObj: JsonObject;
        FieldsArray: JsonArray;
        Result: Text;
    begin
        Field.SetRange(TableNo, Database::"Event Session");
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::"No");
        if Field.FindSet() then
            repeat
                Clear(FieldJsonObj);
                FieldJsonObj.Add('TargetFieldNo', Field."No.");
                FieldJsonObj.Add('TargetFieldName', Field.FieldName);
                FieldsArray.Add(FieldJsonObj);
            until Field.Next() = 0;
        FieldsArray.WriteTo(Result);
        exit(Result);
    end;

    local procedure GetExcelSampleRows(var ExcelBuffer: Record "Excel Buffer"; MaxRows: Integer): Text
    var
        RowNo: Integer;
        EndRow: Integer;
        ValueLine: TextBuilder;
        Result: TextBuilder;
        ColNo: Integer;
        MaxColNo: Integer;
        First: Boolean;
    begin
        ExcelBuffer.Reset();
        ExcelBuffer.SetRange("Row No.", 1);
        if not ExcelBuffer.FindSet() then
            exit('');

        MaxColNo := 0;
        repeat
            if ExcelBuffer."Column No." > MaxColNo then
                MaxColNo := ExcelBuffer."Column No.";
        until ExcelBuffer.Next() = 0;

        ExcelBuffer.SetRange("Row No.", 1);
        ExcelBuffer.FindSet();
        First := true;
        repeat
            if not First then
                Result.Append('|');
            Result.Append(ExcelBuffer."Cell Value as Text");
            First := false;
        until ExcelBuffer.Next() = 0;

        Result.AppendLine();

        EndRow := 1 + MaxRows;
        for RowNo := 2 to EndRow do begin
            ExcelBuffer.SetRange("Row No.", RowNo);
            if not ExcelBuffer.FindSet() then
                break;
            Clear(ValueLine);
            for ColNo := 1 to MaxColNo do begin
                ExcelBuffer.SetRange("Column No.", ColNo);
                if ExcelBuffer.FindFirst() then
                    ValueLine.Append(ExcelBuffer."Cell Value as Text");
                if ColNo < MaxColNo then
                    ValueLine.Append('|');
            end;
            Result.AppendLine(ValueLine.ToText());
        end;
        exit(Result.ToText());
    end;

    local procedure GetTableFieldsWithTypes(): Text
    var
        Field: Record Field;
        FieldJsonObj: JsonObject;
        FieldsArray: JsonArray;
        Result: Text;
    begin
        Field.SetRange(TableNo, Database::"Event Session");
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::"No");
        if Field.FindSet() then
            repeat
                Clear(FieldJsonObj);
                FieldJsonObj.Add('TargetFieldNo', Field."No.");
                FieldJsonObj.Add('TargetFieldName', Field.FieldName);
                FieldJsonObj.Add('TargetFieldType', Format(Field.Type));
                FieldJsonObj.Add('TargetFieldLength', Field.Len);
                FieldsArray.Add(FieldJsonObj);
            until Field.Next() = 0;
        FieldsArray.WriteTo(Result);
        exit(Result);
    end;

    local procedure GetBCSampleData(ProjectNo: Code[20]; MaxRecords: Integer): Text
    var
        EventSession: Record "Event Session";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        SessionArray: JsonArray;
        SessionObj: JsonObject;
        i: Integer;
        Result: Text;
    begin
        EventSession.SetRange("Project Code", ProjectNo);
        EventSession.SetCurrentKey("Project Code");
        if not EventSession.FindSet() then
            exit('[]');

        RecRef.GetTable(EventSession);
        i := 0;
        repeat
            if i >= MaxRecords then
                break;
            SessionObj := SessionRecordToJson(RecRef, EventSession);
            SessionArray.Add(SessionObj);
            i += 1;
        until EventSession.Next() = 0;

        SessionArray.WriteTo(Result);
        exit(Result);
    end;

    local procedure SessionRecordToJson(var RecRef: RecordRef; var EventSession: Record "Event Session"): JsonObject
    var
        FieldRef: FieldRef;
        SessionObj: JsonObject;
        i: Integer;
    begin
        RecRef.Get(EventSession.RecordId);
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Class = FieldRef.Class::Normal then
                SessionObj.Add(Format(FieldRef.Name), Format(FieldRef.Value));
        end;
        exit(SessionObj);
    end;

    local procedure GetProjectInfo(Project: Record Job): Text
    var
        InfoObj: JsonObject;
        Result: Text;
    begin
        InfoObj.Add('ProjectNo', Project."No.");
        InfoObj.Add('Description', Project.Description);
        InfoObj.Add('StartDate', Format(Project."Starting Date", 0, 9));
        InfoObj.Add('EndDate', Format(Project."Ending Date", 0, 9));
        InfoObj.WriteTo(Result);
        exit(Result);
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

    local procedure ParseMappingResponseToProposal(ResponseText: Text; GenerationId: Integer; var FieldMappingProposal: Record "Field Mapping Proposal")
    var
        JsonManagement: Codeunit "Json Management";
        Root: JsonObject;
        MappingsToken: JsonToken;
        MappingsArrayText: Text;
        MappingObjText: Text;
        i: Integer;
    begin
        if ResponseText = '' then
            Error(InvalidJsonErr);

        // SetJsonMode forces the model to return an object, so the root is {"mappings": [...]}
        if not Root.ReadFrom(ResponseText) then
            Error(InvalidJsonErr);

        if not Root.Get('mappings', MappingsToken) then
            Error(InvalidJsonErr);

        MappingsToken.WriteTo(MappingsArrayText);
        JsonManagement.InitializeCollection(MappingsArrayText);

        if JsonManagement.GetCollectionCount() = 0 then
            Error(InvalidJsonErr);

        for i := 0 to JsonManagement.GetCollectionCount() - 1 do begin
            JsonManagement.GetObjectFromCollectionByIndex(MappingObjText, i);
            InsertMappingProposal(FieldMappingProposal, MappingObjText, GenerationId);
        end;
    end;

    local procedure InsertMappingProposal(var FieldMappingProposal: Record "Field Mapping Proposal"; MappingObjText: Text; GenerationId: Integer)
    var
        JsonManagement: Codeunit "Json Management";
        RecRef: RecordRef;
    begin
        JsonManagement.InitializeObject(MappingObjText);

        RecRef.GetTable(FieldMappingProposal);
        RecRef.Init();

        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'SourceColumnNo', FieldMappingProposal.FieldNo("Source Column No."));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'SourceColumnName', FieldMappingProposal.FieldNo("Source Column Name"));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'TargetFieldNo', FieldMappingProposal.FieldNo("Target Field No."));
        JsonManagement.GetValueAndSetToRecFieldNo(RecRef, 'TargetFieldName', FieldMappingProposal.FieldNo("Target Field Name"));
        RecRef.SetTable(FieldMappingProposal);

        FieldMappingProposal."Generation Id" := GenerationId;
        FieldMappingProposal.Insert();
    end;

    local procedure InsertSession(var Job: Record Job; var ExcelBuffer: Record "Excel Buffer"; var FieldMappingProposal: Record "Field Mapping Proposal")
    var
        EventSession: Record "Event Session";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(Database::"Event Session");
        RecRef.Init();

        FieldMappingProposal.FindSet();
        repeat
            if RecRef.FieldExist(FieldMappingProposal."Target Field No.") then begin
                FieldRef := RecRef.Field(FieldMappingProposal."Target Field No.");
                SetFieldRefFromText(FieldRef, GetExcelCellValue(ExcelBuffer, FieldMappingProposal."Source Column No."));
            end;
        until FieldMappingProposal.Next() = 0;

        FieldRef := RecRef.Field(EventSession.FieldNo("Project Code"));
        FieldRef.Value := Job."No.";

        if Format(RecRef.Field(EventSession.FieldNo("Code")).Value) = '' then begin
            RecRef.Close();
            exit;
        end;

        if not RecRef.Insert() then
            RecRef.Modify();

        RecRef.Close();
    end;

    local procedure SetFieldRefFromText(var FieldRef: FieldRef; CellText: Text)
    var
        DateVar: Date;
        TimeVar: Time;
        IntVar: Integer;
        DecVar: Decimal;
    begin
        if CellText = '' then
            exit;

        case FieldRef.Type of
            FieldRef.Type::Text, FieldRef.Type::Code:
                FieldRef.Value := CopyStr(CellText, 1, FieldRef.Length);
            FieldRef.Type::Date:
                if Evaluate(DateVar, CellText, 9) then
                    FieldRef.Value := DateVar;
            FieldRef.Type::Time:
                if Evaluate(TimeVar, CellText, 9) then
                    FieldRef.Value := TimeVar;
            FieldRef.Type::Integer:
                if Evaluate(IntVar, CellText, 9) then
                    FieldRef.Value := IntVar;
            FieldRef.Type::Decimal:
                if Evaluate(DecVar, CellText, 9) then
                    FieldRef.Value := DecVar;
            FieldRef.Type::Option:
                if Evaluate(IntVar, CellText, 9) then
                    FieldRef.Value := IntVar;
            else
                FieldRef.Value := CopyStr(CellText, 1, FieldRef.Length);
        end;
    end;

    local procedure GetExcelCellValue(var ExcelBuffer: Record "Excel Buffer"; ColumnNo: Integer): Text
    begin
        ExcelBuffer.SetRange("Column No.", ColumnNo);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Cell Value as Text");
        exit('');
    end;

    var
        SetupMissingErr: Label 'Event Copilot Setup is missing. Open Event Copilot Setup and enter Azure OpenAI endpoint, deployment, and secret key.';
        InvalidJsonErr: Label 'Copilot returned an invalid or empty response. Please try again.';
}
