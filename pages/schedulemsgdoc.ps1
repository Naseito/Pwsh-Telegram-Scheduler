Add-PodeWebPage -Name "Schedule Document Message" -Icon "message-bookmark" -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name "Document Message" -ScriptBlock {
            $date = $WebEvent.Data['SubmissionDate_Date']
            $time = $WebEvent.Data['SubmissionDate_Time']
            $chat = $WebEvent.Data['Chat']
            $messageText = $WebEvent.Data['Message']
            $fileOriginalName = $WebEvent.Data['Document']
            $extensionDoc = Split-Path -Path $fileOriginalName -Extension 
            $datetime = [datetime]::parseexact(($date + " " + $time), "yyyy-MM-dd HH:mm", $null)
            $messagetimezone = $(if ($WebEvent.Data['DefaultTimeZone'] -eq $true) { $([System.TimeZoneInfo]::GetSystemTimeZones() | Where-Object -Property DisplayName -Like "*Madrid*" | Select-Object -ExpandProperty DisplayName) } else { $WebEvent.Data['TimeZone'] }) #Change it accordingly
            $datetime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, [System.TimeZoneInfo]::Local.Id, $($([System.TimeZoneInfo]::GetSystemTimeZones()) | Where-Object -Property DisplayName -eq $messagetimezone | Select-Object -ExpandProperty Id))
            $id = $datetime.ToString("yyyyMMddHHmm")
            $jsonObject = Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw | ConvertFrom-Json
            if ($jsonObject -eq $null) {
                # Code to handle the case when $jsonObject is null
                $jsonObject = [PSCustomObject]@{
                    messages = @()
                }
            }   
            $messagesSameId = $jsonObject.messages | Where-Object -Property Id -like "$id-*"
            $order = $messagesSameId.Count
            if ($order -ge 10) {
                Out-PodeWebError -Message "Cant add more than 10 scheduled messages per minute"
            }
            else {
                $crontabcommand = "/opt/microsoft/powershell/7/pwsh /usr/src/app/sendtgmessage.ps1 -Id `"$id`""
                $id = $id + "-" + "$order"
                $filename = "$id" + "$extensionDoc"
                While (Test-Path "$($PSScriptRoot)\..\files\$filename") {
                    $file = Split-Path -Path $filename -LeafBase
                    $filename = $file + "$(Get-Random -Minimum 1 -Maximum 100)" + $extensionDoc
                }
                $newRow = New-Object PsObject -Property @{"day" = $datetime.ToString("yyyy-MM-dd HH:mm"); "type" = "document"; "content" = $messageText; "chat" = $chat; "file" = $filename; "id" = $id }
                $jsonObject.messages += $newRow    
                $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
                if ($order -eq 0) {
                    New-CronJob -Command $crontabcommand -Minute $datetime.Minute -Hour $datetime.Hour -DayOfMonth $datetime.Day -Month $datetime.Month | Out-Null
                }
                Save-PodeRequestFile -Key 'Document' -Path "$($PSScriptRoot)/../files/$filename"
                Show-PodeWebToast -Message "Message created with ID $id" -Duration 10000                 
            }
            Reset-PodeWebForm -Name "Document Message"
        } -Content @(
            New-PodeWebDateTime -Name 'SubmissionDate' -DisplayName "Date and time for the message"
            New-PodeWebCheckbox -Name 'DefaultTimeZone' -Checked -AsSwitch -DisplayName "Default Time zone? (UTC+01:00) Madrid" #Change it accordingly
            New-PodeWebSelect -Name 'TimeZone' -DisplayName "Time Zone" -ScriptBlock { return @(foreach ($timezone in $([System.TimeZoneInfo]::GetSystemTimeZones())) { $timezone.DisplayName }) }
            New-PodeWebSelect -Name 'Chat' -ScriptBlock { return @(foreach ($chat in $(Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json)) { $chat.Name }) }
            New-PodeWebTextbox -Name 'Message'
            New-PodeWebFileUpload -Name "Document" -DisplayName "Select Document" -Accept ".pdf", ".docx"
        )
    )
}