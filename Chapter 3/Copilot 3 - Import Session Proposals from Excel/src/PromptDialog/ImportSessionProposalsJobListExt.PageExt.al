pageextension 50507 "Import Session Proposals Ext" extends "Job List"
{
    actions
    {
        addlast(Prompting)
        {
            action(ImportSessionProposals)
            {
                ApplicationArea = All;
                Caption = 'Import Session Proposals';
                ToolTip = 'Use Copilot to map and import session proposals from an Excel file into this project.';
                Image = Sparkle;
                trigger OnAction()
                var
                    ImportSessionProposals: Page "Import Session Proposals";
                begin
                    ImportSessionProposals.SetProject(Rec);
                    ImportSessionProposals.RunModal();
                end;
            }
        }
    }
}
