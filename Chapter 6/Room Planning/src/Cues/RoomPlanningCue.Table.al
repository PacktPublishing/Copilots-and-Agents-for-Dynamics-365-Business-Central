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
            CalcFormula = count("Event Session" where(Status = const(Scheduled), "Room Code" = const(''), "Date" = field("Date Filter")));
            Caption = 'Sessions without a Room';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies how many scheduled sessions in the date filter have no room yet.';
        }
        field(3; "Over Capacity Sessions"; Integer)
        {
            Caption = 'Over Capacity Sessions';
            Editable = false;
            ToolTip = 'Specifies how many future scheduled sessions have more reserved attendees than the assigned room can seat.';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
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
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
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

    local procedure SetAssignedFutureSessionFilter(var EventSession: Record "Event Session")
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Date", '%1..', WorkDate());
        EventSession.SetFilter("Room Code", '<>%1', '');
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
