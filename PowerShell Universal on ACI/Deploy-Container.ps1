#region Import Az and Connect
Import-Module Az
Connect-AzAccount #-Tenant "xxxxxxxx-xxxxx-xxxx-xxxx-xxxxxxxx"
#endregion Import Az and Connect

#region Set some shared defaults
$RandomInteger = Get-Random -Minimum 3000 -Maximum 5000
$Location = "australiaeast"
$ResourceGroupName = "rg-aci$($RandomInteger)"
$ContainerRegistryName = "acr$($RandomInteger)"
$StorageAccountName = "whstorage$($RandomInteger)"
#endregion Set some shared defaults

#region Create a Resource Group
New-AzResourceGroup `
-Name $ResourceGroupName `
-Location $Location
#endregion Create a Resource Group

#region Create Azure Container Registry (ACR)
$Registry = New-AzContainerRegistry `
-Name  $ContainerRegistryName `
-ResourceGroupName $ResourceGroupName `
-Location $Location `
-Sku Basic `
-EnableAdminUser
#endregion Create Azure Container Registry (ACR)

#region Get ACR Credentials
$RegistryCredentials = Get-AzContainerRegistryCredential `
-ResourceGroupName $ResourceGroupName `
-Name $ContainerRegistryName
#endregion Get ACR Credentials

#region Build/Publish Image
# Login to Docker
$RegistryCredentials.Password | docker login $Registry.LoginServer -u $RegistryCredentials.Username --password-stdin
# Build the Image and tag it with the Registry Name
docker build -t "$($Registry.LoginServer)/azpowershelluniversal" .
docker image list
# Push the Image
docker push "$($Registry.LoginServer)/azpowershelluniversal"
#endregion Build/Publish Image

#region Create a Storage Account to persist data for the Container/s
New-AzStorageAccount `
-ResourceGroupName $ResourceGroupName `
-AccountName $StorageAccountName `
-Location $Location `
-SkuName Standard_LRS `
-Kind StorageV2
#endregion Create a Storage Account to persist data for the Container/s

#region Get the Storage Account Keys so we can connect to the storage from the container
$StorageAccountKey = (Get-AzStorageAccountKey `
-ResourceGroupName $ResourceGroupName `
-Name $StorageAccountName).value[0]
$StorageAccountKeyPassword = ConvertTo-SecureString $StorageAccountKey -AsPlainText -Force
$StorageAccountCredential = New-Object System.Management.Automation.PSCredential($("whstorage$RandomInteger"),$StorageAccountKeyPassword)
#endregion Get the Storage Account Keys so we can connect to the storage from the container

#region Create an Azure File Share
# Set the Context
$StorageAccountContext = New-AzStorageContext `
-StorageAccountName $StorageAccountName `
-StorageAccountKey $StorageAccountKey
# Create the File Share
New-AzStorageShare `
-Name "poshuddata" `
-Context $StorageAccountContext
#endregion Create an Azure File Share

#region Deploy PowerShell Universal to the Azure Container Group (ACI)
# Convert the Container Registry Credentials into a PSCredential
$RegistryPassword = ConvertTo-SecureString $RegistryCredentials.Password -AsPlainText -Force
$RegistryPSCredential = New-Object System.Management.Automation.PSCredential($($RegistryCredentials.Username),$RegistryPassword)
# Set Environmental Variables to enable PowerShell Universal to run on ACI and Persist Data
$EnvironmentVariables = @{
    "Data__RepositoryPath" = "./data/Repository"
    "Data__ConnectionString" = "./data/database.db"
    "UniversalDashboard__AssetsFolder" = "./data/UniversalDashboard"
    "Logging__Path" = "./data/logs/log.txt"
    "Kestrel__Endpoints__HTTP__Url" = "http://*:80"
}
# Deploy the container
New-AzContainerGroup `
-ResourceGroupName $ResourceGroupName `
-Name "whposhud$($RandomInteger)" `
-Image "$($Registry.LoginServer)/azpowershelluniversal" `
-RegistryCredential $RegistryPSCredential `
-EnvironmentVariable $EnvironmentVariables `
-Location $Location `
-OsType Linux `
-Cpu 1 `
-MemoryInGB 1 `
-RestartPolicy OnFailure `
-IpAddressType Public `
-Port 80 `
-DnsNameLabel "whposhud$($RandomInteger)" `
-AzureFileVolumeShareName 'poshuddata'`
-AzureFileVolumeAccountCredential $StorageAccountCredential `
-AzureFileVolumeMountPath '/data' `
-IdentityType SystemAssigned
#endregion Deploy PowerShell Universal to the Azure Container Group (ACI)

#region Assign Permissions to the Container Instance so it can view and operate Azure Virtual Machines
New-AzRoleAssignment `
-Objectid (Get-AzADServicePrincipal -DisplayName "whposhud$($RandomInteger)").Id `
-RoleDefinitionName 'Virtual Machine Contributor'
#endregion Assign Permissions to the Container Instance so it can view and operate Azure Virtual Machines