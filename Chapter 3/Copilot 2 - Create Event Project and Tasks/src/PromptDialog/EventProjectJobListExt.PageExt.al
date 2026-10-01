namespace Packt;

using Microsoft.Projects.Project.Job;

pageextension 50407 "Event Project Job List Ext" extends "Job List"
{
    actions
    {
        addlast(Prompting)
        {
            action(CreateEventProject)
            {
                Caption = 'Create Event Project';
                ToolTip = 'Create an event project and preparation tasks from an Event Brief using Copilot.';
                Image = Sparkle;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Create Event Project");
                end;
            }
        }
    }
}
