Add-PodeWebPage -Name "Schedule Title Daily" -Icon "page-layout-header" -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name "Message" -ScriptBlock {
            $date = $WebEvent.Data['SubmissionDate_Date']
            $time = $WebEvent.Data['SubmissionDate_Time']
            $chat = $WebEvent.Data['Chat']
            $messageText = $WebEvent.Data['Message']
            $datetime = [datetime]::parseexact(($date + " " + $time), "yyyy-MM-dd HH:mm", $null)
            $messagetimezone = $(if ($WebEvent.Data['DefaultTimeZone'] -eq $true) { $([System.TimeZoneInfo]::GetSystemTimeZones() | Where-Object -Property DisplayName -Like "*Madrid*" | Select-Object -ExpandProperty DisplayName) } else { $WebEvent.Data['TimeZone'] }) #Change it accordingly
            $datetime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, [System.TimeZoneInfo]::Local.Id, $($([System.TimeZoneInfo]::GetSystemTimeZones()) | Where-Object -Property DisplayName -eq $messagetimezone | Select-Object -ExpandProperty Id))
            $id = "T" + $datetime.ToString("yyyyMMddHHmm")
            $jsonObject = Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw | ConvertFrom-Json
            if ($jsonObject -eq $null) {
                # Code to handle the case when $jsonObject is null
                $jsonObject = [PSCustomObject]@{
                    messages = @()
                }
            }   
            Copy-Item "$($PSScriptRoot)\..\messages\messages.json" -Destination "$($PSScriptRoot)\..\messages\messagesbck.json" -Force
            $crontabcommand = "/opt/microsoft/powershell/7/pwsh /usr/src/app/sendtgmessage.ps1 -Id `"$id`""
            $newRow = New-Object PsObject -Property @{"day" = $datetime.ToString("yyyy-MM-dd HH:mm"); "type" = "title"; "content" = $messageText; "chat" = $chat; "id" = $id; "daysofweek" = "0-6" }
            $jsonObject.messages += $newRow
            $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
            Show-PodeWebToast -Message "Automated title created with ID $id for chat $chat" -Duration 10000
            New-CronJob -Command $crontabcommand -Minute $datetime.Minute -Hour $datetime.Hour -DayOfWeek "0-6" | Out-Null
            Reset-PodeWebPage
        } -Content @(
            New-PodeWebAlert -Value 'The purpose of this kind of automation is to do a countdown for the group title. Use %% in the message field for automatic replacement of the days left to the date.' -Type Warning 
            New-PodeWebDateTime -Name 'SubmissionDate' -DisplayName "End date and time schedule for the series"
            New-PodeWebCheckbox -Name 'DefaultTimeZone' -Checked -AsSwitch -DisplayName "Default Time zone? (UTC+01:00) Madrid" #Change it accordingly
            New-PodeWebSelect -Name 'TimeZone' -DisplayName "Time Zone" -ScriptBlock { return @(foreach ($timezone in $([System.TimeZoneInfo]::GetSystemTimeZones())) { $timezone.DisplayName }) }
            New-PodeWebSelect -Name 'Chat' -ScriptBlock { return @(foreach ($chat in $(Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json)) { $chat.Name }) }
            New-PodeWebTextbox -Name 'Message'
        )
    )
}