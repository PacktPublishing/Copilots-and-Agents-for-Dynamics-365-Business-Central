controladdIn RAGWebPageAddin
{
    Scripts = 'RAGControlAddin.js';
    StartupScript = 'Startup.js';
    StyleSheets = 'RAGControlAddin.css';
    HorizontalStretch = true;
    VerticalStretch = true;

    procedure Initialize(url: Text);

    event ControlAddInReady();
}
