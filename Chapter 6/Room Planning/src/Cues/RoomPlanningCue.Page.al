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
                field("Sessions without a Room"; Rec."Sessions without a Room")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Event Sessions";
                    ToolTip = 'Specifies how many scheduled sessions for this event, on or after the work date, have no room yet.';
                }
                field("Over Capacity Sessions"; Rec."Over Capacity Sessions")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many future scheduled sessions for this event have more reserved attendees than the assigned room can seat.';

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
        Rec.SetFilter("Date Filter", '%1..', WorkDate());
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Sessions without a Room");
        Rec."Over Capacity Sessions" := Rec.CountOverCapacitySessions();
    end;
}
