codeunit 50601 "Build Agenda Install"
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

        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Build Conference Agenda") then
            exit;

        CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"Build Conference Agenda",
            Enum::"Copilot Availability"::Preview,
            Enum::"Copilot Billing Type"::"Not Billed",
            LearnMoreUrlTxt);
    end;
}
