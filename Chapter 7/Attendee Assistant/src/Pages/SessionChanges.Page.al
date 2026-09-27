// ----------------------------------------------------------------------------
// Page 98208 - Session Changes (custom API, read only)
// The change log the assistant reads to answer "has anything changed?".
// The agent filters by changedAt and by the session codes in the attendee's
// agenda. MCP tool (29.0): List_SessionChanges_PAG98208
// ----------------------------------------------------------------------------
page 98208 "Session Changes"
{
    PageType = API;
    Caption = 'Session Change';
    EntityCaption = 'Session Change';
    EntitySetCaption = 'Changes to the published program (room, schedule, speaker, cancellation) with the organizers note';
    APIPublisher = 'cronusEvents';
    APIGroup = 'attendee';
    APIVersion = 'v1.0';
    EntityName = 'sessionChange';
    EntitySetName = 'sessionChanges';
    SourceTable = "CE Session Change";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'id', Locked = true;
                }
                field(sessionCode; Rec."Session Code")
                {
                    Caption = 'sessionCode', Locked = true;
                }
                field(sessionTitle; Rec."Session Name")
                {
                    Caption = 'sessionTitle', Locked = true;
                }
                field(changeType; Rec."Change Type")
                {
                    Caption = 'changeType', Locked = true;
                }
                field(oldValue; Rec."Old Value")
                {
                    Caption = 'oldValue', Locked = true;
                }
                field(newValue; Rec."New Value")
                {
                    Caption = 'newValue', Locked = true;
                }
                field(changedAt; Rec."Changed At")
                {
                    Caption = 'changedAt', Locked = true;
                }
                field(note; Rec.Note)
                {
                    Caption = 'note', Locked = true;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AttendeeSetup: Record "CE Attendee Setup";
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Event Project No.", AttendeeSetup.GetEventProjectNo());
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Session Name");
    end;
}
