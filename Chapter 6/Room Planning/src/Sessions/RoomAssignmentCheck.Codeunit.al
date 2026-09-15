codeunit 50821 "Room Assignment Check"
{
    /// <summary>
    /// Checks a session's room against capacity and other scheduled sessions.
    /// </summary>
    procedure CheckRoomAvailability(var EventSession: Record "Event Session")
    var
        Room: Record Room;
        BlockedReason: Text;
    begin
        if EventSession."Room Code" = '' then
            exit;

        EventSession.CalcFields("Reserved Attendees");

        if not Room.Get(EventSession."Room Code") then
            Error(RoomDoesNotExistErr, EventSession."Room Code");

        if Room.Blocked then begin
            BlockedReason := Room."Blocked Reason";
            if BlockedReason = '' then
                BlockedReason := NoReasonGivenLbl;
            Error(BlockedErr, Room."Code", BlockedReason);
        end;

        if EventSession."Estimated Attendees" <= 0 then
            Error(NoEstimateErr, EventSession."Code");

        if EventSession."Estimated Attendees" > Room.Capacity then
            Error(CapacityEstimateErr, Room."Code", Room.Capacity, EventSession."Code", EventSession."Estimated Attendees");

        if (EventSession."Reserved Attendees" > 0) and (EventSession."Reserved Attendees" > Room.Capacity) then
            Error(CapacityReservedErr, Room."Code", Room.Capacity, EventSession."Code", EventSession."Reserved Attendees");

        CheckDoubleBooking(EventSession, Room."Code");
    end;

    local procedure CheckDoubleBooking(var EventSession: Record "Event Session"; RoomCode: Code[20])
    var
        OtherEventSession: Record "Event Session";
    begin
        OtherEventSession.SetFilter("Code", '<>%1', EventSession."Code");
        OtherEventSession.SetRange("Room Code", RoomCode);
        OtherEventSession.SetRange(Status, OtherEventSession.Status::Scheduled);
        OtherEventSession.SetRange("Date", EventSession.Date);
        if OtherEventSession.FindSet() then
            repeat
                if TimesOverlap(EventSession."Start Time", EventSession."End Time", OtherEventSession."Start Time", OtherEventSession."End Time") then
                    Error(DoubleBookErr, RoomCode, OtherEventSession."Code", OtherEventSession."Start Time", OtherEventSession."End Time");
            until OtherEventSession.Next() = 0;
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
