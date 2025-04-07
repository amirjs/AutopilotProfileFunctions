<#
.SYNOPSIS
This script creates and assigns Autopilot deployment profiles using data from a CSV file.

.DESCRIPTION
The script performs the following actions:
1. Imports the necessary modules for Microsoft Graph API.
2. Connects to Microsoft Graph with the required scopes.
3. Imports Autopilot profile data from a CSV file.
4. Creates Autopilot deployment profiles based on the imported data.
5. Assigns the created profiles to specified groups.

.PARAMETER None
This script does not take any parameters.

.NOTES
Author: Amir Joseph Sayes
For more information, visit amirsayes.co.uk

.EXAMPLE
.\CreateAndAssignAutopilotDeploymentProfile.ps1
This example runs the script to create and assign Autopilot deployment profiles using the data from the "Profiles.csv" file.

#>
# CREDITS
# This script was created by Amir Joseph Sayes.
# For more information, visit amirsayes.co.uk
#>

# Import AutopilotProfileFunctions.ps1 
. "\AutopilotProfileFunctions.ps1"

#check if  the relevant modules are installed and if not install them
$modules = @("Microsoft.Graph.authentication","Microsoft.Graph.Beta.DeviceManagement.Enrollment")
foreach ($module in $modules) {
    if (-not(Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Force -Scope AllUsers
    }
    import-module $module -Force
}

# Connect to MgGraph 
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

# Import the CSV file
$profiles = Import-Csv "Profiles.csv"

foreach ($profile in $profiles) {
    #check if the profile already exists
    $existingProfile = Get-AutopilotDeploymentProfile -ProfileName $profile.DisplayName -ErrorAction SilentlyContinue
    if ($existingProfile) {
        Write-Host "Profile $($profile.DisplayName) already exists. Skipping creation."
        continue
    }
    # Create Autopilot profile
    New-AutopilotDeploymentProfile -DisplayName $profile.DisplayName `
        -DeploymentMode $profile.DeploymentMode `
        -JoinToEntraIDAs $profile.JoinToEntraIDAs `
        -LanguageLocale $profile.LanguageLocale `
        -ProfileType $profile.ProfileType `
        -ApplyDeviceNameTemplate $profile.ApplyDeviceNameTemplate `
        -AllowPreprovisionedDeployment ([bool]::Parse($profile.AllowPreprovisionedDeployment))

    # Assign profile to groups
    Set-AutopilotDeploymentProfileAssignment -ProfileName $profile.DisplayName `
        -IncludedGroupNames $profile.IncludedGroups `
        -ExcludedGroupNames $profile.ExcludedGroups
}

Write-Host "All Autopilot profiles and assignments have been successfully created!"
