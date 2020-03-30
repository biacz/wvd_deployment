Function Logit {
    param(
        [Parameter(Mandatory=$true)][String]$msg
    )
    $timestamp = "[{0:MM/dd/yy} {0:HH:mm:ss zzz} UTC]" -f (Get-Date)
    $filepath = "\\asdf\logs\WVDDeployment.log"
    Add-Content -path $filepath -value "$timestamp - $msg" -Force -ErrorAction "SilentlyContinue"
}

$AAdTenantID = "asdf"
$AzureADServicePrincipal = "asdf"
$AzureADServicePrincipalCredentials = "asdf"
$credentials = New-Object System.Management.Automation.PSCredential($AzureADServicePrincipal, (ConvertTo-SecureString $AzureADServicePrincipalCredentials -AsPlainText -Force))
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $credentials -ServicePrincipal -aadtenantid $AAdTenantID
$tenant = "asdf"

$subs = get-azsubscription
$subs | select-object Name, Id | ft *
$sub_name = read-host "Enter Subscription ID"

set-azcontext -subscription $sub_name

$rgroups = get-azresourcegroup
$rgroups | select-object ResourceGroupName, Location | ft *
$rg_name = read-host "Enter Resource Group Name"
$location = Get-AzResourceGroup -Name $rg_name | select Location -ExpandProperty Location

$TemplateFile = "WVDHostPool.json"

if(!$(get-azresourcegroup)) {
    $location = read-host "Enter location code (eastus, centralus, japaneast, uksouth"
    New-AzResourceGroup -Name $rg_name -Location $location
    write-host $rg_name "created in" $location
}

if($(get-azresourcegroup)) {
    write-host "RG already exists, skipping creation"
}

$domainToJoin = "asdf"
$domainUPN = "asdf"
$ouPath = "asdf"

$pools = get-rdshostpool -TenantName $tenant | select HostPoolName
$pools | ft *
$poolName = read-host -prompt "Pool Name"

$shosts = Get-RdsSessionHost -TenantName $tenant -HostPoolName $poolName | select SessionHostName | sort-object SessionHostName
$shosts | ft *
$rdshPrefix = read-host "Type in the computer name prefix like"

$numberOfVMs = read-host "Number of VMs"
$vmSize = read-host "VM Size (Standard_B2ms; Standard_D2s_v3)"

$vnet = $(Get-AzVirtualNetwork | select Name -expandproperty Name)
$subnet = $(Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $(Get-AzVirtualNetwork) | ? { $_.Name -match "vms" } | select Name -ExpandProperty Name)
$vnetRG = $(Get-AzVirtualNetwork | select ResourceGroupName -ExpandProperty ResourceGroupName)

new-AzResourceGroupDeployment -ResourceGroupName $rg_name -TemplateFile $TemplateFile `
    -isServicePrincipal $true `
    -tenantAdminUpnOrApplicationId $AzureADServicePrincipal `
    -tenantAdminPassword $AADSPCred `
    -aadTenantId $AAdTenantID `
    -rdshNumberOfInstances $numberOfVMs `
    -rdshVmSize $vmSize `
    -domainToJoin $domainToJoin `
    -existingDomainUPN $domainUPN `
    -rdshNamePrefix $rdshPrefix `
    -existingVnetName $vnet `
    -existingSubnetName $subnet `
    -virtualNetworkResourceGroupName $vnetRG `
    -existingTenantName $tenant `
    -hostPoolName $poolName `
    -ouPath $ouPath `
    -sharedimagegalleryname "asdf" `
    -sharedimagedefname "asdf" `
    -sharedImageversion "asdf" `
    -sharedImageresourcegroup "asdf" `
    -sharedImagesubscription "asdf"