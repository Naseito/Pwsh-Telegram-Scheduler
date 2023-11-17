Add-PodeWebPage -Name 'Chat Channels' -Icon 'Chat' -ScriptBlock {
    New-PodeWebHeader -Value 'Chat List' -Size 1
    New-PodeWebCard -Content @(
        New-PodeWebTable -Name 'Channels' -SimpleSort -DataColumn "Chat" -ScriptBlock {
            $chats = Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json
            foreach ($chat in $chats) {
                [ordered]@{
                    Chat    = $($chat.name)
                    Id      = "$($chat.chatid)"
                    Actions = @(
                        New-PodeWebButton -Name 'Delete' -Icon 'Delete-Circle' -IconOnly -ScriptBlock {
                            $chats = Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json
                            $chats = $chats | Where-Object -Property name -ne $WebEvent.Data.Value
                            $chats | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\config\channels.json" -Force
                            Show-PodeWebToast -Message "Chat $($WebEvent.Data.Value) removed" -Duration 10000
                            Sync-PodeWebTable -Id $ElementData.Parent.ID
                        }
                    )

                }
            }
        } 
    )
    New-PodeWebHeader -Value 'Add new chat' -Size 1
    New-PodeWebCard -Content @(
        New-PodeWebForm -Name "Channel" -ScriptBlock {
            $chatname = $WebEvent.Data['Chat']
            $chatid = $WebEvent.Data['ChatID']
            $chats = Get-Content "$($PSScriptRoot)\..\config\channels.json" -Raw | ConvertFrom-Json
            $newRow = New-Object PsObject -Property @{"name" = $chatname; "chatid" = $chatid }
            $chats += $newRow
            $chats  | ConvertTo-Json -Depth 10 | Out-File "$($PSScriptRoot)\..\config\channels.json" -Force
            Reset-PodeWebForm -Name "Channel"
            Sync-PodeWebTable -Name "Channels"
        } -Content @(
            New-PodeWebTextbox -Name 'Chat' -DisplayName "Chat Name"
            New-PodeWebTextbox -Name 'ChatID' -DisplayName "Chat ID"
        ) 
    )  
}