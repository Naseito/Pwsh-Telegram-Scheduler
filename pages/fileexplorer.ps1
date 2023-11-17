Add-PodeWebPage -Name 'File Explorer' -Icon 'file-cabinet' -ScriptBlock {
    $files = Get-ChildItem "$($PSScriptRoot)\..\files"
    $filesString = ""
    foreach ($file in $files) {
        $filesString = $file.Name + "`n" + $filesString
    }
    New-PodeWebCodeBlock -Value $filesString

}