#requires -version 5.0
#requires -RunAsAdministrator
<#
****************************************************************************************************************************************************************************************************************
PROGRAM		: New-AzureRmVmSet.ps1

DESCRIPTION	:
This script creates a set of 1-4 Windows Server 2016 VMs with Network Security Groups for RDP access. In this script, these machines will be deployed using the ABC[DC]## convention, 
where ABC is the 3 letter airport code of the location, DC indicates that these machines can subsequently be configured as domain controllers, and ## represents the sequence numbers, 
i.e. 01, 02, etc. Azure resources will be created as part of an initial process of building a functional environment consisting of compute, storage and netorking components. 
Since this script will be used primarily for demonstration purposes, additional comments, logging and verbose console output have also been included.
***Please rate this script if it has been helpful and feel free to ask questions or provide feedback at the Q&A tab to let me know how we can make it even better!*** 

REQUIREMENTS: WriteToLogs module (https://www.powershellgallery.com/packages/WriteToLogs)
LIMITATIONS	: This script does not provision each VM as a domain controller. This normally requires the addition of Desired State Configuration scripts.
AUTHOR(S)	: Preston K. Parsard
EDITOR(S)	: Preston K. Parsard
KEYWORDS	: KEYWORDS: Mnemonic; [R]esilient<[R]esource Group> [N]eed<Virtual [N]etwork> [V]irtual Machines<[VMs] with [N]etworks<[N]etwork Security Groups> and [A]vailability Sets<[A]vailability Sets>
TAGS        : 0007, Microsoft Azure, Virtual Machines, Windows Server 2016

LICENSE:
The MIT License (MIT)
Copyright (c) 2016 Preston K. Parsard

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

LEGAL DISCLAIMER:
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
This posting is provided "AS IS" with no warranties, and confers no rights.

REFERENCES: 
1. https://gallery.technet.microsoft.com/scriptcenter/Build-AD-Forest-in-Windows-3118c100
2. http://blogs.technet.com/b/heyscriptingguy/archive/2013/06/22/weekend-scripter-getting-started-with-windows-azure-and-powershell.aspx
3. http://michaelwasham.com/windows-azure-powershell-reference-guide/configuring-disks-endpoints-vms-powershell/
4. http://blog.powershell.no/2010/03/04/enable-and-configure-windows-powershell-remoting-using-group-policy/
5. http://azure.microsoft.com/blog/2014/05/13/deploying-antimalware-solutions-on-azure-virtual-machines/
6. http://blogs.msdn.com/b/powershell/archive/2014/08/07/introducing-the-azure-powershell-dsc-desired-state-configuration-extension.aspx
7. http://trevorsullivan.net/2014/08/21/use-powershell-dsc-to-install-dsc-resources/
8. http://blogs.msdn.com/b/powershell/archive/2014/07/21/creating-a-secure-environment-using-powershell-desired-state-configuration.aspx
9. http://blogs.technet.com/b/ashleymcglone/archive/2015/03/20/deploy-active-directory-with-powershell-dsc-a-k-a-dsc-promo.aspx
10.http://blogs.technet.com/b/heyscriptingguy/archive/2013/03/26/decrypt-powershell-secure-string-password.aspx
11.http://blogs.msdn.com/b/powershell/archive/2014/09/10/secure-credentials-in-the-azure-powershell-desired-state-configuration-dsc-extension.aspx
12.http://blogs.technet.com/b/keithmayer/archive/2014/10/24/end-to-end-iaas-workload-provisioning-in-the-cloud-with-azure-automation-and-powershell-dsc-part-1.aspx
13.http://blogs.technet.com/b/keithmayer/archive/2014/07/24/step-by-step-auto-provision-a-new-active-directory-domain-in-the-azure-cloud-using-the-vm-agent-custom-script-extension.aspx
14.https://blogs.msdn.microsoft.com/cloud_solution_architect/2015/05/05/creating-azure-vms-with-arm-powershell-cmdlets/
15.https://msdn.microsoft.com/en-us/powershell/gallery/psget/script/psget_new-scriptfileinfo
16.https://msdn.microsoft.com/en-us/powershell/gallery/psget/script/psget_publish-script
17.https://www.powershellgallery.com/packages/WriteToLogs
****************************************************************************************************************************************************************************************************************
#>

<# 
TASK ITEMS
#>

<# 
***************************************************************************************************************************************************************************
REVISION/CHANGE RECORD	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DATE         VERSION    NAME               CHANGE
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
14 MAR 2017  1.0.0.0 Preston K. Parsard Initial release.
#>

# Resets profiles in case you have multiple Azure Subscriptions and connects to your Azure Account [Uncomment if you haven't already authenticated to your Azure subscription]
Clear-AzureProfile -Force
Login-AzureRmAccount

# Construct custom path for log files 
$LogDir = "New-AzureRmAvSet"
$LogPath = $env:HOMEPATH + "\" + $LogDir
If (!(Test-Path $LogPath))
{
 New-Item -Path $LogPath -ItemType Directory
} #End If

# Create log file with a "u" formatted time-date stamp
$StartTime = (((get-date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")
$24hrTime = $StartTime.Substring(11,4)

$LogFile = "New-AzureRmAvSet-LOG" + "-" + $StartTime + ".log"
$TranscriptFile = "New-AzureRmAvSet-TRANSCRIPT" + "-" + $StartTime + ".log"
$Log = Join-Path -Path $LogPath -ChildPath $LogFile
$Transcript = Join-Path $LogPath -ChildPath $TranscriptFile
# Create Log file
New-Item -Path $Log -ItemType File -Verbose
# Create Transcript file
New-Item -Path $Transcript -ItemType File -Verbose

Start-Transcript -Path $Transcript -IncludeInvocationHeader -Append -Verbose

# To avoid multiple versions installed on the same system, first uninstall any previously installed and loaded versions if they exist
Uninstall-Module -Name WriteToLogs -AllVersions -ErrorAction SilentlyContinue -Verbose

# If the WriteToLogs module isn't already loaded, install and import it for use later in the script for logging operations
If (!(Get-Module -Name WriteToLogs))
{
 # https://www.powershellgallery.com/packages/WriteToLogs
 Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
 Install-PackageProvider -Name Nuget -ForceBootstrap -Force 
 Install-Module -Name WriteToLogs -Repository PSGallery -Force -Verbose
 Import-Module -Name WriteToLogs -Verbose
} #end If

#region INITIALIZE VALUES	

$BeginTimer = Get-Date -Verbose

Do
{
 # Subscription name
 (Get-AzureRmSubscription).SubscriptionName
 [string] $Subscription = Read-Host "Please enter your subscription name, i.e. [MIAC | MSFT] "
 $Subscription = $Subscription.ToUpper()
} #end Do
Until (($Subscription) -ne $null)

# Selects subscription based on subscription name provided in response to the prompt above
Select-AzureRmSubscription -SubscriptionId (Get-AzureRmSubscription -SubscriptionName $Subscription).SubscriptionId

Do
{
 # Resource Group name
 [string] $rg = Read-Host "Please enter a new resource group name [rg##] "
} #end Do
Until (($rg) -match '^rg\d{2}$')


Do 
{
 # This is a uniquely assigned number for each course attendee so that the domain and Azure resources will also have unique names within the same course
 # For class-wide demo scripts, this number will be the last 4 digits of the request number
 [string]$AttendeeNum = Read-Host "Please enter your 4 digit attendee or request number, i.e. [0000] "
}
Until ($AttendeeNum -match '^[0-9][0-9][0-9][0-9]$')

Do
{
 # The site code refers to a 3 letter airport code of the nearest major airport to the training site
 [string]$SiteCode = Read-Host "Please enter your 3 character site code, i.e. [ATL] "
 $SiteCode = $SiteCode.ToUpper()
} #end Do
Until ($SiteCode -match '^[A-Z]{3}$')

Do
{
 # The site code refers to a 3 letter airport code of the nearest major airport to the training site
 [int]$InstanceCount = Read-Host "Please enter the total number of DC instances required [1-4] "
} #end Do
Until ($InstanceCount -le 4 -AND $InstanceCount -ne $null)

# Create and populate prompts object with property-value pairs
# PROMPTS (PromptsObj)
$PromptsObj = [PSCustomObject]@{
 pVerifySummary = "Is this information correct? [YES/NO]"
 pAskToOpenLogs = "Would you like to open the deployment log now ? [YES/NO]"
} #end $PromptsObj

# Create and populate responses object with property-value pairs
# RESPONSES (ResponsesObj): Initialize all response variables with null value
$ResponsesObj = [PSCustomObject]@{
 pProceed = $null
 pOpenLogsNow = $null
} #end $ResponsesObj

Do
{
 # The location refers to a geographic region of an Azure data center
 $Regions = Get-AzureRmLocation | Select-Object -ExpandProperty Location
 Write-ToConsoleAndLog -Output "The list of available regions are :" -Log $Log
 Write-ToConsoleAndLog -Output "" -Log $Log
 Write-ToConsoleAndLog -Output $Regions -Log $Log
 Write-ToConsoleAndLog -Output "" -Log $Log
 $EnterRegionMessage = "Please enter the geographic location (Azure Data Center Region) to which you would like to deploy these resources, i.e. [eastus2 | westus2]"
 Write-ToLogOnly -Output $EnterRegionMessage -Log $Log
 [string]$Region = Read-Host $EnterRegionMessage
 $Region = $Region.ToUpper()
 Write-ToConsoleAndLog -Output "`$Region selected: $Region " -Log $Log
 Write-ToConsoleAndLog -Output "" -Log $Log
} #end Do
Until ($Region -in $Regions)

New-AzureRmResourceGroup -Name $rg -Location $Region -Verbose

# VM image details
$Publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
[string]$sku = "2016-Datacenter"
$ImageName2016 = Get-AzureRmVMImage –Location $Region –Offer $offer –PublisherName $publisher –SKUs $sku
$Version = "latest"

# User name is specified directly in script
$UniversalAdmName = "entadmin"
# Virtual Machine size
$VmSize = "Standard_D1_v2"
# Availability set
$AvSetDcName = "AvSetDC"
# This is the generic top-level domain that will be used in the FQDN of a new domain that can be created later if desired
$gtld = ".lab"
$SiteNamePrefix = "net"

$cred = Get-Credential -UserName $UniversalAdmName -Message "Enter password for user: $UniversalAdmName"
# $UniversalPW = $cred.GetNetworkCredential().password

$DelimDouble = ("=" * 100 )
$Header = "AZURE RM DC DEPLOYMENT DEMO: " + $StartTime

# Create and populate site, subnet and VM properties of the domain with property-value pairs
$ObjDomain = [PSCustomObject]@{
 pFQDN = "R" + $AttendeeNum + $gtld
 pDomainName = "R" + $AttendeeNum
 pSite = $SiteNamePrefix + $AttendeeNum
 # Subnet names matches the VM roles (DC = Domain Controller, AP = Application servers or member servers)
 pSubNetDC = "DC"
 pSubNetAP = "AP"
 pDC = $SiteCode + "DC" # Based on the latest image of Windows Server 2016
} #end $ObjDomain

# Subnet for domain controllers
$DcSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $ObjDomain.pSubnetDC -AddressPrefix 10.0.0.0/28 -Verbose
# Subnet for member servers (AP = Application servers)
$ApSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $ObjDomain.pSubnetAP -AddressPrefix 10.0.0.16/28 -Verbose

$Vnet = New-AzureRmVirtualNetwork -Name $ObjDomain.pSite -ResourceGroupName $rg -Location $Region -AddressPrefix 10.0.0.0/26 -Subnet $DcSubnet,$ApSubnet -Verbose

# NSG Configuration
# https://www.petri.com/create-azure-network-security-group-using-arm-powershell

# Create the NSG names using 'NSG-' as a prefix
$NsgDcSubnetName = "NSG-$($ObjDomain.pSubnetDC)"
$NsgApSubnetName = "NSG-$($ObjDomain.pSubnetAP)"

# Create the AllowRdpInbound rules
$NsgRuleAllowRdpIn = New-AzureRmNetworkSecurityRuleConfig -Name "AllowRdpInbound" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix "Internet" -SourcePortRange "*" `
-DestinationAddressPrefix "VirtualNetwork" -DestinationPortRange 3389 -Protocol Tcp -Verbose
$NsgDcSubnetObj = New-AzureRmNetworkSecurityGroup -Name $NsgDcSubnetName -ResourceGroupName $rg -Location $Region -SecurityRules $NsgRuleAllowRdpIn -Verbose
$NsgApSubnetObj = New-AzureRmNetworkSecurityGroup -Name $NsgApSubnetName -ResourceGroupName $rg -Location $Region -SecurityRules $NsgRuleAllowRdpIn -Verbose

# Associate NSGs with VNETs
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $Vnet -Name $ObjDomain.pSubnetDC -AddressPrefix $DcSubnet.AddressPrefix -NetworkSecurityGroup $NsgDcSubnetObj | Set-AzureRmVirtualNetwork -Verbose
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $Vnet -Name $ObjDomain.pSubnetAP -AddressPrefix $ApSubnet.AddressPrefix -NetworkSecurityGroup $NsgApSubnetObj | Set-AzureRmVirtualNetwork -Verbose

# Specify disk size as 10 GiB
[int]$DataDiskSize = 10

# Create the avialability set for the [future] DCs
If ($InstanceCount -gt 1) 
{
 $DcAvSet = New-AzureRmAvailabilitySet -ResourceGroupName $rg -Name $AvSetDcName -Location $Region -PlatformUpdateDomainCount 5 -PlatformFaultDomainCount 3 $Region -Managed -Verbose
 Write-ToConsoleAndLog -Output "Since multiple instances were requested, an avalailability set named $AvSetDC will be created" -Log $Log
} #end if
else
{
 Write-ToConsoleAndLog -Output "Since only 1 instance was requested, an avalailability set will NOT be created" -Log $Log
} #end else 

# Populate Summary Display Object
# Add properties and values
# Make all values upper-case
 $SummObj = [PSCustomObject]@{
 SUBSCRIPTION = $Subscription.ToUpper()
 RESOURCEGROUP = $rg
 SITECODE = $SiteCode.ToUpper()
 ATTENDEENUM = $AttendeeNum.ToUpper()
 DOMAINFQDN = $ObjDomain.pFQDN.ToUpper()
 DOMAINNETBIOS = $ObjDomain.pDomainName.ToUpper()
 SITENAME = $ObjDomain.pSite.ToUpper()
 DCSUBNET = $ObjDomain.pSubNetDC.ToUpper()
 NSGDC = $NsgDcSubnetName.ToUpper()
 APSUBNET = $ObjDomain.pSubNetAP.ToUpper()
 NSGAP = $NsgApSubnetName.ToUpper()
 DCPREFIX = $ObjDomain.pDC.ToUpper()
 # This is the number of VMs and associated VM resources that will be created
 INSTANCES = $InstanceCount
 REGION = $Region.ToUpper()
 LOGPATH = $Log
 } #end $SummObj
 
#endregion INITIALIZE VALUES

#region FUNCTIONS	

Function New-RandomString
{
 $CombinedCharArray = @()
 $ComplexityRuleSets = @()
 $PasswordArray = @()
 # PCR here means [P]assword [C]omplexity [R]equirement, so the $PCRSampleCount value represents the number of characters that will be generated for each password complexity requirement (alpha upper, lower, and numeric)
 $PCRSampleCount = 4
 $PCR1AlphaUpper = ([char[]]([char]65..[char]90))
 $PCR3AlphaLower = ([char[]]([char]97..[char]122))
 $PCR4Numeric = ([char[]]([char]48..[char]57))

 # Add all of the PCR... arrays into a single consolidated array
 $CombinedCharArray = $PCR1AlphaUpper + $PCR3AlphaLower + $PCR4Numeric
 # This is the set of complexity rules, so it's an array of arrays
 $ComplexityRuleSets = ($PCR1AlphaUpper, $PCR3AlphaLower, $PCR4Numeric)

 # Sample 4 characters from each of the 3 complexity rule sets to generate a complete 12 character random string
 ForEach ($ComplexityRuleSet in $ComplexityRuleSets)
 {
  Get-Random -InputObject $ComplexityRuleSet -Count $PCRSampleCount | ForEach-Object { $PasswordArray += $_ }
 } #end ForEach

 [string]$RandomStringWithSpaces = $PasswordArray
 [string]$Script:RandomString = $RandomStringWithSpaces.Replace(" ","") 
} #end Function

# Create DC VM 
Function Add-VM
{
 # If the number of servers will be less than 9, pad with 0, so that the 3rd server would have a pulbic ip of dcvip03 instead of dcvip3 or a nic of dcnic03 as opposed to dcnic3.
 # This keeps the alignment consistent where all resources will have the same name lengths
 Write-WithTime -Output "Padding public IP and NIC resource names if necessary..." -Log $Log
 Switch ($i)
 {
  { $i -le 9 } 
  { 
   $DcVipPrefix = "dcvip0" 
   $DcNicPrefix = "dcnic0"
  } #end condition
  default 
  { 
   $DcVipPrefix = "dcvip" 
   $DcNicPrefix = "dcnic"
  } #end default
 } #end Switch

 # Create the public ip (VIP) and NIC names based on the prefix and index
 Write-WithTime -Output "Creating public IP name..." -Log $Log
 $DcVipName = $DcVipPrefix + $i
 Write-WithTime -Output "Creating NIC name..." -Log $Log
 $DcNicName = $DcNicPrefix + $i

 # Construct the drive names for the SYSTEM and DATA drives
 Write-WithTime -Output "Constructing SYSTEM drive name page blob..." -Log $Log
 $DriveNameSystem = "$($ObjDomain.pDC)-SYST"
 $DriveNameData = "$($ObjDomain.pDC)-DATA"

 # $x represents the value of the last octect of the private IP address. We skip the first 3 addresses in the network address because they are always reserved in Azure
 $x = $i + 3

 # NOTE: Domain labels have to be lower case
 Write-WithTime -Output "Creating DNS domain label..." -Log $Log
 # Add a random infix (4 numeric digits) inside the Dnslabel name to avoid conflicts with existing deployments generated from this script. The -pip suffix indicates this is a public IP
 New-RandomString
 $DnsLabelInfix = $RandomString.SubString(8,4)
 $DomainLabel = $objDomain.pDC.ToLower() + $DnsLabelInfix + "-pip"

 Write-WithTime -Output "Creating public IP..." -Log $Log
 # Now we can string all the pre-requisites together to construct both the VIP and NIC
 $DCvip = New-AzureRmPublicIpAddress -ResourceGroupName $rg -Name $DcVipName -Location $Region -AllocationMethod Static -DomainNameLabel $DomainLabel -Verbose
 Write-WithTime -Output "Creating NIC..." -Log $Log
 $DCnic = New-AzureRmNetworkInterface -ResourceGroupName $rg -Name $DcNicName -Location $Region -PrivateIpAddress "10.0.0.$x" -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $DCvip.Id -Verbose
 
 # If the VM doesn't aready exist, configure and create it
 If (!((Get-AzureRmVM -ResourceGroupName $rg).Name -match $ObjDomain.pDC))
 {
  Write-WithTime -Output "VM $($ObjDomain.pDC) doesn't already exist. Configuring..." -Log $Log
  # Setup new vm configuration
  If ($InstanceCount -eq 1)
  {
   $DcvmConfig = New-AzureRmVMConfig –VMName $ObjDomain.pDC -VMSize $vmSize | 
   Set-AzureRmVMOperatingSystem -Windows -ComputerName $ObjDomain.pDC -Credential $cred -ProvisionVMAgent -EnableAutoUpdate | 
   Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version $version | 
   Set-AzureRmVMOSDisk -Name $DriveNameSystem -StorageAccountType StandardLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -Verbose
  } #end if
  else
  {
   $DcvmConfig = New-AzureRmVMConfig –VMName $ObjDomain.pDC -VMSize $vmSize -AvailabilitySetId $DcAvSet.Id | 
   Set-AzureRmVMOperatingSystem -Windows -ComputerName $ObjDomain.pDC -Credential $cred -ProvisionVMAgent -EnableAutoUpdate | 
   Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version $version | 
   Set-AzureRmVMOSDisk -Name $DriveNameSystem -StorageAccountType StandardLRS -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite -Verbose
  } #end else

  # Add NIC
  Add-AzureRmVMNetworkInterface -VM $DcvmConfig -Id $DCnic.Id -Verbose

  # Create new VM
  Write-WithTime -Output "Creating VM from configuration..." -Log $Log
  New-AzureRmVM -ResourceGroupName $rg -Location $Region -VM $DcvmConfig -Verbose
  
  # Get current VM configuration
  $vmdc = Get-AzureRmVM -ResourceGroupName $rg -Name $ObjDomain.pDC

  # Set NIC
  Write-WithTime -Output "Adding NIC..." -Log $Log
  Set-AzureRmNetworkInterface -NetworkInterface $DCnic -Verbose

  # Add data disks
  Write-WithTime -Output "Adding data disk for NTDS, SYSV and LOGS directories..." -Log $Log
  Add-AzureRmVMDataDisk -VM $vmdc -Name $DriveNameData -StorageAccountType StandardLRS -Lun 0 -DiskSizeInGB 10 -CreateOption Empty -Caching None -Verbose
 
  # Update disk configuration
  Write-WithTime -Output "Applying new disk configurations..." -Log $Log
  Update-AzureRmVM -ResourceGroupName $rg -VM $vmdc -Verbose
 } #end If
 else
 {
  Write-ToConsoleAndLog -Output "$($ObjDomain.pDC) already exists..." -Log $Log
 } #end else
} #End function

#endregion FUNCTIONS

#region MAIN	

# Clear screen
# Clear-Host 

# Display header
Write-ToConsoleAndLog -Output $DelimDouble -Log $Log
Write-ToConsoleAndLog -Output $Header -Log $Log
Write-ToConsoleAndLog -Output $DelimDouble -Log $Log

# Display Summary
Write-ToConsoleAndLog -Output $SummObj -Log $Log
Write-ToConsoleAndLog -Output $DelimDouble -Log $Log

# Verify parameter values
Do {
$ResponsesObj.pProceed = read-host $PromptsObj.pVerifySummary
$ResponsesObj.pProceed = $ResponsesObj.pProceed.ToUpper()
}
Until ($ResponsesObj.pProceed -eq "Y" -OR $ResponsesObj.pProceed -eq "YES" -OR $ResponsesObj.pProceed -eq "N" -OR $ResponsesObj.pProceed -eq "NO")

# Record prompt and response in log
Write-ToLogOnly -Output $PromptsObj.pVerifySummary -Log $Log
Write-ToLogOnly -Output $ResponsesObj.pProceed -Log $Log

# Exit if user does not want to continue

if ($ResponsesObj.pProceed -eq "N" -OR $ResponsesObj.pProceed -eq "NO")
{
  Write-ToConsoleAndLog -Output "Deployment terminated by user..." -Log $Log
  PAUSE
  EXIT
 } #end if ne Y
else 
{
 # Proceed with deployment
 Write-ToConsoleAndLog -Output "Deploying environment..." -Log $Log

 # Create DC VM(s). Note that we pad the VM name here again, as we did for the VIPs and NICs above to ensure a consistent name length for VM resources
 Write-WithTime -Output "Padding name of VM for a consistent length if necessary..." -Log $Log
 For ($i = 1;$i -le $InstanceCount;$i++)
 {
  Switch ($i) 
  {
   { $i -le 9 } { $ObjDomain.pDC = $SiteCode + "DC0" + $i }
   default 
    { 
     # The VM name is constructed from the site code, "DC" role prefix and the numeric index $i
     $ObjDomain.pDC = $SiteCode + "DC" + $i 
    } #end default
  } #end switch

  Write-WithTime -Output "Building $($ObjDomain.pDC)..." -Log $Log
  Add-VM
 } #end For ($i...)

} #end else

#endregion MAIN

#region FOOTER		

# Calculate elapsed time
Write-WithTime -Output "Calculating script execution time..." -Log $Log
Write-WithTime -Output "Getting current date/time..." -Log $Log
$StopTimer = Get-Date
Write-WithTime -Output "Formating date/time to replace commas(,) with dashes(-)..." -Log $Log
$EndTime = (((Get-Date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")
Write-WithTime -Output "Calculating elapsed time..." -Log $Log
$ExecutionTime = New-TimeSpan -Start $BeginTimer -End $StopTimer

$Footer = "SCRIPT COMPLETED AT: "

Write-ToConsoleAndLog -Output $DelimDouble -Log $Log
Write-ToConsoleAndLog -Output "$Footer $EndTime" -Log $Log
Write-ToConsoleAndLog -Output "TOTAL SCRIPT EXECUTION TIME: $ExecutionTime" -Log $Log
Write-ToConsoleAndLog -Output $DelimDouble -Log $Log

# Prompt to open logs
Do 
{
 $ResponsesObj.pOpenLogsNow = read-host $PromptsObj.pAskToOpenLogs
 $ResponsesObj.pOpenLogsNow = $ResponsesObj.pOpenLogsNow.ToUpper()
}
Until ($ResponsesObj.pOpenLogsNow -eq "Y" -OR $ResponsesObj.pOpenLogsNow -eq "YES" -OR $ResponsesObj.pOpenLogsNow -eq "N" -OR $ResponsesObj.pOpenLogsNow -eq "NO")

# Exit if user does not want to continue
if ($ResponsesObj.pOpenLogsNow -eq "Y" -OR $ResponsesObj.pOpenLogsNow -eq "YES") 
{
 Start-Process notepad.exe $Log
 Start-Process notepad.exe $Transcript
} #end if

# End of script
Write-WithTime -Output "END OF SCRIPT!" -Log $Log

# Close transcript file
Stop-Transcript -Verbose

#endregion FOOTER

Pause