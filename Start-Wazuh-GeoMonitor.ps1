./Import-DotEnvFile -Path ".env"

$TenantId = $env:TENANT_ID
$ClientId = $env:CLIENT_ID
$ClientSecret = $env:CLIENT_SECRET
$SharePointDomain = $env:WAZUH_SHAREPOINT_DOMAIN
$SharePointSite = $env:WAZUH_SHAREPOINT_SITE
$SharePointList = $env:WAZUH_SHAREPOINT_LIST

. ./functions/Get-M365AuthToken.ps1

$AccessToken = Get-M365AuthToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret

. ./functions/Get-SPList.ps1

$exclusionList = Get-SPList -AccessToken $AccessToken -SharePointDomain $SharePointDomain -SharePointSite $SharePointSite -SharePointList $SharePointList
