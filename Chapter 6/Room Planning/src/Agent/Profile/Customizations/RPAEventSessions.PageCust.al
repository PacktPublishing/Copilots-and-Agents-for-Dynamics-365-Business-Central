pagecustomization "RPA Event Sessions" customizes "Event Sessions"
{
    ClearViews = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        modify(Speaker2)
        {
            Visible = false;
        }
        modify(Speaker3)
        {
            Visible = false;
        }
        modify(Speaker4)
        {
            Visible = false;
        }
        modify("Track No.")
        {
            Visible = false;
        }
        modify("Duration (min)")
        {
            Visible = false;
        }
        moveafter("End Time"; "Estimated Attendees")
        moveafter("Estimated Attendees"; "Reserved Attendees")
        moveafter("Reserved Attendees"; "Room Code")
        moveafter("Room Code"; "Actual Attendees")
    }
}
