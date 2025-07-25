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
