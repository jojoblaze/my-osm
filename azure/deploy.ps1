<#
.SYNOPSIS
   Deploys a template to Azure
 
.DESCRIPTION
   Deploys an Azure Resource Manager template
 
.PARAMETER subscriptionId
   The subscription id where the template will be deployed.

#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $subscriptionId,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $False)]
    [string]
    $location
)




#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
Import-Module AzureRM


$defaultResourceGroupName = "my-resource-group"
$defaultLocation = "westeurope"




# sign in
Write-Host "Logging in...";
Connect-AzureRmAccount


# Save context information under %AppData%\Roaming\Windows Azure PowerShell. 
Enable-AzureRmContextAutosave

# view saved context
# Get-AzureRmContext



#If you want to remove a particular context issue command
#Remove-AzureRmContext -Name <name>


# retrieve info about the tenant
# Get-AzureRmTenant





# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzureRmSubscription -SubscriptionID $subscriptionId;


# Resource Group
If ($resourceGroupName -eq [string]::empty) {
    $resourceGroupName = Read-Host -Prompt "Enter the Resource Group name (default: $($defaultResourceGroupName)"
    If ($resourceGroupName -eq [string]::empty) {
        $resourceGroupName = $defaultResourceGroupName
    }
}

# Location
If ($location -eq [string]::empty) {
    $location = Read-Host -Prompt "Enter the location (default: $($defaultLocation))"
    If ($location -eq [string]::empty) {
        $location = $defaultLocation
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource group '$resourceGroupName' does not exist. A new resource group will be created.";
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
} 
else {
    Write-Host "Using existing resource group '$resourceGroupName'";
}


# Start the deployment
Write-Host "Starting deployment...";

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
    -TemplateFile .\create-ubuntu-vm-template.json -TemplateParameterFile .\ubuntu-vm.parameters.json
#-TemplateUri $templatePath -TemplateParameterUri $parametersPath
