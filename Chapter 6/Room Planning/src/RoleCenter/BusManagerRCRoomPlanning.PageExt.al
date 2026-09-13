pageextension 50809 "Bus. Manager RC Room Planning" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Sections)
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
        }
        addlast(embedding)
        {
            action(Projects)
            {
                ApplicationArea = Jobs;
                Caption = 'Projects';
                Image = Job;
                RunObject = Page "Job List";
                ToolTip = 'View and manage projects, including event projects used for room planning.';
            }
        }
    }
}
