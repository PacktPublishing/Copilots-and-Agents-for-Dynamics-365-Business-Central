// Startup script for RAG Control Add-in
// Create the main container
if (!document.getElementById('controlAddInContainer')) {
    const container = document.createElement('div');
    container.id = 'controlAddInContainer';
    document.body.appendChild(container);
}

// Signal that the control add-in is ready
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady', null);
