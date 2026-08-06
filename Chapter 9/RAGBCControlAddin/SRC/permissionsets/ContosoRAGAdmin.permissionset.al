permissionset 50100 ContosoRAGAdmin
{
    Assignable = true;
    Permissions = tabledata "Contoso Events RAG Setup"=RIMD,
        table "Contoso Events RAG Setup"=X,
        page "Contoso Events RAG"=X,
        page "Contoso Events RAG Setup"=X;
}