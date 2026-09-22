namespace Packt;

table 50851 "Room Planning Agent KPI"
{
    Access = Internal;
    Caption = 'Room Planning Agent KPI';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            ToolTip = 'Specifies the unique identifier for the agent user.';
        }
        field(10; "Sessions Assigned"; Integer)
        {
            Caption = 'Sessions Assigned';
            DataClassification = CustomerContent;
            MinValue = 0;
            ToolTip = 'Specifies how many conference sessions this agent has assigned a room to.';
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
