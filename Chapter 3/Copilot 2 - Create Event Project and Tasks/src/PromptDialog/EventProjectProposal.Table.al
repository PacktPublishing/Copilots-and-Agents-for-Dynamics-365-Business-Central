namespace Packt;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

table 50402 "Event Project Proposal"
{
    Caption = 'Event Project Proposal';
    TableType = Temporary;

    fields
    {
        field(1; "Job Task No."; Code[10])
        {
            Caption = 'Job Task No.';
            Editable = false;
        }
        field(2; "Job Short Description"; Text[100])
        {
            Caption = 'Job Short Description';
        }
        field(4; "Extracted Customer"; Text[100])
        {
            Caption = 'Extracted Customer';
        }
        field(5; "Suggested Customer No."; Code[20])
        {
            Caption = 'Suggested Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                UpdateSuggestedCustomerName();
            end;
        }
        field(6; "Suggested Customer Name"; Text[100])
        {
            Caption = 'Suggested Customer Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                CustomerName: Text;
            begin
                CustomerName := "Suggested Customer Name";
                LookupSuggestedCustomerName(CustomerName);
                "Suggested Customer Name" := CopyStr(CustomerName, 1, MaxStrLen("Suggested Customer Name"));
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
                LookupStateManager: Codeunit "Lookup State Manager";
            begin
                if "Suggested Customer Name" = '' then
                    LookupStateManager.ClearSavedRecord();

                if LookupStateManager.IsRecordSaved() then begin
                    Customer := LookupStateManager.GetSavedRecord();
                    if Customer."No." <> '' then begin
                        LookupStateManager.ClearSavedRecord();
                        Validate("Suggested Customer No.", Customer."No.");
                        exit;
                    end;
                end;

                if ShouldSearchForCustomerByName("Suggested Customer No.") then
                    Validate("Suggested Customer No.", Customer.GetCustNo("Suggested Customer Name"));
            end;
        }
        field(3; "Job Full Description"; Blob)
        {
            Caption = 'Job Full Description';
        }
        field(100; "Task Description"; Text[100])
        {
            Caption = 'Task Description';
        }
        field(101; "Action Description Preview"; Text[100])
        {
            Caption = 'Action Description';
        }
        field(102; "Action Description"; Blob)
        {
            Caption = 'Action Description';
        }
        field(103; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(104; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(105; Type; Option)
        {
            Caption = 'Type';
            OptionMembers = Resource,Item,Both;
        }
        field(106; "Item Category"; Text[50])
        {
            Caption = 'Item Category';
        }
        field(107; "Resource Role Description"; Text[50])
        {
            Caption = 'Resource Role Description';
        }
        field(108; Indentation; Integer)
        {
            Editable = false;
        }
        field(109; "Job Task Type"; Enum "Job Task Type")
        {
            Caption = 'Job Task Type';
        }
    }

    keys
    {
        key(Key1; "Job Task No.")
        {
            Clustered = true;
        }
    }

    local procedure UpdateSuggestedCustomerName()
    var
        Customer: Record Customer;
    begin
        if "Suggested Customer No." = '' then begin
            Clear("Suggested Customer Name");
            exit;
        end;

        Customer.Get("Suggested Customer No.");
        "Suggested Customer Name" := Customer.Name;
    end;

    procedure LookupSuggestedCustomerName(var CustomerName: Text): Boolean
    var
        Customer: Record Customer;
        LookupStateManager: Codeunit "Lookup State Manager";
        CustomerRecord: Variant;
        SearchCustomerName: Text;
    begin
        SearchCustomerName := CustomerName;
        if "Suggested Customer No." <> '' then
            Customer.Get("Suggested Customer No.");

        if Customer.SelectCustomer(Customer) then begin
            if "Suggested Customer Name" = Customer.Name then
                CustomerName := SearchCustomerName
            else
                CustomerName := Customer.Name;
            CustomerRecord := Customer;
            LookupStateManager.SaveRecord(CustomerRecord);
            exit(true);
        end;
    end;

    local procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit(true);

        Customer.SetLoadFields("Disable Search by Name");
        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;
}
