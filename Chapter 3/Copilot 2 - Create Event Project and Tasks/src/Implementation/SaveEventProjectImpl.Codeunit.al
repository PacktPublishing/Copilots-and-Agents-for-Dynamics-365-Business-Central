codeunit 50404 "Save Event Project Impl"
{
    procedure ApplyEventProject(var EventProjectProposal: Record "Event Project Proposal")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if not EventProjectProposal.FindSet() then
            exit;

        Job := CreateJob(EventProjectProposal."Job Short Description", EventProjectProposal."Customer Name");

        repeat
            JobTask := CreateJobTask(Job."No.", EventProjectProposal);

            if JobTask."Job Task Type" = JobTask."Job Task Type"::Posting then
                CreateJobPlanningLine(JobTask, EventProjectProposal);
        until EventProjectProposal.Next() = 0;
    end;

    local procedure CreateJob(JobDescription: Text[100]; CustomerSearchKeyword: Text) Job: Record Job
    begin
        Job.Init();
        Job.Validate(Description, JobDescription);
        Job.Validate("Bill-to Customer No.", FindCustomerBySearchKeyword(CustomerSearchKeyword));
        Job.Validate("Starting Date", FindFirstAvailableDateInAllowedLicensePeriod());
        Job.Insert(true);
    end;

    local procedure FindCustomerBySearchKeyword(CustomerSearchKeyword: Text): Code[20]
    var
        Customer: Record Customer;
    begin
        if CustomerSearchKeyword = '' then
            exit('');

        Customer.SetFilter(Name, '&&' + CustomerSearchKeyword + '*');
        if Customer.FindFirst() then
            exit(Customer."No.");

        exit('');
    end;

    local procedure FindFirstAvailableDateInAllowedLicensePeriod(): Date
    begin
        exit(DMY2Date(1, 12, Date2DMY(Today(), 3)));
    end;

    local procedure CreateJobTask(JobNo: Code[20]; var EventProjectProposal: Record "Event Project Proposal" temporary) JobTask: Record "Job Task"
    begin
        JobTask.Init();
        JobTask.Validate("Job No.", JobNo);
        JobTask.Validate("Job Task No.", EventProjectProposal."Job Task No.");
        JobTask.Validate(Description, EventProjectProposal."Task Description");
        JobTask.Validate("Job Task Type", EventProjectProposal."Job Task Type");
        JobTask.Validate(Indentation, EventProjectProposal.Indentation);
        JobTask.Insert(true);
    end;

    local procedure CreateJobPlanningLine(JobTask: Record "Job Task"; var EventProjectProposal: Record "Event Project Proposal" temporary)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineNo: Integer;
    begin
        JobPlanningLineNo := 10000;

        if EventProjectProposal.Type in [EventProjectProposal.Type::Resource, EventProjectProposal.Type::Both] then begin
            JobPlanningLine := CreateBaseJobPlanningLine(JobTask, EventProjectProposal);
            JobPlanningLine.Validate("Line No.", JobPlanningLineNo);
            JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
            JobPlanningLine.Validate("Description 2", EventProjectProposal."Resource Role Description");
            JobPlanningLine.Insert(true);
            JobPlanningLineNo += 1;
        end;

        if EventProjectProposal.Type in [EventProjectProposal.Type::Item, EventProjectProposal.Type::Both] then begin
            Clear(JobPlanningLine);
            JobPlanningLine := CreateBaseJobPlanningLine(JobTask, EventProjectProposal);
            JobPlanningLine.Validate("Line No.", JobPlanningLineNo);
            JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
            JobPlanningLine.Validate("Description 2", EventProjectProposal."Item Category");
            JobPlanningLine.Insert(true);
        end;
    end;

    local procedure CreateBaseJobPlanningLine(JobTask: Record "Job Task"; var EventProjectProposal: Record "Event Project Proposal" temporary) JobPlanningLine: Record "Job Planning Line"
    var
        ActionDescription: Text;
        InStr: InStream;
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", 10000);

        EventProjectProposal.CalcFields("Action Description");
        EventProjectProposal."Action Description".CreateInStream(InStr);
        InStr.ReadText(ActionDescription);

        JobPlanningLine.Validate(Description, CopyStr(ActionDescription, 1, MaxStrLen(JobPlanningLine.Description)));
        if EventProjectProposal."Start Date" <> 0D then
            JobPlanningLine.Validate("Planning Date", EventProjectProposal."Start Date");
        if EventProjectProposal."End Date" <> 0D then
            JobPlanningLine."Planned Delivery Date" := EventProjectProposal."End Date";
    end;
}
