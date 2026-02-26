page 50611 "Agenda Proposal Subpart"
{
    ApplicationArea = All;
    Caption = 'Agenda Proposal';
    PageType = ListPart;
    SourceTable = "Agenda Proposal";
    SourceTableTemporary = true;
    SourceTableView = sorting("Session Date", "Start Time");
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Session Code"; Rec."Session Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the code of the session being scheduled.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the description of the session from the Event Session record.';
                }
                field("Session Date"; Rec."Session Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the session is proposed to take place.';
                }
                field("Track No."; Rec."Track No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the parallel track assigned to the session.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the proposed start time for the session.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the proposed end time for the session.';
                }
            }
        }
    }

    procedure Load(var FromProposal: Record "Agenda Proposal")
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if FromProposal.FindSet() then
            repeat
                Rec := FromProposal;
                Rec.Insert();
            until FromProposal.Next() = 0;
        CurrPage.Update(false);
    end;

    procedure GetRecords(var ToProposal: Record "Agenda Proposal")
    begin
        if Rec.FindSet() then
            repeat
                ToProposal := Rec;
                ToProposal.Insert();
            until Rec.Next() = 0;
    end;
}
