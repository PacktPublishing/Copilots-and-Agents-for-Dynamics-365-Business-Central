pageextension 50612 "Build Agenda Job List Ext" extends "Job List"
{
    actions
    {
        addlast(Prompting)
        {
            action(BuildConferenceAgenda)
            {
                Caption = 'Build Conference Agenda';
                ToolTip = 'Use Copilot to build a conference agenda by calling tools that read session data and event constraints from Business Central.';
                Image = Sparkle;
                ApplicationArea = All;

                trigger OnAction()
                var
                    BuildConferenceAgendaPage: Page "Build Conference Agenda";
                begin
                    BuildConferenceAgendaPage.SetProject(Rec."No.");
                    BuildConferenceAgendaPage.RunModal();
                end;
            }
        }
    }
}
