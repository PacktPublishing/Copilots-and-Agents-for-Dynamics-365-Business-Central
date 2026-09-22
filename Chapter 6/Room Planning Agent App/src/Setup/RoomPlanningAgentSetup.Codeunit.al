namespace Packt;

using System.Agents;
using System.Reflection;
using System.Security.AccessControl;

codeunit 50853 "Room Planning Agent Setup"
{
    Access = Internal;

    procedure GetInitials(): Text[4]
    begin
        exit(AgentInitialsLbl);
    end;

    procedure GetSetupPageId(): Integer
    begin
        exit(Page::"Room Planning Agent Setup");
    end;

    procedure GetSummaryPageId(): Integer
    begin
        exit(Page::"Room Planning Agent KPI");
    end;

    /// <summary>
    /// Gets the instructions from the app resource that was filled from the designed-agent export.
    /// </summary>
    [NonDebuggable]
    procedure GetInstructions(): SecretText
    begin
        exit(NavApp.GetResourceAsText('Instructions/InstructionsV1.txt'));
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    begin
        // Profile "ROOM PLANNING AGENT" lives in Chapter 6 - Room Planning (46e6e597-366b-4ed8-b9aa-ddb98540578c), not in this app.
        Agent.PopulateDefaultProfile(DefaultProfileTok, DependencyAppIdTok, TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        Clear(TempAccessControlBuffer);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        // LOGIN is kept from the designed-agent export (System Application). The Room Planning
        // Agent permission set already includes D365 BASIC, which covers LOGIN.
        TempAccessControlBuffer."App ID" := AccessControlAppId1Tok;
        TempAccessControlBuffer."Role ID" := 'LOGIN';
        TempAccessControlBuffer.Insert();
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := DependencyAppIdTok;
        TempAccessControlBuffer."Role ID" := 'ROOM PLANNING AGENT';
        TempAccessControlBuffer.Insert();
    end;

    procedure GetAgentMetadataProvider(): Enum "Agent Metadata Provider"
    begin
        exit(Enum::"Agent Metadata Provider"::"Room Planning Agent");
    end;

    procedure GetAgentUserName(): Code[50]
    begin
        // Kept verbatim (no ' - ' + CompanyName() suffix): exact-name lookups such as
        // FindAgentByUserName depend on this matching the exported <Name> exactly.
        exit(AgentNameLbl);
    end;

    procedure GetDefaultDisplayName(): Text[80]
    begin
        exit(DefaultDisplayNameLbl);
    end;

    procedure GetAgentSummary(): Text
    begin
        exit(AgentSummaryLbl);
    end;

    procedure GetDefaultLocalizationSettings(var LanguageId: Integer; var LocaleId: Integer; var TimeZoneText: Text[180])
    begin
        LanguageId := 1033;
        LocaleId := 1033;
        TimeZoneText := 'SE Asia Standard Time';
    end;

    procedure InitializeSetupRecord(var TempRoomPlanningAgentSetup: Record "Room Planning Agent Setup" temporary)
    var
        RoomPlanningAgentSetupRecord: Record "Room Planning Agent Setup";
    begin
        if not IsNullGuid(TempRoomPlanningAgentSetup."User Security ID") then
            if RoomPlanningAgentSetupRecord.Get(TempRoomPlanningAgentSetup."User Security ID") then
                TempRoomPlanningAgentSetup.TransferFields(RoomPlanningAgentSetupRecord, false);

        if TempRoomPlanningAgentSetup.IsEmpty() then
            TempRoomPlanningAgentSetup.Insert();
    end;

    procedure SaveSetupRecord(var TempRoomPlanningAgentSetup: Record "Room Planning Agent Setup" temporary; var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentSetup: Codeunit "Agent Setup";
        IsNewAgent: Boolean;
    begin
        IsNewAgent := IsNullGuid(AgentSetupBuffer."User Security ID");

        if AgentSetup.GetChangesMade(AgentSetupBuffer) then begin
            TempRoomPlanningAgentSetup."User Security ID" := AgentSetup.SaveChanges(AgentSetupBuffer);

            if IsNewAgent then
                Agent.SetInstructions(TempRoomPlanningAgentSetup."User Security ID", GetInstructions());
        end;
    end;

    procedure PersistSetupRecord(var TempRoomPlanningAgentSetup: Record "Room Planning Agent Setup" temporary)
    var
        RoomPlanningAgentSetupRecord: Record "Room Planning Agent Setup";
    begin
        if not RoomPlanningAgentSetupRecord.Get(TempRoomPlanningAgentSetup."User Security ID") then begin
            RoomPlanningAgentSetupRecord.Init();
            RoomPlanningAgentSetupRecord."User Security ID" := TempRoomPlanningAgentSetup."User Security ID";
        end;

        if not RoomPlanningAgentSetupRecord.Modify() then
            RoomPlanningAgentSetupRecord.Insert();
    end;

    var
        Agent: Codeunit Agent;
        AccessControlAppId1Tok: Label '63CA2FA4-4F03-4F2B-A480-172FEF340D3F', Locked = true; // System Application
        DependencyAppIdTok: Label '46e6e597-366b-4ed8-b9aa-ddb98540578c', Locked = true; // Chapter 6 - Room Planning
        DefaultProfileTok: Label 'ROOM PLANNING AGENT', Locked = true;
        AgentInitialsLbl: Label 'RPA', MaxLength = 4;
        AgentNameLbl: Label 'ROOM PLANNING AGENT';
        DefaultDisplayNameLbl: Label 'Room Planning Agent';
        AgentSummaryLbl: Label 'Assigns rooms to conference sessions based on expected attendees';
}
