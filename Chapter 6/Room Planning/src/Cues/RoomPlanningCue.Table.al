table 50807 "Room Planning Cue"
{
    Caption = 'Room Planning Cue';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Sessions without a Room"; Integer)
        {
            CalcFormula = count("Event Session" where(Status = const(Scheduled), "Room Code" = const(''), "Date" = field("Date Filter"), "Project Code" = field("Project Code Filter")));
            Caption = 'Sessions without a Room';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies how many scheduled sessions in the date and event filters have no room yet.';
        }
        field(3; "Over Capacity Sessions"; Integer)
        {
            Caption = 'Over Capacity Sessions';
            Editable = false;
            ToolTip = 'Specifies how many future scheduled sessions in the event filter have more reserved attendees than the assigned room can seat.';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Project Code Filter"; Code[20])
        {
            Caption = 'Project Code Filter';
            FieldClass = FlowFilter;
            TableRelation = Job;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure InsertRecord()
    var
        RoomPlanningCue: Record "Room Planning Cue";
    begin
        // Insert through a separate variable. Resetting Rec here would drop the flow filters the
        // FactBox sets from the session row.
        if RoomPlanningCue.Get('') then
            exit;
        RoomPlanningCue.Init();
        RoomPlanningCue."Primary Key" := '';
        RoomPlanningCue.Insert();
    end;

    procedure CountOverCapacitySessions(): Integer
    var
        EventSession: Record "Event Session";
        OverCapacityCount: Integer;
    begin
        SetAssignedFutureSessionFilter(EventSession);
        if EventSession.FindSet() then
            repeat
                if SessionIsOverCapacity(EventSession) then
                    OverCapacityCount += 1;
            until EventSession.Next() = 0;
        exit(OverCapacityCount);
    end;

    procedure DrillDownOverCapacitySessions()
    var
        EventSession: Record "Event Session";
    begin
        // Over capacity compares a FlowField against the room, so it cannot be a filter. Mark the
        // rows instead of building a filter string that grows with the schedule.
        SetAssignedFutureSessionFilter(EventSession);
        if EventSession.FindSet() then
            repeat
                if SessionIsOverCapacity(EventSession) then
                    EventSession.Mark(true);
            until EventSession.Next() = 0;

        EventSession.MarkedOnly(true);
        Page.Run(Page::"Event Sessions", EventSession);
    end;

    local procedure SetAssignedFutureSessionFilter(var EventSession: Record "Event Session")
    var
        ProjectCodeFilter: Text;
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Date", '%1..', WorkDate());
        EventSession.SetFilter("Room Code", '<>%1', '');

        ProjectCodeFilter := Rec.GetFilter("Project Code Filter");
        if ProjectCodeFilter <> '' then
            EventSession.SetFilter("Project Code", ProjectCodeFilter);
    end;

    local procedure SessionIsOverCapacity(EventSession: Record "Event Session"): Boolean
    var
        Room: Record Room;
    begin
        EventSession.CalcFields("Reserved Attendees");
        if not Room.Get(EventSession."Room Code") then
            exit(false);
        exit(EventSession."Reserved Attendees" > Room.Capacity);
    end;
}
