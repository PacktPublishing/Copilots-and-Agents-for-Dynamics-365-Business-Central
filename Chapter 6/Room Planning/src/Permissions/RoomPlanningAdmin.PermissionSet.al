permissionset 50841 "Room Planning Admin"
{
    Assignable = true;
    Caption = 'Room Planning - Admin';
    Permissions =
        tabledata Room = RIMD,
        tabledata "Session Attendee Res. Entry" = RIMD,
        tabledata "Similar Session Buffer" = RIMD,
        tabledata "Room Planning Cue" = RIMD,
        tabledata "Event Session" = RIMD,
        tabledata Job = RID,
        codeunit "Find Similar Sessions" = X,
        codeunit "Room Assignment Check" = X,
        page "Job List" = X,
        page "Room List" = X,
        page "Room Card" = X,
        page "Session Attendee Res. Entries" = X,
        page "Session Attendee Res. FactBox" = X,
        page "Room Planning Cue" = X,
        page "Room Planning Role Center" = X,
        page "Similar Event Sessions" = X,
        page "Event Demo Data" = X,
        page "Event Sessions" = X;
}
