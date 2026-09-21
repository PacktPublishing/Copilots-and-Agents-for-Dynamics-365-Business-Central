table 50828 "Room Planning Agent Setup"
{
    Access = Internal;
    Caption = 'Room Planning Agent Setup';
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    DataPerCompany = false;

    fields
    {
        // Primary key - links to the agent user created by the platform.
        // Do not modify this field.
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            ToolTip = 'Specifies the unique identifier for the user.';
            DataClassification = SystemMetadata;
            Editable = false;
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