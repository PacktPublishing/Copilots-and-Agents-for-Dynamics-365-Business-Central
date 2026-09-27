// ----------------------------------------------------------------------------
// Page 98211 - Session changes (list, for organizers)
// Organizers can add a note to a change; the assistant shows it to attendees.
// ----------------------------------------------------------------------------
page 98211 "CE Session Changes"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Session Changes';
    SourceTable = "CE Session Change";
    SourceTableView = sorting("Changed At") order(descending);
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Changed At"; Rec."Changed At") { ApplicationArea = All; ToolTip = 'Specifies when the change was recorded.'; }
                field("Event Project No."; Rec."Event Project No.") { ApplicationArea = All; ToolTip = 'Specifies the event project of the session.'; Editable = false; }
                field("Session Code"; Rec."Session Code") { ApplicationArea = All; ToolTip = 'Specifies the code of the session that changed.'; Editable = false; }
                field("Session Name"; Rec."Session Name") { ApplicationArea = All; ToolTip = 'Specifies the name of the session that changed.'; }
                field("Change Type"; Rec."Change Type") { ApplicationArea = All; Editable = false; }
                field("Old Value"; Rec."Old Value") { ApplicationArea = All; ToolTip = 'Specifies the value before the change.'; Editable = false; }
                field("New Value"; Rec."New Value") { ApplicationArea = All; ToolTip = 'Specifies the value after the change.'; Editable = false; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}
