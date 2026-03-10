page 50406 "Event Project Proposal Subpart"
{
    PageType = ListPart;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Project Tasks';
    SourceTable = "Event Project Proposal";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                Caption = ' ';
                ShowCaption = false;
                IndentationColumn = DescriptionIndent;
                IndentationControls = "Task Description";

                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Number that identifies the project task.';
                }
                field("Task Description"; Rec."Task Description")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Short description of the task.';
                }
                field("Action Description Preview"; Rec."Action Description Preview")
                {
                    ApplicationArea = All;
                    Caption = 'Action Description';
                    ToolTip = 'Detailed description of the task. Use AssistEdit to view full text.';

                    trigger OnAssistEdit()
                    var
                        InStr: InStream;
                        ActionDescription: Text;
                    begin
                        Rec.CalcFields("Action Description");
                        Rec."Action Description".CreateInStream(InStr);
                        InStr.ReadText(ActionDescription);
                        Message(ActionDescription);
                    end;
                }
                field("Resource Role Description"; Rec."Resource Role Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Role or type of resource needed for this task.';
                }
                field("Item Category"; Rec."Item Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Item category when the task requires items.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Planned start date of the task.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Planned end date of the task.';
                }
            }
        }
    }

    internal procedure Load(var EventProjectProposal: Record "Event Project Proposal")
    begin
        Rec.Reset();
        Rec.DeleteAll();

        EventProjectProposal.Reset();
        if EventProjectProposal.FindSet() then
            repeat
                EventProjectProposal.CalcFields("Action Description");
                Rec.Copy(EventProjectProposal, false);
                Rec."Action Description" := EventProjectProposal."Action Description";
                Rec.Insert();
            until EventProjectProposal.Next() = 0;

        CurrPage.Update(false);
    end;

    internal procedure GetRecords(var EventProjectProposal: Record "Event Project Proposal")
    begin
        EventProjectProposal.Reset();
        EventProjectProposal.DeleteAll();

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                Rec.CalcFields("Action Description");
                EventProjectProposal.Copy(Rec, false);
                EventProjectProposal."Action Description" := Rec."Action Description";
                EventProjectProposal.Insert();
            until Rec.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := Rec.Indentation;
        StyleIsStrong := Rec."Job Task Type" <> Rec."Job Task Type"::Posting;
    end;

    var
        DescriptionIndent: Integer;
        StyleIsStrong: Boolean;
}
