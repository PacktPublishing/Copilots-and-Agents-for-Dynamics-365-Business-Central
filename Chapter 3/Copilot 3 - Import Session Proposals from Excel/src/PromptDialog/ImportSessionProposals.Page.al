page 50505 "Import Session Proposals"
{
    PageType = PromptDialog;
    Caption = 'Import Session Proposals';
    IsPreview = true;
    Extensible = false;
    SourceTable = "Mapping Generation History";
    SourceTableTemporary = true;

    layout
    {
        area(PromptOptions)
        {
            field(DataExposureField; DataExposure)
            {
                Caption = 'Data Exposure';
                ApplicationArea = All;
                ToolTip = 'Controls how much data is exposed to Copilot. None: schema only. Excel: adds sample rows from the file. Excel and Business Central: also adds field types, existing BC session records, and project info.';

                trigger OnValidate()
                begin
                end;
            }
        }
        area(Prompt)
        {
            group(EventProject)
            {
                Caption = 'Event Project';
                field(ProjectNo; Project."No.")
                {
                    ApplicationArea = All;
                    Caption = 'Project No.';
                    Editable = false;
                    ToolTip = 'Specifies the event project this import is linked to.';
                }
                field(ProjectDescription; Project.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Project Description';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the description of the event project.';
                }
            }
            group(ExcelFile)
            {
                Caption = 'Excel File';
                field(FileName; FileName)
                {
                    ApplicationArea = All;
                    Caption = 'File';
                    Editable = false;
                    ToolTip = 'Shows the name of the attached Excel file containing session proposals.';
                }
            }
        }
        area(Content)
        {
            part(FieldMappingProposal; "Field Mapping Proposal Subpart")
            {
                ApplicationArea = All;
                ShowFilter = false;
                Editable = true;
                Enabled = true;
                SubPageLink = "Generation Id" = field("Generation Id");
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Map Fields';
                ToolTip = 'Let Copilot map the Excel column headers to the Event Session table fields.';
                trigger OnAction()
                begin
                    GenerateMappingProposal();
                end;
            }
            systemaction(Regenerate)
            {
                ToolTip = 'Generate a new mapping suggestion and add it to the history.';
                trigger OnAction()
                begin
                    GenerateMappingProposal();
                end;
            }
            systemaction(Attach)
            {
                ToolTip = 'Attach an Excel file containing approved session proposals.';
                trigger OnAction()
                begin
                    ReadExcelFile();
                end;
            }
            systemaction(Ok)
            {
                Caption = 'Import';
                ToolTip = 'Import session proposals from Excel using the currently selected field mapping.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then
            ApplyImport();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.IsEmpty() then
            exit;

        if xRec."Generation Id" = Rec."Generation Id" then
            exit;

        DataExposure := Rec."Data Exposure";
    end;

    var
        Project: Record Job;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileName: Text;
        DataExposure: Enum "Data Exposure";

    procedure SetProject(FromProject: Record Job)
    begin
        Project := FromProject;
    end;

    local procedure ReadExcelFile()
    var
        InStr: InStream;
        SheetName: Text;
        ImportSessionsLbl: Label 'Import Session Proposals from Excel';
        ExcelFilterLbl: Label 'Excel files (*.xlsx, *.xls)|*.xlsx;*.xls', Locked = true;
    begin
        UploadIntoStream(ImportSessionsLbl, '', ExcelFilterLbl, FileName, InStr);
        if FileName = '' then
            exit;

        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStr);

        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(InStr, SheetName);
        TempExcelBuffer.ReadSheet();
    end;

    local procedure GenerateMappingProposal()
    var
        FieldMappingProposal: Record "Field Mapping Proposal";
        ImportSessionProposalsImpl: Codeunit "Import Session Proposals Impl";
    begin
        if FileName = '' then
            Error(NoFileAttachedErr);

        SaveGenerationHistory();

        ImportSessionProposalsImpl.Generate(TempExcelBuffer, Rec."Generation Id", DataExposure, Project, FieldMappingProposal);
        CurrPage.FieldMappingProposal.Page.Load(FieldMappingProposal);
    end;

    local procedure SaveGenerationHistory()
    begin
        if not Rec.IsEmpty() then
            Rec.FindLast();

        Rec."Generation Id" := Rec."Generation Id" + 1;
        Rec."Data Exposure" := DataExposure;
        Rec.Insert();
    end;

    local procedure ApplyImport()
    var
        FieldMappingProposal: Record "Field Mapping Proposal";
        ImportSessionProposalsImpl: Codeunit "Import Session Proposals Impl";
    begin
        CurrPage.FieldMappingProposal.Page.GetRecords(Rec."Generation Id", FieldMappingProposal);
        ImportSessionProposalsImpl.ImportSessionsUsingMapping(Project, TempExcelBuffer, FieldMappingProposal);
    end;

    var
        NoFileAttachedErr: Label 'Please attach an Excel file first.';
}
