// This page serves as a template for creating custom agent setup pages.
// The Agent Setup Part handles common agent configuration (name, state, access control).
// Extend this page by adding your own fields and groups for agent-specific settings.
// ------------------------------------------------------------------------------------------------

using System.Agents;
using System.AI;

page 50828 "Room Planning Agent Setup"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = All;
    IsPreview = true;
    Caption = 'Set up the Room Planning Agent';
    InstructionalText = 'Assigns rooms to conference sessions based on expected attendees.';
    AdditionalSearchTerms = 'Room Planning Agent, Agent';
    SourceTable = "Room Planning Agent Setup";
    SourceTableTemporary = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            // The Agent Setup Part provides standard agent configuration UI
            // including name, display name, state, and access control settings.
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }

            // Add your own groups and fields below.
            // Each field should set IsUpdated := true in OnValidate to enable the Update button.
            group(AdditionalConfiguration)
            {
                Caption = 'Additional Configuration';

                field(DisplayName; AgentDisplayName)
                {
                    Caption = 'Display Name';
                    ApplicationArea = All;
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
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Room Planning Agent Capability") then
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
        RoomPlanningAgentIsNotEnabledInCopilotCapabilitiesErr: Label 'The Room Planning Agent capability is not enabled in Copilot capabilities.\\Please enable the capability before setting up the agent.';
        AgentDisplayName: Text[80];
}