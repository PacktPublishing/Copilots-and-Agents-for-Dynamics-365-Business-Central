codeunit 50606 "Get Event Schedule" implements "AOAI Function"
{
    var
        ProjectCode: Code[20];

    procedure SetProjectCode(FromProjectCode: Code[20])
    begin
        ProjectCode := FromProjectCode;
    end;

    procedure GetName(): Text
    begin
        exit('GetEventSchedule');
    end;

    procedure GetPrompt() ToolJObj: JsonObject
    var
        FunctionJObject: JsonObject;
    begin
        ToolJObj.Add('type', 'function');
        FunctionJObject.Add('name', GetName());
        FunctionJObject.Add('description', 'Returns the event schedule constraints: start date, end date, daily start and end times, lunch break window, and the required break duration between sessions. Use this to determine the available time slots for scheduling.');
        FunctionJObject.Add('parameters', NullValue());
        ToolJObj.Add('function', FunctionJObject);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        Job: Record Job;
        ScheduleObj: JsonObject;
        Result: Text;
    begin
        if not Job.Get(ProjectCode) then
            exit('Event project not found.');

        ScheduleObj.Add('startDate', Format(Job."Starting Date", 0, 9));
        ScheduleObj.Add('endDate', Format(Job."Ending Date", 0, 9));
        ScheduleObj.Add('eventStartTime', '09:00');
        ScheduleObj.Add('eventEndTime', '17:00');
        ScheduleObj.Add('lunchStartTime', '13:00');
        ScheduleObj.Add('lunchEndTime', '14:00');
        ScheduleObj.Add('breakBetweenSessions', '15 min');

        ScheduleObj.WriteTo(Result);
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
