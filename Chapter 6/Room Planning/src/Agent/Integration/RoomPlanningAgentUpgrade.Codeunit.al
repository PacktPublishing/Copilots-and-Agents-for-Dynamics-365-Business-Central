// using System.Agents;
// using System.Security.AccessControl;
// using System.Upgrade;

codeunit 50833 "Room Planning Agent Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        // TODO: Add upgrade logic to update agent instances with the latest instructions/configuration
        // when they need to be changed.
        // UpgradeAgent();
    end;

    // local procedure UpgradeAgent()
    // var
    //     RoomPlanningAgentSetup: Record "Room Planning Agent Setup";
    //     UpgradeTag: Codeunit "Upgrade Tag";
    // begin
    //     if UpgradeTag.HasUpgradeTag(GetUpgradeTag()) then
    //         exit;

    //     if not RoomPlanningAgentSetup.FindSet() then
    //         exit;

    //     repeat
    //         UpgradeAgentInstructions(RoomPlanningAgentSetup);
    //     until RoomPlanningAgentSetup.Next() = 0;

    //     UpgradeTag.SetUpgradeTag(GetUpgradeTag());
    // end;

    // local procedure UpgradeAgentInstructions(var RoomPlanningAgentSetup: Record "Room Planning Agent Setup")
    // var
    //     Agent: Codeunit Agent;
    //     RoomPlanningAgentSetupCU: Codeunit "Room Planning Agent Setup";
    // begin
    //     Agent.SetInstructions(RoomPlanningAgentSetup."User Security ID", RoomPlanningAgentSetupCU.GetInstructions());
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    // local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    // begin
    //     PerDatabaseUpgradeTags.Add(GetUpgradeTag());
    // end;

    // local procedure GetUpgradeTag() : Code[250]
    // begin
    //     exit('RoomPlanningAgentInstructionUpgradeV2');
    // end;
}
