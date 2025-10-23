$RegPath = "HKLM:\Software\terascripting"
$RegKey = "SystemSetup"
$TZ = "Eastern Standard Time"

if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

if ((Get-ItemProperty -Path $RegPath -Name $RegKey -ErrorAction SilentlyContinue).$RegKey -ne $true) {

    # Remove MSEdge Icon
    Remove-Item -Path "$ENV:public\Desktop\Microsoft Edge.lnk" -ErrorAction SilentlyContinue

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

    Get-AppxPackage -AllUsers | Where-Object { $_.Name -in $AppxPackagesToUninstall } | ForEach-Object { $_ | Remove-AppxPackage }

    Set-TimeZone -Id $TZ
    powercfg -h off

    Set-ItemProperty -Path $RegPath -Name $RegKey -Value $true
}

# As barebones as I want for "general" usage (VS:Code doesn't like SYSTEM)
$WingetPackagesToInstall = @(
	("Mozilla.Firefox"),
	("7zip.7zip")
)

# QEMU Guest Tools
if ((Get-CimInstance Win32_ComputerSystem).Manufacturer -eq "QEMU") {
    $WingetPackagesToInstall += @(
        ("RedHat.VirtIO")
    )
}

# Make sure winget is available (May take a moment for the task to finish)
while (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 10
}

# Fix permissions for authenticated users
$WinGetFolderPath = Get-ChildItem -Path ([IO.Path]::Combine($env:ProgramFiles, 'WindowsApps')) -Filter "Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe" | Sort-Object Name | Select-Object -Last 1

if ($null -ne $WinGetFolderPath) {
    $WinGetFolderPath = $WinGetFolderPath.FullName

    $authenticatedUsersSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-11")
    $authenticatedUsersGroup = $authenticatedUsersSid.Translate([System.Security.Principal.NTAccount])
    $acl = Get-Acl $WinGetFolderPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($authenticatedUsersGroup, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $WinGetFolderPath -AclObject $acl
}

# Install packages
foreach ($package in $WingetPackagesToInstall) {
    winget install --id $package --accept-package-agreements --accept-source-agreements --exact --silent
}

