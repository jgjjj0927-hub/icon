@echo off
chcp 65001 >nul
setlocal DisableDelayedExpansion
title Смена курсора мыши
mode con cols=78 lines=36
color 0B

rem ============================================================
rem  СМЕНА КУРСОРА МЫШИ ИЗ .ICO / .CUR / PNG / JPG
rem  Запуск: двойной клик. Или перетащите файл на этот .bat
rem  Права администратора не нужны.
rem  ВАЖНО: сохранять файл в кодировке UTF-8 БЕЗ BOM.
rem ============================================================

set "STORE=%APPDATA%\CustomCursors"
if not exist "%STORE%" mkdir "%STORE%"
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
echo                 СМЕНА КУРСОРА МЫШИ  (.ico / .cur / .png / .jpg)
echo   ==========================================================
echo.
if defined DROPPED_NAME echo    Файл для установки: "%DROPPED_NAME%"
if defined DROPPED_NAME echo.
echo    Выберите действие и нажмите цифру:
echo.
echo    [1]  Поставить свою иконку на ВСЕ курсоры     (самый простой вариант)
echo    [2]  Заменить только ОДИН курсор              (стрелка, рука и т.д.)
echo    [3]  Вернуть стандартные курсоры Windows
echo.
echo    ----------------------------------------------------------
echo    [4]  Размер курсора: %SIZE% px                (нажмите, чтобы сменить)
echo    [5]  Открыть папку с созданными курсорами
echo    [6]  Открыть настройки мыши Windows
echo    [0]  Выход
echo.
echo    Подсказка: размер действует для PNG/JPG. Настоящие .ico и .cur
echo    берутся как есть (у .cur правится только точка наведения).
echo.
choice /c 1234560 /n /m "   Ваш выбор: "
goto m%errorlevel%

:m1
set "ROLES=Arrow Help AppStarting Wait Crosshair IBeam NWPen No SizeNS SizeWE SizeNWSE SizeNESW SizeAll UpArrow Hand"
set "WHAT=все курсоры"
goto apply

:m2
cls
echo.
echo   ==========================================================
echo                  КАКОЙ КУРСОР ЗАМЕНИТЬ?
echo   ==========================================================
echo.
echo    [1]  Обычная стрелка
echo    [2]  Рука (когда наводите на ссылку)
echo    [3]  Текстовый курсор (в поле ввода текста)
echo    [4]  Ожидание (когда система занята)
echo    [5]  Фоновая загрузка (стрелка с кружком)
echo    [6]  Перекрестие (точное выделение)
echo.
echo    [0]  Назад в меню
echo.
choice /c 1234560 /n /m "   Ваш выбор: "
goto s%errorlevel%

:s1
set "ROLES=Arrow"
set "WHAT=обычная стрелка"
goto apply
:s2
set "ROLES=Hand"
set "WHAT=рука"
goto apply
:s3
set "ROLES=IBeam"
set "WHAT=текстовый курсор"
goto apply
:s4
set "ROLES=Wait"
set "WHAT=ожидание"
goto apply
:s5
set "ROLES=AppStarting"
set "WHAT=фоновая загрузка"
goto apply
:s6
set "ROLES=Crosshair"
set "WHAT=перекрестие"
goto apply
:s7
goto main

:m3
goto reset

:m4
if "%SIZE%"=="32" (set "SIZE=48") else if "%SIZE%"=="48" (set "SIZE=64") else (set "SIZE=32")
goto main

:m5
start "" explorer "%STORE%"
goto main

:m6
start "" control main.cpl,,1
goto main

:m7
exit /b

rem ------------------------------------------------------------
rem  Установка курсора
rem ------------------------------------------------------------
:apply
call :getfile
if not defined ICO_IN (
    echo.
    echo    Файл не выбран. Возвращаю в меню.
    timeout /t 2 >nul
    goto main
)

for %%A in ("%ICO_IN%") do set "NAME=%%~nA"

rem  Один запуск PowerShell на ВСЕ роли: конвертация + реестр
set "ROLES=%ROLES%"
set "SELF=%~f0"
set "ICO=%ICO_IN%"
set "CUR_DIR=%STORE%"
set "SCHEME_NAME=%NAME%"

