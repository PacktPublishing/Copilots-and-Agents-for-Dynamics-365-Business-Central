codeunit 50741 "Import Sess Proposals AI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = AITest;
    InherentEntitlements = X;
    InherentPermissions = X;

    [Test]
    procedure TestImportSessionProposalsMapping()
    var
        AITTestContext: Codeunit "AIT Test Context";
        ImportSessionProposalsImpl: Codeunit "Import Session Proposals Impl";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempFieldMappingProposal: Record "Field Mapping Proposal" temporary;
        Job: Record Job;
        ExpectedData: Codeunit "Test Input Json";
        RowInput: Codeunit "Test Input Json";
        SampleEl: Codeunit "Test Input Json";
        SampleFound: Boolean;
        HeadersCsv: Text;
        SampleRowText: Text;
        OutputMsg: Text;
        DataExposure: Enum "Data Exposure";
        ActualMappings: Integer;
        Accuracy: Decimal;
    begin
        HeadersCsv := AITTestContext.GetQuestion().ValueAsText();
        RowInput := AITTestContext.GetInput();
        SampleRowText := '';
        SampleEl := RowInput.ElementExists('sample_row', SampleFound);
        if SampleFound then
            SampleRowText := SampleEl.ValueAsText();

        BuildExcelBuffer(HeadersCsv, SampleRowText, TempExcelBuffer);
        DataExposure := ResolveDataExposure(AITTestContext.GetTestSetup());

        if not TryRunImportMapping(ImportSessionProposalsImpl, TempExcelBuffer, DataExposure, Job, TempFieldMappingProposal) then begin
            AITTestContext.SetAccuracy(0.0);
            AITTestContext.SetTestOutput(GetLastErrorText());
            exit;
        end;

        ActualMappings := TempFieldMappingProposal.Count();
        ExpectedData := AITTestContext.GetExpectedData();
        Accuracy := ScoreMappingAccuracy(ExpectedData, TempFieldMappingProposal, ActualMappings);

        OutputMsg := BuildMappingOutputSummary(HeadersCsv, ActualMappings, TempFieldMappingProposal);
        AITTestContext.SetAccuracy(Accuracy);
        AITTestContext.SetTestOutput(OutputMsg);
    end;

    local procedure BuildExcelBuffer(HeadersCsv: Text; SampleRowText: Text; var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        Headers: List of [Text];
        Cells: List of [Text];
        HeaderText: Text;
        CellText: Text;
        ColNo: Integer;
    begin
        Headers := HeadersCsv.Split(',');
        ColNo := 1;
        foreach HeaderText in Headers do begin
            TempExcelBuffer.Init();
            TempExcelBuffer."Row No." := 1;
            TempExcelBuffer."Column No." := ColNo;
            TempExcelBuffer."Cell Value as Text" := CopyStr(HeaderText.Trim(), 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
            TempExcelBuffer.Insert();
            ColNo += 1;
        end;

        if SampleRowText = '' then
            exit;

        Cells := SampleRowText.Split(',');
        ColNo := 1;
        foreach CellText in Cells do begin
            TempExcelBuffer.Init();
            TempExcelBuffer."Row No." := 2;
            TempExcelBuffer."Column No." := ColNo;
            TempExcelBuffer."Cell Value as Text" := CopyStr(CellText.Trim(), 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
            TempExcelBuffer.Insert();
            ColNo += 1;
        end;
    end;

    local procedure ResolveDataExposure(TestSetup: Codeunit "Test Input Json"): Enum "Data Exposure"
    var
        El: Codeunit "Test Input Json";
        Found: Boolean;
        Txt: Text;
    begin
        El := TestSetup.ElementExists('data_exposure', Found);
        if not Found then
            exit(Enum::"Data Exposure"::None);

        Txt := El.ValueAsText().ToLower();
        case Txt of
            'none':
                exit(Enum::"Data Exposure"::None);
            'excel':
                exit(Enum::"Data Exposure"::Excel);
            'excelandbc':
                exit(Enum::"Data Exposure"::ExcelAndBC);
            else
                exit(Enum::"Data Exposure"::None);
        end;
    end;

    local procedure ScoreMappingAccuracy(ExpectedData: Codeunit "Test Input Json"; var TempFieldMappingProposal: Record "Field Mapping Proposal"; ActualMappings: Integer): Decimal
    var
        MappingsArray: Codeunit "Test Input Json";
        Pair: Codeunit "Test Input Json";
        SrcEl: Codeunit "Test Input Json";
        TgtEl: Codeunit "Test Input Json";
        MinEl: Codeunit "Test Input Json";
        MinFound: Boolean;
        MapFound: Boolean;
        SrcFound: Boolean;
        TgtFound: Boolean;
        i: Integer;
        Matched: Integer;
        TotalPairs: Integer;
    begin
        MappingsArray := ExpectedData.ElementExists('expected_mappings', MapFound);
        if MapFound then begin
            TotalPairs := MappingsArray.GetElementCount();
            if TotalPairs > 0 then begin
                Matched := 0;
                for i := 0 to TotalPairs - 1 do begin
                    Pair := MappingsArray.ElementAt(i);
                    SrcEl := Pair.ElementExists('source', SrcFound);
                    if not SrcFound then
                        continue;
                    TgtEl := Pair.ElementExists('target_field_name', TgtFound);
                    if not TgtFound then
                        continue;
                    if MappingRowExists(TempFieldMappingProposal, SrcEl.ValueAsText(), TgtEl.ValueAsText()) then
                        Matched += 1;
                end;
                exit(Round(Matched / TotalPairs, 0.0001));
            end;
        end;

        MinEl := ExpectedData.ElementExists('min_mappings', MinFound);
        if MinFound then begin
            if ActualMappings >= MinEl.ValueAsInteger() then
                exit(1.0)
            else
                exit(0.0);
        end;

        if ActualMappings > 0 then
            exit(1.0);
        exit(0.0);
    end;

    local procedure MappingRowExists(var TempFieldMappingProposal: Record "Field Mapping Proposal"; SourceName: Text; TargetFieldName: Text): Boolean
    begin
        TempFieldMappingProposal.Reset();
        if TempFieldMappingProposal.FindSet() then
            repeat
                if NamesMatch(TempFieldMappingProposal."Source Column Name", SourceName) and
                   NamesMatch(TempFieldMappingProposal."Target Field Name", TargetFieldName)
                then
                    exit(true);
            until TempFieldMappingProposal.Next() = 0;
        exit(false);
    end;

    local procedure NamesMatch(Actual: Text; Expected: Text): Boolean
    begin
        exit(Actual.Trim().ToLower() = Expected.Trim().ToLower());
    end;

    local procedure BuildMappingOutputSummary(HeadersCsv: Text; ActualMappings: Integer; var TempFieldMappingProposal: Record "Field Mapping Proposal"): Text
    var
        B: TextBuilder;
    begin
        B.AppendLine('Headers: ' + HeadersCsv);
        B.AppendLine('Mappings: ' + Format(ActualMappings));
        TempFieldMappingProposal.Reset();
        if TempFieldMappingProposal.FindSet() then
            repeat
                B.AppendLine(StrSubstNo('  %1 -> %2 (%3)', TempFieldMappingProposal."Source Column Name", TempFieldMappingProposal."Target Field Name", Format(TempFieldMappingProposal."Target Field No.")));
            until TempFieldMappingProposal.Next() = 0;
        exit(B.ToText());
    end;

    [TryFunction]
    local procedure TryRunImportMapping(ImportSessionProposalsImpl: Codeunit "Import Session Proposals Impl"; var TempExcelBuffer: Record "Excel Buffer"; DataExposure: Enum "Data Exposure"; var Job: Record Job; var TempFieldMappingProposal: Record "Field Mapping Proposal")
    begin
        ImportSessionProposalsImpl.Generate(TempExcelBuffer, 1, DataExposure, Job, TempFieldMappingProposal);
    end;
}
