page 50810 "Room Planning Role Center"
{
    ApplicationArea = All;
    Caption = 'Room Planning';
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            part(RoomPlanningCue; "Room Planning Cue")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Embedding)
        {
            action(Projects)
            {
                ApplicationArea = Jobs;
                Caption = 'Projects';
                Image = Job;
                RunObject = Page "Job List";
                ToolTip = 'Opens Projects (Job List). Select the target event project, then open Event Sessions for that project to estimate attendance and assign rooms.';
            }
            action(Rooms)
            {
                ApplicationArea = All;
                Caption = 'Rooms';
                Image = Warehouse;
                RunObject = Page "Room List";
                ToolTip = 'Opens Rooms so you can check Code, Capacity, and Blocked before assigning a Room Code on a session.';
            }
        }
        area(Sections)
        {
            group(ProjectsSection)
            {
                Caption = 'Projects';
                ToolTip = 'Navigate to event projects used for room planning.';
                action(JobList)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    Image = Job;
                    RunObject = Page "Job List";
                    ToolTip = 'Opens Projects (Job List). Select the target event project, then open Event Sessions for that project to estimate attendance and assign rooms.';
                }
            }
            group(RoomsSection)
            {
                Caption = 'Rooms';
                ToolTip = 'Navigate to venue rooms used for session assignment.';
                action(RoomList)
                {
                    ApplicationArea = All;
                    Caption = 'Rooms';
                    Image = Warehouse;
                    RunObject = Page "Room List";
                    ToolTip = 'Opens Rooms so you can check Code, Capacity, and Blocked before assigning a Room Code on a session.';
                }
            }
        }
    }
}
