/// <summary>
/// Lets the user review and edit the room-assignment request before it is sent to
/// the Room Planning Agent as a new task.
/// </summary>
page 50836 "RPA Assign Task Dialog"
{
    PageType = StandardDialog;
    Caption = 'Assign Rooms with Agent';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(MessageText; MessageText)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
                ShowMandatory = true;
                InstructionalText = 'Describe the room assignment you want. Edit the suggested message, or replace it with your own.';
                ToolTip = 'Specifies the room-assignment request to send to the Room Planning Agent.';
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
        MessageRequiredErr: Label 'Enter a room-assignment request before you continue.';
}
