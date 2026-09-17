pagecustomization "RPA Room Card" customizes "Room Card"
{
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
