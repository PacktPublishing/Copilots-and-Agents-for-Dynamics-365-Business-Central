codeunit 50501 "Import Sess. Proposals Install"
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
        LearnMoreUrlTxt: Label 'https://github.com/PacktPublishing/AI-solutions-for-Dynamics-365-Business-Central', Locked = true;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Import Session Proposals") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Import Session Proposals", LearnMoreUrlTxt);
    end;
}
