codeunit 50823 "Find Similar Sessions"
{
    procedure FindSimilar(CurrentSession: Record "Event Session"; var SimilarSessionBuffer: Record "Similar Session Buffer" temporary)
    var
        EventSession: Record "Event Session";
        SimilarityResult: Record "Similarity Result" temporary;
        SemanticSearch: Codeunit "Semantic Search";
        RecRef: RecordRef;
        FieldIds: List of [Integer];
        SearchText: Text;
    begin
        SimilarSessionBuffer.Reset();
        SimilarSessionBuffer.DeleteAll();

        SearchText := BuildSearchText(CurrentSession);
        if SearchText = '' then
            Error(EmptySearchTextErr);

        EventSession.SetFilter(Code, '<>%1', CurrentSession.Code);
        if EventSession.Count() > MaxSearchSpace() then
            Error(SearchSpaceTooLargeErr, MaxSearchSpace());

        FieldIds.Add(EventSession.FieldNo(Name));
        FieldIds.Add(EventSession.FieldNo(Description));
        FieldIds.Add(EventSession.FieldNo(Speaker1));
        FieldIds.Add(EventSession.FieldNo(Speaker2));
        FieldIds.Add(EventSession.FieldNo(Speaker3));
        FieldIds.Add(EventSession.FieldNo(Speaker4));

        RecRef.GetTable(EventSession);
        SemanticSearch.SetSearchTarget(RecRef);
        SemanticSearch.SetMaxResults(MaxResults());
        if not SemanticSearch.FindSimilarByField(SearchText, FieldIds, SimilarityResult) then
            exit;

        if SimilarityResult.FindSet() then
            repeat
                if EventSession.GetBySystemId(SimilarityResult."System ID") then
                    InsertBufferRow(SimilarSessionBuffer, EventSession, SimilarityResult);
            until SimilarityResult.Next() = 0;
    end;

    local procedure BuildSearchText(EventSession: Record "Event Session"): Text
    var
        SearchBuilder: TextBuilder;
    begin
        AppendSearchPart(SearchBuilder, EventSession.Name);
        AppendSearchPart(SearchBuilder, EventSession.Description);
        AppendSearchPart(SearchBuilder, EventSession.Speaker1);
        AppendSearchPart(SearchBuilder, EventSession.Speaker2);
        AppendSearchPart(SearchBuilder, EventSession.Speaker3);
        AppendSearchPart(SearchBuilder, EventSession.Speaker4);
        exit(SearchBuilder.ToText());
    end;

    local procedure AppendSearchPart(var SearchBuilder: TextBuilder; Part: Text)
    begin
        Part := Part.Trim();
        if Part = '' then
            exit;
        if SearchBuilder.Length() > 0 then
            SearchBuilder.Append(' ');
        SearchBuilder.Append(Part);
    end;

    local procedure InsertBufferRow(var SimilarSessionBuffer: Record "Similar Session Buffer" temporary; EventSession: Record "Event Session"; SimilarityResult: Record "Similarity Result" temporary)
    begin
        SimilarSessionBuffer.Init();
        SimilarSessionBuffer.Rank := SimilarityResult."No.";
        SimilarSessionBuffer.Similarity := Round(SimilarityResult.Similarity, 0.01);
        SimilarSessionBuffer.Code := EventSession.Code;
        SimilarSessionBuffer.Name := EventSession.Name;
        SimilarSessionBuffer.Description := EventSession.Description;
        SimilarSessionBuffer.Speaker1 := EventSession.Speaker1;
        SimilarSessionBuffer.Speaker2 := EventSession.Speaker2;
        SimilarSessionBuffer.Speaker3 := EventSession.Speaker3;
        SimilarSessionBuffer.Speaker4 := EventSession.Speaker4;
        SimilarSessionBuffer."Project Code" := EventSession."Project Code";
        SimilarSessionBuffer.Date := EventSession.Date;
        SimilarSessionBuffer.Status := EventSession.Status;
        SimilarSessionBuffer."Estimated Attendees" := EventSession."Estimated Attendees";
        SimilarSessionBuffer."Actual Attendees" := EventSession."Actual Attendees";
        SimilarSessionBuffer."Room Code" := EventSession."Room Code";
        SimilarSessionBuffer.Insert();
    end;

    local procedure MaxResults(): Integer
    begin
        exit(10);
    end;

    local procedure MaxSearchSpace(): Integer
    begin
        exit(1000);
    end;

    var
        EmptySearchTextErr: Label 'Enter a name, description, or speaker on this session before finding similar sessions.';
        SearchSpaceTooLargeErr: Label 'Semantic search is limited to %1 records. Narrow the filters first.';
}
