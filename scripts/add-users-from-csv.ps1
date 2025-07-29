param (
    [string]$CsvPath = "$(Build.SourcesDirectory)\users.csv",
    [string]$Organization = "$(ADO_ORG)",
    [string]$Pat = "$(ADO_PAT)"
)

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found at $CsvPath"
    exit 1
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
$headers = @{ Authorization = "Basic $auth"; "Content-Type" = "application/json" }

$users = Import-Csv -Path $CsvPath

foreach ($user in $users) {
    Write-Output $user
    # $emailToAdd = $user.email
    # $licenseType = $user.licensetype

    # Write-Output "Adding user: $emailToAdd with license type: $licenseType"

    # $postUrl = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements?api-version=7.1-preview.1"

    # $body = @{
    #     accessLevel = @{
    #         accountLicenseType = $licenseType
    #     }
    #     user = @{
    #         principalName = $emailToAdd
    #         subjectKind = "user"
    #     }
    # } | ConvertTo-Json -Depth 10

    # try {
    #     $response = Invoke-RestMethod -Uri $postUrl -Method Post -Headers $headers -Body $body
    #     Write-Output "Successfully added: $emailToAdd"
    # } catch {
    #     Write-Error "Failed to add user "
    # }
}
