Import-Module "$($PSScriptRoot)\crontab\CronTab.psd1"

function Set-MessageSchedule {
    $jsonObject = Get-Content "$($PSScriptRoot)\messages\messages.json" -Raw | ConvertFrom-Json
    $currentCronJobs = Get-CronJob | Where-Object -Property Command -ne ""
    $currentCronJobs | Remove-CronJob -Force

    foreach ($message in $jsonObject.messages) {
        if ($message.id -like "R*") {
            $crontabcommand = "/opt/microsoft/powershell/7/pwsh /usr/src/app/sendtgmessage.ps1 -Id `"$($message.id)`""
            $dateEndStr = $message.id.Replace("R", "", 1)
            $dateEnd = [datetime]::parseexact($dateEndStr, "yyyyMMddHHmm", $null)
            New-CronJob -Command $crontabcommand -Minute $dateEnd.Minute -Hour $dateEnd.Hour -DayOfWeek $message.daysofweek | Out-Null
        }
        elseif($message.id -like "T*"){
            $crontabcommand = "/opt/microsoft/powershell/7/pwsh /usr/src/app/sendtgmessage.ps1 -Id `"$($message.id)`""
            $dateEndStr = $message.id.Replace("T", "", 1)
            $dateEnd = [datetime]::parseexact($dateEndStr, "yyyyMMddHHmm", $null)
            New-CronJob -Command $crontabcommand -Minute $dateEnd.Minute -Hour $dateEnd.Hour -DayOfWeek $message.daysofweek | Out-Null
        }
        else {
            $commonId = $message.id.Split("-")[0]
            if ($message.id -eq "$commonId-0") {
                $crontabcommand = "/opt/microsoft/powershell/7/pwsh /usr/src/app/sendtgmessage.ps1 -Id `"$($commonId)`""
                $datetime = [datetime]::parseexact(($message.day), "yyyy-MM-dd HH:mm", $null)
                New-CronJob -Command $crontabcommand -Minute $datetime.Minute -Hour $datetime.Hour -DayOfMonth $datetime.Day -Month $datetime.Month | Out-Null
            }
        }
    }
}

