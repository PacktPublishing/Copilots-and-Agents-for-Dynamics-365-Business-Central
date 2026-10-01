namespace Packt;

table 50200 "Event Copilot Setup"
{
    Description = 'Azure OpenAI setup for Chapter 3 copilots.';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
        }
        field(2; Endpoint; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Endpoint';
        }
        field(3; Deployment; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Deployment';
        }
        field(4; "Secret Key"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Secret';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    procedure GetEndpoint(): Text[250]
    begin
        exit(Rec.Endpoint);
    end;

    procedure GetDeployment(): Text[250]
    begin
        exit(Rec.Deployment);
    end;

    [NonDebuggable]
    procedure GetSecretKey(): Text
    var
        SecretKey: Text;
    begin
        if IsNullGuid(Rec."Secret Key") then
            exit('');
        if not IsolatedStorage.Get(Rec."Secret Key", DataScope::Module, SecretKey) then
            exit('');
        exit(SecretKey);
    end;

    [NonDebuggable]
    procedure SetSecretKeyToIsolatedStorage(SecretKey: Text)
    var
        NewSecretGuid: Guid;
    begin
        if not IsNullGuid(Rec."Secret Key") then
            if not IsolatedStorage.Delete(Rec."Secret Key", DataScope::Module) then;
        NewSecretGuid := CreateGuid();
        IsolatedStorage.Set(NewSecretGuid, SecretKey, DataScope::Module);
        Rec."Secret Key" := NewSecretGuid;
    end;

    procedure IsConfigured(): Boolean
    begin
        if not Rec.Get() then
            exit(false);
        if Rec.Endpoint = '' then
            exit(false);
        if Rec.Deployment = '' then
            exit(false);
        if IsNullGuid(Rec."Secret Key") then
            exit(false);
        exit(GetSecretKey() <> '');
    end;
}
