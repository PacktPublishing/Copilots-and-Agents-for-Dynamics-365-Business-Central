permissionset 50202 "Event Copilot Admin"
{
    Assignable = true;
    Caption = 'Event Copilot Admin';
    Permissions =
        tabledata "Event Copilot Setup" = RIMD,
        tabledata "Event Session" = RIMD,
        page "Event Copilot Setup" = X,
        page "Event Sessions" = X;
}
