#==============================================
# Generated On: 08/03/2016
# Generated By: Gary Coburn
# Automation Specialist
# Organization: VMware
# Twitter: @coburnGary
# Install bootstrap, java, and gugent
#==============================================
#----------------------------------------------
#==================USAGE=======================
# Only tested and for use on Windows 2008 R2 and 2012 R2 Server
# Works with vRA 7.0, 7.0.1, and 7.1
#----------------------------------------------
#===============REQUIREMENTS ===================
# For this script to run successfully be sure:
# 	To run PowerShell as administrator
#	  To have admin rights on the server
#
#   .NET framework 3.5 is a requirement for this script
#   Please ensure .NET framework 3.5 or above is installed or you have internet
#   access to run the install
#
#----------------------------------------------

# Accept parameters from the commandline to set the default variables

    param(
      [string]$vRAurl="",
      [string]$IaaS="",
      [string]$Password="",
      [string]$Version=""
    )

# ----------------------------------------
#   USER CONFIGURATION - EDIT AS NEEDED
# ----------------------------------------

# If this is unattended then these will be set by the parameters
# Otherwise you can preset these for run time or simply answer the prompts

# $vRAurl = "{$appliance}"
# $IaaS = "{$iaas}"
# $Password = "{$password}"
# $Version = "7.1"

# ----------------------------------------
# 		END OF USER CONFIGURATION
# ----------------------------------------


# ----------------------------------------
# 	     Functions
# ----------------------------------------
# function to write output to both file and screen
function Write-Feedback()
{

    Write-Host -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor $msg;
    $msg | Out-File "C:\opt\agentinstall.txt" -Append;
}

# function to download files
function downloadNeededFiles($url,$file)
{
    $msg = "$file Downloading";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $clnt = New-Object System.Net.WebClient
    $clnt.DownloadFile($url,$file)
    $msg = "$file Downloaded";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
}

# function to extract zip files
function extractZip($file,$dest)
{
    $msg = "$file extracting files";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
    $shell = new-object -com shell.application
    if (!(Test-Path "$file"))
    {
        throw "$file does not exist"
    }
    New-Item -ItemType Directory -Force -Path $dest -WarningAction SilentlyContinue
    $shell.namespace($dest).copyhere($shell.namespace("$file").items())
    $msg = "$file extracted";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
}

# ----------------------------------------
# 	     End Functions
# ----------------------------------------


# ------------------------------------
#           Log file start
# ----------------------------------
# Creating Directory and Log file path

New-Item -ItemType Directory -Force -Path C:\opt
"Starting the log file" | Out-file -FilePath C:\opt\agentinstall.txt | Write-Host
$msg = "logging all messages:";$BackgroundColor = "Black";$ForegroundColor = "Red";Write-Feedback

# ----------------------------------------
# 		CHECK POWERSHELL SESSION
# ----------------------------------------

$Elevated = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
& {
    if ($Elevated.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))
    {
        $msg =  "PowerShell is running as an administrator.";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
    } Else {
        $msg =  "Exiting - Powershell must be run as an adminstrator.";$BackgroundColor = "Black";$ForegroundColor = "Red";Write-Feedback
		throw "Powershell must be run as an adminstrator."
	}
    if( $ENV:Processor_architecture -eq "AMD64" )
    {
        $msg =  "You are running 64-bit PowerShell.";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
    }
    else
    {
        $msg =  "Exiting - 32 Bit is not supported.";$BackgroundColor = "Black";$ForegroundColor = "Red";Write-Feedback
        throw "This script must exit as Windows 32 bit isn't supported."
    }
}
# ----------------------------------------
# 		END OF POWERSHELL CHECK
# ----------------------------------------

# ---------------------------------------
#      Check Operating System Version and .NET Framework
# ---------------------------------------
# Grab the OS Name
$os = (get-WMiObject -class Win32_OperatingSystem).caption
 $msg =  "OS = $os";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
if ( $os -like "*2012 R2*" )
{
    $msg =  "Adding .NET 3.5 features";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
    Install-WindowsFeature -name NET-Framework-Core
    $msg =  ".NET 3.5 features installed";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
}
elseif ( $os -like "*2008 R2*" )
{
  $framework=(Get-ChildItem -Path $Env:windir\Microsoft.NET\Framework | Where-Object {$_.PSIsContainer -eq $true } | Where-Object {$_.Name -match 'v\d\.\d'} | Sort-Object -Property Name -Descending | Select-Object -First 1).Name -split "v"
  $msg =  "Framework version = $framework";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
  if ($framework -le "3.0.0")
  {
    $msg =  ".NET 3.5 doesn't appear to be installed";$BackgroundColor = "Black";$ForegroundColor = "Red";Write-Feedback
    import-module servermanager
    add-windowsfeature as-net-framework
  }
}
else
{
    $msg =  "OS = $os is not supported please execute against Windows 2008 or 2012 R2 only!";$BackgroundColor = "Black";$ForegroundColor = "Red";Write-Feedback
     Throw "This script must exit due to unsupported operating system. Review the log file c:\opt\agentinstall.txt for more info"
}
# ----------------------------------------
# 		END OF OS CHECK
# ----------------------------------------


# ----------------------------------------
# 		Install Script
# ----------------------------------------

