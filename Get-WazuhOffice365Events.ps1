./Import-DotEnvFile -Path ".env"
# --- Configuration ---
# Wazuh Indexer IP address or hostname
$wazuhIndexerIP = Read-Host "Enter Wazuh IP Address:"

# Wazuh API credentials
# For better security, consider loading these from a secure source instead of hardcoding.
$username = Read-Host "Please enter your username:"
$password = Read-Host -Prompt "Enter your password:" -AsSecureString
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
# Output file path
$outputFile = ".\data\office365_events.json"

# --- Script ---

# Construct the URI for the search query
$uri = "https://{0}:9200/wazuh-alerts-*/_search" -f $wazuhIndexerIP

# Create the Base64 encoded credentials for Basic Authentication
$pair = "{0}:{1}" -f $username, $password
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

# Set up the authorization header
$headers = @{
    "Authorization" = "Basic {0}" -f $encodedCredentials
}

# Define the query to find specific Office 365 events
$query = @{
    query = @{
        bool = @{
            must = @(
                @{
                    match = @{
                        "rule.groups" = "office365"
                    }
                },
                @{
                    terms = @{
                        "data.office365.Operation" = @("UserLoginFailed", "UserLoggedIn") # Corrected field path
                    }
                }
            )
        }
    }
    sort = @(
        @{
            "@timestamp" = @{
                order = "desc"
            }
        }
    )
    size = 3
}

# Convert the query to a JSON string
$jsonBody = $query | ConvertTo-Json -Depth 10

# Execute the REST API call
try {
    # The -SkipCertificateCheck switch is used to bypass SSL certificate validation.
    # In a production environment, you should use a valid certificate.
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -Body $jsonBody -ContentType "application/json" -SkipCertificateCheck

    # Check if any events were returned
    if ($response.hits.hits) {
        # --- MODIFIED PART ---
        # Extract just the event source data
        $events = $response.hits.hits._source

        # Convert the event objects to a nicely formatted JSON string
        $jsonOutput = $events | ConvertTo-Json -Depth 10

        # Save the JSON string to the specified file
        $jsonOutput | Out-File -FilePath $outputFile -Encoding utf8

        Write-Output "Successfully retrieved and saved $($events.Count) Office 365 events to $outputFile"
        # --- END OF MODIFICATION ---
    } else {
        Write-Output "No Office 365 events found."
    }
}
catch {
    Write-Error "An error occurred while querying the Wazuh Indexer API:"
    Write-Error $_.Exception.Message
}