// ------------------------------------------------------------------------------------------------
// Re-imports AI Test Toolkit datasets/suites on app upgrade (e.g. after suites were deleted).
// ------------------------------------------------------------------------------------------------

codeunit 50742 "Import Sess Prop Test Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Install: Codeunit "Import Sess Prop Test Install";
    begin
        Install.ImportResources();
    end;
}
