permissionset 50100 CRONUSRAGAdmin
{
    Caption = 'CRONUS Events RAG Admin';
    Assignable = true;
    Permissions = tabledata "CRONUS Events RAG Setup" = RIMD,
        table "CRONUS Events RAG Setup" = X,
        page "CRONUS Events RAG" = X,
        page "CRONUS Events RAG Setup" = X;
}