./Import-DotEnvFile -Path ".env"
# --- Configuration ---
# Wazuh Indexer IP address or hostname
$wazuhIndexerIP = Read-Host "Enter Wazuh IP Address:"

# Wazuh API credentials
$username = Read-Host "Please enter your username:"
$password = Read-Host -Prompt "Enter your password:" -AsSecureString
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Output file path
$outputFile = ".\data\office365_events.json"
$lastIdFile = ".\data\last_processed_id.txt"

# --- Script ---

# Read the last processed ID if it exists
$lastProcessedId = $null
if (Test-Path $lastIdFile) {
    $lastProcessedId = Get-Content $lastIdFile -Raw
    $lastProcessedId = $lastProcessedId.Trim()
    Write-Output "Last processed ID: $lastProcessedId"
} else {
    Write-Output "No previous ID found. Will fetch latest events."
}

# Construct the URI for the search query
$uri = "https://{0}:9200/wazuh-alerts-*/_search" -f $wazuhIndexerIP

# Create the Base64 encoded credentials for Basic Authentication
$pair = "{0}:{1}" -f $username, $password
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

# Set up the authorization header
$headers = @{
    "Authorization" = "Basic {0}" -f $encodedCredentials
}

# Build the must array
$mustArray = @(
    @{
        match = @{
            "rule.groups" = "office365"
        }
    },
    @{
        terms = @{
            "data.office365.Operation" = @("UserLoginFailed", "UserLoggedIn")
        }
    }
)

# If we have a last processed ID, treat it as a timestamp-based ID
if ($lastProcessedId) {
    # Convert the ID to a comparable timestamp value
    # The ID appears to be a timestamp with microseconds
    try {
        $idAsTimestamp = [double]$lastProcessedId
        Write-Output "Last processed ID as timestamp: $idAsTimestamp"
        
        # Add a range filter using the ID directly as a timestamp comparison
        # Since IDs decrease with time (newer events have higher IDs), we want IDs greater than the last one
        $mustArray += @{
            range = @{
                "_id" = @{
                    gt = $lastProcessedId
                }
            }
        }
        Write-Output "Filtering for events with ID > $lastProcessedId"
    }
    catch {
        Write-Warning "Could not parse last processed ID as timestamp. Proceeding without ID filter."
    }
}

# Define the main query
$query = @{
    query = @{
        bool = @{
            must = $mustArray
            must_not = @(
                @{
                    term = @{
                        "GeoLocation.country_name" = "Norway"
                    }
                }
            )
        }
    }
    sort = @(
        @{
            "id" = @{
                order = "desc"  # Sort by ID descending to get newest events first
            }
        }
    )
    size = 100
}

# Convert the query to a JSON string
$jsonBody = $query | ConvertTo-Json -Depth 10

# Execute the REST API call
try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -Body $jsonBody -ContentType "application/json" -SkipCertificateCheck

    # Check if any events were returned
    if ($response.hits.hits -and $response.hits.hits.Count -gt 0) {
        # Extract the full hits (including _id)
        $hits = $response.hits.hits
        
        # Extract just the event source data for saving
        $events = $hits._source

        # Convert the event objects to a nicely formatted JSON string
        $jsonOutput = $events | ConvertTo-Json -Depth 10

        # Save the JSON string to the specified file
        $jsonOutput | Out-File -FilePath $outputFile -Encoding utf8

        # Save the ID of the most recent event (first in the sorted array since we sort by ID desc)
        $mostRecentId = $hits[0]._id
        $mostRecentId | Out-File -FilePath $lastIdFile -Encoding utf8 -NoNewline

        Write-Output "Successfully retrieved and saved $($events.Count) new Office 365 events to $outputFile"
        Write-Output "Most recent event ID saved: $mostRecentId"
        
        # Optional: Display some info about the events
        Write-Output "`nEvent summary:"
        foreach ($i in 0..([Math]::Min($events.Count - 1, 4))) {
            $event = $events[$i]
            Write-Output "- $($event.'@timestamp'): $($event.data.office365.Operation) by $($event.data.office365.UserId)"
        }
        if ($events.Count -gt 5) {
            Write-Output "... and $($events.Count - 5) more events"
        }
    } else {
        Write-Output "No new Office 365 events found."
    }
}
catch {
    Write-Error "An error occurred while querying the Wazuh Indexer API:"
    Write-Error $_.Exception.Message
}