codeunit 50821 "Room Assignment Check"
{
    procedure CheckRoomAvailability(var RoomAssignmentBuffer: Record "Room Assignment Buffer")
    var
        Room: Record Room;
        BlockedReason: Text;
    begin
        if RoomAssignmentBuffer."Room Code" = '' then
            exit;

        if not Room.Get(RoomAssignmentBuffer."Room Code") then
            Error(RoomDoesNotExistErr, RoomAssignmentBuffer."Room Code");

        if Room.Blocked then begin
            BlockedReason := Room."Blocked Reason";
            if BlockedReason = '' then
                BlockedReason := NoReasonGivenLbl;
            Error(BlockedErr, Room."Code", BlockedReason);
        end;

        if RoomAssignmentBuffer."Estimated Attendees" <= 0 then
            Error(NoEstimateErr, RoomAssignmentBuffer."Session Code");

        if RoomAssignmentBuffer."Estimated Attendees" > Room.Capacity then
            Error(CapacityEstimateErr, Room."Code", Room.Capacity, RoomAssignmentBuffer."Session Code", RoomAssignmentBuffer."Estimated Attendees");

        if (RoomAssignmentBuffer."Reserved Attendees" > 0) and (RoomAssignmentBuffer."Reserved Attendees" > Room.Capacity) then
            Error(CapacityReservedErr, Room."Code", Room.Capacity, RoomAssignmentBuffer."Session Code", RoomAssignmentBuffer."Reserved Attendees");

        CheckBufferDoubleBooking(RoomAssignmentBuffer, Room."Code");
        CheckSessionDoubleBooking(RoomAssignmentBuffer, Room."Code");
    end;

    local procedure CheckBufferDoubleBooking(var RoomAssignmentBuffer: Record "Room Assignment Buffer"; RoomCode: Code[20])
    var
        OtherBuffer: Record "Room Assignment Buffer";
    begin
        OtherBuffer.Copy(RoomAssignmentBuffer, true);
        OtherBuffer.SetFilter("Session Code", '<>%1', RoomAssignmentBuffer."Session Code");
        OtherBuffer.SetRange("Room Code", RoomCode);
        OtherBuffer.SetRange("Date", RoomAssignmentBuffer.Date);
        OtherBuffer.SetRange(Status, OtherBuffer.Status::Scheduled);
        if OtherBuffer.FindSet() then
            repeat
                if TimesOverlap(RoomAssignmentBuffer."Start Time", RoomAssignmentBuffer."End Time", OtherBuffer."Start Time", OtherBuffer."End Time") then
                    Error(DoubleBookErr, RoomCode, OtherBuffer."Session Code", OtherBuffer."Start Time", OtherBuffer."End Time");
            until OtherBuffer.Next() = 0;
    end;

    local procedure CheckSessionDoubleBooking(var RoomAssignmentBuffer: Record "Room Assignment Buffer"; RoomCode: Code[20])
    var
        EventSession: Record "Event Session";
        BufferLookup: Record "Room Assignment Buffer";
    begin
        EventSession.SetRange("Room Code", RoomCode);
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetRange("Date", RoomAssignmentBuffer.Date);
        if EventSession.FindSet() then
            repeat
                BufferLookup.Copy(RoomAssignmentBuffer, true);
                if not BufferLookup.Get(EventSession."Code") then
                    if TimesOverlap(RoomAssignmentBuffer."Start Time", RoomAssignmentBuffer."End Time", EventSession."Start Time", EventSession."End Time") then
                        Error(DoubleBookErr, RoomCode, EventSession."Code", EventSession."Start Time", EventSession."End Time");
            until EventSession.Next() = 0;
    end;

    local procedure TimesOverlap(StartTime1: Time; EndTime1: Time; StartTime2: Time; EndTime2: Time): Boolean
    begin
        if (StartTime1 = 0T) or (EndTime1 = 0T) or (StartTime2 = 0T) or (EndTime2 = 0T) then
            exit(false);
        exit((StartTime1 < EndTime2) and (StartTime2 < EndTime1));
    end;

    var
        RoomDoesNotExistErr: Label 'Room %1 does not exist.';
        NoReasonGivenLbl: Label 'No reason given.';
        BlockedErr: Label 'Room %1 is blocked: %2. Choose another room.';
        NoEstimateErr: Label 'Session %1 has no estimated attendees. Fill in Estimated Attendees before assigning a room.';
        CapacityEstimateErr: Label 'Room %1 seats %2, but session %3 estimates %4 attendees. Choose a room with at least %4 seats.';
        CapacityReservedErr: Label 'Room %1 seats %2, but session %3 has %4 reserved attendees. Choose a room with at least %4 seats.';
        DoubleBookErr: Label 'Room %1 is already assigned to session %2, which runs from %3 to %4. Choose a room that is free in this slot.';
}
