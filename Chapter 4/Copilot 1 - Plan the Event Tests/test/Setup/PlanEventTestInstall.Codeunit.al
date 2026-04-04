// ------------------------------------------------------------------------------------------------
// Chapter 4 - Plan the Event Tests
// Install codeunit: loads datasets and test suites from .resources for the AI Test Toolkit.
// ------------------------------------------------------------------------------------------------

codeunit 50700 "Plan Event Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        DatasetPaths: List of [Text];
        TestSuitePaths: List of [Text];
        ResourcePath: Text;
    begin
        DatasetPaths := NavApp.ListResources('Datasets/*.jsonl');
        foreach ResourcePath in DatasetPaths do
            SetupDataInput(ResourcePath);

        TestSuitePaths := NavApp.ListResources('TestSuites/*.xml');
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
        NavApp.GetResource(FilePath, ResInStream);
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
