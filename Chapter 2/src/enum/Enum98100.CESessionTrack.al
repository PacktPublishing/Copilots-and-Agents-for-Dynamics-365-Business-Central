
// ----------------------------------------------------------------------------
// Enum 98100 - Session track
// Values match the four tracks used by the session-browsing-by-track skill.
// ----------------------------------------------------------------------------
enum 98100 "CE Session Track"
{
    Extensible = true;
    Caption = 'Session Track';

    value(0; Development) { Caption = 'Development'; }
    value(1; Business) { Caption = 'Business'; }
    value(2; Consulting) { Caption = 'Consulting'; }
    value(3; Sponsors) { Caption = 'Sponsors'; }
}