pagecustomization "RPA Similar Sessions" customizes "Similar Event Sessions"
{
    layout
    {
        modify(Description)
        {
            Visible = false;
        }
        modify(Speaker1)
        {
            Visible = false;
        }
        modify(Status)
        {
            Visible = false;
        }
        modify("Estimated Attendees")
        {
            Visible = false;
        }
        modify("Room Code")
        {
            Visible = false;
        }
    }
}
