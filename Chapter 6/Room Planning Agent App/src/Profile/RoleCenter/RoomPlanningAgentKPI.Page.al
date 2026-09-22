namespace Packt;

page 50852 "Room Planning Agent KPI"
{
    ApplicationArea = All;
    Caption = 'Room Planning Agent Summary';
    Editable = false;
    Extensible = false;
    PageType = CardPart;
    SourceTable = "Room Planning Agent KPI";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            cuegroup(KeyMetrics)
            {
                Caption = 'Key Performance Indicators';

                field(SessionsAssigned; Rec."Sessions Assigned")
                {
                    Caption = 'Sessions Assigned';
                    ToolTip = 'Specifies how many conference sessions this agent has assigned a room to.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        GetRelevantAgent();
    end;

    local procedure GetRelevantAgent()
    var
        UserSecurityIDFilter: Text;
    begin
        if IsNullGuid(Rec."User Security ID") then begin
            UserSecurityIDFilter := Rec.GetFilter("User Security ID");
            if not Evaluate(Rec."User Security ID", UserSecurityIDFilter) then
                Error(AgentDoesNotExistErr);
        end;

        if not Rec.Get(Rec."User Security ID") then
            Rec.Insert();
    end;

    var
        AgentDoesNotExistErr: Label 'The agent does not exist. Please check the configuration.';
}
