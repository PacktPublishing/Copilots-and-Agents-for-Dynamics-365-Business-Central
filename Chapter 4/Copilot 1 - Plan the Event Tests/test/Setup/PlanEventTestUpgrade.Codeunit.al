// ------------------------------------------------------------------------------------------------
// Re-imports AI Test Toolkit datasets/suites on app upgrade (e.g. after suites were deleted).
// ------------------------------------------------------------------------------------------------

codeunit 50702 "Plan Event Test Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Install: Codeunit "Plan Event Test Install";
    begin
        Install.ImportResources();
    end;
}
