// ----------------------------------------------------------------------------
// Permission set 98216 - Attendee Assistant organizer
// For the organizers: setup, demo actions and the notes on the change log.
// Combine with "Room Planning Admin" (Chapter 6). Never assign it to the
// identity behind the MCP connection.
// ----------------------------------------------------------------------------
permissionset 98216 "CE Attendee Admin"
{
    Assignable = true;
    Caption = 'Cronus Events - Attendee Assistant Organizer';
    IncludedPermissionSets = "CE Attendee MCP";

    Permissions =
        tabledata "CE Attendee Setup" = RIMD,
        tabledata "CE Session Change" = RIM,
        page "CE Attendee Setup" = X,
        page "CE Session Changes" = X,
        codeunit "CE Attendee Demo Data" = X;
}
