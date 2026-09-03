pageextension 50214 "Event Sessions Job Card Ext" extends "Job Card"
{
    actions
    {
        addfirst("&Job")
        {
            action(EventSessions)
            {
                ApplicationArea = All;
                Caption = 'Event Sessions';
                Image = Calendar;
                RunObject = Page "Event Sessions";
                RunPageLink = "Project Code" = field("No.");
                ToolTip = 'View all event sessions for this project.';
            }
        }
        addfirst(Category_Category7)
        {
            actionref(EventSessions_Promoted; EventSessions)
            {
            }
        }
    }
}
