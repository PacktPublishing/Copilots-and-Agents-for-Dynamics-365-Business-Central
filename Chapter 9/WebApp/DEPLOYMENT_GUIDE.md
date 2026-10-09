# How to Create the Deployment ZIP Package

## 📋 What You Need

- **Frontend** folder (with `dist` subfolder after building)
- **Backend** folder  
- **.NET 10 SDK** installed on the build machine (`dotnet --list-sdks`)
- **ASP.NET Core 10 runtime** available on the deployment host
- **Azure OpenAI** chat and embedding deployments supporting the v1 API, plus **Azure AI Search**
- File compression tool (Windows File Explorer or 7-Zip)

The backend uses stable Microsoft Agent Framework packages and the stable OpenAI SDK against Azure OpenAI's `/openai/v1/` API. Keep `AzureOpenAI:Endpoint` configured as the resource root (for example, `https://YOUR_RESOURCE_NAME.openai.azure.com/`); the backend appends the API path. Existing API keys and deployment names remain valid, and embeddings must have 1,536 dimensions to match the search index. Do not add the legacy `Azure.AI.OpenAI` package: version 2.1.0 is not runtime-compatible with the OpenAI SDK required by these Agent Framework packages.

---

## 🚀 Step-by-Step Instructions

### Step 1: Build the Frontend

1. Open **Command Prompt** or **PowerShell**
2. Navigate to the Frontend folder:
   ```
   cd Frontend
   ```
3. Run the build command:
   ```
   npm run build
   ```