$msg =  "Validating if the proper values are set";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
# Accept parameters if you are passing this via User Interaction
if (!$vRAurl) {
  $msg = "User configuration not set and no command line parameters detected ";$BackgroundColor = "Black";$ForegroundColor = "Red";Write-Feedback
  $vRAurl = read-Host -Prompt "What is the fqdn of your vRA Appliance? (vraServer.domain)  "
  $IaaS = read-Host -Prompt "What is fqdn of your IaaS Server? (ex. windowsServer.domain)  "
  $Password = read-Host -Prompt "What would you like the password for the darwin user to be?  "
  $Version = read-Host -Prompt "What version of vRA are you using? (ex 7.0, 7.0.1, 7.1)  "
}

$msg =  "The following values have been set";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$msg =  "vRA Appliance is $vRAurl ";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$msg =  "IaaS server is $IaaS ";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$msg =  "Password is ******** ";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$msg =  "The version you have is set to $Version";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback


# ----------------------------------------
# Set the download files needed based on your vRA Version
if ( $Version -eq "7.0" )
{
  $msg =  "Setting files for $Version";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
  $bootstrapFile="https://" + $vRAurl + ":5480/service/software/download/vmware-vra-software-agent-bootstrap-windows_7.0.0.0.zip"
  $agentFile="https://" + $vRAurl + ":5480/service/software/download/GuestAgentInstaller_x64.exe"
  $javaFile="https://" + $vRAurl + ":5480/service/software/download/jre-1.8.0_66-win64.zip"
}
elseif ( $Version -eq "7.0.1" )
{
  $msg =  "Setting files for $Version";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
  $bootstrapFile="https://" + $vRAurl + ":5480/service/software/download/vmware-vra-software-agent-bootstrap-windows_7.0.0.0.zip"
  $agentFile="https://" + $vRAurl + ":5480/installer/GuestAgentInstaller_x64.exe"
  $javaFile="https://" + $vRAurl + ":5480/service/software/download/jre-1.8.0_72-win64.zip"
}
else
{
  $msg =  "Setting files for $Versoin";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
  $bootstrapFile="https://" + $vRAurl + "/software/download/vmware-vra-software-agent-bootstrap-windows_7.1.0.0.zip"
  $agentFile="https://" + $vRAurl + "/software/download/GuestAgentInstaller_x64.exe"
  $javaFile="https://" + $vRAurl + "/software/download/jre-1.8.0_102-win64.zip"
}

$msg =  "Creating directory structure needed";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
New-Item -ItemType Directory -Force -Path C:\opt\vmware-jre
New-Item -ItemType Directory -Force -Path C:\opt\bootstrap
$msg =  "Directories Created";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback

# ----------------------------------------
# Download and Extract the JRE components
# ----------------------------------------
$msg = "The URL specified is $vRAurl";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$msg = "Calling to download JRE zip";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
$url=$javaFile
$msg = "The full URL to your JRE file is $url";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$file="c:\opt\jre.zip"
$dest="c:\opt\vmware-jre\"
# Call Download Function
downloadNeededFiles $url $file
# Call Extract Function
extractZip $file $dest

# ----------------------------------------
# Download and execute the Guest Agent Installer
# ----------------------------------------
$msg = "Calling the download for guest agent";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
$url=$agentFile
$msg = "The full URL to your GuestAgentInstaller file is $url";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$file="c:\GuestAgentInstaller_x64.exe"
# Call Download Function
downloadNeededFiles $url $file
$msg = "Executing: $file";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
cd c:\
Start-Process C:\GuestAgentInstaller_x64.exe -Wait -PassThru
$msg = "$file Executed";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback

# Execute the winservice to put our Agent ready at start up
$msg = "The fqdn you specificed is $IaaS";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$IaaSwithPort=$IaaS + ":443"
$argumentList = " -i -h $IaaSwithPort -p ssl"
$msg = "Command we run will be winservice.exe & $argumentList";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
cd c:\VRMGuestAgent
$msg = "Executing winservice";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
$winservicefile = ("winservice.exe")
$gugentInstall = Start-Process $winservicefile -ArgumentList $argumentList -Wait -PassThru
$msg = "Execution of winservice complete";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback

# Download and execute vRA bootstrap agent
$msg = "Downloading Bootstrap";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
cd C:\opt\bootstrap
$url=$bootstrapFile
$msg = "The full URL to your bootstrap file is $url";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$file="c:\opt\bootstrap\bootstrap.zip"
$dest="c:\opt\bootstrap\"
# Call Download Function
downloadNeededFiles $url $file
# Call Extract Function
extractZip $file $dest

$msg = "Executing install.bat";$BackgroundColor = "Black";$ForegroundColor = "Yellow";Write-Feedback
$bootstrapFile = ("install.bat")
$argumentList = " password=$Password managerServiceHost=$IaaS cloudProvider=vsphere"
$msg = "Command we run will be install.bat & $argumentList";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$bootstrapInstall = Start-Process $bootstrapFile -ArgumentList $argumentList -Wait | Out-File -FilePath C:\opt\AgentInstall.txt -Append
$msg = "Execution of install.bat complete";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback

# ----------------------------------------
# 		Install Script Complete
# ----------------------------------------

# ---------------------------------------
#       Cleaning up
# ---------------------------------------
$msg = "Cleaning up downloaded files";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
$msg = "Deleting jre.zip";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
Remove-Item C:\opt\jre.zip
$msg = "Deleting guestagent.exe";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
Remove-Item C:\GuestAgentInstaller_x64.exe
$msg = "Deleting bootstrap.zip";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback
Remove-Item C:\opt\bootstrap\bootstrap.zip
# ---------------------------------------
#       Clean up complete
# ---------------------------------------

$msg = "INSTALL COMPLETE! Ready for shutdown";$BackgroundColor = "Black";$ForegroundColor = "Green";Write-Feedback

# ------------------------------------
#           End Log File
# ----------------------------------
