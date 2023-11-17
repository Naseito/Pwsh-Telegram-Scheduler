Add-PodeWebPage -Name 'Messages Queue' -Icon 'tray-full' -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebTable -Name 'Messages' -SimpleSort -DataColumn "ID" -ScriptBlock {
            $jsonObject = Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw | ConvertFrom-Json
            foreach ($message in $jsonObject.messages) {
                [ordered]@{
                    ID       = "$($message.id)"
                    Date     = $($message.day)
                    Type     = "$($message.Type)"
                    Content  = "$($message.Content)"
                    File     = $(if ($message.file -ne $null) { $message.file }else { "" });
                    Chat     = $($message.Chat)
                    Location = $(if ($message.location -ne $mull) { $message.location }else { "" });
                    Actions  = @(
                        New-PodeWebButton -Name 'Delete' -Icon 'Delete-Circle' -IconOnly -ScriptBlock {
                            Copy-Item "$($PSScriptRoot)\..\messages\messages.json" -Destination "$($PSScriptRoot)\..\messages\messagesbck.json" -Force
                            $jsonObject = Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw | ConvertFrom-Json
                            $messageToDeleteId = $WebEvent.Data.Value
                            if ($messageToDeleteId -like "R*" -or $messageToDeleteId -like "T*") {
                                $jsonObject.messages = $jsonObject.messages | Where-Object -Property Id -ne $messageToDeleteId
                                $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
                                $cronjobs = Get-CronJob
                                $cronjobtodelete = $cronjobs | Where-Object -Property Command -like "*$messageToDeleteId*"
                                $cronjobtodelete | Remove-CronJob -Force
                                Show-PodeWebToast -Message "Crontab for repetitive schedule with ID $messageToDeleteId has been removed" -Duration 10000
                                Show-PodeWebToast -Message "Entry with ID $messageToDeleteId has been removed" -Duration 10000
                                Sync-PodeWebTable -Id $ElementData.Parent.ID
                            }
                            else {
                                $filename = $jsonObject.messages | Where-Object -Property id -eq $messageToDeleteId | Select-Object -ExpandProperty file
                                if ($null -ne $filename -and $(Test-Path "$($PSScriptRoot)\..\files\$filename") -eq $true) {
                                    Remove-Item "$($PSScriptRoot)\..\files\$filename"
                                    Show-PodeWebToast -Message "File \files\$filename has been removed" -Duration 10000
                                }
                                $datemessage = $jsonObject.messages | Where-Object -Property Id -eq $messageToDeleteId | Select-Object -ExpandProperty day 
                                $commonId = $messageToDeleteId.Split("-")[0]
                                $jsonObject.messages = $jsonObject.messages | Where-Object -Property Id -ne $messageToDeleteId
                                $messagesSameId = $jsonObject.messages | Where-Object -Property Id -like "$commonId-*"
                                if ($messagesSameId.Count -gt 0) {
                                    $newIndexes = @()
                                    $indexes = @()
                                    $count = -1
                                    foreach ($messageSameId in $messagesSameId) {                                  
                                        $index = [int]($messageSameId.id.Split("-")[1])
                                        $indexes += $index
                                        $count = $count + 1
                                        $newIndexes += $count
                                    }
                                    for ($i = 0; $i -lt $indexes.Length; $i++) {
                                        for ($j = 0; $j -lt $messages.Count; $j++) {
                                            if ($jsonObject.messages[$j].Id -eq $($messageToDeleteId + "-" + $indexes[$i].ToString())) {
                                                $jsonObject.messages[$j].Id = $($messageToDeleteId + "-" + $newIndexes[$i].ToString())
                                            }
                                        }
                                    }
                                }
                                $jsonObject | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
                                $jsonObject = Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw | ConvertFrom-Json
                                if ($messagesSameId.Count -eq 0) {
                                    $cronjobs = Get-CronJob
                                    $cronjobtodelete = $cronjobs | Where-Object -Property Command -Like "*$commonId*"
                                    $cronjobtodelete | Remove-CronJob -Force
                                    Show-PodeWebToast -Message "Crontab for date $datemessage has been removed" -Duration 10000
                                }
                                Show-PodeWebToast -Message "Message with ID $messageToDeleteId has been removed" -Duration 10000
                                Sync-PodeWebTable -Id $ElementData.Parent.ID
                            }
                            
                            
                        }
                    )

                }
            }
        } 
    )
}