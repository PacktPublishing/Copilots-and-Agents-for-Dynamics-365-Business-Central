// ------------------------------------------------------------------------------------------------
// Re-imports AI Test Toolkit datasets/suites on app upgrade (e.g. after suites were deleted).
// ------------------------------------------------------------------------------------------------

codeunit 50722 "Create Event Proj Test Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Install: Codeunit "Create Event Proj Test Install";
    begin
        Install.ImportResources();
    end;
}
