page 50818 "Event Demo Data"
{
    ApplicationArea = All;
    Caption = 'Event Demo Data';
    Editable = false;
    PageType = Card;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(Instructional)
            {
                Caption = 'Cronus BC Tech Summit';
                InstructionalText = 'Creates the Cronus BC Tech Summit venue in Amsterdam, 11-12 June 2027. Set the work date to a day before 11 June 2027 before you plan rooms. Run the actions in order: venue and schedule first (past conferences include reservations; 2027 rooms and reservations stay empty), then 2027 reservations, then cancel a session, then day-one actuals.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetupVenueAndSchedule)
            {
                ApplicationArea = All;
                Caption = 'Set up venue and schedule';
                Image = Setup;
                ToolTip = 'Creates rooms, jobs, last year''s completed sessions with reservations, and the 2027 schedule. This year''s reservations stay empty and rooms stay unassigned.';

                trigger OnAction()
                var
                    CronusRoomDemoData: Codeunit "Event Demo Data";
                begin
                    CronusRoomDemoData.GenerateVenueAndSchedule();
                    Message(VenueReadyMsg);
                end;
            }
            action(AddAttendeeReservations)
            {
                ApplicationArea = All;
                Caption = 'Add attendee reservations';
                Image = CoupledUsers;
                ToolTip = 'Adds conference-app reservations on the 2027 sessions. Run this after the venue and schedule exist.';

                trigger OnAction()
                var
                    CronusRoomDemoData: Codeunit "Event Demo Data";
                begin
                    CronusRoomDemoData.GenerateReservations();
                    Message(ReservationsReadyMsg);
                end;
            }
            action(CancelASession)
            {
                ApplicationArea = All;
                Caption = 'Cancel a session';
                Image = Cancel;
                ToolTip = 'Cancels the opening keynote T27-KEY. The room on that session is left as it is so you can clear it on Event Sessions.';

                trigger OnAction()
                var
                    CronusRoomDemoData: Codeunit "Event Demo Data";
                begin
                    CronusRoomDemoData.CancelKeynoteSession();
                    Message(KeynoteCancelledMsg);
                end;
            }
            action(FillDayOneActuals)
            {
                ApplicationArea = All;
                Caption = 'Fill day-one actuals';
                Image = Calculate;
                ToolTip = 'Writes Actual Attendees on TECH2027 sessions on 11 June 2027 that do not have an actual yet.';

                trigger OnAction()
                var
                    CronusRoomDemoData: Codeunit "Event Demo Data";
                begin
                    CronusRoomDemoData.FillDayOneActuals();
                    Message(ActualsReadyMsg);
                end;
            }
            action(CleanDemoData)
            {
                ApplicationArea = All;
                Caption = 'Clean demo data';
                Image = Delete;
                ToolTip = 'Deletes reservation entries, TECH20xx event sessions, and demo rooms. Jobs are deleted when nothing else still uses them.';

                trigger OnAction()
                var
                    CronusRoomDemoData: Codeunit "Event Demo Data";
                begin
                    if not Confirm(CleanDemoDataQst) then
                        exit;
                    CronusRoomDemoData.DeleteDemoData();
                    Message(DemoDataDeletedMsg);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetupVenueAndSchedule_Promoted; SetupVenueAndSchedule)
            {
            }
            actionref(AddAttendeeReservations_Promoted; AddAttendeeReservations)
            {
            }
            actionref(CancelASession_Promoted; CancelASession)
            {
            }
            actionref(FillDayOneActuals_Promoted; FillDayOneActuals)
            {
            }
            actionref(CleanDemoData_Promoted; CleanDemoData)
            {
            }
        }
    }

    var
        VenueReadyMsg: Label 'Venue, jobs, history with reservations, and the 2027 schedule are ready. This year''s reservations are empty and rooms are unassigned.';
        ReservationsReadyMsg: Label 'Attendee reservations have been added for the 2027 sessions.';
        KeynoteCancelledMsg: Label 'The opening keynote T27-KEY is now cancelled. Its room was not cleared.';
        ActualsReadyMsg: Label 'Actual attendees have been filled for day-one sessions.';
        CleanDemoDataQst: Label 'Delete reservation entries, TECH20xx event sessions, demo rooms, and the matching jobs if they are unused?';
        DemoDataDeletedMsg: Label 'Room Planning demo data has been deleted. You can run Set up venue and schedule again.';
}
