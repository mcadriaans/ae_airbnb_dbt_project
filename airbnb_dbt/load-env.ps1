Get-Content .env | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $name, $value = $line -split '=', 2
        Set-Item -Path "Env:$($name.Trim())" -Value $value.Trim()
    }
}