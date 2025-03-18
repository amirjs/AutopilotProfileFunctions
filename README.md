Full blog post on [https://amirsayes.co.uk/?p=8536&preview=true&_thumbnail_id=8561](https://amirsayes.co.uk/2025/03/16/automating-autopilot-profile-creation-and-assignments-using-powershell-graph-api-for-intune/)
# Introduction

In large enterprises with a global presence, IT administrators often face the challenge of managing Windows Autopilot deployment profiles across different regions. These deployment profiles often have different device naming conventions, languages, or target Organizational Units (Hybrid Join Deployments), requiring separate Autopilot profiles with unique configuration settings.

This usually requires a lot of manual work when setting up new Windows Autopilot profiles and configurations.

To solve this problem, I developed a set of PowerShell functions that:

✅ Create new Autopilot profiles via Graph API  
✅ Assign them to region-specific dynamic groups  

By leveraging these functions, IT admins can easily generate multiple Autopilot profiles and assign them to the appropriate groups on the fly. Additionally, this process can be fully automated by reading configurations from a CSV file, enabling mass profile creation with minimal effort.

---

## The Challenge: Managing Autopilot Profiles in a Global Organization

In a global enterprise, different regions may follow unique device naming conventions and deployment settings. For example:

| Region          | Device Naming Convention | Deployment Mode | Language (Locale) | Join Type  |
|---------------|----------------------|----------------|-----------------|-----------|
| North America | NA-XXXXX             | User-driven    | en-US           | Hybrid    |
| Germany       | GR-XXXXX             | Self-deploying | de-DE           | AzureAD   |
| Japan         | APAC-XXXXX           | User-driven    | ja-JP           | AzureAD   |
| Brazil        | LATAM-XXXXX          | Self-deploying | pt-BR           | AzureAD   |

Since Autopilot profiles cannot be dynamically assigned to devices based on naming patterns within Intune, IT admins must create multiple deployment profiles and assign them to separate dynamic groups based on device attributes.

Doing this manually is time-consuming and error-prone—this is where automation comes in.

---

## Automating Autopilot Profiles with PowerShell Graph API

Manually configuring Autopilot deployment profiles via Microsoft Intune can be time-consuming, especially when managing multiple profiles for different device types (Windows, HoloLens, etc.), deployment modes (Hybrid, Azure AD Join, Self-deploying, etc.), and language settings.

To automate this process, I created the `New-AutopilotDeploymentProfile` function, which allows admins to define all necessary parameters within PowerShell.

### Creating an Autopilot Profile Using PowerShell

The `New-AutopilotDeploymentProfile` function enables the creation of customized Autopilot deployment profiles by specifying parameters such as:

- **Display name** → Profile name for identification
- **Deployment mode** → User-driven, self-deploying
- **Join type** → Hybrid Azure AD Join or Azure AD Join
- **Language locale** → Default language setting or a specific Locale
- **Device type** → Windows PC or HoloLens

#### Example 1: Create a Hybrid Joined Deployment Profile for Windows PC

```powershell
New-AutopilotDeploymentProfile -DisplayName "Test from Code2" `
    -Description "This is a test profile from code" `
    -JoinToEntraIDAs "Hybrid" `
    -DeploymentMode "UserDriven" `
    -LanguageLocale "en-US" `
    -ProfileType windowsPc `
    -AllowPreprovisionedDeployment $true
```

💡 **What This Does:**

- Creates a Hybrid Azure AD joined Autopilot deployment profile for Windows PCs  
- Configures the language locale as English (US)  
- Enables pre-provisioning (formerly known as white-glove) for faster deployment  

#### Example 2: Create an Azure AD Joined Deployment Profile for HoloLens

```powershell
New-AutopilotDeploymentProfile -DisplayName "Test from Code" `
    -Description "This is a test profile from code" `
    -LanguageLocale "en-US" `
    -ProfileType Hololens `
    -DeploymentMode SelfDeploying `
    -JoinToEntraIDAs azureAD `
    -HideLicenseTerms $false `
    -HidePrivacySettings $false `
    -ApplyDeviceNameTemplate "HOLO%SERIAL%"
```

💡 **What This Does:**

- Creates a Self-Deploying Autopilot profile for HoloLens devices  
- Ensures devices automatically join Azure AD  
- Uses a device naming convention (HOLO%SERIAL%) to match organizational standards  
- Keeps the license terms and privacy settings visible in the Out-of-Box Experience (OOBE)  

#### Example 3: Create an Azure AD Joined Deployment Profile for Windows PCs

```powershell
New-AutopilotDeploymentProfile -DisplayName "AzureAD joined profile" `
    -Description "This is a test profile from code" `
    -LanguageLocale "de-CH" `
    -ProfileType windowsPc `
    -ConvertAllTargetedDevicesToAutopilot $false `
    -DeploymentMode UserDriven `
    -AllowPreprovisionedDeployment $true `
    -JoinToEntraIDAs azureAD
```

---

## Assigning Autopilot Profiles to Dynamic Groups

Once an Autopilot deployment profile is created, it must be assigned to a device group to ensure the correct devices receive the right profile.

To automate this process, I created the `Set-AutopilotDeploymentProfileAssignment` function, which allows admins to:

✅ Assign an Autopilot profile to multiple groups  
✅ Exclude specific groups from receiving the profile  
✅ Automate assignments across regions and deployment types  

#### Example: Assigning an Autopilot Profile to Multiple Groups

```powershell
Set-AutopilotDeploymentProfileAssignment -ProfileName "MyProfile" `
    -IncludedGroupNames "Group1", "Group2" `
    -ExcludedGroupNames "Group3"
```

💡 **What This Does:**

- Assigns the Autopilot profile "MyProfile" to Group1 and Group2  
- Excludes Group3 from receiving this profile  

---

## Scaling Automation: Creating Multiple Profiles from a CSV

For organizations that manage multiple Autopilot profiles, manually running these commands for each profile is inefficient. Instead, you can read all profile configurations from a CSV file and automate bulk creation.

### CSV Example: `Profiles.csv`

```csv
DisplayName,DeploymentMode,JoinToEntraIDAs,LanguageLocale,ProfileType,ApplyDeviceNameTemplate,AllowPreprovisionedDeployment,IncludedGroups,ExcludedGroups
North America Profile,UserDriven,azureAD,en-US,windowsPc,NA-%SERIAL%,TRUE,Autopilot-NA,None
Europe Profile,SelfDeploying,azureAD,en-GB,windowsPc,EU-%SERIAL%,FALSE,Autopilot-EU,TestGroup
APAC Profile,UserDriven,Hybrid,en-US,windowsPc,APAC-%SERIAL%,TRUE,Autopilot-APAC,None
```

### PowerShell Script to Automate Everything

```powershell
# Import AutopilotProfileFunctions.ps1 
. "\AutopilotProfileFunctions.ps1"

#check if  the relevant modules are installed and if not install them
$modules = @("Microsoft.Graph.authentication","Microsoft.Graph.Beta.DeviceManagement.Enrollment")
foreach ($module in $modules) {
    if (-not(Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Force -AllowClobber
    }
    import-module $module -Force
}

# Connect to MgGraph 
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

# Import the CSV file
$profiles = Import-Csv "Profiles.csv"
foreach ($profile in $profiles) {
    New-AutopilotDeploymentProfile -DisplayName $profile.DisplayName `
        -DeploymentMode $profile.DeploymentMode `
        -JoinToEntraIDAs $profile.JoinToEntraIDAs `
        -LanguageLocale $profile.LanguageLocale `
        -ProfileType $profile.ProfileType `
        -ApplyDeviceNameTemplate $profile.ApplyDeviceNameTemplate `
        -AllowPreprovisionedDeployment $profile.AllowPreprovisionedDeployment
}
```

🚀 **Get started today!** Download the script from GitHub and start automating your Autopilot management!
