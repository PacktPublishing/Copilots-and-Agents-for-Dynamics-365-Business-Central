page 50830 "Room Planning Agent KPI"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Room Planning Agent Summary';
    SourceTable = "Room Planning Agent KPI";
    Editable = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

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

    /// <summary>
    /// Retrieves the relevant agent's KPI record for display.
    /// This page is launched via IAgentMetadata.GetSummaryPageId(). The platform sets a filter on the
    /// "User Security ID" field before opening the page, so the source record may not be fully populated
    /// on open - the filter is evaluated here to resolve and load the correct record.
    /// </summary>
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
