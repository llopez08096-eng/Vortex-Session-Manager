$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $dir 'Launch.vbs'
$icon = Join-Path $dir 'VortexSessionManager.ico'
if (-not (Test-Path $launcher)) { throw 'Launch.vbs is missing.' }
if (-not (Test-Path $icon)) {
    $brand = Join-Path $dir 'brand.png'
    if (-not (Test-Path $brand)) { throw 'brand.png and VortexSessionManager.ico are missing.' }
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap($brand)
    try {
        $handle = $bmp.GetHicon()
        $generated = [System.Drawing.Icon]::FromHandle($handle)
        try {
            $stream = [System.IO.File]::Create($icon)
            try { $generated.Save($stream) } finally { $stream.Dispose() }
        } finally { $generated.Dispose() }
    } finally { $bmp.Dispose() }
}
$shell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('DesktopDirectory')
$targets = @(
    (Join-Path $dir 'Vortex Session Manager.lnk'),
    (Join-Path $desktop 'Vortex Session Manager.lnk')
)
foreach ($path in $targets) {
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = $launcher
    $shortcut.WorkingDirectory = $dir
    $shortcut.IconLocation = $icon + ',0'
    $shortcut.Description = 'Vortex Session Manager'
    $shortcut.Save()
    Write-Host ('Created: ' + $path)
}
Write-Host 'Use the Vortex Session Manager shortcut instead of Launch.bat.'
