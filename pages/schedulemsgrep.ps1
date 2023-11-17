Add-PodeWebPage -Name "Schedule Repeated Message" -Icon "calendar-sync" -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name "Message" -ScriptBlock {
            $date = $WebEvent.Data['SubmissionDate_Date']
            $time = $WebEvent.Data['SubmissionDate_Time']
            $chat = $WebEvent.Data['Chat']
            $daysToRepeat = $WebEvent.Data['WeekDays']
            $daysToRepeat = $daysToRepeat.Replace("Sunday", "0")
            $daysToRepeat = $daysToRepeat.Replace("Monday", "1")
            $daysToRepeat = $daysToRepeat.Replace("Tuesday", "2")
            $daysToRepeat = $daysToRepeat.Replace("Wednesday", "3")
            $daysToRepeat = $daysToRepeat.Replace("Thursday", "4")
            $daysToRepeat = $daysToRepeat.Replace("Friday", "5")
            $daysToRepeat = $daysToRepeat.Replace("Saturday", "6")
            $messageText = $WebEvent.Data['Message']
            $datetime = [datetime]::parseexact(($date + " " + $time), "yyyy-MM-dd HH:mm", $null)
            $messagetimezone = $(if ($WebEvent.Data['DefaultTimeZone'] -eq $true) { $([System.TimeZoneInfo]::GetSystemTimeZones() | Where-Object -Property DisplayName -Like "*Madrid*" | Select-Object -ExpandProperty DisplayName) } else { $WebEvent.Data['TimeZone'] }) #Change it accordingly
            $datetime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, [System.TimeZoneInfo]::Local.Id, $($([System.TimeZoneInfo]::GetSystemTimeZones()) | Where-Object -Property DisplayName -eq $messagetimezone | Select-Object -ExpandProperty Id))
            $id = "R" + $datetime.ToString("yyyyMMddHHmm")
            $jsonObject = Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw | ConvertFrom-Json
            if ($jsonObject -eq $null) {
                # Code to handle the case when $jsonObject is null
                $jsonObject = [PSCustomObject]@{
                    messages = @()
                }
            }         
            $crontabcommand = "/opt/microsoft/powershell/7/pwsh /usr/src/app/sendtgmessage.ps1 -Id `"$id`""
            $newRow = New-Object PsObject -Property @{"day" = $datetime.ToString("yyyy-MM-dd HH:mm"); "type" = "repeat"; "content" = $messageText; "chat" = $chat; "id" = $id; "daysofweek" = $daysToRepeat }
            $jsonObject.messages += $newRow
            $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
            Show-PodeWebToast -Message "Repeated Message created with ID $id" -Duration 10000
            New-CronJob -Command $crontabcommand -Minute $datetime.Minute -Hour $datetime.Hour -DayOfWeek $daysToRepeat | Out-Null
            Reset-PodeWebPage
        } -Content @(
            New-PodeWebDateTime -Name 'SubmissionDate' -DisplayName "End date and time schedule for the series"
            New-PodeWebSelect -Name 'WeekDays' -Options 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' -Multiple -DisplayName "Weeks for repeating the message"
            New-PodeWebCheckbox -Name 'DefaultTimeZone' -Checked -AsSwitch -DisplayName "Default Time zone? (UTC+01:00) Madrid" #Change it accordingly
            New-PodeWebSelect -Name 'TimeZone' -DisplayName "Time Zone" -ScriptBlock { return @(foreach ($timezone in $([System.TimeZoneInfo]::GetSystemTimeZones())) { $timezone.DisplayName }) }
            New-PodeWebSelect -Name 'Chat' -ScriptBlock { return @(foreach ($chat in $(Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json)) { $chat.Name }) }
            New-PodeWebTextbox -Name 'Message' -Multiline
        )
    )
}