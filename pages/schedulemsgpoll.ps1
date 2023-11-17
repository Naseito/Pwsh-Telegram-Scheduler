Add-PodeWebPage -Name "Schedule Poll" -Icon "chart-box-outline" -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name "Message" -ScriptBlock {
            $date = $WebEvent.Data['SubmissionDate_Date']
            $time = $WebEvent.Data['SubmissionDate_Time']
            $chat = $WebEvent.Data['Chat']
            $question = $WebEvent.Data['Question']
            $isanonymous = if ($null -eq $WebEvent.Data['Anonymous']) { $false }else { $true }
            $ismultiple = if ($null -eq $WebEvent.Data['Multiple']) { $false }else { $true }
            $messageText = $WebEvent.Data['PollOptions']
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
                $newRow = New-Object PsObject -Property @{"day" = $datetime.ToString("yyyy-MM-dd HH:mm"); "type" = "poll"; "content" = $messageText; "chat" = $chat; "id" = $id; "question" = $question; "anonymous" = $isanonymous; "multiple" = $ismultiple }
                $jsonObject.messages += $newRow
                $messages | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
                Show-PodeWebToast -Message "Message created with ID $id" -Duration 10000
            }

            if ($order -eq 0) {
                New-CronJob -Command $crontabcommand -Minute $datetime.Minute -Hour $datetime.Hour -DayOfMonth $datetime.Day -Month $datetime.Month | Out-Null
            }
            Reset-PodeWebPage
        } -Content @(
            New-PodeWebDateTime -Name 'SubmissionDate' -DisplayName "Date and time for the message"
            New-PodeWebCheckbox -Name 'DefaultTimeZone' -Checked -AsSwitch -DisplayName "Default Time zone? (UTC+01:00) Madrid" #Change it accordingly
            New-PodeWebSelect -Name 'TimeZone' -DisplayName "Time Zone" -ScriptBlock { return @(foreach ($timezone in $([System.TimeZoneInfo]::GetSystemTimeZones())) { $timezone.DisplayName }) }
            New-PodeWebSelect -Name 'Chat' -ScriptBlock { return @(foreach ($chat in $(Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json)) { $chat.Name }) }
            New-PodeWebCheckbox -Name 'Anonymous' -AsSwitch -DisplayName "Anonymous poll"
            New-PodeWebCheckbox -Name 'Multiple' -AsSwitch -DisplayName "Multiple Answers"
            New-PodeWebTextbox -Name 'Question'
            New-PodeWebAlert -Value 'Fill all the options in the textbox bellow, separating them with a semicolon ";"' -Type Info
            New-PodeWebTextbox -Name 'PollOptions' -Multiline
        )
    )
}