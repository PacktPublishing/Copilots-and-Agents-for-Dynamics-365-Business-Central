namespace Packt;

/// <summary>
/// Lets the user review and edit the room-planning message before it is sent to the agent.
/// </summary>
page 50858 "RPA Assign Task Dialog"
{
    Caption = 'Assign Rooms with Agent';
    InherentEntitlements = X;
    InherentPermissions = X;
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(MessageText; MessageText)
            {
                ApplicationArea = All;
                InstructionalText = 'Describe which event needs rooms assigned. Edit the suggested message, or replace it with your own.';
                MultiLine = true;
                ShowCaption = false;
                ShowMandatory = true;
                ToolTip = 'Specifies the message the Room Planning Agent should use to identify the event and assign rooms to its sessions.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if MessageText = '' then
                Error(MessageRequiredErr);
        exit(true);
    end;

    procedure GetMessage(): Text
    begin
        exit(MessageText);
    end;

    procedure SetSuggestedMessage(SuggestedMessage: Text)
    begin
        MessageText := CopyStr(SuggestedMessage, 1, MaxStrLen(MessageText));
    end;

    var
        MessageText: Text;
        MessageRequiredErr: Label 'Enter a message for the Room Planning Agent before you continue.';
}
