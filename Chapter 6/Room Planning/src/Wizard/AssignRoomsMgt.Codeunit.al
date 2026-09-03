codeunit 50822 "Assign Rooms Mgt"
{
    procedure Load(var RoomAssignmentBuffer: Record "Room Assignment Buffer"; ProjectCode: Code[20])
    var
        EventSession: Record "Event Session";
    begin
        RoomAssignmentBuffer.Reset();
        RoomAssignmentBuffer.DeleteAll();

        SetThisEventFilter(EventSession, ProjectCode);
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Date", '%1..', WorkDate());
        if EventSession.FindSet() then
            repeat
                InsertBufferRow(RoomAssignmentBuffer, EventSession);
            until EventSession.Next() = 0;

        EventSession.Reset();
        SetThisEventFilter(EventSession, ProjectCode);
        EventSession.SetRange(Status, EventSession.Status::Cancelled);
        EventSession.SetFilter("Room Code", '<>%1', '');
        EventSession.SetFilter("Date", '%1..', WorkDate());
        if EventSession.FindSet() then
            repeat
                if not RoomAssignmentBuffer.Get(EventSession."Code") then
                    InsertBufferRow(RoomAssignmentBuffer, EventSession);
            until EventSession.Next() = 0;
    end;

    procedure Finish(var RoomAssignmentBuffer: Record "Room Assignment Buffer"): Boolean
    begin
        if not ConfirmFinish() then
            exit(false);

        ApplyRoomChanges(RoomAssignmentBuffer);
        exit(true);
    end;

    local procedure ConfirmFinish(): Boolean
    var
        IsSkipConfirm: Boolean;
    begin
        OnBeforeFinish(IsSkipConfirm);
        if IsSkipConfirm then
            exit(true);
        exit(Confirm(ApplyRoomChangesQst));
    end;

    local procedure ApplyRoomChanges(var RoomAssignmentBufferOnPage: Record "Room Assignment Buffer")
    var
        RoomAssignmentBuffer: Record "Room Assignment Buffer";
    begin
        // Walk a shared copy so the wizard page keeps its own filters, sorting and position.
        RoomAssignmentBuffer.Copy(RoomAssignmentBufferOnPage, true);
        RoomAssignmentBuffer.Reset();
        if RoomAssignmentBuffer.FindSet() then
            repeat
                ApplyRoomChange(RoomAssignmentBuffer);
            until RoomAssignmentBuffer.Next() = 0;
    end;

    local procedure ApplyRoomChange(var RoomAssignmentBuffer: Record "Room Assignment Buffer")
    var
        EventSession: Record "Event Session";
    begin
        EventSession.Get(RoomAssignmentBuffer."Session Code");
        if EventSession.Status = EventSession.Status::Cancelled then
            ClearCancelledSessionRoom(EventSession)
        else
            AssignChangedRoom(EventSession, RoomAssignmentBuffer);
    end;

    local procedure ClearCancelledSessionRoom(var EventSession: Record "Event Session")
    begin
        if EventSession."Room Code" = '' then
            exit;
        EventSession.Validate("Room Code", '');
        EventSession.Modify(true);
    end;

    local procedure AssignChangedRoom(var EventSession: Record "Event Session"; var RoomAssignmentBuffer: Record "Room Assignment Buffer")
    var
        RoomAssignmentCheck: Codeunit "Room Assignment Check";
    begin
        if RoomAssignmentBuffer."Room Code" = RoomAssignmentBuffer."Original Room Code" then
            exit;
        RoomAssignmentCheck.CheckRoomAvailability(RoomAssignmentBuffer);
        EventSession.Validate("Room Code", RoomAssignmentBuffer."Room Code");
        EventSession.Modify(true);
    end;

    local procedure SetThisEventFilter(var EventSession: Record "Event Session"; ProjectCode: Code[20])
    begin
        if ProjectCode <> '' then
            EventSession.SetRange("Project Code", ProjectCode);
    end;

    local procedure InsertBufferRow(var RoomAssignmentBuffer: Record "Room Assignment Buffer"; EventSession: Record "Event Session")
    begin
        EventSession.CalcFields("Reserved Attendees");
        RoomAssignmentBuffer.Init();
        RoomAssignmentBuffer."Session Code" := EventSession."Code";
        RoomAssignmentBuffer.Name := EventSession.Name;
        RoomAssignmentBuffer.Date := EventSession.Date;
        RoomAssignmentBuffer."Start Time" := EventSession."Start Time";
        RoomAssignmentBuffer."End Time" := EventSession."End Time";
        RoomAssignmentBuffer.Status := EventSession.Status;
        RoomAssignmentBuffer."Estimated Attendees" := EventSession."Estimated Attendees";
        RoomAssignmentBuffer."Reserved Attendees" := EventSession."Reserved Attendees";
        RoomAssignmentBuffer."Room Code" := EventSession."Room Code";
        RoomAssignmentBuffer."Original Room Code" := EventSession."Room Code";
        RoomAssignmentBuffer.Insert();
    end;

    var
        ApplyRoomChangesQst: Label 'Apply the room changes?';

    [IntegrationEvent(false, false)]
    procedure OnBeforeFinish(var SkipConfirm: Boolean)
    begin
    end;
}
