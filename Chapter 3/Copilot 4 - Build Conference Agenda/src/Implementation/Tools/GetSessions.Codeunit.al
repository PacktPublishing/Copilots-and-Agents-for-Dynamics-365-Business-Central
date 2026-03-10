codeunit 50605 "Get Sessions" implements "AOAI Function"
{
    var
        ProjectCode: Code[20];

    procedure SetProjectCode(FromProjectCode: Code[20])
    begin
        ProjectCode := FromProjectCode;
    end;

    procedure GetName(): Text
    begin
        exit('GetSessions');
    end;

    procedure GetPrompt() ToolJObj: JsonObject
    var
        FunctionJObject: JsonObject;
        ParametersJObject: JsonObject;
        PropertiesJObject: JsonObject;
        StatusFilterJObject: JsonObject;
        EnumArray: JsonArray;
    begin
        EnumArray.Add('draft');
        EnumArray.Add('scheduled');
        EnumArray.Add('all');
        StatusFilterJObject.Add('type', 'string');
        StatusFilterJObject.Add('description', 'Use ''draft'' for sessions not yet scheduled (default). Use ''scheduled'' to get currently scheduled sessions when rescheduling from scratch. Use ''all'' for every session.');
        StatusFilterJObject.Add('enum', EnumArray);
        PropertiesJObject.Add('statusFilter', StatusFilterJObject);
        ParametersJObject.Add('type', 'object');
        ParametersJObject.Add('properties', PropertiesJObject);
        FunctionJObject.Add('name', GetName());
        FunctionJObject.Add('description', 'Returns conference sessions for the current event project. Use statusFilter to get draft sessions (default), currently scheduled sessions (for rescheduling), or all sessions. Each session includes code, name, description, speakers, and duration in minutes.');
        FunctionJObject.Add('parameters', ParametersJObject);
        ToolJObj.Add('type', 'function');
        ToolJObj.Add('function', FunctionJObject);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        EventSession: Record "Event Session";
        SessionsArray: JsonArray;
        SessionObj: JsonObject;
        Result: Text;
        StatusFilterToken: JsonToken;
        StatusFilter: Text;
    begin
        EventSession.SetRange("Project Code", ProjectCode);
        if Arguments.Get('statusFilter', StatusFilterToken) then
            StatusFilter := LowerCase(StatusFilterToken.AsValue().AsText());
        case StatusFilter of
            'scheduled':
                EventSession.SetRange(Status, "Event Session Status"::Scheduled);
            'all':
                ; // No status filter
            else
                EventSession.SetRange(Status, "Event Session Status"::Draft); // default
        end;
        if EventSession.FindSet() then
            repeat
                Clear(SessionObj);
                SessionObj.Add('sessionCode', EventSession."Code");
                SessionObj.Add('name', EventSession.Name);
                SessionObj.Add('description', EventSession.Description);
                SessionObj.Add('speaker1', EventSession.Speaker1);
                SessionObj.Add('speaker2', EventSession.Speaker2);
                SessionObj.Add('speaker3', EventSession.Speaker3);
                SessionObj.Add('speaker4', EventSession.Speaker4);
                SessionObj.Add('durationMinutes', EventSession."Duration (min)");
                SessionsArray.Add(SessionObj);
            until EventSession.Next() = 0;

        SessionsArray.WriteTo(Result);
        exit(Result);
    end;
}
