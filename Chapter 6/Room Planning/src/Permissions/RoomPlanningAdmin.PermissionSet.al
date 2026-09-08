permissionset 50841 "Room Planning Admin"
{
    Assignable = true;
    Caption = 'Room Planning - Admin';
    Permissions =
        tabledata Room = RIMD,
        tabledata "Session Attendee Res. Entry" = RIMD,
        tabledata "Room Assignment Buffer" = RIMD,
        tabledata "Similar Session Buffer" = RIMD,
        tabledata "Room Planning Cue" = RIMD,
        tabledata "Event Session" = RIMD,
        tabledata Job = RID,
        codeunit "Find Similar Sessions" = X,
        page "Room List" = X,
        page "Room Card" = X,
        page "Session Attendee Res. Entries" = X,
        page "Event Session Card" = X,
        page "Session Attendee Res. FactBox" = X,
        page "Room Planning Cue" = X,
        page "Assign Rooms" = X,
        page "Similar Event Sessions" = X,
        page "Room Planning Demo Data" = X,
        page "Event Sessions" = X;
}
