
function New-AutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Creates a new Windows Autopilot deployment profile.

    .DESCRIPTION
    The New-AutopilotDeploymentProfile function creates a new Windows Autopilot deployment profile with specified parameters. 
    It validates the input parameters based on the profile type and deployment mode, constructs the profile parameters, 
    and creates the deployment profile using the Microsoft Graph API.

    .PARAMETER ProfileType
    Specifies the type of profile. Valid values are "windowsPc" and "Hololens".

    .PARAMETER DisplayName
    Specifies the display name of the deployment profile.

    .PARAMETER Description
    Specifies the description of the deployment profile.

    .PARAMETER ConvertAllTargetedDevicesToAutopilot
    Indicates whether to convert all targeted devices to Autopilot. Default is $false.

    .PARAMETER DeploymentMode
    Specifies the deployment mode. Valid values are "SelfDeploying" and "UserDriven". Default is "UserDriven".

    .PARAMETER JoinToEntraIDAs
    Specifies the type of join to Entra ID. Valid values are "hybrid" and "azureAD".

    .PARAMETER SkipADConnectivityCheck
    Indicates whether to skip the Active Directory connectivity check. Default is $false.

    .PARAMETER HideLicenseTerms
    Indicates whether to hide the license terms. Default is $true.

    .PARAMETER HidePrivacySettings
    Indicates whether to hide the privacy settings. Default is $true.

    .PARAMETER HideChangeAccountOptions
    Indicates whether to hide the change account options. Default is $true.

    .PARAMETER UserType
    Specifies the user type. valid values are "standard" or "administrator". Default is "standard".

    .PARAMETER AllowPreprovisionedDeployment
    Indicates whether to allow pre-provisioned deployment. Default is $false.

    .PARAMETER LanguageLocale
    Specifies the language locale. This parameter is mandatory.

    .PARAMETER AutomaticallyConfigureKeyboard
    Indicates whether to automatically configure the keyboard. Default is $true.

    .PARAMETER ApplyDeviceNameTemplate
    Specifies the device name template.
    Create a unique name for your devices. Names must be 15 characters or less, and can contain letters (a-z, A-Z), numbers (0-9), and hyphens. Names must not contain only numbers. Names cannot include a blank space. Use the %SERIAL% macro to add a hardware-specific serial number. Alternatively, use the %RAND:x% macro to add a random string of numbers, where x equals the number of digits to add.

    .EXAMPLE
    New-AutopilotDeploymentProfile -DisplayName "Test from Code2" -Description "This is a test profile from code" -JoinToEntraIDAs "Hybrid" -DeploymentMode "UserDriven" -LanguageLocale "en-US" -ProfileType windowsPc -AllowPreprovisionedDeployment $true
    Creates a new Windows Autopilot Hybrid joined deployment profile for Windows PC with the specified display name and language locale

    .EXAMPLE
    New-AutopilotDeploymentProfile -DisplayName "Test from Code" -Description "This is a test profile from code" -LanguageLocale "en-US" -ProfileType Hololens -DeploymentMode SelfDeploying -JoinToEntraIDAs azureAD -HideLicenseTerms $false -HidePrivacySettings $false -ApplyDeviceNameTemplate "HOLO%SERIAL%"
    Creates a new Autopilot AAD joined deployment profile for HoloLens with specified name template

    .EXAMPLE
    New-AutopilotDeploymentProfile -DisplayName "AzureAD joined profile" -Description "This is a test profile from code" -LanguageLocale "de-CH" -ProfileType windowsPc -ConvertAllTargetedDevicesToAutopilot $false -DeploymentMode UserDriven -AllowPreprovisionedDeployment $true -JoinToEntraIDAs azureAD
    Creates a new Autopilot AAD joined deployment profile for Windows PC 

    .NOTES
    # CREDITS
    # This script was created by Amir Joseph Sayes.
    # For more information, visit amirsayes.co.uk

    #>
    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory = $true)]
        [ValidateSet("windowsPc","Hololens")]
        [string]$ProfileType,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [bool]$ConvertAllTargetedDevicesToAutopilot = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("SelfDeploying","UserDriven")]
        [string]$DeploymentMode = "UserDriven",

        [Parameter(Mandatory = $false)]
        [ValidateSet("hybrid", "azureAD")]        
        [string]$JoinToEntraIDAs,        

        [Parameter(Mandatory = $false)]
        [bool]$SkipADConnectivityCheck = $false,  
        
        [Parameter(Mandatory = $false)]
        [bool]$HideLicenseTerms = $true,

        [Parameter(Mandatory = $false)]
        [bool]$HidePrivacySettings = $true,  
        
        [Parameter(Mandatory = $false)]        
        [bool]$HideChangeAccountOptions = $true,    

        [Parameter(Mandatory = $false)]             
        [ValidateSet("standard", "administrator")]      
        [string]$UserType = "standard",

        [Parameter(Mandatory = $false)]
        [bool]$AllowPreprovisionedDeployment = $false,

        [Parameter(Mandatory = $true)]        
        [string]$LanguageLocale,                                                                   

        [Parameter(Mandatory = $false)]
        [bool]$AutomaticallyConfigureKeyboard = $true,

        [Parameter(Mandatory = $false)]
        [string]$ApplyDeviceNameTemplate
    )     

    # Validate conditions for Hololens
    if ($ProfileType -eq "Hololens") {
        if ($DeploymentMode -ne "SelfDeploying") {
            throw "Invalid DeploymentMode specified for ProfileType 'Hololens'. DeploymentMode must be 'SelfDeploying'."
        }
        if ($JoinToEntraIDAs -ne "azureAD") {
            throw "Invalid JoinToEntraIDAs specified for ProfileType 'Hololens'. JoinToEntraIDAs must be 'azureAD'."
        }
        if ($HideLicenseTerms -ne $false) {
            throw "Invalid HideLicenseTerms specified for ProfileType 'Hololens'. HideLicenseTerms must be 'false'."
        }
        if ($HidePrivacySettings -ne $false) {
            throw "Invalid HidePrivacySettings specified for ProfileType 'Hololens'. HidePrivacySettings must be 'false'."
        }
        if ($UserType -ne "standard") {
            throw "Invalid UserType specified for ProfileType 'Hololens'. UserType must be 'standard'."
        }
        if ($AllowPreprovisionedDeployment -ne $false) {
            throw "Invalid AllowPreprovisionedDeployment specified for ProfileType 'Hololens'. AllowPreprovisionedDeployment must be 'false'."
        }
        if ($HideChangeAccountOptions -ne $true) {
            throw "Invalid HideChangeAccountOptions specified for ProfileType 'Hololens'. HideChangeAccountOptions must be 'true'."
        }
        # Set DeviceUsageType to shared for selfDeploying deployment mode
        $DeviceUsageType = "shared"
    }

    # Validate conditions for windowPc
    if ($ProfileType -eq "windowsPc") {
        if ($DeploymentMode -eq "selfDeploying") {
            if ($JoinToEntraIDAs -ne "azureAD") {
                throw "Invalid JoinToEntraIDAs specified for DeploymentMode 'selfDeploying'. JoinToEntraIDAs must be 'azureAD'."
            }
            if ($HideLicenseTerms -ne $true) {
                throw "Invalid HideLicenseTerms specified for DeploymentMode 'selfDeploying'. HideLicenseTerms must be 'True'."
            }
            if ($HidePrivacySettings -ne $true) {
                throw "Invalid HidePrivacySettings specified for DeploymentMode 'selfDeploying'. HidePrivacySettings must be 'True'."
            }
            if ($UserType -ne "standard") {
                throw "Invalid UserType specified for DeploymentMode 'selfDeploying'. UserType must be 'standard'."
            }
            # Set DeviceUsageType to shared for selfDeploying deployment mode
            $DeviceUsageType = "shared"
        }
        elseif ($DeploymentMode -eq "userDriven") {
            if ($JoinToEntraIDAs -eq "hybrid") {
                if ("" -ne $ApplyDeviceNameTemplate) {
                    throw "You can not choose a name template for hybrid joined deployments"
                }
            }
            # Set DeviceUsageType to shared for User-Driven deployment mode
            $DeviceUsageType = "singleUser"         
        }            
    }
    #Get all possible locales world wide
    $AllLocales = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) | Select-Object -Property Name, DisplayName    
    #Check if $Locale parameter is a valid value from $AllLocales.name    
    if (-not ($AllLocales.Name -contains $LanguageLocale) -and $LanguageLocale -ne "os-default"){
        throw "Invalid LanguageLocale specified: $LanguageLocale. Please provide a valid locale."
    }  
    
    # if $ApplyDeviceNameTemplate is not empty, validate that Names must be 15 characters or less, and can contain letters (a-z, A-Z), numbers (0-9), and hyphens. Names must not contain only numbers. Names cannot include a blank space. Use the %SERIAL% macro to add a hardware-specific serial number. Alternatively, use the %RAND:x% macro to add a random string of numbers, where x equals the number of digits to add.
    if ($ApplyDeviceNameTemplate) {
        if ($ApplyDeviceNameTemplate.Length -gt 15) {
            throw "Device name template must be 15 characters or less."
        }
        if ($ApplyDeviceNameTemplate -match '^[0-9]+$') {
            throw "Device name template must not contain only numbers."
        }
        if ($ApplyDeviceNameTemplate -match '\s') {
            throw "Device name template must not contain blank spaces."
        }
        if ($ApplyDeviceNameTemplate -notmatch '^[a-zA-Z0-9\-]*$' -and $ApplyDeviceNameTemplate -notmatch '%SERIAL%' -and $ApplyDeviceNameTemplate -notmatch '%RAND:\d+%') {
            throw "Device name template can contain letters (a-z, A-Z), numbers (0-9), hyphens, %SERIAL%, and %RAND:x% macros only."
        }
    }
    # Construct params
    # Set the profile type based on the join type
    if ($JoinToEntraIDAs -eq "hybrid") {
        $odataType = "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile"        
        $ApplyDeviceNameTemplate = ""
    } else {
        $odataType = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"
        $SkipADConnectivityCheck = $false
    }   
    # Create the parameters for the deployment profile
    $params = @{
        "@odata.type" = $odataType
        displayName = $DisplayName
        description = $Description
        deviceNameTemplate = $ApplyDeviceNameTemplate
        locale = $LanguageLocale
        preprovisioningAllowed = $AllowPreprovisionedDeployment
        deviceType = $ProfileType
        hardwareHashExtractionEnabled = $ConvertAllTargetedDevicesToAutopilot
        roleScopeTagIds = @()
        hybridAzureADJoinSkipConnectivityCheck = $SkipADConnectivityCheck
        outOfBoxExperienceSetting = @{
            deviceUsageType = $DeviceUsageType
            escapeLinkHidden = $HideChangeAccountOptions
            privacySettingsHidden = $HidePrivacySettings
            eulaHidden = $HideLicenseTerms
            userType = $UserType
            keyboardSelectionPageSkipped = $AutomaticallyConfigureKeyboard
        }
    }
    # Create the deployment profile
    $res = New-MgBetaDeviceManagementWindowsAutopilotDeploymentProfile -BodyParameter $params | Format-List *
    return $res
}    

