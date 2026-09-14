// ----------------------------------------------------------------------------
// Enum 98101 - Registration status
// ----------------------------------------------------------------------------
enum 98101 "CE Registration Status"
{
    Extensible = true;
    Caption = 'Registration Status';

    value(0; Pending) { Caption = 'Pending'; }
    value(1; Confirmed) { Caption = 'Confirmed'; }
    value(2; Cancelled) { Caption = 'Cancelled'; }
}
