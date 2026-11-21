@echo off
setlocal EnableDelayedExpansion
title Cursor Changer
mode con cols=78 lines=30 2>nul
color 0B

set "STORE=%APPDATA%\CustomCursors"
if not exist "%STORE%" mkdir "%STORE%" 2>nul

set "SIZE=32"
set "DROPPED="
set "DROPPED_NAME="
if not "%~1"=="" (
    set "DROPPED=%~1"
    set "DROPPED_NAME=%~nx1"
)

:main
cls
echo.
echo   ==========================================================
echo                 CURSOR CHANGER  (.ico / .png / .jpg)
echo   ==========================================================
echo.
if defined DROPPED_NAME echo    File: !DROPPED_NAME!
if defined DROPPED_NAME echo.
echo    [1]  Set my icon to ALL cursors
echo    [2]  Replace ONE cursor
echo    [3]  Reset to Windows defaults
echo    ----------------------------------------------------------
echo    [4]  Cursor size: !SIZE! px
echo    [5]  Open cursors folder
echo    [6]  Open Windows mouse settings
echo    [0]  Exit
echo.
choice /c 1234560 /n /m "   Your choice: "
goto m!errorlevel!

:m1
set "ROLES=Arrow Help AppStarting Wait Crosshair IBeam NWPen No SizeNS SizeWE SizeNWSE SizeNESW SizeAll UpArrow Hand"
set "WHAT=all cursors"
goto apply

:m2
cls
echo.
echo    [1] Arrow   [2] Hand   [3] Text
echo    [4] Wait    [5] Background   [6] Crosshair
echo    [0] Back
echo.
choice /c 1234560 /n /m "   Your choice: "
goto s!errorlevel!

:s1
set "ROLES=Arrow"
set "WHAT=arrow"
goto apply
:s2
set "ROLES=Hand"
set "WHAT=hand"
goto apply
:s3
set "ROLES=IBeam"
set "WHAT=text"
goto apply
:s4
set "ROLES=Wait"
set "WHAT=wait"
goto apply
:s5
set "ROLES=AppStarting"
set "WHAT=background"
goto apply
:s6
set "ROLES=Crosshair"
set "WHAT=crosshair"
goto apply
:s7
goto main

:m3
goto reset

:m4
if "!SIZE!"=="32" (set "SIZE=48") else if "!SIZE!"=="48" (set "SIZE=64") else (set "SIZE=32")
goto main

:m5
start "" explorer "%STORE%"
goto main

:m6
start "" control main.cpl,,1
goto main

:m7
exit /b

:apply
call :getfile
if not defined ICO_IN (
    echo    No file selected.
    ping -n 3 127.0.0.1 >nul
    goto main
)

set "NAME="
for %%A in ("!ICO_IN!") do set "NAME=%%~nA"
if not defined NAME set "NAME=custom"

echo.
echo    Converting: !NAME!
echo.

for %%R in (%ROLES%) do (
    set "CUR_OUT=%STORE%\!NAME!_%%R.cur"
    set "HOT=tl"
    for %%C in (Crosshair IBeam Wait No SizeNS SizeWE SizeNWSE SizeNESW SizeAll) do if "%%R"=="%%C" set "HOT=center"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $hot=$env:HOT; $size=[int]$env:SIZE; if($size -lt 16 -or $size -gt 128){$size=32}; $b=[IO.File]::ReadAllBytes($env:ICO_IN); $isIco=($b.Length -gt 22 -and $b[0] -eq 0 -and $b[1] -eq 0 -and $b[2] -eq 1 -and $b[3] -eq 0); if($isIco){$b[2]=2; $n=[BitConverter]::ToUInt16($b,4); for($i=0;$i -lt $n;$i++){$o=6+16*$i; $w=[int]$b[$o]; if($w -eq 0){$w=256}; $h=[int]$b[$o+1]; if($h -eq 0){$h=256}; if($hot -eq 'center'){$x=[int]($w/2); $y=[int]($h/2)}else{$x=0;$y=0}; $b[$o+4]=$x -band 255; $b[$o+5]=($x -shr 8) -band 255; $b[$o+6]=$y -band 255; $b[$o+7]=($y -shr 8) -band 255}; [IO.File]::WriteAllBytes($env:CUR_OUT,$b)}else{Add-Type -AssemblyName System.Drawing; $img=[System.Drawing.Image]::FromFile($env:ICO_IN); $bmp=New-Object System.Drawing.Bitmap $size,$size,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb); $g=[System.Drawing.Graphics]::FromImage($bmp); $g.InterpolationMode='HighQualityBicubic'; $s=[Math]::Min($size/[double]$img.Width,$size/[double]$img.Height); $dw=[int][Math]::Max(1,[Math]::Round($img.Width*$s)); $dh=[int][Math]::Max(1,[Math]::Round($img.Height*$s)); $g.DrawImage($img,[int](($size-$dw)/2),[int](($size-$dh)/2),$dw,$dh); $g.Dispose(); $img.Dispose(); $ms=New-Object IO.MemoryStream; $bmp.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png); $png=$ms.ToArray(); $ms.Dispose(); $bmp.Dispose(); if($hot -eq 'center'){$hx=[int]($size/2); $hy=[int]($size/2)}else{$hx=0;$hy=0}; $out=New-Object IO.MemoryStream; $wr=New-Object IO.BinaryWriter($out,[Text.Encoding]::UTF8,$true); $wr.Write([uint16]0); $wr.Write([uint16]2); $wr.Write([uint16]1); $wr.Write([byte]$size); $wr.Write([byte]$size); $wr.Write([byte]0); $wr.Write([byte]0); $wr.Write([uint16]$hx); $wr.Write([uint16]$hy); $wr.Write([uint32]$png.Length); $wr.Write([uint32]22); $wr.Write($png); $wr.Flush(); $wr.Dispose(); [IO.File]::WriteAllBytes($env:CUR_OUT,$out.ToArray()); $out.Dispose()}"
    if errorlevel 1 (
        echo    [ERROR] Failed for role %%R
        pause
        goto main
    )
    reg add "HKCU\Control Panel\Cursors" /v %%R /t REG_SZ /d "!CUR_OUT!" /f >nul
)

