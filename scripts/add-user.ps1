param(
  [string]$Email,
  [string]$License
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
foreach ($userEntry in $response.value) {
  if ($userEntry.user.principalName -and $userEntry.user.principalName.ToLower() -eq $Email.ToLower()) {
    Write-Host "User '$Email' already exists."
    $userFound = $true
    break
  }
}

if (-not $userFound) {
  Write-Host "User not found. Adding to organization..."

  $body = @{
    accessLevel = @{ accountLicenseType = $License }
    user = @{
      principalName = $Email
      subjectKind = "user"
    }
  } | ConvertTo-Json -Depth 10

  $addUrl = "https://vsaex.dev.azure.com/$organization/_apis/userentitlements?api-version=4.1-preview.1"

  try {
    Invoke-RestMethod -Uri $addUrl -Method Post -Headers $headers -Body $body
    Write-Host "User '$Email' added successfully with license '$License'."
  } catch {
    Write-Error "Failed to add user: $_"
    exit 1
  }
}
