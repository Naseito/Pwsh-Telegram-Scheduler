Add-PodeWebPage -Name 'Json Messages Editor' -Icon 'code-json' -ScriptBlock {
    New-PodeWebCard -Content @(
        New-PodeWebAlert -Value 'If you save the Json while empty, next time that a messages is generated from the website it will add a null entry that you will need to delete manually' -Type Warning 
        New-PodeWebCodeEditor -Name 'Editor' -Language 'json' -Value $(Get-Content "$($PSScriptRoot)\..\messages\messages.json" -Raw) -Upload {
            Copy-Item "$($PSScriptRoot)\..\messages\messages.json" -Destination "$($PSScriptRoot)\..\messages\messagesbck.json" -Force
            $jsonStr = $WebEvent.Data | Select-Object -ExpandProperty Value
            $jsonStr | Out-File "$($PSScriptRoot)\..\messages\messages.json" -Force
            Show-PodeWebToast -Message "Messages Json Saved" -Duration 10000
            Set-MessageSchedule
            Show-PodeWebToast -Message "Crontab refreshed" -Duration 10000
        }
    )

}