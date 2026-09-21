using System.Agents;

enumextension 50829 "RPA Metadata Provider" extends "Agent Metadata Provider"
{
    value(50829; "Room Planning Agent") // TODO: Rename your agent type, must be unique
    {
        Caption = 'Room Planning Agent'; // TODO: Update caption for your agent type
        Implementation = IAgentFactory = RoomPlanningAgentFactory, IAgentMetadata = RoomPlanningAgentMetadata, IAgentTaskExecution = RoomPlanningAgentTaskExecution;
    }
}