echo.
echo    Создаю курсоры из файла: "%NAME%"
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath $env:SELF -Raw -Encoding UTF8) -split ('#PS'+'_START'))[1]"
if errorlevel 1 (
    echo.
    echo    [ОШИБКА] Не удалось преобразовать файл в курсор.
    echo    Реестр не тронут. Попробуйте PNG с прозрачным фоном.
    echo.
    pause
    goto main
)

call :refresh
set "DROPPED="
set "DROPPED_NAME="
echo    ----------------------------------------------------------
echo    [ГОТОВО]  Заменено: %WHAT%
echo    Файлы курсора сохранены в:
echo    "%STORE%"
echo    ----------------------------------------------------------
echo.
echo    Если курсор не поменялся сразу, выйдите из учётной записи
echo    Windows и войдите снова.
echo.
pause
goto main

rem ------------------------------------------------------------
rem  Сброс на стандартные курсоры
rem ------------------------------------------------------------
:reset
reg add "HKCU\Control Panel\Cursors" /v Arrow       /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_arrow.cur"   /f >nul
reg add "HKCU\Control Panel\Cursors" /v Help        /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_helpsel.cur" /f >nul
reg add "HKCU\Control Panel\Cursors" /v AppStarting /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_working.ani" /f >nul
reg add "HKCU\Control Panel\Cursors" /v Wait        /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\cursors\aero_busy.ani"    /f >nul
reg add "HKCU\Control Panel\Cursors" /v Crosshair   /t REG_SZ        /d ""                                        /f >nul
reg add "HKCU\Control Panel\Cursors" /v IBeam       /t REG_SZ        /d ""                                        /f >nul
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
echo.
echo    [ГОТОВО]  Стандартные курсоры Windows возвращены.
echo.
pause
goto main

rem ------------------------------------------------------------
rem  Выбор файла (диалог или перетащенный файл)
rem ------------------------------------------------------------
:getfile
set "ICO_IN="
if defined DROPPED if exist "%DROPPED%" (
    if exist "%DROPPED%\*" (
        echo.
        echo    [ОШИБКА] Перетащена папка, а нужен файл.
        timeout /t 2 >nul
        exit /b
    )
    set "ICO_IN=%DROPPED%"
    exit /b
)
echo.
echo    Открываю окно выбора файла...
for /f "usebackq delims=" %%F in (`powershell -NoProfile -STA -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.Form; $f.TopMost=$true; $d=New-Object System.Windows.Forms.OpenFileDialog; $d.Title='Выберите иконку или картинку для курсора'; $d.InitialDirectory=[Environment]::GetFolderPath('UserProfile')+'\Downloads'; $d.Filter='Иконки и картинки|*.ico;*.cur;*.png;*.jpg;*.jpeg;*.bmp;*.gif|Все файлы|*.*'; if($d.ShowDialog($f) -eq 'OK'){$d.FileName}"`) do set "ICO_IN=%%F"
exit /b

rem ------------------------------------------------------------
rem  Применить курсоры без перезагрузки
rem ------------------------------------------------------------
:refresh
powershell -NoProfile -Command "Add-Type -Namespace W -Name U -MemberDefinition '[DllImport(\"user32.dll\",SetLastError=true)] public static extern bool SystemParametersInfo(uint a,uint b,IntPtr c,uint d);'; [W.U]::SystemParametersInfo(0x57,0,[IntPtr]::Zero,3) | Out-Null"
exit /b

