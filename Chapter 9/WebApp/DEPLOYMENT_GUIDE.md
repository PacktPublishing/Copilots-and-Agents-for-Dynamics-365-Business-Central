# How to Create the Deployment ZIP Package

## 📋 What You Need

- **Frontend** folder (with `dist` subfolder after building)
- **Backend** folder  
- File compression tool (Windows File Explorer or 7-Zip)

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
   dotnet publish -c Release -o ./publish
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
   cd C:\TEMP\CONTOSOWEBAPP\Backend\publish
   Compress-Archive -Path ./* -DestinationPath ../app-service-deploy.zip -Force
   ```
3. The ZIP file is created in the Backend folder

---

### Step 5: Verify the ZIP File

1. Open File Explorer
2. Navigate to **`C:\TEMP\CONTOSOWEBAPP\`**
3. Look for **`app-service-deploy.zip`** (should be ~24 MB)
4. ✅ You're done!

---

## 📤 Upload to Azure App Service

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
- Make sure .NET 8 SDK is installed: `dotnet --version`
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
