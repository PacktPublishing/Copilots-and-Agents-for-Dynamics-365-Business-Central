pagecustomization "RPA Job List" customizes "Job List"
{
    ClearViews = true;

    actions
    {
        // Keep Event Sessions (from Common). Hide the rest of Project navigation.
        modify("Job Task &Lines")
        {
            Visible = false;
        }
        modify("&Dimensions")
        {
            Visible = false;
        }
        modify("&Statistics")
        {
            Visible = false;
        }
        modify("Assigned Resources")
        {
            Visible = false;
        }
        modify(SalesInvoicesCreditMemos)
        {
            Visible = false;
        }
        modify("Co&mments")
        {
            Visible = false;
        }
        modify(AssemblyOrders)
        {
            Visible = false;
        }
        modify("W&IP")
        {
            Visible = false;
        }
        modify("&Prices")
        {
            Visible = false;
        }
        modify(Prices)
        {
            Visible = false;
        }
        modify("Plan&ning")
        {
            Visible = false;
        }
        modify(History)
        {
            Visible = false;
        }
        modify(Warehouse_Related)
        {
            Visible = false;
        }
        modify("<Action9>")
        {
            Visible = false;
        }
        modify(Warehouse)
        {
            Visible = false;
        }
        modify("Job Actual to Budget")
        {
            Visible = false;
        }
        modify("Job Actual to Budget (Cost)")
        {
            Visible = false;
        }
        modify("Job Actual to Budget (Price)")
        {
            Visible = false;
        }
        modify("Job Analysis")
        {
            Visible = false;
        }
        modify("Job - Planning Lines")
        {
            Visible = false;
        }
        modify("Job - Suggested Billing")
        {
            Visible = false;
        }
        modify("Job Cost Suggested Billing")
        {
            Visible = false;
        }
        modify("Customer Jobs (Cost)")
        {
            Visible = false;
        }
        modify("Jobs per Customer")
        {
            Visible = false;
        }
        modify("Customer Jobs (Price)")
        {
            Visible = false;
        }
        modify("Items per Job")
        {
            Visible = false;
        }
        modify("Jobs per Item")
        {
            Visible = false;
        }
        modify("Report Job Quote")
        {
            Visible = false;
        }
        modify("Send Job Quote")
        {
            Visible = false;
        }
        modify(ProjectsAnalysis)
        {
            Visible = false;
        }
        modify("Financial Management")
        {
            Visible = false;
        }
        modify(Action23)
        {
            Visible = false;
        }
        modify(Category_Process)
        {
            Visible = false;
        }
        modify(Category_Dimensions)
        {
            Visible = false;
        }
        modify("&Statistics_Promoted")
        {
            Visible = false;
        }
        modify("Co&mments_Promoted")
        {
            Visible = false;
        }
        modify(SalesInvoicesCreditMemos_Promoted)
        {
            Visible = false;
        }
        modify("Job Task &Lines_Promoted")
        {
            Visible = false;
        }
        modify("Assigned Resources_Promoted")
        {
            Visible = false;
        }
        modify("Ledger E&ntries_Promoted")
        {
            Visible = false;
        }
        modify(Category_Category6)
        {
            Visible = false;
        }
        modify(Category_WIP)
        {
            Visible = false;
        }
        modify(Category_Category4)
        {
            Visible = false;
        }
        modify(Category_Report)
        {
            Visible = false;
        }
    }
}
