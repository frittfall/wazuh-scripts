#requires -Version 5.1

<#
.SYNOPSIS
    A PowerShell script to check a Wazuh alert against an exclusion list in a SharePoint Online list.
.DESCRIPTION
    This script performs the following actions:
    1. Reads a JSON event from standard input (e.g., from Wazuh).
    2. Authenticates to Microsoft Graph API using client credentials.
    3. Fetches a list of excluded users from a specified SharePoint Online list.
    4. Provides a placeholder function to check if an alert should be triggered based on the exclusion list.
.NOTES
    Author: Gemini
    Version: 1.0
    Prerequisites: The following environment variables must be set before running the script:
        - TENANT_ID
        - CLIENT_ID
        - CLIENT_SECRET
        - SHAREPOINT_DOMAIN
        - SHAREPOINT_SITE
        - SHAREPOINT_LIST
#>

# Verbose output can be enabled for debugging by running with the -Verbose switch.
[CmdletBinding()]
param()

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

function Get-SPExclusionList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AccessToken,
        [Parameter(Mandatory=$true)]
        [string]$SharePointDomain,
        [Parameter(Mandatory=$true)]
        [string]$SharePointSite,
        [Parameter(Mandatory=$true)]
        [string]$SharePointList
    )

    $headers = @{
        "Authorization" = "Bearer $AccessToken"
    }

    try {
        # Get Site ID
        $siteUrl = "https://graph.microsoft.com/v1.0/sites/${SharePointDomain}.sharepoint.com:/sites/${SharePointSite}"
        Write-Verbose "Getting Site ID from '$siteUrl'"
        $siteResponse = Invoke-RestMethod -Uri $siteUrl -Headers $headers -Method Get
        $siteId = $siteResponse.id

        # Get List Items
        $listUrl = "https://graph.microsoft.com/v1.0/sites/$siteId/lists/$SharePointList/items?expand=fields"
        Write-Verbose "Getting list items from '$listUrl'"
        $listResponse = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get

        $exclusionList = @()
        
        # Process each item from the list
        foreach ($item in $listResponse.value) {
            $exclusionList += [PSCustomObject]@{
                email   = $item.fields.Email_x0020_address_x0020_for_x0
                country = $item.fields.Provide_x0020_country_x0020_to_x
                expires = $item.fields.Expires_x0020_date
            }
        }
        
        return $exclusionList
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        Write-Error "Error: #10003 | Failed to get SharePoint list. Status Code: $statusCode. Message: $errorMessage"
        exit 10003
    }
}

function Test-ShouldAlert {
    [CmdletBinding()]
    param (
        [string]$EmailAddress,
        [string]$UserObjectId,
        [string]$Country,
        [array]$ExclusionList
    )

    # Placeholder logic. Implement your check here.
    # For now, it just prints the email address if provided.
    if (-not [string]::IsNullOrEmpty($EmailAddress)) {
        Write-Host "Checking alert for email: $EmailAddress from country: $Country"
    }
}



# --- Main Script Execution ---




# 2. Get credentials from environment variables
$TenantId = $env:TENANT_ID
$ClientId = $env:CLIENT_ID
$ClientSecret = $env:CLIENT_SECRET
$SharePointDomain = $env:WAZUH_SHAREPOINT_DOMAIN
$SharePointSite = $env:WAZUH_SHAREPOINT_SITE
$SharePointList = $env:WAZUH_SHAREPOINT_LIST

# Validate that environment variables are set
if (-not ($TenantId -and $ClientId -and $ClientSecret -and $SharePointDomain -and $SharePointSite -and $SharePointList)) {
    Write-Error "Error: #10004 | One or more required environment variables are not set."
    exit 10004
}

# 3. Authenticate and get exclusion list
$accessToken = Get-M365AuthToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$exclusionList = Get-SPExclusionList -AccessToken $accessToken -SharePointDomain $SharePointDomain -SharePointSite $SharePointSite -SharePointList $SharePointList

# 4. (Example) Check if an alert should be triggered based on the Wazuh event
# You would extract the relevant fields from the $event object here.
# For example:
# $userEmail = $event.parameters.alert.data.msft.userPrincipalName
# $country = $event.parameters.alert.data.msft.location.country
# $userObjectId = $event.parameters.alert.data.msft.UserId
# Test-ShouldAlert -EmailAddress $userEmail -UserObjectId $userObjectId -Country $country -ExclusionList $exclusionList

# For demonstration, printing the retrieved list
Write-Host "--- Retrieved Exclusion List ---"
$exclusionList | Format-Table

exit 0