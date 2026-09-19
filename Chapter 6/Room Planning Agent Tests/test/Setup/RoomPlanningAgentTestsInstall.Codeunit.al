// ------------------------------------------------------------------------------------------------
// Chapter 6 - Room Planning Agent Tests
// Install codeunit: loads the dataset, suite setup, and suite configuration from .resources
// for the AI Development Toolkit - Evaluation.
// ------------------------------------------------------------------------------------------------
codeunit 50871 "Room Planning Agent Tst Inst."
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        ImportResources();
    end;

    procedure ImportResources()
    var
        DatasetPaths: List of [Text];
        TestSuitePaths: List of [Text];
        ResourcePath: Text;
    begin
        // Datasets and suite_setup files are both YAML, loaded the same way.
        DatasetPaths := NavApp.ListResources('*.yaml');
        foreach ResourcePath in DatasetPaths do
            SetupDataInput(ResourcePath);

        TestSuitePaths := NavApp.ListResources('configuration/*.xml');
        foreach ResourcePath in TestSuitePaths do
            SetupTestSuite(ResourcePath);
    end;

    local procedure SetupDataInput(FilePath: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        FileName: Text;
        ResInStream: InStream;
    begin
        FileName := FilePath.Substring(FilePath.LastIndexOf('/') + 1);
        NavApp.GetResource(FilePath, ResInStream, TextEncoding::UTF8);
        AITALTestSuiteMgt.ImportTestInputs(FileName, ResInStream);
    end;

    local procedure SetupTestSuite(Filepath: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        XMLSetupInStream: InStream;
    begin
        NavApp.GetResource(Filepath, XMLSetupInStream);
        AITALTestSuiteMgt.ImportAITestSuite(XMLSetupInStream);
    end;
}
