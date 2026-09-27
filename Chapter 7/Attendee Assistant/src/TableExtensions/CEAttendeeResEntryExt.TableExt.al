// ----------------------------------------------------------------------------
// Table extension 98203 - Session attendee reservation (Chapter 7 additions)
// Chapter 6 defines "Session Attendee Res. Entry": one row per attendee email
// and session, "reserved in the conference app". The attendee assistant is
// that app, so its personal agenda is this table. Every agenda entry raises
// Reserved Attendees, the demand signal the Room Planning Agent uses.
// Chapter 7 adds the rating and read-only views of the session, so the
// agenda tools return what an attendee needs without a second call.
// ----------------------------------------------------------------------------
tableextension 98203 "CE Attendee Res. Entry Ext" extends "Session Attendee Res. Entry"
{
    fields
    {
        field(98200; "Event Project No."; Code[20])
        {
            Caption = 'Event Project No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session"."Project Code" where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98201; "Session Name"; Text[100])
        {
            Caption = 'Session Name';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session".Name where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98202; "Session Date"; Date)
        {
            Caption = 'Session Date';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session"."Date" where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98203; "Start Time"; Time)
        {
            Caption = 'Start Time';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session"."Start Time" where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98204; "End Time"; Time)
        {
            Caption = 'End Time';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session"."End Time" where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98205; "Room Code"; Code[20])
        {
            Caption = 'Room Code';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session"."Room Code" where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98206; "Session Status"; Enum "Event Session Status")
        {
            Caption = 'Session Status';
            FieldClass = FlowField;
            CalcFormula = lookup("Event Session".Status where("Code" = field("Session Code")));
            Editable = false;
        }
        field(98210; Rating; Integer)
        {
            Caption = 'Rating';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 5;
            Editable = false;
            ToolTip = 'Specifies the rating (1 to 5) the attendee gave the session after attending it. 0 means not rated.';
        }
        field(98211; "Rated At"; DateTime)
        {
            Caption = 'Rated At';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
