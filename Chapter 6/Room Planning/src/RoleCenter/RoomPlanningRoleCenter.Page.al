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
                ToolTip = 'View and manage projects, including event projects used for room planning.';
            }
            action(Rooms)
            {
                ApplicationArea = All;
                Caption = 'Rooms';
                Image = Warehouse;
                RunObject = Page "Room List";
                ToolTip = 'View venue rooms, capacity, and blocked status for room assignment.';
            }
        }
        area(Sections)
        {
            group(ProjectsSection)
            {
                Caption = 'Projects';
                ToolTip = 'Open projects and related event planning.';
                action(JobList)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    Image = Job;
                    RunObject = Page "Job List";
                    ToolTip = 'View and manage projects, including event projects used for room planning.';
                }
            }
            group(RoomsSection)
            {
                Caption = 'Rooms';
                ToolTip = 'Open venue rooms used for session assignment.';
                action(RoomList)
                {
                    ApplicationArea = All;
                    Caption = 'Rooms';
                    Image = Warehouse;
                    RunObject = Page "Room List";
                    ToolTip = 'View venue rooms, capacity, and blocked status for room assignment.';
                }
            }
        }
    }
}
