page 50302 "Plan Event"
{
    PageType = PromptDialog;
    Extensible = false;
    Caption = 'Plan Event';
    IsPreview = true;

    layout
    {
        area(Prompt)
        {
            field(EventBriefText; EventBriefText)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
                InstructionalText = 'Paste the Event Brief (text or Markdown from Chapter 2). The copilot will propose planning steps.';
            }
        }
        area(Content)
        {
            field(PlanningStepsText; PlanningStepsText)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
                Editable = false;
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';
                ToolTip = 'Generate planning steps from the Event Brief using Copilot.';

                trigger OnAction()
                begin
                    PlanningStepsText := PlanEventImpl.GeneratePlanningSteps(EventBriefText);
                end;
            }
            systemaction(Cancel)
            {
                Caption = 'Discard';
                ToolTip = 'Discard the generated planning steps.';
            }
        }
    }

    var
        PlanEventImpl: Codeunit "Plan Event Impl";
        EventBriefText: Text;
        PlanningStepsText: Text;
}
