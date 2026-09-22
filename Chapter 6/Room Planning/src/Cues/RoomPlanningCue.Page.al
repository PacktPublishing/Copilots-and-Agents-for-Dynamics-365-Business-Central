page 50816 "Room Planning Cue"
{
    ApplicationArea = All;
    Caption = 'Room Planning';
    PageType = CardPart;
    SourceTable = "Room Planning Cue";

    layout
    {
        area(Content)
        {
            cuegroup(RoomPlanning)
            {
                Caption = 'Room Planning';
                field("Sessions without Estimate"; Rec."Sessions without Estimate")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Event Sessions";
                    ToolTip = 'Counts scheduled sessions with Estimated Attendees = 0. Open each session, use Reserved Attendees or Find Similar past Actual Attendees, then set the estimate before assigning a room.';
                }
                field("Sessions without a Room"; Rec."Sessions without a Room")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Event Sessions";
                    ToolTip = 'Counts scheduled sessions with an empty Room Code. Open the list, set Estimated Attendees first if needed, then assign a free room that fits.';
                }
                field("Over Capacity Sessions"; Rec."Over Capacity Sessions")
                {
                    ApplicationArea = All;
                    ToolTip = 'Counts scheduled sessions where Reserved Attendees exceed the assigned room Capacity. Move each session to a larger free room, or leave it and ask for help.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownOverCapacitySessions();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InsertRecord();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Sessions without Estimate", "Sessions without a Room");
        Rec."Over Capacity Sessions" := Rec.CountOverCapacitySessions();
    end;
}
