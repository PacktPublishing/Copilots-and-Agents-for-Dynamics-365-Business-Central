permissionset 50842 "Room Planning Agent"
{
    Assignable = true;
    Caption = 'Room Planning - Agent';
    // D365 BASIC: foundation UI/system access agents need (Microsoft agent samples assign this).
    // D365 JOBS, VIEW: Job List and related project objects for Projects navigation.
    IncludedPermissionSets = "D365 BASIC", "D365 JOBS, VIEW";
    Permissions =
        tabledata Job = R,
        tabledata "Event Session" = RM,
        tabledata Room = R,
        tabledata "Session Attendee Res. Entry" = R,
        tabledata "Similar Session Buffer" = RIMD,
        tabledata "Room Planning Cue" = RIMD,
        tabledata "Room Planning Agent Setup" = RIMD,
        tabledata "Room Planning Agent KPI" = RIMD,
        codeunit "Find Similar Sessions" = X,
        codeunit "Room Assignment Check" = X,
        codeunit "RPA KPI Logging" = X,
        page "Room Planning Role Center" = X,
        page "Room Planning Agent Setup" = X,
        page "Room Planning Agent KPI" = X,
        page "RPA Assign Task Dialog" = X,
        page "Room Planning Cue" = X,
        page "Job List" = X,
        page "Job Card" = X,
        page "Event Sessions" = X,
        page "Room List" = X,
        page "Room Card" = X,
        page "Similar Event Sessions" = X,
        page "Session Attendee Res. Entries" = X,
        page "Session Attendee Res. FactBox" = X;
}
