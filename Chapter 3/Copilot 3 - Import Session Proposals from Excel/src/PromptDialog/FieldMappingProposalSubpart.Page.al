page 50506 "Field Mapping Proposal Subpart"
{
    ApplicationArea = All;
    Caption = 'Field Mapping Proposal';
    PageType = ListPart;
    SourceTable = "Field Mapping Proposal";
    SourceTableTemporary = true;
    SourceTableView = sorting("Generation Id", "Target Field No.");
    InsertAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Source Column Name"; Rec."Source Column Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Excel column header.';
                }
                field("Target Field Name"; Rec."Target Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the matched Business Central field name.';
                }
                field("Source Column No."; Rec."Source Column No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the column number in the Excel file.';
                }
                field("Target Field No."; Rec."Target Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number in the Event Session table.';
                }
            }
        }
    }

    procedure Load(var FieldMappingProposal: Record "Field Mapping Proposal")
    begin
        // Insert new generation's rows into the existing temp table so previous
        // generations are preserved for history navigation via SubPageLink.
        if FieldMappingProposal.FindSet() then
            repeat
                Rec := FieldMappingProposal;
                Rec.Insert();
            until FieldMappingProposal.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure GetRecords(GenerationId: Integer; var FieldMappingProposal: Record "Field Mapping Proposal")
    begin
        Rec.SetRange("Generation Id", GenerationId);
        FieldMappingProposal.Copy(Rec, true);
        Rec.SetRange("Generation Id");
    end;
}
