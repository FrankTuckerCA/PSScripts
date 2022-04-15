<#*************************************************************************************************************************
    Setup-NewComputer 1.0 4/14/2022 
    Frank Tucker
    Use all, part, or modify this Script. Just add or remove ###. Manually select and run. 
    Administrative rights requried 
    Don't forget Powershell set-executiion & to DotSource ./setup-NewComputer.ps1 
    Set-ExecutionPolicy Bypass -Scope Process -Force  ./setupnewcomputer.ps1
***************************************************************************************************************************#>

<#*************************************************************************************************************************
    Create & Schdule Choco & Winget Upgrade PS1 Script
    .ps1 will be stored in the root path of the user runing this script.  C:\users\$env:username\
***************************************************************************************************************************#>
#Create Choco & Winget upgrade script
$UpdateScriptName    = "ChocoWingetUpdate.ps1"
$UpdateScriptPath    = "c:\users\$env:username\"
$UpdateScriptContent = '#****Chocolatey Update****','choco upgrade all -y -acceptlicense','#****Winget Update****','winget upgrade -h --all --slient --accept-package-agreements --accept-source-agreements'
$UpdateScriptContent | out-file -FilePath "$UpdateScriptPath$UpdateScriptName" -Force

#Schedule Choco & Winget Upgrade Script
$ScheduledTaskTrigger    = (New-ScheduledTaskTrigger -Weekly -DaysOfWeek  Sunday -At 1:00:00)
$ScheduledTaskAction     = (New-ScheduledTaskAction -execute "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" `
                            -Argument  $UpdateScriptPath$UpdateScriptName)
$ScheduledTaskSettingSet = (New-ScheduledTaskSettingsSet -WakeToRun -Compatibility Win8)
$ScheduledTaskName       = 'ChocoWingetUpdate'
#$Principal              = 
$ScheduledTask           = (New-ScheduledTask -Action $ScheduledTaskAction -Description $ScheduledTaskName `
                             -Settings $ScheduledTaskSettingSet -Trigger $ScheduledTaskTrigger)
Register-ScheduledTask $ScheduledTaskName -InputObject $ScheduledTask

<#*************************************************************************************************************************
    DISM Add-WindowsCapability.
    Find: Get-WindowsCapability -online
**************************************************************************************************************************#>
#RSAT Remote Server Adminisration Tools
Get-WindowsCapability -Online -Name RSAT.Active* | Add-WindowsCapability -Online

<#**************************************************************************************************************************
    DISM Enable-WindowsOptionalFeature. 
    Find: Get-WindowsOptionalFeature -online
    FeatureName: TelentClient, TFTP, SimpleTCP, Printing-PrintToPDFServices-Features, Internet-Explorer-Optional-amd64,
                       Microsoft-Windows-Subsystem-Linux,Microsoft-Hyper-V-All
****************************************************************************************************************************#>
#Enable-WindowsOptionalFeature -Online Microsoft-Hyper-V-All

<#**************************************************************************************************************************
    Winget
    Search for packages: winget search --name 
    Do not use * with --name
****************************************************************************************************************************#>
$WingetPackages = 'WinDbg Preview'
winget.exe install $WingetPackages -h --silent --accept-package-agreements --accept-source-agreements

<#***************************************************************************************************************************
    Chocolatey & Chocolatey Packages
****************************************************************************************************************************#>
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
#****Chocolatey Package Lists****
$ChocoApps   = 'paint.net','vlc','cdburnerxp', 'paint.net', 'zoom', 'winrar'
$ChocoNet    = 'winpcap','wireshark','Putty','AngryIP'
$ChocoDev    = 'github-desktop','visualstudiocode','yumi','rufus', 'sysinternals'
$ChocoFull   = $ChocoApps+$ChocoNet+$ChocoDev
    
#****chocolatey Install  ****
#Choco install $ChocoListNet
#choco install $ChocoListApps
Choco install $ChocoFull -A -Y

<#*****************************************************************************************************************************
    PowerShell Gallery Modules List
*******************************************************************************************************************************#>
$ModuleListBasic = 'PSScriptTools','xrobocopy','CredentialManager','EnhancedHTML2','find-smbshare','xpendingreboot','carbon',`
   'auditpolicydsc','csecurityoptions','posh-subnettools','psnmap', 'Winget','WingetTools','Winscp','zip'  
$ModuleListNetwork ='WakeOnLan','psnmap','WakeOnLan'
$ModuleListCloud = 'Azure','Azure.Storage','psgithub'
$ModuleListServerManagment = 'ADReportingTools'
$ModuleListFull = $ModuleListBasic+$ModuleListNetwork+$ModuleListCloud+$ModuleListServerManagment
  
<#*******************************************************************************************************************************
    PowerShell Gallery Module Install
*********************************************************************************************************************************#>
#Install-Module -Name $ModuleListBasic   -Confirm:$false -AcceptLicense
#Install-Module -Name $ModuleListNetwork -Confirm:$false -AcceptLicense
#Install-Module -Name $ModuleListCloud   -Confirm:$false -AcceptLicense
Install-Module -Name $ModuleListFull -force -Confirm:$false -AcceptLicense

<#*************************************************************************************************************************
    PNPUtil.exe Install Drivers into the online Windows driver store.  
    DISM Powersell Module Add-WindowsDriver can only add drivers to an Offline image.wim
    Export drivers from exising PC: Export-WindowsDriver or Pnputil.exe 
***************************************************************************************************************************#>
#$DriverINFPath = c:\users\administrator\drv
#pnputil.exe /add-driver $DriverINFPath\*.inf

<#**************************************************************************************************************************
    Install Chrome Web Broswer
    Google Chrome Enterprise info: https://chromeenterprise.google/intl/en_US/browser/download/#windows-tab
****************************************************************************************************************************#>
#Temp directory to download chrome. $env:temp is the temp folder for the user account running this script. 
$InstallDir = $env:temp

#Download the installer
$source = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B03FE9563-80F9-119F-DA3D-72FBBB94BC26%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26ap%3Dx64-stable/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$destination = "$InstallDir\chrome.msi"
Invoke-WebRequest $source -OutFile $destination

#Start the installation
msiexec.exe /i "$InstallDir\chrome.msi" /q /norestart 

#Wait XX Seconds for the installation to finish
Start-Sleep -s 120

#Remove the installer
Remove-Item -Force $InstallDir\chrome*

<#***************************************************************************************************************************
    Update Powershell Help and Restart
****************************************************************************************************************************#>
Update-Help
#Restart-Computer
