param(
  [string]$Email
)

if (-not $Email) {
  Write-Error "User email is required."
  exit 1
}

$organization = $env:ADO_ORG
$pat = $env:ADO_PAT
if (-not $pat) {
  Write-Error "ADO_PAT environment variable is not set."
  exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
$headers = @{ Authorization = "Basic $auth"; "Content-Type" = "application/json" }

$url = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements?api-version=4.1-preview.1&top=1500"

Write-Host "Fetching users from ADO org '$organization'..."
$response = Invoke-RestMethod -Uri $url -Headers $headers

$userFound = $false
$userId = $null

foreach ($userEntry in $response.value) {
  if ($userEntry.user.principalName -and $userEntry.user.principalName.ToLower() -eq $Email.ToLower()) {
    $userFound = $true
    $userId = $userEntry.id
    Write-Host "User '$Email' found, ID: $userId"
    break
  }
}

if (-not $userFound) {
  Write-Host "User '$Email' not found. Nothing to delete."
  return
}

$deleteUrl = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements/$userId?api-version=4.1-preview.1"

try {
  Invoke-RestMethod -Uri $deleteUrl -Method Delete -Headers $headers
  Write-Host "User '$Email' successfully removed from org."
} catch {
  Write-Error "Failed to remove user: $_"
  exit 1
}
