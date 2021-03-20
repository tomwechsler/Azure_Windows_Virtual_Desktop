Set-Location c:\
Clear-Host

#Install the Az Module
Install-Module -Name Az -Force -AllowClobber -Verbose

#Verify the WVD Moduel is Installed
Get-InstalledModule -Name Az.Desk*

#Install the WVD module Only
Install-Module -Name Az.DesktopVirtualization

#Update the module
Update-Module Az.DesktopVirtualization

#Log into Azure
Connect-AzAccount

#Select the correct subscription
Get-AzContext
Get-AzSubscription
Get-AzSubscription -SubscriptionName "Nutzungsbasierte Bezahlung" | Select-AzSubscription

#Download AzFilesHybrid
#https://github.com/Azure-Samples/azure-files-samples/releases

##Join the Storage Account for SMB Auth Microsoft Source:
##https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable

#Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

#Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path

Set-Location C:\AzFilesHybrid

.\CopyToPSPath.ps1 

#Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

#Login with an Azure AD credential that has either storage account owner or contributor Azure role assignment
Connect-AzAccount

#Define parameters
$SubscriptionId = "<your-subscription-id-here>"
$ResourceGroupName = "<resource-group-name-here>"
$StorageAccountName = "<storage-account-name-here>"

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

#Register the target storage account with your active directory environment
Join-AzStorageAccountForAuth `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -DomainAccountType "<ComputerAccount|ServiceLogonAccount>" `
        -OrganizationalUnitDistinguishedName "<ou-distinguishedname-here>" # If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.

#You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose

#Confirm the feature is enabled
#Get the target storage account
$storageaccount = Get-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName

#List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties

#Mount the file

#Define parameters
$StorageAccountName = "<storage-account-name-here>"
$ShareName = "<share-name-here>"
$StorageAccountKey = "<account-key-here>"

#Run the code below to test the connection and mount the share
$connectTestResult = Test-NetConnection -ComputerName "$StorageAccountName.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded)
{
  net use T: "\\$StorageAccountName.file.core.windows.net\$ShareName" /user:Azure\$StorageAccountName $StorageAccountKey
} 
else 
{
  Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN,   Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

#Path to the file share
#Replace drive letter, storage account name and share name with your settings
#"\\<StorageAccountName>.file.core.windows.net\<ShareName>"