Add-PodeWebPage -Name 'Crond Inspector' -Icon 'message-text-clock' -ScriptBlock {
    New-PodeWebCodeBlock -Value $(Get-Content "/etc/crontabs/root" -Raw)
}