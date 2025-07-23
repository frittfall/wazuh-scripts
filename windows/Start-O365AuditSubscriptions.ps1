./Import-DotEnvFile -Path ".env"
$clientId = $env:CLIENT_ID
$clientSecret = $env:CLIENT_SECRET
$tenantId = $env:TENANT_ID
$resource = "https://manage.office.com"

$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$tokenRequestBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = $resource
}

$tokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $tokenRequestBody
$accessToken = $tokenResponse.access_token

Invoke-RestMethod -Uri "https://manage.office.com/api/v1.0/${tenantID}/activity/feed/subscriptions/start?contentType=DLP.All" -Headers @{ Authorization = "Bearer $accessToken"; ContentType = "application/json" } -Method Post; $response.value
Invoke-RestMethod -Uri "https://manage.office.com/api/v1.0/${tenantID}/activity/feed/subscriptions/start?contentType=Audit.AzureActiveDirectory" -Headers @{ Authorization = "Bearer $accessToken"; ContentType = "application/json" } -Method Post; $response.value
Invoke-RestMethod -Uri "https://manage.office.com/api/v1.0/${tenantID}/activity/feed/subscriptions/start?contentType=Audit.SharePoint" -Headers @{ Authorization = "Bearer $accessToken"; ContentType = "application/json" } -Method Post; $response.value
Invoke-RestMethod -Uri "https://manage.office.com/api/v1.0/${tenantID}/activity/feed/subscriptions/start?contentType=Audit.Exchange" -Headers @{ Authorization = "Bearer $accessToken"; ContentType = "application/json" } -Method Post; $response.value
Invoke-RestMethod -Uri "https://manage.office.com/api/v1.0/${tenantID}/activity/feed/subscriptions/start?contentType=Audit.General" -Headers @{ Authorization = "Bearer $accessToken"; ContentType = "application/json" } -Method Post; $response.value