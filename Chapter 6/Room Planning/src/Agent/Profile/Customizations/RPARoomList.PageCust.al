pagecustomization "RPA Room List" customizes "Room List"
{
    ClearViews = true;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        modify(Floor)
        {
            Visible = false;
        }
        modify("Has Recording")
        {
            Visible = false;
        }
    }
}
