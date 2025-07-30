param (
    [string]$CsvPath,
    [string]$Organization,
    [string]$Pat
)

if (-not $Pat) {
    Write-Error "Missing ADO PAT (Personal Access Token)."
    exit 1
}

if (-not $Organization) {
    Write-Error "Missing Azure DevOps organization."
    exit 1
}

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found at: $CsvPath"
    exit 1
}

# Prepare headers
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
$headers = @{ Authorization = "Basic $auth"; "Content-Type" = "application/json" }

# Read users from CSV
$users = Import-Csv -Path $CsvPath

foreach ($user in $users) {
    $email = $user.email

    if (-not $email) {
        Write-Warning "Skipping empty row."
        continue
    }

    Write-Output "`n=== Attempting to remove user: $email ==="

    # Step 1: Get user entitlement details
    $top = 1500
    $skip = 0
    $url = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements?api-version=4.1-preview.1&skip=$skip&top=$top"

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers
    } catch {
        Write-Error "Failed to call Azure DevOps API: $_"
        continue
    }

    $userEntry = $response.value | Where-Object {
        $_.user.principalName -and $_.user.principalName.ToLower() -eq $email.ToLower()
    }

    if (-not $userEntry) {
        Write-Warning "User '$email' not found in organization."
        continue
    }

    $userId = $userEntry.id

    if (-not $userId) {
        Write-Error "User ID missing for '$email'. Skipping."
        continue
    }

    $deleteUrl = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements/$userId?api-version=4.1-preview.1"

    try {
        Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers
        Write-Output "Successfully deleted user '$email' from organization '$Organization'."
    } catch {
        Write-Error "Failed to delete user '$email': $_"
    }
}
