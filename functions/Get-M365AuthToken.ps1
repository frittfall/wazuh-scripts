function Get-M365AuthToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        [Parameter(Mandatory=$true)]
        [string]$ClientId,
        [Parameter(Mandatory=$true)]
        [string]$ClientSecret
    )

    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $tokenBody = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "https://graph.microsoft.com/.default"
    }

    try {
        Write-Verbose "Requesting Access Token..."
        $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody
        Write-Host "Success: Access Token acquired successfully."
        return $tokenResponse.access_token
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Error "Error: #10001 | Failed to get access token. Server response code: $statusCode"
        # Terminate script with a specific exit code
        exit 10001
    }
}
