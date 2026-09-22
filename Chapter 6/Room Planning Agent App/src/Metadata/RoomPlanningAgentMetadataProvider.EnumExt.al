namespace Packt;

using System.Agents;

enumextension 50851 "RPA Metadata Provider" extends "Agent Metadata Provider"
{
    value(50851; "Room Planning Agent")
    {
        Caption = 'Room Planning Agent';
        Implementation = IAgentFactory = RoomPlanningAgentFactory, IAgentMetadata = RoomPlanningAgentMetadata, IAgentTaskExecution = RoomPlanningAgentTaskExecution;
    }
}
