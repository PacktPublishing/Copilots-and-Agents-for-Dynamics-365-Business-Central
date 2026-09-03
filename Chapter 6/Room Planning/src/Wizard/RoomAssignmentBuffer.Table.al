table 50803 "Room Assignment Buffer"
{
    Caption = 'Room Assignment Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Session Code"; Code[20])
        {
            Caption = 'Session Code';
            NotBlank = true;
            ToolTip = 'Specifies the session to assign a room to.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the session title.';
        }
        field(3; "Date"; Date)
        {
            Caption = 'Date';
            ToolTip = 'Specifies the scheduled date for the session.';
        }
        field(4; "Start Time"; Time)
        {
            Caption = 'Start Time';
            ToolTip = 'Specifies the scheduled start time.';
        }
        field(5; "End Time"; Time)
        {
            Caption = 'End Time';
            ToolTip = 'Specifies the scheduled end time.';
        }
        field(6; Status; Enum "Event Session Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the current status of the session.';
        }
        field(7; "Estimated Attendees"; Integer)
        {
            Caption = 'Estimated Attendees';
            ToolTip = 'Specifies how many attendees you expect at this session. Fill this in from comparable sessions at previous conferences. It is your estimate, not a counted figure.';
        }
        field(8; "Reserved Attendees"; Integer)
        {
            Caption = 'Reserved Attendees';
            ToolTip = 'Specifies how many attendees have reserved this session in the conference app. It is zero until attendees start planning their schedule, and not every attendee who reserves a session turns up.';
        }
        field(9; "Room Code"; Code[20])
        {
            Caption = 'Room Code';
            TableRelation = Room;
            ToolTip = 'Specifies the room for this session. A room is too small when its capacity is below the number of attendees you estimate. Two sessions cannot share a room in the same slot.';

            trigger OnValidate()
            var
                RoomAssignmentCheck: Codeunit "Room Assignment Check";
            begin
                RoomAssignmentCheck.CheckRoomAvailability(Rec);
            end;
        }
        field(10; "Original Room Code"; Code[20])
        {
            Caption = 'Original Room Code';
            Editable = false;
            ToolTip = 'Specifies the room code that was on the session when the list was loaded. Finish uses it to detect change.';
        }
    }

    keys
    {
        key(PK; "Session Code")
        {
            Clustered = true;
        }
        key(SK; "Date", "Start Time", "Session Code")
        {
        }
    }

    procedure GetAttendeeDemandStyle(): Text
    begin
        if not SessionIsFutureAndScheduled() then
            exit('');

        if Rec."Reserved Attendees" = 0 then
            exit('');

        if SessionIsOverCapacity() then
            exit(UnfavorableStyleTxt);

        if ReservedAttendeesExceedEstimate() then
            exit(AmbiguousStyleTxt);

        exit('');
    end;

    local procedure SessionIsFutureAndScheduled(): Boolean
    begin
        if Rec.Date < WorkDate() then
            exit(false);
        exit(Rec.Status = Rec.Status::Scheduled);
    end;

    local procedure SessionIsOverCapacity(): Boolean
    var
        Room: Record Room;
    begin
        if Rec."Room Code" = '' then
            exit(false);
        if not Room.Get(Rec."Room Code") then
            exit(false);
        exit(Rec."Reserved Attendees" > Room.Capacity);
    end;

    local procedure ReservedAttendeesExceedEstimate(): Boolean
    begin
        exit(Rec."Reserved Attendees" > Rec."Estimated Attendees");
    end;

    var
        UnfavorableStyleTxt: Label 'Unfavorable', Locked = true;
        AmbiguousStyleTxt: Label 'Ambiguous', Locked = true;
}
