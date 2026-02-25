page 50201 "Event Copilot Setup"
{
    Caption = 'Event Copilot Setup';
    PageType = Card;
    SourceTable = "Event Copilot Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Azure OpenAI';
                field(Endpoint; Rec.Endpoint)
                {
                    ApplicationArea = All;
                    InstructionalText = 'https://[resource].openai.azure.com/';
                }
                field(Deployment; Rec.Deployment)
                {
                    ApplicationArea = All;
                    InstructionalText = 'Enter the deployment name (e.g. gpt-4o).';
                }
                field(SecretKey; SecretKey)
                {
                    ApplicationArea = All;
                    Caption = 'Secret Key';
                    ExtendedDatatype = Masked;
                    trigger OnValidate()
                    begin
                        Rec.SetSecretKeyToIsolatedStorage(SecretKey);
                    end;
                }
            }
        }
    }

    var
        [NonDebuggable]
        SecretKey: Text;

    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SecretKey := Rec.GetSecretKey();
    end;
}
