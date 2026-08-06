// Control Add-in for displaying RAG web application
var ragWebPageUrl = '';

// Initialize the control add-in with the URL
function Initialize(url) {
    ragWebPageUrl = url;
    if (url && url.length > 0) {
        loadWebPage(url);
    }
}

// Load the web page in an iframe
function loadWebPage(url) {
    // Ensure the container exists
    if (!document.getElementById('controlAddInContainer')) {
        const container = document.createElement('div');
        container.id = 'controlAddInContainer';
        document.body.appendChild(container);
    }
    
    const controlContainer = document.getElementById('controlAddInContainer');
    
    if (controlContainer) {
        // Create iframe element
        const iframe = document.createElement('iframe');
        iframe.id = 'ragWebPageFrame';
        iframe.src = url;
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.border = 'none';
        iframe.allow = 'geolocation; microphone; camera; clipboard-write';
        
        // Clear previous content and add the iframe
        controlContainer.innerHTML = '';
        controlContainer.appendChild(iframe);
    }
}

// Refresh the web page
function RefreshWebPage() {
    const iframe = document.getElementById('ragWebPageFrame');
    if (iframe) {
        iframe.src = ragWebPageUrl;
    }
}

// Get the current URL
function GetCurrentUrl() {
    return ragWebPageUrl;
}
