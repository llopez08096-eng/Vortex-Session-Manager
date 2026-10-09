Option Explicit
Dim shell, fso, scriptDir, cmd, code
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File " & Chr(34) & scriptDir & "\VortexSessionManager.ps1" & Chr(34)
code = shell.Run(cmd, 0, True)
If code <> 0 Then
  MsgBox "Vortex Session Manager closed with an error. Run Debug.bat to see diagnostic output.", vbExclamation, "Vortex Session Manager"
End If
