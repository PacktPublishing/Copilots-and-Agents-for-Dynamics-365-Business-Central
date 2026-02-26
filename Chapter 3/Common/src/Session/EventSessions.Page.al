page 50212 "Event Sessions"
{
    ApplicationArea = All;
    Caption = 'Event Sessions';
    PageType = List;
    SourceTable = "Event Session";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for the session.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the session title.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short description of the session.';
                }
                field(Speaker1; Rec.Speaker1)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the first speaker.';
                }
                field(Speaker2; Rec.Speaker2)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the second speaker.';
                }
                field(Speaker3; Rec.Speaker3)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the third speaker.';
                }
                field(Speaker4; Rec.Speaker4)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the fourth speaker.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the session.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scheduled date for the session.';
                }
                field("Track No."; Rec."Track No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the track number assigned to this session.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scheduled start time.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scheduled end time.';
                }
                field("Duration (min)"; Rec."Duration (min)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the duration of the session in minutes.';
                }
            }
        }
    }
}
