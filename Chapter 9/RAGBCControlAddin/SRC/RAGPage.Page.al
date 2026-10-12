page 50100 "CRONUS Events RAG"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'CRONUS Events RAG';
    SourceTable = "Integer";

    layout
    {
        area(Content)
        {
            usercontrol(RAGWebPageAddin; RAGWebPageAddin)
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                var
                    RAGSetup: Record "CRONUS Events RAG Setup";
                    WebPageUrl: Text;
                begin
                    if RAGSetup.Get('DEFAULT') then
                        WebPageUrl := RAGSetup."Web Page URL"
                    else
                        WebPageUrl := '';
                    if WebPageUrl <> '' then begin
                        CurrPage.RAGWebPageAddin.Initialize(WebPageUrl);
                    end else begin
                        Message('Please configure the RAG Setup page with a Web Page URL.');
                    end;
                end;
            }
        }
    }

    // actions
    // {
    //     area(Processing)
    //     {
    //         action(OpenInBrowser)
    //         {
    //             ApplicationArea = All;
    //             Caption = 'Open in Browser';
    //             Image = Web;
    //             Promoted = true;
    //             PromotedCategory = Process;

    //             trigger OnAction()
    //             begin
    //                 Hyperlink('https://airagwebapp-fvhydhayhkadd6dh.italynorth-01.azurewebsites.net/index.html');
    //             end;
    //         }
    //     }
    // }
}
