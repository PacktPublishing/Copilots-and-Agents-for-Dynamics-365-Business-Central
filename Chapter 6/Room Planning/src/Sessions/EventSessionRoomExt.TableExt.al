tableextension 50808 "Event Session Room Ext" extends "Event Session"
{
    fields
    {
        field(50800; "Room Code"; Code[20])
        {
            Caption = 'Room Code';
            DataClassification = CustomerContent;
            TableRelation = Room;
            ToolTip = 'Specifies the room assigned to this session. The room must exist, must not be blocked, must seat the estimated and reserved attendees, and must be free in this time slot.';

            trigger OnValidate()
            var
                RoomAssignmentCheck: Codeunit "Room Assignment Check";
            begin
                RoomAssignmentCheck.CheckRoomAvailability(Rec);
            end;
        }
        field(50801; "Estimated Attendees"; Integer)
        {
            Caption = 'Estimated Attendees';
            DataClassification = CustomerContent;
            MinValue = 0;
            ToolTip = 'Specifies how many attendees you expect at this session. Fill this in from comparable sessions at previous conferences. It is your estimate, not a counted figure.';
        }
        field(50802; "Reserved Attendees"; Integer)
        {
            CalcFormula = count("Session Attendee Res. Entry" where("Session Code" = field("Code")));
            Caption = 'Reserved Attendees';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies how many attendees have reserved this session in the conference app. It is zero until attendees start planning their schedule, and not every attendee who reserves a session turns up.';
        }
        field(50803; "Actual Attendees"; Integer)
        {
            Caption = 'Actual Attendees';
            DataClassification = CustomerContent;
            MinValue = 0;
            ToolTip = 'Specifies how many attendees were in the room. Fill this in after the session. Last year''s actuals are how you judge an estimate.';
        }
    }

    procedure GetAttendeeDemandStyle(): Text
    begin
        if not SessionIsFutureAndScheduled() then
            exit('');

        Rec.CalcFields("Reserved Attendees");
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
