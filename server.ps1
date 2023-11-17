Import-Module Pode.Web
Import-Module "$($PSScriptRoot)\crontab\CronTab.psd1"
Import-Module "$($PSScriptRoot)\scheduler.psm1"


if ((Test-Path "$($PSScriptRoot)\files\") -eq $false) { New-Item "$($PSScriptRoot)\files\" -ItemType Directory -Force }


Start-PodeServer {
    if ($IsLinux) {
        Add-PodeEndpoint -Address * -Hostname subdomain.domain.com -Port 8080 -Protocol Http # Change the domain accordingly.
    }
    elseif ($IsWindows) {
        Add-PodeEndpoint -Address "localhost" -Port 8080 -Protocol Http # For testing and development purposes. Can be deleted
    }
    Use-PodeWebTemplates -Title 'XXXXXXXX Telegram Platform' -Theme Dark
    Set-PodeWebHomePage -Layouts @(
        New-PodeWebHero -Title 'Welcome to XXXXXXXX Telegram Platform!' -Message "Stats" -Content @(
            New-PodeWebTile -Name 'Messages queued' -ScriptBlock {
                $jsonObject = Get-Content "$($PSScriptRoot)\messages\messages.json" -Raw | ConvertFrom-Json
                $msgCount = ($jsonObject.messages).Count
                if ($msgCount -eq 0) {
                    $color = 'red'
                }
                elseif ($msgCount -gt 0) {
                    $color = 'green'
                }
                $msgCount | Update-PodeWebTile -ID $ElementData.ID -Colour $color
            } `
                -ClickScriptBlock { Move-PodeWebUrl -Url "/pages/Messages_Queue" }
            New-PodeWebTile -Name 'Crond entries' -ScriptBlock {
                $jobs = (Get-CronJob | Where-Object -Property Command -ne "").Count
                if ($jobs -eq 0) {
                    $color = 'blue'
                }
                elseif ($jobs -gt 0 -and $jobs -le 20) {
                    $color = 'green'
                }
                elseif ($jobs -gt 20 -and $jobs -le 100) {
                    $color = 'yellow'
                }
                elseif ($jobs -gt 100) {
                    $color = 'red'
                }
                $jobs | Update-PodeWebTile -ID $ElementData.ID -Colour $color
            } `
                -ClickScriptBlock { Move-PodeWebUrl -Url "/pages/Crond_Inspector" }
            New-PodeWebTile -Name 'Files' -ScriptBlock {
                $files = (Get-ChildItem "$($PSScriptRoot)\files\" -Recurse -File).Count
                if ($files -eq 0) {
                    $color = 'blue'
                }
                elseif ($files -gt 0 -and $files -le 100) {
                    $color = 'green'
                }
                elseif ($files -gt 100 -and $files -le 200) {
                    $color = 'yellow'
                }
                elseif ($files -gt 200) {
                    $color = 'red'
                }
                $files | Update-PodeWebTile -ID $ElementData.ID -Colour $color
            } `
            -ClickScriptBlock { Move-PodeWebUrl -Url "/pages/File_Explorer" }
        )
    )
    Use-PodeWebPages
}