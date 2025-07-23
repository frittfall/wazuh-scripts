./Import-DotEnvFile -Path ".env"
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
$tenantId = $env:TENANT_ID
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
Write-Host "------------------------------------`n"

# 2. Start Subscriptions
$contentTypes = @(
    "DLP.All",
    "Audit.AzureActiveDirectory",
    "Audit.SharePoint",
    "Audit.Exchange",
    "Audit.General"
)

foreach ($contentType in $contentTypes) {
    Write-Host "Attempting to start subscription for: $contentType"
    
    # Execute curlpture all output to $response variable
    $response = curl -s -X POST "https://manage.office.com/api/v1.0/${tenantId}/activity/feed/subscriptions/start?contentType=${contentType}" `
      -H "Authorization: Bearer ${accessToken}" `
      -H "Content-Type: application/json" `
      -H "Content-Length: 0"

    # Check if the response contains the "does not exist" error string
    if ($response -like "*does not exist*") {
        Write-Host "❌ Monitoring is not enabled in Purview. Error: #0001"
        Write-Host "This must be enabled manually in the Microsoft Purview compliance portal before subscriptions can be created."
        # Break the loop since this is a tenant-level issue
        break
    }
    $error_code = ($response | ConvertFrom-Json).error.code
    if ($error_code -contains "AF20024") {
        Write-Host "⚠️ ${contentType} is already activated. Error: #0002"
    }

    else {
        # For a successful response or a different error, display the output
        Write-Host "✅ API Response:"
        Write-Host ($response | ConvertFrom-Json | ConvertTo-Json -Depth 100)
    }
    
}