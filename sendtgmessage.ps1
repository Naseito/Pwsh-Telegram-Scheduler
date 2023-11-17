param(
    [string]$Id
)
if (-not (Get-Module -Name pwshPlaces -ListAvailable)) {
    Install-Module pwshPlaces -Force
}
Import-Module PoshGram
Import-Module pwshPlaces
Import-Module "$($PSScriptRoot)\crontab\CronTab.psd1"
function Remove-Message {
    param (
        [string]$IdDeletion,
        $messagesList
    )
    $messagesList.messages = $messagesList.messages | Where-Object -Property id -NotLike "$IdDeletion-*"
    $messagesList | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\messages\messages.json" -Force
    $cronjobs = Get-CronJob
    $cronjobtodelete = $cronjobs | Where-Object -Property Command -like "*$IdDeletion*"
    $cronjobtodelete | Remove-CronJob -Force
}

function Send-TgMessage {
    param (
        $MessageBlock,
        $configurationBlock,
        $channelBlock
    )
    $telegramBotApiKey = $configurationBlock.telegramapikey
    $channel = $channels | Where-Object -Property Name -eq $MessageBlock.chat | Select-Object -ExpandProperty chatid
    switch ($MessageBlock.type) {
        "normal" {
            Send-TelegramTextMessage -BotToken $telegramBotApiKey -ChatID $channel -Message $MessageBlock.content
        }
        "repeat" {
            Send-TelegramTextMessage -BotToken $telegramBotApiKey -ChatID $channel -Message $MessageBlock.content
        }
        "image" {
            Send-TelegramLocalPhoto -BotToken $telegramBotApiKey -ChatID $channel -Caption $MessageBlock.content -PhotoPath "$($PSScriptRoot)\files\$($MessageBlock.file)"
            Remove-Item "$($PSScriptRoot)\files\$($MessageBlock.file)"
        }   
        "document" {
            Send-TelegramLocalDocument -BotToken $telegramBotApiKey -ChatID $channel -Caption $MessageBlock.content -File "$($PSScriptRoot)\files\$($MessageBlock.file)"
            Remove-Item "$($PSScriptRoot)\files\$($MessageBlock.file)"
        }
        "location" {

            $bingMapsApiKey = $configurationBlock.bingmapsapikey
            $location = Invoke-BingGeoCode -Query $MessageBlock.location -BingMapsAPIKey $bingMapsApiKey -MaxResults 1
            Send-TelegramLocation -BotToken $telegramBotApiKey -ChatID $channel -Latitude $location.latitude -Longitude $location.longitude
            Start-Sleep -Seconds 2
            Send-TelegramTextMessage -BotToken $telegramBotApiKey -ChatID $channel -Message $MessageBlock.content
        }
        "title" {
            $dateEndStr = $MessageBlock.id.Replace("T", "", 1)
            $dateEnd = [datetime]::parseexact($dateEndStr, "yyyyMMddHHmm", $null)
            $now = (Get-Date)
            $daysleft = ($dateEnd - $now).Days
            $title = $MessageBlock.content.Replace("%%", "$daysleft")
            $URL = "https://api.telegram.org/bot$($telegramBotApiKey)/setChatTitle?chat_id=$($channel)&title=$($title)"
            Invoke-RestMethod -Uri $URL
        }
        "poll" {
            $options = $MessageBlock.content.Split(";")
            Send-TelegramPoll -BotToken $telegramBotApiKey -ChatID $channel -Question $MessageBlock.question -Options $options -IsAnonymous $MessageBlock.anonymous -MultipleAnswers $MessageBlock.multiple
        }
        Default {}
    }
}

$jsonObject = Get-Content "$($PSScriptRoot)\messages\messages.json" -Raw | ConvertFrom-Json
$configuration = Get-Content "$($PSScriptRoot)\config\config.json" -Raw | ConvertFrom-Json
$channels = Get-Content "$($PSScriptRoot)\config\channels.json" -Raw | ConvertFrom-Json

# For repetitive messages
if ($Id -like "R*") {
    $messageToSend = $jsonObject.messages | Where-Object -Property Id -eq $Id
    Send-TgMessage -MessageBlock $messageToSend -configurationBlock $configuration -channelBlock $channels
    $dateEndStr = $Id.Replace("R", "", 1)
    $dateEnd = [datetime]::parseexact($dateEndStr, "yyyyMMddHHmm", $null)
    $now = (Get-Date)
    if ($dateEnd.Year -eq $now.Year -and $dateEnd.Month -eq $now.Month -and $dateEnd.Day -eq $now.Day) {
        $jsonObject.messages = $jsonObject.messages | Where-Object -Property id -NotLike $Id
        $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\messages\messages.json" -Force
        $cronjobs = Get-CronJob
        $cronjobtodelete = $cronjobs | Where-Object -Property Command -like "*$Id*"
        $cronjobtodelete | Remove-CronJob -Force
    }
    Start-Sleep -Seconds 3
    exit
}
elseif ($Id -like "T*") {
    $messageToSend = $jsonObject.messages | Where-Object -Property Id -eq $Id
    Send-TgMessage -MessageBlock $messageToSend -configurationBlock $configuration -channelBlock $channels
    $dateEndStr = $Id.Replace("T", "", 1)
    $dateEnd = [datetime]::parseexact($dateEndStr, "yyyyMMddHHmm", $null)
    $now = (Get-Date)
    if ($dateEnd.Year -eq $now.Year -and $dateEnd.Month -eq $now.Month -and $dateEnd.Day -eq $now.Day) {
        $jsonObject.messages = $jsonObject.messages | Where-Object -Property id -NotLike $Id
        $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\messages\messages.json" -Force
        $cronjobs = Get-CronJob
        $cronjobtodelete = $cronjobs | Where-Object -Property Command -like "*$Id*"
        $cronjobtodelete | Remove-CronJob -Force
    }
}
else {
    $checkYear = [datetime]::parseexact(($Id), "yyyyMMddHHmm", $null)
    if ($checkYear.Year -ne $((Get-Date).Year)) {
        exit
    }
}

$messagesToSend = $jsonObject.messages | Where-Object -Property Id -like "$Id-*"
if ($messagesToSend.Count -ge 1) {
    for ($i = 0; $i -lt $messagesToSend.Count; $i++) {
        Send-TgMessage -MessageBlock $($messagesToSend | Where-Object -Property id -eq "$Id-$i") -configurationBlock $configuration -channelBlock $channels
        Start-Sleep -Seconds 3
    }
}

Remove-Message -IdDeletion $Id -messagesList $jsonObject