function Set-AutopilotDeploymentProfileAssignment {
    <#
.SYNOPSIS
Assigns a Windows Autopilot deployment profile to specified groups.

.DESCRIPTION
The Set-AutopilotDeploymentProfileAssignment function assigns a Windows Autopilot deployment profile to specified included and excluded groups. 
It retrieves the profile by name, validates the group names, and creates the profile assignments using the Microsoft Graph API.

.PARAMETER ProfileName
Specifies the name of the deployment profile to assign.

.PARAMETER IncludedGroupNames
Specifies the names of the groups to include in the assignment.

.PARAMETER ExcludedGroupNames
Specifies the names of the groups to exclude from the assignment.

.EXAMPLE
Set-AutopilotDeploymentProfileAssignment -ProfileName "MyProfile" -IncludedGroupNames "Group1", "Group2"

Assigns the deployment profile "MyProfile" to the groups "Group1" and "Group2".

.NOTES
    # CREDITS
    # This script was created by Amir Joseph Sayes.
    # For more information, visit amirsayes.co.uk
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$IncludedGroupNames,

        [Parameter(Mandatory=$false)]
        [string[]]$ExcludedGroupNames
    )

    $profile = Get-MgBetaDeviceManagementWindowsAutopilotDeploymentProfile -All |
        Where-Object { $_.DisplayName -eq $ProfileName }
    if (!$profile) {
        throw "Deployment profile '$ProfileName' not found."
    }
    elseif ($profile.count -gt 1) {
        throw "More than one profile found with name $ProfileName"
    }

    function Get-GroupIdByName {
        param (
            [string]$GroupName
        )
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
        if (!$group) {
            throw "Group '$GroupName' not found."
        }
        return $group.Id
    }

    $IncludedGroupIds = @()
    if ($IncludedGroupNames -and $IncludedGroupNames -notcontains "AllDevices" ) {
        foreach ($groupName in $IncludedGroupNames) {
            $IncludedGroupIds += Get-GroupIdByName -GroupName $groupName
        }
    }

    $ExcludedGroupIds = @()
    if ($ExcludedGroupNames) {
        foreach ($groupName in $ExcludedGroupNames) {
            $ExcludedGroupIds += Get-GroupIdByName -GroupName $groupName
        }
    }

    if ($IncludedGroupNames -and ($IncludedGroupNames -contains "AllDevices")) {
        if ($IncludedGroupNames.Count -gt 1 -or $ExcludedGroupNames) {
            throw "No other included or excluded groups allowed when assigning 'All Devices'."
        }
        $params = @{
            target = @{
                "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
            }
        }
        New-MgBetaDeviceManagementWindowsAutopilotDeploymentProfileAssignment -WindowsAutopilotDeploymentProfileId $profile.Id -BodyParameter $params
    }
    else {
        foreach ($groupId in $IncludedGroupIds) {
            $params = @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId       = $groupId
                }
            }
            New-MgBetaDeviceManagementWindowsAutopilotDeploymentProfileAssignment -WindowsAutopilotDeploymentProfileId $profile.Id -BodyParameter $params
        }
        foreach ($groupId in $ExcludedGroupIds) {
            $params = @{
                target = @{
                    "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget"
                    groupId       = $groupId
                }
            }
            New-MgBetaDeviceManagementWindowsAutopilotDeploymentProfileAssignment -WindowsAutopilotDeploymentProfileId $profile.Id -BodyParameter $params
        }
    }
}