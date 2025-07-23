function Import-DotEnvFile {
    param (
        [string]$Path = ".env"
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "'.env' file not found at '$Path'."
        return
    }

    Get-Content $Path | ForEach-Object {
        # Skip empty lines or lines starting with '#' (comments)
        if ([string]::IsNullOrWhiteSpace($_) -or $_.TrimStart().StartsWith('#')) {
            continue
        }

        # Split the line into name and value
        $parts = $_.Split('=', 2)
        if ($parts.Count -eq 2) {
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()

            # Set the environment variable
            Set-Item -Path Env:$name -Value $value
            Write-Host "Loaded environment variable: $name"
        } else {
            Write-Warning "Invalid line in '.env' file: '$_'"
        }
    }
}
Import-DotEnvFile