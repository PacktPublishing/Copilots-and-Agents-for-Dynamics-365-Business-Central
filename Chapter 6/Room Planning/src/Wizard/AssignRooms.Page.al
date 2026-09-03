page 50810 "Assign Rooms"
{
    ApplicationArea = All;
    Caption = 'Assign Rooms';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Room Assignment Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Date", "Start Time", "Session Code");

    layout
    {
        area(Content)
        {
            group(Instructional)
            {
                Caption = 'Assign rooms';
                InstructionalText = 'Set a room on each upcoming session. A room is too small when its capacity is below the attendees you estimate. Two sessions cannot share a room in the same slot. Changes are not saved until you finish.';
                ShowCaption = false;
            }
            repeater(Sessions)
            {
                field("Session Code"; Rec."Session Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the session to assign a room to.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the session title.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the scheduled date for the session.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the scheduled start time.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the scheduled end time.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the current status of the session.';
                }
                field("Estimated Attendees"; Rec."Estimated Attendees")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies how many attendees you expect at this session. Fill this in from comparable sessions at previous conferences. It is your estimate, not a counted figure.';
                }
                field("Reserved Attendees"; Rec."Reserved Attendees")
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies how many attendees have reserved this session in the conference app. It is zero until attendees start planning their schedule, and not every attendee who reserves a session turns up.';
                }
                field("Room Code"; Rec."Room Code")
                {
                    ApplicationArea = All;
                    StyleExpr = SessionStyle;
                    ToolTip = 'Specifies the room for this session. A room is too small when its capacity is below the number of attendees you estimate. Two sessions cannot share a room in the same slot.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Room)
            {
                ApplicationArea = All;
                Caption = 'Room';
                Enabled = Rec."Room Code" <> '';
                Image = Warehouse;
                RunObject = Page "Room Card";
                RunPageLink = "Code" = field("Room Code");
                ToolTip = 'Open the card for the room on this row.';
            }
            action(Finish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Writes the room codes from this list back to the sessions. Rows you did not change are left as they are.';

                trigger OnAction()
                var
                    AssignRoomsMgt: Codeunit "Assign Rooms Mgt";
                begin
                    if AssignRoomsMgt.Finish(Rec) then
                        CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AssignRoomsMgt: Codeunit "Assign Rooms Mgt";
    begin
        AssignRoomsMgt.Load(Rec);
        if Rec.FindFirst() then;
    end;

    trigger OnAfterGetRecord()
    begin
        SessionStyle := Rec.GetAttendeeDemandStyle();
    end;

    var
        SessionStyle: Text;
}
