pageextension 50304 "Plan Event Job List Ext" extends "Job List"
{
    actions
    {
        addlast(Prompting)
        {
            action(PlanEvent)
            {
                Caption = 'Plan Event';
                ToolTip = 'Generate planning steps from an Event Brief using Copilot.';
                Image = Sparkle;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Plan Event");
                end;
            }
        }
    }
}
