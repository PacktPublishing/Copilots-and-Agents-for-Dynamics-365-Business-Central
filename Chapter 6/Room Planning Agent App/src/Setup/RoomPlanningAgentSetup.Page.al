namespace Packt;

using System.Agents;
using System.AI;

page 50850 "Room Planning Agent Setup"
{
    AdditionalSearchTerms = 'Room Planning Agent, Agent';
    ApplicationArea = All;
    Caption = 'Set up Room Planning Agent';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    InstructionalText = 'Assigns rooms to conference sessions based on expected attendees.';
    IsPreview = true;
    PageType = ConfigurationDialog;
    SourceTable = "Room Planning Agent Setup";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(AdditionalConfiguration)
            {
                Caption = 'Agent';
                InstructionalText = 'Review the display name used for this Room Planning Agent instance.';

                field(DisplayName; AgentDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the display name of the agent.';

                    trigger OnValidate()
                    begin
                        AgentSetupBuffer.Validate("Display Name", AgentDisplayName);
                        AgentSetupBuffer.Modify(true);
                        IsUpdated := true;

                        CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(AgentSetupBuffer);
                        CurrPage.AgentSetupPart.Page.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                Enabled = IsUpdated;
                ToolTip = 'Apply the changes to the agent setup.';
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discards the changes and closes the setup page.';
            }
        }
    }

    trigger OnOpenPage()
    var
        RoomPlanningAgentSetup: Codeunit "Room Planning Agent Setup";
        UserSecurityIDFilter: Text;
        UserSecurityID: Guid;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Room Planning Agent") then
            Error(RoomPlanningAgentIsNotEnabledInCopilotCapabilitiesErr);

        UserSecurityIDFilter := Rec.GetFilter("User Security ID");
        if not Evaluate(UserSecurityID, UserSecurityIDFilter) then
            Clear(UserSecurityID);

        Rec."User Security ID" := UserSecurityID;

        CurrPage.AgentSetupPart.Page.Initialize(
            UserSecurityID,
            RoomPlanningAgentSetup.GetAgentMetadataProvider(),
            RoomPlanningAgentSetup.GetAgentUserName(),
            RoomPlanningAgentSetup.GetDefaultDisplayName(),
            RoomPlanningAgentSetup.GetAgentSummary());

        InitializePage();
        IsUpdated := CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;

    trigger OnAfterGetRecord()
    begin
        InitializePage();
        IsUpdated := IsUpdated or CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsUpdated := IsUpdated or CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        IsUpdated := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RoomPlanningAgentSetup: Codeunit "Room Planning Agent Setup";
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        RoomPlanningAgentSetup.SaveSetupRecord(Rec, AgentSetupBuffer);
        RoomPlanningAgentSetup.PersistSetupRecord(Rec);
        exit(true);
    end;

    local procedure InitializePage()
    var
        RoomPlanningAgentSetup: Codeunit "Room Planning Agent Setup";
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        RoomPlanningAgentSetup.InitializeSetupRecord(Rec);

        AgentDisplayName := AgentSetupBuffer."Display Name";
        IsUpdated := IsUpdated or CurrPage.AgentSetupPart.Page.GetChangesMade();
    end;

    var
        AgentSetupBuffer: Record "Agent Setup Buffer";
        AzureOpenAI: Codeunit "Azure OpenAI";
        IsUpdated: Boolean;
        AgentDisplayName: Text[80];
        RoomPlanningAgentIsNotEnabledInCopilotCapabilitiesErr: Label 'The Room Planning Agent capability is not enabled in Copilot capabilities.\\Please enable the capability before setting up the agent.';
}
