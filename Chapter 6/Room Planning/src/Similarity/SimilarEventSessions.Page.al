page 50819 "Similar Event Sessions"
{
    ApplicationArea = All;
    Caption = 'Similar Event Sessions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Similar Session Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting(Rank);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Rank; Rec.Rank)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the similarity rank. Lower numbers are closer matches.';
                }
                field(Similarity; Rec.Similarity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the relative similarity score for this result set. Higher is closer.';
                }
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for the session.';

                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the session title.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description of the session.';
                }
                field(Speaker1; Rec.Speaker1)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the first speaker.';
                }
                field("Project Code"; Rec."Project Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the event project this session belongs to.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scheduled date for the session.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the session.';
                }
                field("Estimated Attendees"; Rec."Estimated Attendees")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many attendees you expect at this session.';
                }
                field("Actual Attendees"; Rec."Actual Attendees")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many attendees were in the room.';
                }
                field("Room Code"; Rec."Room Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the room assigned to this session.';
                }
            }
        }
    }

    procedure SetBuffer(var SimilarSessionBuffer: Record "Similar Session Buffer" temporary)
    begin
        if SimilarSessionBuffer.FindSet() then
            repeat
                Rec := SimilarSessionBuffer;
                Rec.Insert();
            until SimilarSessionBuffer.Next() = 0;
        if Rec.FindFirst() then;
    end;
}
