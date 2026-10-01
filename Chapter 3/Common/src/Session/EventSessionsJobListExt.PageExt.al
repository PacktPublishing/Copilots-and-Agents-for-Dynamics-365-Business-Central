namespace Packt;

using Microsoft.Projects.Project.Job;

pageextension 50213 "Event Sessions Job List Ext" extends "Job List"
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
                ToolTip = 'View all event sessions for this project.';
                RunObject = Page "Event Sessions";
                RunPageLink = "Project Code" = field("No.");
            }
        }
        addfirst(Category_Category5)
        {
            actionref(EventSessions_Promoted; EventSessions)
            {
            }
        }
    }
}
