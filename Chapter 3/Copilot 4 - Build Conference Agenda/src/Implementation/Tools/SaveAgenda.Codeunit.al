codeunit 50607 "Save Agenda" implements "AOAI Function"
{
    var
        AgendaProposal: Record "Agenda Proposal";

    procedure SetContext(var FromProposal: Record "Agenda Proposal")
    begin
        // Share the caller's temp table instance so Execute fills the same in-memory data.
        AgendaProposal.Copy(FromProposal, true);
    end;

    procedure GetName(): Text
    begin
        exit('SaveAgenda');
    end;

    procedure GetPrompt() ToolJObj: JsonObject
    var
        FunctionJObject: JsonObject;
        ParametersJObject: JsonObject;
        PropertiesJObject: JsonObject;
        ScheduleArrayJObject: JsonObject;
        ItemsJObject: JsonObject;
        ItemPropertiesJObject: JsonObject;
        SessionCodeJObject: JsonObject;
        DateJObject: JsonObject;
        TrackNoJObject: JsonObject;
        StartTimeJObject: JsonObject;
        EndTimeJObject: JsonObject;
        ItemRequiredArray: JsonArray;
        ScheduleRequiredArray: JsonArray;
    begin
        // --- item property schemas ---
        SessionCodeJObject.Add('type', 'string');
        SessionCodeJObject.Add('description', 'The session code from GetSessions');

        DateJObject.Add('type', 'string');
        DateJObject.Add('description', 'Date in yyyy-MM-dd format');

        TrackNoJObject.Add('type', 'integer');
        TrackNoJObject.Add('description', 'Track number, 1-based');

        StartTimeJObject.Add('type', 'string');
        StartTimeJObject.Add('description', 'Start time in HH:mm format');

        EndTimeJObject.Add('type', 'string');
        EndTimeJObject.Add('description', 'End time in HH:mm format');

        ItemPropertiesJObject.Add('sessionCode', SessionCodeJObject);
        ItemPropertiesJObject.Add('date', DateJObject);
        ItemPropertiesJObject.Add('trackNo', TrackNoJObject);
        ItemPropertiesJObject.Add('startTime', StartTimeJObject);
        ItemPropertiesJObject.Add('endTime', EndTimeJObject);

        ItemRequiredArray.Add('sessionCode');
        ItemRequiredArray.Add('date');
        ItemRequiredArray.Add('trackNo');
        ItemRequiredArray.Add('startTime');
        ItemRequiredArray.Add('endTime');

        // --- items schema (one scheduled session) ---
        ItemsJObject.Add('type', 'object');
        ItemsJObject.Add('properties', ItemPropertiesJObject);
        ItemsJObject.Add('required', ItemRequiredArray);

        // --- schedule array property ---
        ScheduleArrayJObject.Add('type', 'array');
        ScheduleArrayJObject.Add('description', 'Array of scheduled sessions');
        ScheduleArrayJObject.Add('items', ItemsJObject);

        // --- top-level parameters ---
        PropertiesJObject.Add('schedule', ScheduleArrayJObject);
        ScheduleRequiredArray.Add('schedule');
        ParametersJObject.Add('type', 'object');
        ParametersJObject.Add('properties', PropertiesJObject);
        ParametersJObject.Add('required', ScheduleRequiredArray);

        FunctionJObject.Add('name', GetName());
        FunctionJObject.Add('description', 'Saves the proposed conference schedule. Call this after determining the optimal schedule for all sessions using the data from GetSessions and GetEventInfo. Provide a complete schedule for every session.');
        FunctionJObject.Add('parameters', ParametersJObject);

        ToolJObj.Add('type', 'function');
        ToolJObj.Add('function', FunctionJObject);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ScheduleToken: JsonToken;
        ScheduleArray: JsonArray;
        ItemToken: JsonToken;
        i: Integer;
    begin
        AgendaProposal.Reset();
        AgendaProposal.DeleteAll();

        if not Arguments.Get('schedule', ScheduleToken) then
            exit('No schedule provided.');

        ScheduleArray := ScheduleToken.AsArray();
        for i := 0 to ScheduleArray.Count() - 1 do begin
            ScheduleArray.Get(i, ItemToken);
            InsertProposal(ItemToken.AsObject());
        end;

        exit('Saved ' + Format(ScheduleArray.Count()) + ' sessions to the agenda proposal.');
    end;

    local procedure InsertProposal(ItemObj: JsonObject)
    var
        JTok: JsonToken;
        TimeText: Text;
        ParsedTime: Time;
    begin
        AgendaProposal.Init();

        if ItemObj.Get('sessionCode', JTok) then
            AgendaProposal."Session Code" := CopyStr(JTok.AsValue().AsText(), 1, MaxStrLen(AgendaProposal."Session Code"));

        if ItemObj.Get('date', JTok) then
            AgendaProposal."Session Date" := JTok.AsValue().AsDate();

        if ItemObj.Get('trackNo', JTok) then
            AgendaProposal."Track No." := JTok.AsValue().AsInteger();

        if ItemObj.Get('startTime', JTok) then begin
            TimeText := JTok.AsValue().AsText();
            if Evaluate(ParsedTime, TimeText) then
                AgendaProposal."Start Time" := ParsedTime;
        end;

        if ItemObj.Get('endTime', JTok) then begin
            TimeText := JTok.AsValue().AsText();
            if Evaluate(ParsedTime, TimeText) then
                AgendaProposal."End Time" := ParsedTime;
        end;

        if AgendaProposal."Session Code" <> '' then
            AgendaProposal.Insert();
    end;
}
