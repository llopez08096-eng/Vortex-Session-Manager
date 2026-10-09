$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
public static class WindowTools {
 public class Entry { public IntPtr Handle; public string Title; public string Process; public int Pid; }
 public delegate bool EnumWindowsProc(IntPtr h,IntPtr p);
 [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc cb,IntPtr p);
 [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr h,int cmd);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint id);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,IntPtr x);
 [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a,uint b,bool on);
 [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr h,StringBuilder b,int n);
 [DllImport("user32.dll")] private static extern int GetWindowTextLength(IntPtr h);
 public static List<Entry> Windows() {
   var list=new List<Entry>();
   EnumWindows((h,p)=>{
     if(!IsWindowVisible(h)) return true;
     int n=GetWindowTextLength(h);if(n==0)return true;
     var b=new StringBuilder(n+1);GetWindowText(h,b,b.Capacity);
     var name=b.ToString();if(String.IsNullOrWhiteSpace(name))return true;
     uint pid;GetWindowThreadProcessId(h,out pid);
     string proc="unknown.exe";
     try {var inf=Process.GetProcessById((int)pid);try{proc=inf.MainModule.ModuleName;}catch{proc=inf.ProcessName+".exe";}}catch{}
     list.Add(new Entry{Handle=h,Title=name,Process=proc,Pid=(int)pid});return true;
   },IntPtr.Zero);
   return list;
 }
 public static bool Focus(IntPtr h) {
   if(!IsWindow(h))return false;if(GetForegroundWindow()==h)return true;
   IntPtr prev=GetForegroundWindow();
   uint fg=prev==IntPtr.Zero?0:GetWindowThreadProcessId(prev,IntPtr.Zero);
   uint tgt=GetWindowThreadProcessId(h,IntPtr.Zero),own=GetCurrentThreadId();
   var linked=new List<uint>();
   try {
     foreach(uint t in new uint[]{fg,tgt})
       if(t!=0&&t!=own&&!linked.Contains(t)&&AttachThreadInput(own,t,true))linked.Add(t);
     if(IsIconic(h))ShowWindowAsync(h,9);
     BringWindowToTop(h);SetForegroundWindow(h);
   } finally {foreach(uint t in linked)AttachThreadInput(own,t,false);}
   return GetForegroundWindow()==h;
 }
}
public static class VortexNative {
 [DllImport("shell32.dll",CharSet=CharSet.Unicode)]
 public static extern int SetCurrentProcessExplicitAppUserModelID(string id);
 [DllImport("user32.dll",CharSet=CharSet.Auto)]
 public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
}
'@
[System.Windows.Forms.Application]::EnableVisualStyles()
[void][VortexNative]::SetCurrentProcessExplicitAppUserModelID('Vortex.SessionManager.Desktop')
$bg=[Drawing.Color]::FromArgb(14,10,22)
$panel=[Drawing.Color]::FromArgb(22,16,34)
$panel2=[Drawing.Color]::FromArgb(30,22,46)
$border=[Drawing.Color]::FromArgb(72,52,114)
$accent=[Drawing.Color]::FromArgb(151,71,255)
$accent2=[Drawing.Color]::FromArgb(193,126,255)
$text=[Drawing.Color]::FromArgb(244,240,255)
$muted=[Drawing.Color]::FromArgb(186,176,214)
$buttonDark=[Drawing.Color]::FromArgb(38,28,58)
$success=[Drawing.Color]::FromArgb(60,193,112)
$warn=[Drawing.Color]::FromArgb(232,177,59)
$errorColor=[Drawing.Color]::FromArgb(230,83,109)
$form=New-Object Windows.Forms.Form
$form.Text='Vortex Session Manager'
$form.ClientSize=New-Object Drawing.Size(760,660)
$form.StartPosition='CenterScreen'
$form.BackColor=$bg
$form.ForeColor=$text
$form.FormBorderStyle='FixedSingle'
$form.MaximizeBox=$false
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.AutoScaleMode='Dpi'
$ico=Join-Path $PSScriptRoot 'VortexSessionManager.ico'
$logoForIcon=Join-Path $PSScriptRoot 'brand.png'
if((-not (Test-Path $ico)) -and (Test-Path $logoForIcon)){
 try {
  $bmp=New-Object Drawing.Bitmap($logoForIcon)
  $hIcon=$bmp.GetHicon()
  $createdIcon=[Drawing.Icon]::FromHandle($hIcon)
  $stream=[IO.File]::Create($ico)
  try {$createdIcon.Save($stream)} finally {$stream.Dispose();$createdIcon.Dispose();$bmp.Dispose()}
 } catch { [Windows.Forms.MessageBox]::Show(('Icon generation failed: '+$_.Exception.Message)) | Out-Null }
}
if(Test-Path $ico){$form.Icon=New-Object Drawing.Icon($ico)}
$form.ShowIcon=$true
$form.ShowInTaskbar=$true
$form.Add_Shown({
 if($form.Icon){
  [void][VortexNative]::SendMessage($form.Handle,128,[IntPtr]0,$form.Icon.Handle)
  [void][VortexNative]::SendMessage($form.Handle,128,[IntPtr]1,$form.Icon.Handle)
 }
})
function Label([string]$s,[int]$x,[int]$y,[int]$w,[int]$h,[int]$size=10,[bool]$bold=$false,[Drawing.Color]$color=$text,[object]$parent=$form){
 $c=New-Object Windows.Forms.Label
 $c.Text=$s;$c.Location=New-Object Drawing.Point($x,$y);$c.Size=New-Object Drawing.Size($w,$h)
 $style=if($bold){[Drawing.FontStyle]::Bold}else{[Drawing.FontStyle]::Regular}
 $c.Font=New-Object Drawing.Font('Segoe UI',$size,$style)
 $c.ForeColor=$color;$c.BackColor=[Drawing.Color]::Transparent;$parent.Controls.Add($c);return $c
}
function Panel([int]$x,[int]$y,[int]$w,[int]$h,[Drawing.Color]$color=$panel2,[bool]$edge=$false,[object]$parent=$form){
 $c=New-Object Windows.Forms.Panel
 $c.Location=New-Object Drawing.Point($x,$y);$c.Size=New-Object Drawing.Size($w,$h)
 $c.BackColor=$color
 if($edge){$c.BorderStyle='FixedSingle'}
 $parent.Controls.Add($c);return $c
}
function Button([string]$s,[int]$x,[int]$y,[int]$w,[int]$h,[object]$parent,[bool]$primary=$false){
 $c=New-Object Windows.Forms.Button
 $c.Text=$s;$c.Location=New-Object Drawing.Point($x,$y);$c.Size=New-Object Drawing.Size($w,$h)
 $c.FlatStyle='Flat';$c.Cursor=[Windows.Forms.Cursors]::Hand;$c.ForeColor=$text
 if($primary){$c.BackColor=$accent;$c.FlatAppearance.BorderSize=0}
 else {$c.BackColor=$buttonDark;$c.FlatAppearance.BorderSize=1;$c.FlatAppearance.BorderColor=$border}
 $parent.Controls.Add($c);return $c
}
$brandPath=Join-Path $PSScriptRoot 'brand.png'
function Picture([object]$parent,[int]$x,[int]$y,[int]$w,[int]$h){
 $c=New-Object Windows.Forms.PictureBox
 $c.Location=New-Object Drawing.Point($x,$y)
 $c.Size=New-Object Drawing.Size($w,$h);$c.SizeMode='Zoom'
 if(Test-Path $brandPath){$c.Image=[Drawing.Image]::FromFile($brandPath)}
 $parent.Controls.Add($c);return $c
}
$header=Panel 0 0 760 96 $panel
$brandBox=Picture $header 22 18 58 58
[void](Label 'Vortex Session Manager' 94 18 420 36 18 $true $text $header)
$line=Panel 0 95 760 1 $border
$config=Panel 24 116 712 230 $panel2 $true
[void](Label 'TARGET WINDOW' 18 16 220 20 9 $true $accent2 $config)
$target=New-Object Windows.Forms.ComboBox
$target.DropDownStyle='DropDownList';$target.Location=New-Object Drawing.Point(20,44)
$target.Size=New-Object Drawing.Size(510,30)
$target.BackColor=$buttonDark;$target.ForeColor=$text;$config.Controls.Add($target)
$refresh=Button 'Refresh' 547 43 140 34 $config
$detect=Button 'Capture Active Window' 20 90 210 36 $config
[void](Label 'Find visible windows or capture Vortex after 3 seconds.' 244 98 440 20 9 $false $muted $config)
[void](Label 'SESSION SETTINGS' 18 146 220 20 9 $true $accent2 $config)
$interval=New-Object Windows.Forms.NumericUpDown
$interval.Location=New-Object Drawing.Point(20,174);$interval.Size=New-Object Drawing.Size(120,30)
$interval.Minimum=5;$interval.Maximum=3600;$interval.Value=60
$interval.BackColor=$buttonDark;$interval.ForeColor=$text;$config.Controls.Add($interval)
[void](Label 'seconds between jumps' 150 178 205 24 10 $false $muted $config)
$status=Label 'Ready' 520 175 165 24 11 $true $text $config
$status.TextAlign='MiddleRight'
$actions=Panel 24 362 712 82 $panel2 $true
$start=Button 'Start' 20 20 210 42 $actions $true
$pause=Button 'Pause' 250 20 210 42 $actions
$stop=Button 'Stop' 480 20 210 42 $actions
$pause.Enabled=$false;$stop.Enabled=$false
$countdown=Label 'Next jump: not scheduled' 28 456 320 24 10 $false $muted
$credits=Panel 390 452 346 72 $panel2 $true
$creditsIcon=Picture $credits 14 14 42 42
[void](Label 'CREDITS' 68 10 120 18 9 $true $accent2 $credits)
[void](Label 'Logo by VORTEXCREATIONS' 68 26 265 18 10 $true $text $credits)
[void](Label 'Scripting / GUI By Kits' 68 44 265 18 9 $false $muted $credits)
[void](Label 'ACTIVITY LOG' 28 551 180 18 9 $true $accent2)
$log=New-Object Windows.Forms.TextBox
$log.Location=New-Object Drawing.Point(24,575);$log.Size=New-Object Drawing.Size(712,58)
$log.Multiline=$true;$log.ReadOnly=$true;$log.ScrollBars='Vertical'
$log.BorderStyle='FixedSingle';$log.BackColor=$panel2;$log.ForeColor=$text
$form.Controls.Add($log)
$script:running=$false;$script:paused=$false;$script:busy=$false
$script:targetHandle=[IntPtr]::Zero
$script:next=[DateTime]::MaxValue
$script:captureAt=[DateTime]::MaxValue
$script:capturePending=$false
$script:targetEntries=@()
function Write-Log([string]$message){$log.AppendText(('{0:HH:mm:ss}  {1}' -f (Get-Date),$message)+[Environment]::NewLine)}
function Set-Status([string]$s,[string]$tone='default'){
 $status.Text=$s
 $status.ForeColor=switch($tone){
  'success' {$success}
  'warn' {$warn}
  'error' {$errorColor}
  default {$text}
 }
}
function Get-SelectedTarget{
 if($target.SelectedIndex -lt 0 -or $target.SelectedIndex -ge $script:targetEntries.Count){return $null}
 return $script:targetEntries[$target.SelectedIndex]
}
function Populate-Targets([IntPtr]$prefer=[IntPtr]::Zero){
 $old=Get-SelectedTarget
 $saved=if($prefer -ne [IntPtr]::Zero){$prefer}elseif($old){[IntPtr]$old.Handle}else{[IntPtr]::Zero}
 $entries=@([WindowTools]::Windows()|Where-Object{
  $_.Process -notmatch '^(powershell|pwsh|conhost)(\.exe)?$' -and $_.Title -ne $form.Text
 }|Sort-Object @{Expression={if($_.Process -match '(?i)^Vortex\.exe$'){0}else{1}}},@{Expression={$_.Title}})
 $target.Items.Clear();$script:targetEntries=@();$seen=@{};$selection=-1
 foreach($entry in $entries){
  $processKey=$entry.Pid.ToString()
  if($seen.ContainsKey($processKey) -and $entry.Handle -ne $saved){continue}
  $seen[$processKey]=$true
  $name=($entry.Process+' - '+$entry.Title) -replace '[^\x20-\x7E]',' '
  if($name.Length -gt 88){$name=$name.Substring(0,85)+'...'}
  $rec=[pscustomobject]@{Display=$name;Handle=$entry.Handle;Title=$entry.Title;Process=$entry.Process}
  $script:targetEntries+=,$rec
  [void]$target.Items.Add($name)
  if($entry.Handle -eq $saved){$selection=$script:targetEntries.Count-1}
 }
 if($selection -lt 0){
  for($i=0;$i -lt $script:targetEntries.Count;$i++){
   if($script:targetEntries[$i].Process -match '(?i)^Vortex\.exe$'){$selection=$i;break}
  }
 }
 if($selection -ge 0){$target.SelectedIndex=$selection}
 elseif($target.Items.Count -gt 0){$target.SelectedIndex=0}
 if($target.Items.Count -eq 0){Set-Status 'No windows found' 'warn'}
 else{Set-Status 'Ready'}
 Write-Log "Found $($target.Items.Count) applications."
}
function Stop-Session{
 $script:running=$false;$script:paused=$false
 $start.Enabled=$true;$pause.Enabled=$false;$stop.Enabled=$false
 $refresh.Enabled=$true;$detect.Enabled=$true;$target.Enabled=$true
 $pause.Text='Pause';$countdown.Text='Next jump: not scheduled'
 Set-Status 'Stopped' 'warn'
}
function Do-Jump{
 if(-not [WindowTools]::IsWindow($script:targetHandle)){
  Write-Log 'Target window closed. Session stopped.';Stop-Session;return
 }
 $previous=[WindowTools]::GetForegroundWindow()
 if($previous -eq [IntPtr]::Zero){Write-Log 'No foreground window. Jump skipped.';return}
 try{
  if(-not [WindowTools]::Focus($script:targetHandle)){
   Write-Log 'Windows denied focus switching.';Set-Status 'Focus blocked' 'warn';return
  }
  Start-Sleep -Milliseconds 180
  if([WindowTools]::GetForegroundWindow() -ne $script:targetHandle){
   Write-Log 'Target lost focus.';Set-Status 'Focus lost' 'warn';return
  }
  [Windows.Forms.SendKeys]::SendWait(' ')
  Write-Log 'Jump sent to target window.';Set-Status 'Running' 'success'
 }catch{
  Write-Log ('Jump error: '+$_.Exception.Message);Set-Status 'Jump error' 'error'
 }finally{
  if($previous -ne $script:targetHandle -and [WindowTools]::IsWindow($previous)){
   [void][WindowTools]::Focus($previous)
  }
 }
}
$refresh.Add_Click({try{Populate-Targets}catch{Write-Log ('Refresh error: '+$_.Exception.Message)}})
$detect.Add_Click({
 $script:capturePending=$true;$script:captureAt=(Get-Date).AddSeconds(3)
 $detect.Enabled=$false;Set-Status 'Capture pending' 'warn'
 Write-Log 'Switch to Vortex within 3 seconds.'
})
$start.Add_Click({
 $selected=Get-SelectedTarget
 if(-not $selected){
  [void][Windows.Forms.MessageBox]::Show('Select a target window first.','Vortex Session Manager');return
 }
 $script:targetHandle=[IntPtr]$selected.Handle
 if(-not [WindowTools]::IsWindow($script:targetHandle)){
  Write-Log 'Target no longer exists. Refresh and retry.';Set-Status 'Invalid target' 'error';return
 }
 $script:running=$true;$script:paused=$false
 $script:next=(Get-Date).AddSeconds([double]$interval.Value)
 $start.Enabled=$false;$pause.Enabled=$true;$stop.Enabled=$true
 $refresh.Enabled=$false;$detect.Enabled=$false;$target.Enabled=$false
 $pause.Text='Pause';Set-Status 'Running' 'success'
 Write-Log ('Started: '+$selected.Title+' | '+$selected.Process)
})
$pause.Add_Click({
 $script:paused=-not $script:paused
 if($script:paused){$pause.Text='Resume';Set-Status 'Paused' 'warn';Write-Log 'Session paused.'}
 else{$pause.Text='Pause';$script:next=(Get-Date).AddSeconds([double]$interval.Value)
  Set-Status 'Running' 'success';Write-Log 'Session resumed.'}
})
$stop.Add_Click({Stop-Session;Write-Log 'Session stopped.'})
$timer=New-Object Windows.Forms.Timer
$timer.Interval=200
$timer.Add_Tick({
 if($script:capturePending -and (Get-Date) -ge $script:captureAt){
  $script:capturePending=$false;$detect.Enabled=$true
  $active=[WindowTools]::GetForegroundWindow()
  if($active -ne [IntPtr]::Zero){
   Populate-Targets $active
   $selected=Get-SelectedTarget
   if($selected -and [IntPtr]$selected.Handle -eq $active){
    Write-Log 'Active window captured.';Set-Status 'Target selected' 'success'
   }else{Write-Log 'Capture failed. Try Refresh.';Set-Status 'Capture failed' 'error'}
  }
 }
 if(-not $script:running -or $script:paused -or $script:busy){return}
 $remaining=[Math]::Max(0,[Math]::Ceiling(($script:next-(Get-Date)).TotalSeconds))
 $countdown.Text="Next jump: $remaining seconds"
 if((Get-Date) -ge $script:next){
  $script:busy=$true
  try{Do-Jump}catch{Write-Log ('Unexpected error: '+$_.Exception.Message);Set-Status 'Error' 'error'}
  finally{
   if($script:running){$script:next=(Get-Date).AddSeconds([double]$interval.Value)}
   $script:busy=$false
  }
 }
})
$form.Add_FormClosed({
 $timer.Stop()
 if($brandBox.Image){$brandBox.Image.Dispose()}
 if($creditsIcon.Image){$creditsIcon.Image.Dispose()}
})
try{Populate-Targets}catch{Write-Log ('Startup discovery failed: '+$_.Exception.Message)}
Write-Log 'Ready. Select Vortex.exe and start the session.'
$timer.Start()
[void]$form.ShowDialog()
