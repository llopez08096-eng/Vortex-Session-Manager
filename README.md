# Vortex Session Manager

A Windows PowerShell desktop utility with a black-and-purple interface for selecting an application window and running an interval-based jump action.

## Features

- Detect and select open application windows, including `Vortex.exe`
- Adjustable jump interval
- Start, pause/resume, and stop controls
- Attempts to focus the target, send Space, and restore the previous window
- Custom Vortex logo and launcher shortcut
- Session activity log

## Repository status

**Repository status:** `VortexSessionManager.ps1` is now committed. The custom `brand.png` and `VortexSessionManager.ico` image assets still need to be uploaded. Until then, the app can launch without its Vortex images, but the branded shortcut creator will require the ICO file.

## Running on Windows

1. Download the repository as a ZIP and extract it to a permanent location.
2. Double-click `Launch.bat`.
3. Select `Vortex.exe` (or capture the active window), choose an interval, and click Start.
4. Optional: run `Create Shortcut.bat` for a desktop shortcut using the included icon.

Requires Windows PowerShell 5.1 and .NET Framework Windows Forms.

### Troubleshooting

If the launcher exits unexpectedly, run `Debug.bat` to display errors. Windows may refuse focus switching; games may not accept synthetic input. The application has not been verified across all Windows configurations.

## Credits

- **Logo by VORTEXCREATIONS**
- **Scripting / GUI By Kits**

## Licensing

No open-source license has been selected. All rights are reserved by their respective owners unless a license is added. The Custom Vortex Logo branding is credited to VORTEXCREATIONS and should not be reused without permission.
