===========================================================================================================
MOBILE APP DEPLOYMENT
===========================================================================================================
# First build the mobile app
flutter build apk --release

# then get the apk from the build folder (name of apk would be something like this app-release.apk)
D:\localRepo_Arjun\reminderFlutter\taskify_app\build\app\outputs\flutter-apk\app-release.apk

===========================================================================================================
WEBSITE DEPLOYMENT
===========================================================================================================
# *First build the web app
flutter build web --release

# *Copy the build to the IIS
Copy-Item -Path "build\web\*" -Destination "C:\inetpub\wwwroot\TaskifyWeb" -Recurse -Force

# *Then set the config file
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <!-- Serve static files directly -->
        <rule name="Flutter Static" stopProcessing="true">
          <match url="^(assets|icons|flutter_bootstrap\.js|main\.dart\.js|favicon\.png|manifest\.json|flutter\.js).*" />
          <action type="Rewrite" url="{R:0}" />
        </rule>
        
        <!-- Route everything else to index.html for SPA routing -->
        <rule name="Flutter SPA" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
          </conditions>
          <action type="Rewrite" url="index.html" />
        </rule>
      </rules>
    </rewrite>
    
    <!-- MIME types -->
    <staticContent>
      <remove fileExtension=".json" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <remove fileExtension=".wasm" />
      <mimeMap fileExtension=".wasm" mimeType="application/wasm" />
    </staticContent>
    
  </system.webServer>
</configuration>

# Then create the application pool and site (set the C:\inetpub\wwwroot\TaskifyWeb as physical path)

# Updating the deployed web app
# 1. Build
cd d:\localRepo_Arjun\reminderFlutter\taskify_app
flutter build web --release
# 2. Copy to IIS (overwrites old files)
Copy-Item -Path "build\web\*" -Destination "C:\inetpub\wwwroot\TaskifyWeb" -Recurse -Force
# 3. Hard refresh browser
# Press Ctrl + Shift + R