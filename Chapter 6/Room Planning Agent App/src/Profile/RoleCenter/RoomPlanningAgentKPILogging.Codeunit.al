namespace Packt;

using System.Agents;

codeunit 50859 "Room Planning Agent KPI Log"
{
    Access = Internal;
    EventSubscriberInstance = StaticAutomatic;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"Event Session", 'OnAfterModifyEvent', '', false, false)]
    local procedure LogSessionAssignedOnAfterModify(var Rec: Record "Event Session"; var xRec: Record "Event Session"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Room Code" = '' then
            exit;
        if xRec."Room Code" <> '' then
            exit;

        IncrementSessionsAssigned();
    end;

    local procedure IncrementSessionsAssigned()
    var
        KPI: Record "Room Planning Agent KPI";
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
        AgentUserSecurityId: Guid;
    begin
        if not AgentSession.IsAgentSession(AgentMetadataProvider) then
            exit;
        if AgentMetadataProvider <> Enum::"Agent Metadata Provider"::"Room Planning Agent" then
            exit;

        AgentUserSecurityId := UserSecurityId();
        if not KPI.Get(AgentUserSecurityId) then begin
            KPI.Init();
            KPI."User Security ID" := AgentUserSecurityId;
            KPI."Sessions Assigned" := 1;
            KPI.Insert();
            exit;
        end;

        KPI."Sessions Assigned" += 1;
        KPI.Modify();
    end;
}
