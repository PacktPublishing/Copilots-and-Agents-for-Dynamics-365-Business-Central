page 50101 "CRONUS Events RAG Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'CRONUS Events RAG Setup';
    SourceTable = "CRONUS Events RAG Setup";
    SourceTableTemporary = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Web Page URL"; Rec."Web Page URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the URL of the RAG web application';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get('DEFAULT') then begin
            Rec."Primary Key" := 'DEFAULT';
            Rec.Insert();
        end;
    end;
}
