// ----------------------------------------------------------------------------
// Enum 98201 - Session change type
// One entry in the change log per kind of change the organizers make.
// ----------------------------------------------------------------------------
enum 98201 "CE Session Change Type"
{
    Extensible = true;
    Caption = 'Session Change Type';

    value(0; Room) { Caption = 'Room'; }
    value(1; Schedule) { Caption = 'Schedule'; }
    value(2; Speaker) { Caption = 'Speaker'; }
    value(3; Cancelled) { Caption = 'Cancelled'; }
    value(4; Other) { Caption = 'Other'; }
}
