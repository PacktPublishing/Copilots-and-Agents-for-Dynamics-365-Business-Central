permissionset 50842 "Room Planning Agent"
{
    Assignable = true;
    Caption = 'Room Planning - Agent';
    Permissions =
        tabledata Job = R,
        tabledata "Event Session" = RM,
        tabledata Room = R,
        tabledata "Session Attendee Res. Entry" = R,
        tabledata "Room Planning Cue" = RIMD;
}
