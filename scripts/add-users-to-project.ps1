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
    $licenseType = $user.licensetype
    $projectName = $user.projectname
    $groupType = $user.grouptype

    if (-not $email -or -not $projectName -or -not $groupType) {
        Write-Warning "Skipping entry due to missing fields. Email: $email, Project: $projectName, Group: $groupType"
        continue
    }

    Write-Output "`n=== Processing: $email for project '$projectName' with license '$licenseType' and group '$groupType' ==="

    # Step 1: Get project ID
    $projectListUrl = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.1-preview.4"
    try {
        $projectResponse = Invoke-RestMethod -Uri $projectListUrl -Headers $headers
        $project = $projectResponse.value | Where-Object { $_.name -eq $projectName }

        if ($null -eq $project) {
            Write-Error "Project '$projectName' not found. Skipping user '$email'."
            continue
        }

        $projectId = $project.id
        Write-Output "Found project ID: $projectId"
    } catch {
        Write-Error " Failed to fetch project ID: $_"
        continue
    }

    # Step 2: Add user to org and project
    $postUrl = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements?api-version=7.1-preview.1"

    $body = @{
        accessLevel = @{
            accountLicenseType = $licenseType
            licensingSource    = "account"
        }
        user = @{
            principalName = $email
            subjectKind   = "user"
        }
        projectEntitlements = @(
            @{
                projectRef = @{
                    id = $projectId
                }
                group = @{
                    groupType = $groupType
                }
            }
        )
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri $postUrl -Method Post -Headers $headers -Body $body
        Write-Output "User '$email' added to project '$projectName' with group '$groupType'."
    } catch {
        Write-Error "Failed to add user '$email': $_"
    }
}
