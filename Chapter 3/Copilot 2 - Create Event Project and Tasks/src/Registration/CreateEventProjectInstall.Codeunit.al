namespace Packt;

using System.AI;
using System.Environment;

codeunit 50401 "Create Event Project Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        LearnMoreUrlTxt: Label 'https://learn.microsoft.com/en-us/dynamics365/business-central/developer/devenv-develop-copilot', Locked = true;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;

        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Create Event Project") then
            exit;

        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Create Event Project", LearnMoreUrlTxt);
    end;
}
