// ----------------------------------------------------------------------------
// Permission set 98212 - Attendee Assistant
// Assign to the user (or service principal) behind the Copilot Studio MCP
// connection. It reads the program (Chapter 3 sessions, Chapter 6 rooms) and
// writes only reservations, ratings and the session rating average.
// The MCP configuration decides which tools exist; this permission set
// decides what those tools may touch in the database.
// ----------------------------------------------------------------------------
permissionset 98212 "CE Attendee MCP"
{
    Assignable = true;
    Caption = 'Cronus Events - Attendee Assistant';

    Permissions =
        tabledata "Event Session" = RM,                   // M: rating average refreshed by rateSession
        tabledata Room = R,
        tabledata "Session Attendee Res. Entry" = RIMD,
        tabledata Job = R,
        tabledata "CE Attendee Setup" = R,
        tabledata "CE Session Change" = RI,
        table "CE Attendee Setup" = X,
        table "CE Session Change" = X,
        page "Attendee Sessions" = X,
        page "Attendee Agenda" = X,
        page "Session Changes" = X,
        codeunit "CE Attendee Agenda Mgt" = X,
        codeunit "CE Session Change Log" = X;
}
