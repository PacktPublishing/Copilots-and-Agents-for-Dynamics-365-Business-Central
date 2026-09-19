codeunit 50821 "Room Assignment Check"
{
    /// <summary>
    /// Checks a session's room against capacity and other scheduled sessions.
    /// </summary>
    procedure CheckRoomAvailability(var EventSession: Record "Event Session")
    var
        Room: Record Room;
        ConflictingSession: Record "Event Session";
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

        if FindDoubleBookingConflict(EventSession, ConflictingSession) then
            Error(DoubleBookErr, EventSession."Room Code", ConflictingSession."Code", ConflictingSession."Start Time", ConflictingSession."End Time");
    end;

    /// <summary>
    /// Returns true when any scheduled session has an empty Room Code.
    /// </summary>
    procedure ScheduledSessionsWithoutRoomExist(): Boolean
    var
        EventSession: Record "Event Session";
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetRange("Room Code", '');
        exit(not EventSession.IsEmpty());
    end;

    /// <summary>
    /// Returns true when any scheduled session's demand (estimated or reserved attendees)
    /// exceeds the assigned room capacity.
    /// </summary>
    procedure OverCapacityAssignmentsExist(): Boolean
    var
        EventSession: Record "Event Session";
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Room Code", '<>%1', '');
        if not EventSession.FindSet() then
            exit(false);

        repeat
            if SessionDemandExceedsCapacity(EventSession) then
                exit(true);
        until EventSession.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Returns true when any two scheduled sessions share a room on the same date with overlapping times.
    /// </summary>
    procedure DoubleBookedAssignmentsExist(): Boolean
    var
        EventSession: Record "Event Session";
        ConflictingSession: Record "Event Session";
    begin
        EventSession.SetRange(Status, EventSession.Status::Scheduled);
        EventSession.SetFilter("Room Code", '<>%1', '');
        if not EventSession.FindSet() then
            exit(false);

        repeat
            if FindDoubleBookingConflict(EventSession, ConflictingSession) then
                exit(true);
        until EventSession.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// True when Max(Estimated Attendees, Reserved Attendees) exceeds the assigned room capacity.
    /// </summary>
    procedure SessionDemandExceedsCapacity(EventSession: Record "Event Session"): Boolean
    var
        Room: Record Room;
        Demand: Integer;
    begin
        if EventSession."Room Code" = '' then
            exit(false);
        if not Room.Get(EventSession."Room Code") then
            exit(false);

        EventSession.CalcFields("Reserved Attendees");
        Demand := EventSession."Estimated Attendees";
        if EventSession."Reserved Attendees" > Demand then
            Demand := EventSession."Reserved Attendees";

        exit(Demand > Room.Capacity);
    end;

    /// <summary>
    /// Finds another scheduled session that uses the same room on the same date with overlapping times.
    /// </summary>
    procedure FindDoubleBookingConflict(EventSession: Record "Event Session"; var ConflictingSession: Record "Event Session"): Boolean
    begin
        Clear(ConflictingSession);
        if EventSession."Room Code" = '' then
            exit(false);

        ConflictingSession.SetFilter("Code", '<>%1', EventSession."Code");
        ConflictingSession.SetRange("Room Code", EventSession."Room Code");
        ConflictingSession.SetRange(Status, ConflictingSession.Status::Scheduled);
        ConflictingSession.SetRange("Date", EventSession.Date);
        if not ConflictingSession.FindSet() then
            exit(false);

        repeat
            if TimesOverlap(EventSession."Start Time", EventSession."End Time", ConflictingSession."Start Time", ConflictingSession."End Time") then
                exit(true);
        until ConflictingSession.Next() = 0;

        exit(false);
    end;

    procedure TimesOverlap(StartTime1: Time; EndTime1: Time; StartTime2: Time; EndTime2: Time): Boolean
    begin
        if (StartTime1 = 0T) or (EndTime1 = 0T) or (StartTime2 = 0T) or (EndTime2 = 0T) then
            exit(false);
        exit((StartTime1 < EndTime2) and (StartTime2 < EndTime1));
    end;

    var
        RoomDoesNotExistErr: Label 'Room %1 does not exist. Open Rooms and pick an existing room code; do not invent a new one.', Comment = '%1 = Room code';
        NoReasonGivenLbl: Label 'No reason given.';
        BlockedErr: Label 'Room %1 is blocked: %2. Choose another room that is not blocked.', Comment = '%1 = Room code, %2 = Blocked reason';
        NoEstimateErr: Label 'Session %1 has no estimated attendees. Set Estimated Attendees first (from Reserved Attendees or Find Similar past Actual Attendees), then assign a room.', Comment = '%1 = Session code';
        CapacityEstimateErr: Label 'Room %1 seats %2, but session %3 estimates %4 attendees. Choose a room with at least %4 seats, or lower the estimate if it was wrong.', Comment = '%1 = Room code, %2 = Room capacity, %3 = Session code, %4 = Estimated attendees';
        CapacityReservedErr: Label 'Room %1 seats %2, but session %3 has %4 reserved attendees. Choose a room with at least %4 seats.', Comment = '%1 = Room code, %2 = Room capacity, %3 = Session code, %4 = Reserved attendees';
        DoubleBookErr: Label 'Room %1 is already assigned to session %2, which runs from %3 to %4. Choose a different room that is free in this date and time slot.', Comment = '%1 = Room code, %2 = Conflicting session code, %3 = Start time, %4 = End time';
}
