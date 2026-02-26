codeunit 50608 "Get Current Agenda" implements "AOAI Function"
{
    var
        ProjectCode: Code[20];

    procedure SetProjectCode(FromProjectCode: Code[20])
    begin
        ProjectCode := FromProjectCode;
    end;

    procedure GetName(): Text
    begin
        exit('GetCurrentAgenda');
    end;

    procedure GetPrompt() ToolJObj: JsonObject
    var
        FunctionJObject: JsonObject;
    begin
        ToolJObj.Add('type', 'function');
        FunctionJObject.Add('name', GetName());
        FunctionJObject.Add('description', 'Returns the current conference agenda — sessions that are already scheduled (status Scheduled) for the event project. Use this when the user asks to view, show, or review the current agenda.');
        FunctionJObject.Add('parameters', NullValue());
        ToolJObj.Add('function', FunctionJObject);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        EventSession: Record "Event Session";
        AgendaArray: JsonArray;
        SessionObj: JsonObject;
        Result: Text;
    begin
        EventSession.SetRange("Project Code", ProjectCode);
        EventSession.SetRange(Status, "Event Session Status"::Scheduled);
        if not EventSession.FindSet() then
            exit('No sessions are currently scheduled.');

        repeat
            Clear(SessionObj);
            SessionObj.Add('sessionCode', EventSession."Code");
            SessionObj.Add('name', EventSession.Name);
            SessionObj.Add('date', Format(EventSession."Date", 0, 9));
            SessionObj.Add('trackNo', EventSession."Track No.");
            SessionObj.Add('startTime', Format(EventSession."Start Time", 0, 9));
            SessionObj.Add('endTime', Format(EventSession."End Time", 0, 9));
            AgendaArray.Add(SessionObj);
        until EventSession.Next() = 0;

        AgendaArray.WriteTo(Result);
        exit(Result);
    end;

    local procedure NullValue(): JsonValue
    var
        JNull: JsonValue;
    begin
        JNull.SetValueToNull();
        exit(JNull);
    end;
}
