table 50829 "Room Planning Agent KPI"
{
    Access = Internal;
    Caption = 'Room Planning Agent KPI';
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    DataPerCompany = false;

    fields
    {
        // This field is part of the IAgentMetadata.GetSummaryPageId() contract.
        // The platform filters on "User Security ID" when opening the summary page,
        // so it must be the primary key of this table.
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the unique identifier for the agent user.';
            Editable = false;
        }
        field(10; "Sessions Assigned"; Integer)
        {
            Caption = 'Sessions Assigned';
            ToolTip = 'Specifies how many conference sessions this agent has assigned a room to.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
    }
}