4. Wait for it to finish (you'll see "built in X seconds")
5. A **`dist`** folder will be created in Frontend
6. Close the terminal

---

### Step 2: Copy Frontend to Backend

1. Open **File Explorer**
2. Navigate to **`Frontend\dist`** folder
3. Select **all files** inside (Ctrl+A)
4. **Copy** them (Ctrl+C)
5. Navigate to **`Backend\wwwroot`** folder
   - If `wwwroot` folder doesn't exist, create it:
     - Right-click in Backend folder → New → Folder → Name it `wwwroot`
6. **Paste** files inside (Ctrl+V)
7. You should see files like `index.html`, `assets`, `favicon.svg` in `wwwroot`

---

### Step 3: Publish the Backend

1. Open **Command Prompt** or **PowerShell**
2. Navigate to Backend folder:
   ```
   cd Backend
   ```
3. Publish for production:
   ```
   dotnet publish -c Release -o .\publish
   ```
4. Wait for it to finish (2-3 minutes)
5. A **`publish`** folder will be created in Backend
6. Close the terminal

---

### Step 4: Create the ZIP File

**Option A: Using Windows File Explorer (Easy)**

1. Open **File Explorer**
2. Go to **`Backend\publish`** folder
3. Select **all files** inside (Ctrl+A)
4. Right-click → **Send to** → **Compressed (zipped) folder**
5. Name it: **`app-service-deploy.zip`**
6. The ZIP file is created in the `publish` folder
7. **Move** it to the project root (`C:\TEMP\CONTOSOWEBAPP\`)

**Option B: Using PowerShell (Faster)**

1. Open **PowerShell**
2. Run:
   ```powershell
   cd C:\TEMP\CONTOSOWEBAPP
   Compress-Archive -Path .\Backend\publish\* -DestinationPath .\app-service-deploy.zip -Force
   ```
3. The ZIP file is created in the project root, outside the publish folder

---

### Step 5: Verify the ZIP File

1. Open File Explorer
2. Navigate to **`C:\TEMP\CONTOSOWEBAPP\`**
3. Look for **`app-service-deploy.zip`**
4. Open the archive and confirm that `Backend.dll`, `Backend.deps.json`, and `Backend.runtimeconfig.json` are at its root, with `wwwroot\index.html` inside the archive
5. For Windows App Service, also confirm that the published `web.config` is at the archive root
6. Do not include an outer `Backend` or `publish` folder; package size alone does not prove the ZIP is correct

---

## 📤 Upload to Azure App Service

Before uploading this framework-dependent package, configure the App Service runtime stack for .NET 10. Confirm that .NET 10 is available for the selected operating system and hosting environment. For Windows IIS hosting outside App Service, install the .NET 10 Hosting Bundle.

1. Go to **Azure Portal**
2. Click your **App Service**
3. Click **"Deployment Center"** (left sidebar)
4. Click **"Manual deployment"** tab
5. **Drag and drop** `app-service-deploy.zip` into the upload area
   - OR click to browse and select the file
6. Wait 2-3 minutes for deployment
7. Click **"Restart"** when done
8. Visit your app URL

---

## Alternative: ZIP Deployment Through Kudu

Kudu is the deployment and diagnostic site associated with your App Service. Use this method if you prefer deploying through **Advanced Tools**, or if the portal's manual deployment option is not available.

### Before deploying

- Confirm the runtime stack is **.NET 10** and **WebSockets** are enabled for SignalR.
- Configure the Azure OpenAI and Azure AI Search values in App Service environment variables, using names such as `AzureOpenAI__Endpoint` and `AzureAISearch__ApiKey`. Do not put production secrets in the ZIP.
- This ZIP already contains the published backend and built frontend. Leave `SCM_DO_BUILD_DURING_DEPLOYMENT` unset or set it to `false`; no server-side restore or frontend build is needed.
- If deploying to a slot, open **Advanced Tools for that slot** to avoid accidentally deploying to production.

### Windows App Service: Kudu ZIP Push Deploy

1. In **Azure Portal**, open the target App Service or deployment slot.
2. Select **Development Tools > Advanced Tools > Go** and sign in with an account authorized to deploy to the app.
3. In Kudu, select **Tools > Zip Push Deploy**.
   - For a standard App Service, the address typically looks like:
     ```text
     https://<app-name>.scm.azurewebsites.net/ZipDeploy
     ```
   - Use the SCM hostname opened by **Advanced Tools**, especially for slots or apps with a different hostname.
4. Drag **`app-service-deploy.zip`** into the file explorer area on the **ZIP Push Deploy page**.
5. Wait for the page to report **"Deployment successful"**. Check the messages below the file explorer for errors.
   - For deployment history, open `<your-SCM-base-URL>/api/deployments` while signed in and follow the deployment's `log_url` for details.
6. To inspect the deployed files, open **Debug Console > PowerShell** or **CMD** and navigate to:
   ```text
   D:\home\site\wwwroot
   ```
   Confirm that:
   - `Backend.dll`, `Backend.deps.json`, `Backend.runtimeconfig.json`, and `web.config` are directly in this directory.
   - The React entry page is at `D:\home\site\wwwroot\wwwroot\index.html`. The nested `wwwroot` is intentional: the outer directory is App Service's deployment root, and the inner directory contains ASP.NET Core's static files.
7. If necessary, restart the App Service from the portal.
8. Open the application's public URL, not the SCM URL, and verify:
   - The React interface loads.
   - `/api/document/status` returns `"status": "ready"`.
   - PDF upload and chat work with the configured Azure services.

**ZIP Push Deploy is not the same as dragging a ZIP into the ordinary Debug Console.** Debug Console drag-and-drop can upload or extract files, but it is not a substitute for ZIP Deploy's deployment records and cleanup of files left over from an earlier ZIP deployment. Use the dedicated **Zip Push Deploy** page.

### Linux App Service or unavailable ZIP Deploy UI

The browser-based Kudu ZIP Deploy UI is not supported on Linux App Service. Use Azure CLI from your local project-root terminal instead:

```powershell
az login
az webapp deploy --resource-group "<resource-group>" --name "<app-name>" --src-path ".\app-service-deploy.zip" --type zip
```

For a deployment slot, add `--slot "<slot-name>"`. This command uses Kudu's publish API and restarts the app after deployment. The ZIP Deploy REST API (`/api/zipdeploy`) is another option for deployment automation.

For troubleshooting:

- **Kudu access denied:** check deployment permissions and SCM-site access restrictions.
- **App fails to start:** confirm .NET 10 runtime availability, the archive's root layout, and the required Azure configuration. Inspect App Service logs and the Kudu `LogFiles` directory.
- **Frontend is missing:** confirm the archive contains `wwwroot\index.html` and its `assets` folder.
- **Swagger returns 404 in production:** this app enables Swagger only in Development; use `/api/document/status` for a basic production check.

Reference: [Deploy ZIP packages to Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/deploy-zip).

---

## ✅ What's in the ZIP File

- Backend API (all .NET files)
- Frontend React app (in `wwwroot` folder)
- Both run on the same domain
- Ready for Azure App Service

---

## 🆘 Troubleshooting

**Issue: "npm run build" fails**
- Make sure Node.js is installed: `node --version`
- Run `npm install` first in Frontend folder

**Issue: "dotnet publish" fails**
- Make sure .NET 10 SDK is installed: `dotnet --list-sdks`
- Delete `bin` and `obj` folders, try again

**Issue: No `wwwroot` folder in Backend**
- Create it manually: Right-click in Backend → New → Folder → `wwwroot`

**Issue: ZIP file is too small (< 20 MB)**
- Make sure you copied files from `Frontend\dist`
- Make sure `Backend\wwwroot` has the React files

---

## 📝 Common Mistakes to Avoid

❌ Don't zip the entire `Backend` folder - only zip the `publish` folder contents  
❌ Don't forget to copy Frontend/dist to Backend/wwwroot  
❌ Don't skip the `npm run build` step  
❌ Don't close the terminal before the build finishes  

---

**Once the ZIP is created and uploaded to Azure, your app is live!** 🎉
