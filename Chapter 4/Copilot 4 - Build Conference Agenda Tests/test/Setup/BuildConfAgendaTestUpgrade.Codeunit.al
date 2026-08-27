// ------------------------------------------------------------------------------------------------
// Re-imports AI Test Toolkit datasets/suites on app upgrade (e.g. after suites were deleted).
// ------------------------------------------------------------------------------------------------

codeunit 50762 "Build Conf Agenda Test Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Install: Codeunit "Build Conf Agenda Test Install";
    begin
        Install.ImportResources();
    end;
}