reg add "HKCU\Control Panel\Cursors" /v "Scheme Source" /t REG_DWORD /d 1 /f >nul
call :refresh
echo    [DONE] Changed: !WHAT!
echo    Saved to: !STORE!
pause
goto main

:reset
reg add "HKCU\Control Panel\Cursors" /v Arrow       /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_arrow.cur"   /f >nul
reg add "HKCU\Control Panel\Cursors" /v Help        /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_helpsel.cur" /f >nul
reg add "HKCU\Control Panel\Cursors" /v AppStarting /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_working.ani" /f >nul
reg add "HKCU\Control Panel\Cursors" /v Wait        /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_busy.ani"    /f >nul
reg add "HKCU\Control Panel\Cursors" /v Crosshair   /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_cross.cur"   /f >nul
reg add "HKCU\Control Panel\Cursors" /v IBeam       /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_text.cur"    /f >nul
reg add "HKCU\Control Panel\Cursors" /v NWPen       /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_pen.cur"     /f >nul
reg add "HKCU\Control Panel\Cursors" /v No          /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_unavail.cur" /f >nul
reg add "HKCU\Control Panel\Cursors" /v SizeNS      /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_ns.cur"      /f >nul
reg add "HKCU\Control Panel\Cursors" /v SizeWE      /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_ew.cur"      /f >nul
reg add "HKCU\Control Panel\Cursors" /v SizeNWSE    /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_nwse.cur"    /f >nul
reg add "HKCU\Control Panel\Cursors" /v SizeNESW    /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_nesw.cur"    /f >nul
reg add "HKCU\Control Panel\Cursors" /v SizeAll     /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_move.cur"    /f >nul
reg add "HKCU\Control Panel\Cursors" /v UpArrow     /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_up.cur"      /f >nul
reg add "HKCU\Control Panel\Cursors" /v Hand        /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_link.cur"    /f >nul
reg add "HKCU\Control Panel\Cursors" /ve /t REG_SZ /d "Windows Default" /f >nul
reg add "HKCU\Control Panel\Cursors" /v "Scheme Source" /t REG_DWORD /d 2 /f >nul
call :refresh
echo    [DONE] Default cursors restored.
pause
goto main

:getfile
set "ICO_IN="
if defined DROPPED if exist "!DROPPED!" set "ICO_IN=!DROPPED!"
if defined ICO_IN exit /b
for /f "usebackq delims=" %%F in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.Form; $f.TopMost=$true; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Filter='Images|*.ico;*.png;*.jpg;*.jpeg;*.bmp;*.gif'; if($d.ShowDialog($f) -eq 'OK'){$d.FileName}"`) do set "ICO_IN=%%F"
exit /b

:refresh
powershell -NoProfile -Command "Add-Type -Namespace W -Name U -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool SystemParametersInfo(uint a,uint b,IntPtr c,uint d);'; [W.U]::SystemParametersInfo(0x57,0,[IntPtr]::Zero,3)|Out-Null" >nul 2>&1
exit /b
