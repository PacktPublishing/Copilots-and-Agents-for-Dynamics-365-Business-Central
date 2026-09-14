
// Assign to the Entra ID app (service principal) used by the Copilot Studio connection.
permissionset 98112 "CE Conference Access"
{
    Assignable = true;
    Caption = 'Cronus Events - Conference Access';

    Permissions =
        tabledata "CE Events Setup" = R,
        tabledata "CE Conference Attendee" = RIM,
        tabledata "CE Conference Speaker" = RM,
        tabledata "CE Conference Session" = R,
        table "CE Events Setup" = X,
        table "CE Conference Attendee" = X,
        table "CE Conference Speaker" = X,
        table "CE Conference Session" = X,
        page "CE Attendee API" = X,
        page "CE Speaker API" = X,
        page "CE Session API" = X,
        page "CE Conference Attendees" = X,
        page "CE Conference Attendee Card" = X,
        page "CE Conference Speakers" = X,
        page "CE Conference Sessions" = X,
        page "CE Events Setup" = X;
}
