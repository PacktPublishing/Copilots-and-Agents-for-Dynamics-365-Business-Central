// ----------------------------------------------------------------------------
// Table extension 98202 - Event session (Chapter 7 additions)
// "Event Session" comes from Chapter 3 (Common) and already carries the
// program: code, name, description, Speaker1-4, Date, Start Time, End Time,
// Track No., Status and Project Code. Chapter 6 (Room Planning) adds the
// Room Code and the attendee figures. Chapter 7 adds what an attendee asks
// about during the event: the room by name and floor, when the session last
// changed, and the attendees' ratings.
// ----------------------------------------------------------------------------
tableextension 98202 "CE Event Session Ext" extends "Event Session"
{
    fields
    {
        field(98200; "Room Name"; Text[100])
        {
            Caption = 'Room Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Room.Name where("Code" = field("Room Code")));
            Editable = false;
            ToolTip = 'Specifies the name of the room assigned to the session, as attendees see it on the signs.';
        }
        field(98201; "Room Floor"; Integer)
        {
            Caption = 'Room Floor';
            FieldClass = FlowField;
            CalcFormula = lookup(Room.Floor where("Code" = field("Room Code")));
            Editable = false;
            ToolTip = 'Specifies the floor of the room assigned to the session. 0 is the ground floor.';
        }
        field(98202; "Last Changed At"; DateTime)
        {
            Caption = 'Last Changed At';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies when the organizers last changed the room, the schedule, the speaker or the status of a session that was already in the program.';
        }
        field(98203; "Average Rating"; Decimal)
        {
            Caption = 'Average Rating';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 1 : 1;
            ToolTip = 'Specifies the average rating (1 to 5) given by the attendees who rated the session.';
        }
        field(98204; "Ratings Count"; Integer)
        {
            Caption = 'Ratings Count';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies how many attendees rated the session.';
        }
    }
}
