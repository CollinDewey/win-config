$RegPath = "HKCU:\Software\terascripting"
$RegKey = "UserSetup"
$AppxRegKey = "UserSetupAppx"
$WingetRegKey = "UserSetupWinget"
$UseWinget = $true

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    $xml = @"
    <toast>
      <visual>
        <binding template="ToastGeneric">
            <text>$Title</text>
            <text>$Message</text>
        </binding>
      </visual>
    </toast>
"@

    $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
    $XmlDocument.loadXml($xml)

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier('Windows.SystemToast.DeviceEnrollmentActivity').Show($XmlDocument)
}

if (-not (Test-Path $RegPath)) {
    Show-Notification -Title "User Setup" -Message "Doing first-time setup"
    New-Item -Path $RegPath -Force | Out-Null
}

if ((Get-ItemProperty -Path $RegPath -Name $RegKey -ErrorAction SilentlyContinue).$RegKey -ne $true) {
    # The Edge icon appears after the script starts. Annoying but whatever.
    Start-Sleep -Seconds 15

    # Remove MSEdge Icon
    Remove-Item -Path "$ENV:userprofile\Desktop\Microsoft Edge.lnk" -ErrorAction SilentlyContinue

    # Edge Autolaunch
    Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run\MicrosoftEdgeAutoLaunch_*"

    # Standby
    powercfg /X standby-timeout-ac 0
    powercfg /X monitor-timeout-ac 0

    # Unpin Start Menu Tiles (Windows 10)
    $key = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\*start.tilegrid`$windows.data.curatedtilecollection.tilecollection\Current" -ErrorAction SilentlyContinue
    if ($key) {
        $data = $key.Data[0..25] + ([byte[]](202,50,0,226,44,1,1,0,0))
        Set-ItemProperty -Path $key.PSPath -Name "Data" -Type Binary -Value $data
    }

    # Unpin all apps from taskbar
    (New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ForEach-Object{$_.Verbs() | Where-Object{$_.Name.replace('&','') -match 'Unpin from taskbar'} | ForEach-Object{$_.DoIt()}}

    # Bye OneDrive
    # This will bring up UAC, up to you to accept it or not.
    $OneDrivePath = @('C:\Windows\System32\OneDriveSetup.exe', 'C:\Windows\SysWOW64\OneDriveSetup.exe')
    $OneDrivePath | ForEach-Object {
        If (Test-Path $_) {
            Start-Process $_ -ArgumentList "/uninstall" -Wait
        }
    }

    Set-ItemProperty -Path $RegPath -Name $RegKey -Value $true
}

# Uninstall APPX Packages
if ((Get-ItemProperty -Path $RegPath -Name $AppxRegKey -ErrorAction SilentlyContinue).$AppxRegKey -ne $true) {
    # Give Windows a moment to settle installing them
    Start-Sleep -Seconds 30

    $AppxPackagesToUninstall = @(
        ("AppUp.IntelManagementandSecurityStatus"),
        ("Clipchamp.Clipchamp"),
        ("DolbyLaboratories.DolbyAccess"),
        ("DolbyLaboratories.DolbyDigitalPlusDecoderOEM"),
        ("Microsoft.BingNews"),
        ("Microsoft.BingSearch"),
        ("Microsoft.BingWeather"),
        ("Microsoft.Copilot"),
        ("MicrosoftCorporationII.MicrosoftFamily"),
        ("MicrosoftCorporationII.QuickAssist"),
        ("Microsoft.GamingApp"),
        ("Microsoft.GetHelp"),
        ("Microsoft.Getstarted"),
        ("Microsoft.Microsoft3DViewer"),
        ("Microsoft.MicrosoftOfficeHub"),
        ("Microsoft.MicrosoftSolitaireCollection"),
        ("Microsoft.MicrosoftStickyNotes"),
        ("Microsoft.MixedReality.Portal"),
        ("Microsoft.MSPaint"),
        ("Microsoft.Office.OneNote"),
        ("Microsoft.OfficePushNotificationUtility"),
        ("Microsoft.OutlookForWindows"),
        ("Microsoft.Paint"),
        ("Microsoft.People"),
        ("Microsoft.PowerAutomateDesktop"),
        ("Microsoft.SkypeApp"),
        ("Microsoft.StartExperiencesApp"),
        ("MicrosoftTeams"),
        ("Microsoft.Todos"),
        ("Microsoft.Wallet"),
        ("Microsoft.WindowsAlarms"),
        ("Microsoft.WindowsCamera"),
        ("microsoft.windowscommunicationsapps"),
        ("Microsoft.Windows.Copilot"),
        ("Microsoft.Windows.CrossDevice"),
        ("Microsoft.Windows.DevHome"),
        ("Microsoft.WindowsFeedbackHub"),
        ("Microsoft.WindowsMaps"),
        ("Microsoft.WindowsSoundRecorder"),
        ("Microsoft.Windows.Teams"),
        ("Microsoft.XboxApp"),
        ("Microsoft.XboxGameOverlay"),
        ("Microsoft.XboxGamingOverlay"),
        ("Microsoft.XboxIdentityProvider"),
        ("Microsoft.XboxSpeechToTextOverlay"),
        ("Microsoft.Xbox.TCUI"),
        ("Microsoft.YourPhone"),
        ("Microsoft.ZuneMusic"),
        ("Microsoft.ZuneVideo"),
        ("MSTeams"),
    	("Microsoft.549981C3F5F10") # Cortana
    )

    Get-AppxPackage | Where-Object { $_.Name -in $AppxPackagesToUninstall } | ForEach-Object { $_ | Remove-AppxPackage }

    Set-ItemProperty -Path $RegPath -Name $AppxRegKey -Value $true
    
    # Blindly assume this is last
    Show-Notification -Title "User Setup" -Message "First-time setup complete, please relogin"
}


if ($UseWinget -and (Get-ItemProperty -Path $RegPath -Name $WingetRegKey -ErrorAction SilentlyContinue).$WingetRegKey -ne $true) {
    $WingetPackagesToInstall = @(
        ("Microsoft.VisualStudioCode"),
        ("Microsoft.WindowsTerminal")
    )

    # Make sure winget is available (May take a moment for the task to finish)
    while (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Start-Sleep -Seconds 10
    }

    # Install packages
    foreach ($package in $WingetPackagesToInstall) {
        winget install --id $package --accept-package-agreements --accept-source-agreements --exact --silent
    }

    Set-ItemProperty -Path $RegPath -Name $WingetRegKey -Value $true
}