rem #PS_START
$ErrorActionPreference = 'Stop'
$made = New-Object System.Collections.Generic.List[string]
try {
    $roles = $env:ROLES -split ' '
    $size  = [int]$env:SIZE
    if ($size -lt 16 -or $size -gt 128) { $size = 32 }
    $src   = $env:ICO
    $dir   = $env:CUR_DIR
    $name  = $env:SCHEME_NAME
    if (-not (Test-Path -LiteralPath $src)) { throw "Файл не найден" }
    $b = [IO.File]::ReadAllBytes($src)
    if ($b.Length -lt 22) { throw "Файл слишком мал или повреждён" }
    $isCur = ($b[0] -eq 0 -and $b[1] -eq 0 -and $b[2] -eq 2 -and $b[3] -eq 0)
    $isIco = ($b[0] -eq 0 -and $b[1] -eq 0 -and $b[2] -eq 1 -and $b[3] -eq 0)
    $isImg = -not ($isCur -or $isIco)

    $png = $null
    if ($isImg) {
        Add-Type -AssemblyName System.Drawing
        $img = [System.Drawing.Image]::FromFile($src)
        $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.Clear([System.Drawing.Color]::Transparent)
        $s  = [Math]::Min($size / [double]$img.Width, $size / [double]$img.Height)
        $dw = [int][Math]::Max(1, [Math]::Round($img.Width  * $s))
        $dh = [int][Math]::Max(1, [Math]::Round($img.Height * $s))
        $g.DrawImage($img, [int](($size - $dw) / 2), [int](($size - $dh) / 2), $dw, $dh)
        $g.Dispose(); $img.Dispose()
        $ms = New-Object IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $png = $ms.ToArray()
        $ms.Dispose(); $bmp.Dispose()
    }

    $paths = @{}
    foreach ($r in $roles) {
        $center = @('Crosshair','IBeam','Wait','No','SizeNS','SizeWE','SizeNWSE','SizeNESW','SizeAll') -contains $r
        $out = Join-Path $dir ($name + '_' + $r + '.cur')

        if ($isImg) {
            # PNG/JPG/BMP/GIF (в том числе переименованный в .ico): строим .cur
            if ([IO.Path]::GetExtension($src).ToLower() -match '^\.(jpe?g|jfif)$') {
                Write-Host '    Внимание: JPG без прозрачности — курсор будет непрозрачным квадратом. PNG даст лучший результат.'
            }
            $hx = 0
            if ($center) { $hx = [int]($size / 2) }
            $outMs = New-Object IO.MemoryStream
            $wr = New-Object IO.BinaryWriter $outMs
            $wr.Write([uint16]0); $wr.Write([uint16]2); $wr.Write([uint16]1)
            $wr.Write([byte]$size); $wr.Write([byte]$size); $wr.Write([byte]0); $wr.Write([byte]0)
            $wr.Write([uint16]$hx); $wr.Write([uint16]$hx)
            $wr.Write([uint32]$png.Length); $wr.Write([uint32]22)
            $wr.Write($png)
            $wr.Flush()
            [IO.File]::WriteAllBytes($out, $outMs.ToArray())
            $wr.Dispose(); $outMs.Dispose()
        } else {
            # Настоящий .ico или .cur: правим тип и горячую точку
            $data = [byte[]]$b.Clone()
            $data[2] = 2
            $n = [BitConverter]::ToUInt16($data, 4)
            if ($n -lt 1) { throw "В файле нет изображений" }
            for ($i = 0; $i -lt $n; $i++) {
                $o = 6 + 16 * $i
                if ($o + 16 -gt $data.Length) { throw "Файл повреждён" }
                $w = [int]$data[$o];   if ($w -eq 0) { $w = 256 }
                $h = [int]$data[$o+1]; if ($h -eq 0) { $h = 256 }
                if ($center) { $x = [int]($w / 2); $y = [int]($h / 2) } else { $x = 0; $y = 0 }
                $data[$o+4] = $x -band 255; $data[$o+5] = ($x -shr 8) -band 255
                $data[$o+6] = $y -band 255; $data[$o+7] = ($y -shr 8) -band 255
            }
            [IO.File]::WriteAllBytes($out, $data)
        }

        $made.Add($out)
        $paths[$r] = $out
        Write-Host ("    OK   " + $r)
    }

    # Всё сконвертировано — только теперь пишем реестр
    $key = 'HKCU:\Control Panel\Cursors'
    foreach ($r in $roles) {
        Set-ItemProperty -Path $key -Name $r -Value $paths[$r]
    }
    Set-ItemProperty -Path $key -Name '(default)' -Value $name
    Set-ItemProperty -Path $key -Name 'Scheme Source' -Value 1 -Type DWord
    Write-Host ('    Реестр обновлён, схема: ' + $name)
    exit 0
} catch {
    foreach ($f in $made) {
        try { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue } catch {}
    }
    Write-Host ('    Ошибка: ' + $_.Exception.Message)
    exit 1
}
