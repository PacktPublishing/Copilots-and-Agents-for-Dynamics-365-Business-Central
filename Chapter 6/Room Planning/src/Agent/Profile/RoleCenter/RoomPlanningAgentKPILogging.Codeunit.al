using System.Agents;

/// <summary>
/// Subscribes to Event Session modifications and increments Sessions Assigned
/// when this agent sets Room Code from blank to a value.
/// </summary>
codeunit 50837 "RPA KPI Logging"
{
    Access = Internal;
    EventSubscriberInstance = StaticAutomatic;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"Event Session", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyEventSession(var Rec: Record "Event Session"; var xRec: Record "Event Session"; RunTrigger: Boolean)
    var
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if not RunTrigger then
            exit;

        if not AgentSession.IsAgentSession(AgentMetadataProvider) then
            exit;

        if AgentMetadataProvider <> Enum::"Agent Metadata Provider"::"Room Planning Agent" then
            exit;

        // Count only the first assignment: Room Code going from blank to a value,
        // not a later edit of an already-assigned session.
        if xRec."Room Code" <> '' then
            exit;
        if Rec."Room Code" = '' then
            exit;

        UpdateKPI(UserSecurityId(), 1);
    end;

    local procedure UpdateKPI(AgentUserSecurityId: Guid; AssignedIncrement: Integer)
    var
        RoomPlanningAgentKPI: Record "Room Planning Agent KPI";
    begin
        if not RoomPlanningAgentKPI.Get(AgentUserSecurityId) then begin
            RoomPlanningAgentKPI.Init();
            RoomPlanningAgentKPI."User Security ID" := AgentUserSecurityId;
            RoomPlanningAgentKPI.Insert();
        end;

        RoomPlanningAgentKPI."Sessions Assigned" += AssignedIncrement;
        RoomPlanningAgentKPI.Modify();
    end;
}
