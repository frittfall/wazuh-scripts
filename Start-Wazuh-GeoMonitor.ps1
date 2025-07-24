./Import-DotEnvFile -Path ".env"

$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
$tenantId = $env:TENANT_ID

$wazuhSharePointDomain = $env:WAZUH_SHAREPOINT_DOMAIN
$wazuhSharePointSite = $env:WAZUH_SHAREPOINT_SITE
$wazuhSharePointList = $env:WAZUH_SHAREPOINT_LIST

$resource = "https://manage.office.com"

# 1. Get Access Token
Write-Host "Acquiring access token..."
$tokenResponseJson = curl -s -X POST "https://login.microsoftonline.com/$tenantId/oauth2/token" `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "grant_type=client_credentials" `
  -d "client_id=$clientId" `
  -d "client_secret=$clientSecret" `
  -d "resource=$resource"

$accessToken = ($tokenResponseJson | ConvertFrom-Json).access_token

if (-not $accessToken) {
    Write-Host "❌ Failed to acquire access token. Exiting."
    Write-Host "Response: $tokenResponseJson"
    exit
}
Write-Host "✅ Access Token acquired successfully."
Write-Host "--------------------------------------`n"
function Get-ListData {
    $siteURL = "https://graph.microsoft.com/v1.0/sites/${wazuhSharePointDomain}.sharepoint.com/sites/${wazuhSharePointSite}"

    try {
        # Use Invoke-RestMethod for cleaner JSON handling and better proxy control
        $site_response = Invoke-RestMethod -Uri $siteURL -Method Get -Headers @{
            "Authorization" = "Bearer ${accessToken}"
            "Content-Type" = "application/json"
        } -ErrorAction Stop

        # If a proxy is specifically configured and needed, you'd add -Proxy "http://your.proxy.com:port"
        # Or if you need to bypass proxy explicitly for this call:
        # $site_response = Invoke-RestMethod -Uri $siteURL -Method Get -Headers @{ ... } -NoProxy

        Write-Host "Site Response: $($site_response | ConvertTo-Json -Depth 5)"
    }
    catch {
        Write-Host "❌ Error getting list data: $($_.Exception.Message)"
    }
}

Get-ListData