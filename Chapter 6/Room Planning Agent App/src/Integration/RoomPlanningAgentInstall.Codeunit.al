namespace Packt;

using System.Agents;
using System.AI;

codeunit 50851 "Room Planning Agent Install"
{
    Subtype = Install;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    var
        RoomPlanningAgentSetup: Record "Room Planning Agent Setup";
    begin
        RegisterCapability();

        if not RoomPlanningAgentSetup.FindSet() then
            exit;

        repeat
            InstallAgent(RoomPlanningAgentSetup);
        until RoomPlanningAgentSetup.Next() = 0;
    end;

    local procedure InstallAgent(var RoomPlanningAgentSetup: Record "Room Planning Agent Setup")
    begin
        InstallAgentInstructions(RoomPlanningAgentSetup);
        InstallAgentLocalization(RoomPlanningAgentSetup);
    end;

    local procedure InstallAgentInstructions(var RoomPlanningAgentSetup: Record "Room Planning Agent Setup")
    var
        Agent: Codeunit Agent;
        RoomPlanningAgentSetupCU: Codeunit "Room Planning Agent Setup";
    begin
        Agent.SetInstructions(RoomPlanningAgentSetup."User Security ID", RoomPlanningAgentSetupCU.GetInstructions());
    end;

    local procedure InstallAgentLocalization(var RoomPlanningAgentSetup: Record "Room Planning Agent Setup")
    var
        Agent: Codeunit Agent;
        RoomPlanningAgentSetupCU: Codeunit "Room Planning Agent Setup";
        LanguageId: Integer;
        LocaleId: Integer;
        TimeZoneText: Text[180];
    begin
        RoomPlanningAgentSetupCU.GetDefaultLocalizationSettings(LanguageId, LocaleId, TimeZoneText);
        Agent.UpdateLocalizationSettings(RoomPlanningAgentSetup."User Security ID", LanguageId, LocaleId, TimeZoneText);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://learn.microsoft.com/dynamics365/business-central/dev-itpro/ai/ai-agent-sdk-overview', Locked = true;
    begin
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Room Planning Agent") then
            CopilotCapability.UnregisterCapability(Enum::"Copilot Capability"::"Room Planning Agent");

        CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"Room Planning Agent",
            Enum::"Copilot Availability"::Preview,
            "Copilot Billing Type"::"Microsoft Billed",
            LearnMoreUrlTxt);
    end;
}
