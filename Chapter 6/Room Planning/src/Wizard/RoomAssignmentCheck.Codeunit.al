codeunit 50821 "Room Assignment Check"
{
    /// <summary>
    /// Checks one wizard row against the rooms, the other wizard rows, and the stored sessions.
    /// The row that is passed in is never filtered or repositioned, so the wizard can call this
    /// from OnValidate without losing the record the user is editing.
    /// </summary>
    procedure CheckRoomAvailability(var FromRoomAssignmentBuffer: Record "Room Assignment Buffer")
    var
        Room: Record Room;
        BlockedReason: Text;
    begin
        if FromRoomAssignmentBuffer."Room Code" = '' then
            exit;

        if not Room.Get(FromRoomAssignmentBuffer."Room Code") then
            Error(RoomDoesNotExistErr, FromRoomAssignmentBuffer."Room Code");

        if Room.Blocked then begin
            BlockedReason := Room."Blocked Reason";
            if BlockedReason = '' then
                BlockedReason := NoReasonGivenLbl;
            Error(BlockedErr, Room."Code", BlockedReason);
        end;

        if FromRoomAssignmentBuffer."Estimated Attendees" <= 0 then
            Error(NoEstimateErr, FromRoomAssignmentBuffer."Session Code");

        if FromRoomAssignmentBuffer."Estimated Attendees" > Room.Capacity then
            Error(CapacityEstimateErr, Room."Code", Room.Capacity, FromRoomAssignmentBuffer."Session Code", FromRoomAssignmentBuffer."Estimated Attendees");

        if (FromRoomAssignmentBuffer."Reserved Attendees" > 0) and (FromRoomAssignmentBuffer."Reserved Attendees" > Room.Capacity) then
            Error(CapacityReservedErr, Room."Code", Room.Capacity, FromRoomAssignmentBuffer."Session Code", FromRoomAssignmentBuffer."Reserved Attendees");

        CheckDoubleBookingInWizard(FromRoomAssignmentBuffer, Room."Code");
        CheckDoubleBookingOnSessions(FromRoomAssignmentBuffer, Room."Code");
    end;

    local procedure CheckDoubleBookingInWizard(var FromRoomAssignmentBuffer: Record "Room Assignment Buffer"; RoomCode: Code[20])
    var
        RoomAssignmentBuffer: Record "Room Assignment Buffer";
    begin
        // Share the wizard's temporary table, then filter the copy. Filters and position are per
        // record variable, so the row being validated stays where the user left it.
        RoomAssignmentBuffer.Copy(FromRoomAssignmentBuffer, true);
        RoomAssignmentBuffer.Reset();
        RoomAssignmentBuffer.SetFilter("Session Code", '<>%1', FromRoomAssignmentBuffer."Session Code");
        RoomAssignmentBuffer.SetRange("Room Code", RoomCode);
        RoomAssignmentBuffer.SetRange("Date", FromRoomAssignmentBuffer.Date);
        RoomAssignmentBuffer.SetRange(Status, RoomAssignmentBuffer.Status::Scheduled);
        if RoomAssignmentBuffer.FindSet() then
            repeat
                if TimesOverlap(FromRoomAssignmentBuffer."Start Time", FromRoomAssignmentBuffer."End Time", RoomAssignmentBuffer."Start Time", RoomAssignmentBuffer."End Time") then
                    Error(DoubleBookErr, RoomCode, RoomAssignmentBuffer."Session Code", RoomAssignmentBuffer."Start Time", RoomAssignmentBuffer."End Time");
            until RoomAssignmentBuffer.Next() = 0;
    end;

    local procedure CheckDoubleBookingOnSessions(var FromRoomAssignmentBuffer: Record "Room Assignment Buffer"; RoomCode: Code[20])
    var
        EventSession: Record "Event Session";
        RoomAssignmentBuffer: Record "Room Assignment Buffer";
    begin
        RoomAssignmentBuffer.Copy(FromRoomAssignmentBuffer, true);
        RoomAssignmentBuffer.Reset();

        EventSession.SetRange("Room Code", RoomCode);
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetRange("Date", FromRoomAssignmentBuffer.Date);
        if EventSession.FindSet() then
            repeat
                // Sessions the wizard holds are judged on their wizard row, not on the stored room.
                if not RoomAssignmentBuffer.Get(EventSession."Code") then
                    if TimesOverlap(FromRoomAssignmentBuffer."Start Time", FromRoomAssignmentBuffer."End Time", EventSession."Start Time", EventSession."End Time") then
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
