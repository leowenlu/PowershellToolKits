    $global:smtp="mail.bigpond.com"  #SMTP server 
    $Global:EmailTo="leo.wenlu@gmail.com"  # Will send emails to this email address
    $Global:EmailFrom="NoReply@itengineer.com.au" #MarkEmailSentFromThisEmailAddress
    $Global:LeoToolKits=@{
           AboutMe= "
                  ************************************************************************`r
                  *  LeoToolKits :   Powershell CMDLETs                                  *`r
                  *  Written By  :   Leo Li       05/08/2014                             *`r
                  *  Version     :   V0.02                                               *`r
                  *  Support     :   support@itengineer.com.au                           *`r
                  ************************************************************************`r
                  "
          MyName = $myInvocation.InvocationName   #Test Viriable

          }

$Global:NewLine = "`r`n"

#region old ones
Function send-WOL {
 <#
    .SYNOPSIS
    Sends a number of magic packets using UDP broadcast, 
    .DESCRIPTION
    Send_WOL sends a specified number of magic packets to a MAC address in order to wake up the machine.
    NOTE:
       If you send the Magic Packet across different subnets, make sure you enalbe this feature in your router.
 
    .PARAMETER MacAddress
    The MAC address of the machine to wake up, this parameter is mandatory.
 
    .PARAMETER Network
    IP address of the machine, or network address.
      NOTE:   Check your ip address and subnet, as the script cannot check them out.
  .PARAMETER SubnetMask
       Subnet mask, the default value is 255.255.255.255
  .PARAMETER Packets
       How many magic packets will be sent,default is 5
  #>
[CmdletBinding()]
 param (
   [Parameter(
      Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]              
      [string]$MacAddress,
  [Parameter(Mandatory=$false)]
      $network= [net.ipaddress]::Broadcast, 
  [Parameter(Mandatory=$false)]
    $SubnetMask= [net.ipaddress]::Broadcast,
  [Parameter(Mandatory=$false)]
      $Packets=5
    )
try {
    if($network.gettype().equals([string])) {
        $network = [net.ipaddress]::Parse($network);
    }
    if($SubnetMask.gettype().equals([string])) {
        $SubnetMask = [net.ipaddress]::Parse($SubnetMask);
    }
      
    #get broadcast address based on the network and subnet. 
  $broadcast = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $SubnetMask.address -bor $network.address))

   #This again assumes that you had given . as the delimeter in MAC address and removes that from MAC address    
    $mac = [Net.NetworkInformation.PhysicalAddress]::Parse($MacAddress.toupper().replace(".",""))

    $u = New-Object net.sockets.udpclient
    
  #Create end points for the broadcast address at port 0,7,9    
    $ep = New-Object net.ipendpoint $broadcast, 0
    $ep2 = New-Object net.ipendpoint $broadcast, 7
    $ep3 = New-Object net.ipendpoint $broadcast, 9
    $payload = [byte[]]@(255,255,255, 255,255,255);
    $payload += ($mac.GetAddressBytes()*16)

    for($i = 0; $i -lt $packets; $i++) {
        $u.Send($payload, $payload.Length, $ep) | Out-Null
        $u.Send($payload, $payload.Length, $ep2) | Out-Null
        $u.Send($payload, $payload.Length, $ep3) | Out-Null
        sleep 1;
    }
} catch {
#catch block catches any error from try block
    $Error | Write-Error;
}
}
function Check-TcpPort {
<#
	.SYNOPSIS
		Check a TCP Port

	.DESCRIPTION
		Opens a connection to a given (or default) TCP Port to a server or network device.
		This is NOT a simple port ping, it creates a real connection to see if the port is alive!

	.PARAMETER Port
		 Default is 25

	.PARAMETER Server
		 e.g. "www.google.com" or "192.168.16.10"
		 SMTP Server to use

	.EXAMPLE
		PS C:\> Check-TcpPort -port 80 -server www.google.com 

		# Check port 80/TCP on the www.google.com

	.EXAMPLE
		PS C:\> CheckTcpPort -Port:25 -Server:mx.net-experts.net

		# Check port 25/TCP on Server mx.net-experts.net

	.OUTPUTS
		boolean
		Value is True or False

	.NOTES
		Notes
#>
	
	[CmdletBinding(ConfirmImpact = 'None',
				   SupportsShouldProcess = $true)]
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false)]
		[Int32]
		$Port=80,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false)]
		[string]
		$Server="localhost"
	)
	
	# Cleanup
	Remove-Variable ThePortStatus -Force -Confirm:$false -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
	
	# Set the defaults for some stuff

	
	# Create a function to open a TCP connection
	$ThePortStatus = New-Object Net.Sockets.TcpClient -ErrorAction SilentlyContinue
	
	# Look if the Server is online and the port is open
	try {
		# Try to connect to one of the on Premise Exchange front end servers
		$ThePortStatus.Connect($Server, $Port)
	} catch [System.Exception]
	{
		# BAD, but do nothing yet! This is something the the caller must handle
	}
	
	# Share the info with the caller
	$ThePortStatus.Client.Connected
	
	# Cleanup
	Remove-Variable ThePortStatus -Force -Confirm:$false -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
	
	# CLOSE THE TCP Connection
	if ($ThePortStatus.Connected) {
		# Mail works, close the connection
		$ThePortStatus.Close()
	}
	
	# Cleanup
	Remove-Variable ThePortStatus -Scope:Global -Force -Confirm:$false -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
	
	# Do a garbage collection
	if ((Get-Command run-gc -errorAction SilentlyContinue)) {
		run-gc
	}
}
function remove-UserProfiles {
<#
	.SYNOPSIS

	.DESCRIPTION

	.PARAMETER Port

	.PARAMETER Server

	.EXAMPLE

	.EXAMPLE

	.OUTPUTS

	.NOTES
		Notes
#>

[cmdletbinding()]            
param(            
 [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]    
 [string[]]$ComputerName = $env:computername,            
 [Parameter(mandatory=$false)][ValidateNotNull()]
 [System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)            
            
Begin {
        $Org_ErrorActionPreference=$ErrorActionPreference
        $ErrorActionPreference="SilentlyContinue "   
        $BaseParam=@{ErrorAction = 'Stop'}
        if($Credential) { $CredentialPASS=$Credential
                          $BaseParam.add('Credential',$CredentialPASS)
                           }
        if($AsJob) { $BaseParam.add('AsJob',$true)}   
    }            
            
Process {     
try{
    Write-host   "Please wait, attempting to get WMI object from $ComputerName : "
    $profiles = Get-WmiObject -Class Win32_UserProfile -Computer $ComputerName @BaseParam | Where-Object {!$_.Special}
    $DI_obj = Get-WmiObject -Class win32_logicaldisk -Filter drivetype='3' -Computer $ComputerName @BaseParam 
    write-host "WMIs objectes loaded. Done!"
}
catch{
    Write-Error "Failed to get WMI from the remote computer ($ComputerName) . "
    Write-Warning "Check if the computer is online and if you do have Admin rights on the computer."
}
$Profile_Group=@()
    $id=0

foreach ($p in $profiles){ #load all user profiles on the target computer
       $objSID = New-Object System.Security.Principal.SecurityIdentifier($p.sid)
   
       $objuser = $objSID.Translate([System.Security.Principal.NTAccount])            
       $UserName = $objuser.value.split("\")[1]
         if(!$UserName){$UserName="N/A"}
      # $USERNAME=$objuser.value
       $UserDir = $p.LocalPath
       if($p.LastUseTime -ne $null) { 
            $Lastuse = $p.ConvertToDateTime($p.LastUseTime)
          }
         $obj = New-Object psobject
         Add-Member  -InputObject $obj -MemberType NoteProperty -Name ID -Value $id 
         Add-Member  -InputObject $obj -MemberType NoteProperty -Name SID -Value $p.sid 
         Add-Member  -InputObject $obj -MemberType NoteProperty -Name UserName -Value $UserName
         Add-Member  -InputObject $obj -MemberType NoteProperty -Name UserDir -Value $UserDir 
         Add-Member  -InputObject $obj -MemberType NoteProperty -Name LastUse -Value $Lastuse 
       $Profile_Group+=$obj
        $id++
}

#$fordel=New-Object System.Collections.ArrayList  #for deletion
if (!$Profile_Group){
   write-error "NO Profile found, will quite the script!!"
   pause
   exit
}
   $InputKeys=$null
    while(($InputKeys -ne 'x') -or ($InputKeys -ne 'X')){
        #Start-Sleep -s 2
        clear 
        Write-Host "ComputerName     :`t$computername"
        Write-Host "storage summary as bellow:"
        foreach($d in $DI_obj){
            "`tDriveID`t :{0:3}" -f $($d.DeviceID)
            "`tFreeSpace:{0:n2}GB" -f $($d.FreeSpace/1GB)
            "`tTotalSize:{0:n2}GB" -f $($d.Size/1GB)
           write-host "`t---"  
        }
        Write-Host  
        Write-Host  "User prifiles at $computername listed as follow:"
        Write-Host  
        
        #   Write-Host -object $Profile_Group 
      "{0,-3}`t{1,-25}`t{2,-35}`t`t{3:20}" -f "ID","UserName","Profile Dir","Last Logon"
      "{0,-3}`t{1,-25}`t{2,-35}`t`t{3:20}" -f "==","==========","============","============"
        foreach($u in $Profile_Group){
          "{0,-3}`t{1,-25}`t{2,-35}`t`t{3:hh:mm   dd-MM-yyyy}" -f $u.id,$u.UserName,$u.UserDir,$u.Lastuse
        }
        write-host
        write-host "Please enter the ID number for deletion.  'r' to refesh data from $computername ."
        write-host "For mutiple selection, please separate IDs with ',', for example: 1,2,3,4 "
        
        
        $InputKeys = read-host " 'X' to quite"

         if(($inputKeys -eq 'r') -or ($inputKeys -eq 'R')){
              #Refresh all WMIs
               try{
                    cls
                    Write-host   "       Please wait, refreshing data from $ComputerName : "
                    $profiles = Get-WmiObject -Class Win32_UserProfile -Computer $ComputerName @BaseParam | Where-Object {!$_.Special}
                    $DI_obj = Get-WmiObject -Class win32_logicaldisk -Filter drivetype='3' -Computer $ComputerName @BaseParam 
                    write-host "WMIs objectes loaded. Done!"
                    PAUSE
                    continue
                }
                catch{
                    Write-Error "Failed to get WMI from the remote computer ($ComputerName) . "
                    Write-Warning "Check if the computer is online and if you do have Admin rights on the computer."
                }


            }

        if ($InputKeys) {$inputArray=$InputKeys.Split(',')}
        $validKey=$true
           
        foreach ($in in $InputArray) {# check input 
                   if (($in -lt 0 ) -or ($in -gt $Profile_Group.count)){
                    write-error "$in is not valid ID number,please check and try agin" 
                    $validKey=$false
                    }
         }
         $OP_Group=$Profile_Group
        if(($validKey) -and ($inputArray)){
           #delete the profiles selected
           #Display remained user profiles again
             foreach ($item in $InputArray) {
                 write-host "Deleting profile ID:  $item .  !"
                    ($profiles | Where-Object{$_.SID -eq $Profile_Group[$($item)].sid}).delete()
                     if ($?){
                        Write-Host "$($Profile_Group[$($itme)].Username) deleted successfully on $ComputerName. ^_^"            
                        # pop out the object from $Profile_Group when ID=ITEM  
                         $OP_Group = $OP_Group | where-object{$_.ID -ne $item}
                           }
                     else{
                       Write-Warning "Failed to delete the profile, $($Profile_Group[$($item)].Username) on $ComputerName"    
                       Write-Warning "Please check if the user is still logged on, or you donot have right to delete the profile."        
                          }
                  }
 
          }
         elseif((-not $validKey) -and (($inputarray -ne 'x') -or ($inputarray -ne 'X' ) ))
           {
              Write-Warning "Invalid ID entered, try again!"
              pause
            }
         $Profile_Group=$OP_Group   
         
         sleep 3s 
     }#end while 


}

end{
  $ErrorActionPreference =$Org_ErrorActionPreference     
}

}
function restart-servers{
<#
	.SYNOPSIS

	.DESCRIPTION

	.PARAMETER Port

	.PARAMETER Server

	.EXAMPLE

	.EXAMPLE

	.OUTPUTS

	.NOTES
		Notes
#>

[cmdletbinding()]            
param(            
 [Parameter(
           Mandatory=$false,
           Position=0,
           ValueFromPipeline=$true,
           ValueFromPipelineByPropertyName=$true)]            
           [String[]]$ComputerName="localhost",           
 [Parameter(mandatory=$false)][ValidateNotNull()]
 [System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)

Begin {
        $Org_ErrorActionPreference=$ErrorActionPreference
        $ErrorActionPreference="SilentlyContinue "   
        $BaseParam=@{ErrorAction = 'Stop'}
        if($Credential) { $CredentialPASS=$Credential
                          $BaseParam.add('Credential',$CredentialPASS)
                           }
        if($AsJob) { $BaseParam.add('AsJob',$true)}   
    }            
            
Process {   
        Get-WmiObject win32_operatingsystem  | select csname, @{LABEL=’LastBootUpTime’;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}
End{

}

}
#region Invoke-CMCActions
FUNCTION Invoke-CMCActions{
param ( [Parameter(
           Mandatory=$true,
           Position=0,
           ValueFromPipeline=$true,
           ValueFromPipelineByPropertyName=$true)]            
           [String[]]$ComputerName="localhost",
           [Parameter(mandatory=$false)][ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,
           [Parameter(Mandatory = $true)] 
            [ValidateSet('MachinePolicy', 
            'DiscoveryData', 
            'ComplianceEvaluation', 
            'AppDeployment',  
            'HardwareInventory', 
            'UpdateDeployment', 
            'UpdateScan', 
            'SoftwareInventory')] 
            [string]$ClientAction, 
            [Parameter()] 
            [switch]$AsJob,
            [switch]$log
             )
BEGIN{
    # Setting varalbes
    $Results= @() # returned result, output
    $LogSring=""
    $LogfileName="CMActionslog.txt"
    $LogFileHeader="
                  ************************************************************************`r
                  *  CMActions :   Sending Actions to SCCM Client site                   *`r
                  *  Written By:   Leo Li       09/09/2016                               *`r
                  *  Version   :   V0.01                                                 *`r
                  *  Support   :   support@itengineer.com.au                             *`r
                  ************************************************************************`rn"
       
    $LogNewLine="-------------------|-|-|-|-|-> Start Line <-|-|-|-|-|--------------------`rn   
    "
    # write-LogFile -logfile $LogfileName -logstring $LogFileHeader
        try { 
            $ScheduleIDMappings = @{ 
                'MachinePolicy' = '{00000000-0000-0000-0000-000000000021}'; 
                'DiscoveryData' = '{00000000-0000-0000-0000-000000000003}'; 
                'ComplianceEvaluation' = '{00000000-0000-0000-0000-000000000071}'; 
                'AppDeployment' = '{00000000-0000-0000-0000-000000000121}'; 
                'HardwareInventory' = '{00000000-0000-0000-0000-000000000001}'; 
                'UpdateDeployment' = '{00000000-0000-0000-0000-000000000108}'; 
                'UpdateScan' = '{00000000-0000-0000-0000-000000000113}'; 
                'SoftwareInventory' = '{00000000-0000-0000-0000-000000000002}'; 
            } 
            $ScheduleID = $ScheduleIDMappings[$ClientAction] 
        } catch { 
            Write-Error $_.Exception.Message 
        } 

if($log){
         $path = [System.IO.Path]::Combine( $env:HOMEPATH,"PSlog\$LogFileName")
         $mode = [System.IO.FileMode]::Append
         $access = [System.IO.FileAccess]::Write
         $sharing = [IO.FileShare]::Read
         $fs = New-Object IO.FileStream($path, $mode, $access, $sharing)
         $script:LogFileObj = New-Object System.IO.StreamWriter($fs)

         $LogScriptInfoObj=Get-Item (join-path $env:HOMEPATH "PSlog\$LogFileName") -ErrorAction SilentlyContinue    
         if(-not $LogScriptInfoObj){
           try{
                   Write-Verbose "Created $LogFileName. "
                  $script:LogFileObj.writeline("$LogFileHeader`n")
                  }
               catch{
                  Write-Verbose "Failed to create $Fun_LogFileName !"
                 $script:LogFileObj=$null
                  }
               Finally
                    {  }
            }
            else {
                  $script:LogFileObj.writeline("$LogNewLine")
        
            }
              
  }


}

PROCESS{

    foreach ($computer in $ComputerName){
    if (-not (test-connection $computer -Quiet)){
        write-verbose "The computer $computer is NOT online!"
        write-logfile -logfileobj $script:LogFileObj -logstr "The computer $computer is NOT online!"
        break}
    else{
      Write-Output $computer
      write-logfile -logfileobj ($script:LogFileObj) -logstr "The computer $computer is  online!"

    }    

    }
}
END{
     #close logfile.
     if ($script:LogFileObj){
       $script:LogFileObj.Flush()
       $script:LogFileObj.Close()
       $script:LogFileObj.Dispose()
}
}

}

#endregion 

function start-MultiJobs {#V1
[cmdletBinding()]
Param(
[Parameter(Mandatory=$true,Position=0)]$FilePath,
[Parameter(Mandatory=$true)][System.Collections.ArrayList]$jobslist, #used to build up the jobs,and will pass to the script as arg[0]
$maxJobs = 10,
$JobPrefix = "MultiJobs_",
$Args
)

BEGIN{


if (get-job |? {$_.name -like "$JobPrefix*"}) {#Remove OLD jobs if any
   $jobs = get-job |? {$_.name -like "$JobPrefix*"}
   $jobs | Stop-Job
   $jobs | Remove-Job
   Write-Verbose "Old jobs found and removed"
}
$jobsToRun = @()
$jobsRunning = @()
$jobsFinished = @()

Write-Verbose "Creating Background jobs" 

Foreach( $j in $Jobslist ){ #setup multijobs, replace your details here based on your case
   Write-Verbose " created: $j "

  $ts= New-Object PSObject -Property @{
        outFile  = $TmpOutFileLocation +($f.info)+".csv"
        jobName  = ($JobPrefix+$j)
        filepath = $FilePath # scriptblock file location
   }


   if($Args){ 
               $ts| Add-Member -MemberType NoteProperty  -Name Args -Value "$j,$Args"
                             
               }   

     else
               {
                  $ts | Add-Member -MemberType NoteProperty  -Name Args -Value "$j"
                                             
               }


  $jobsToRun += $ts
}

Write-Verbose "Background jobs created.!"

}
Process{
$results = @()
do {
   $jobs = @()
   $jobs = @(get-job |? {$_.name -like "$JobPrefix*"})
   foreach($job in $jobs){
       if ($job.state -eq "completed"){
           $j = $jobsRunning | Where{$_.jobName -eq $job.Name}

          if($job.HasMoreData) { $results += receive-Job -job $job} #output file, import the result.
           #Process this job as it's done.
           Write-Verbose "-----> Job $($jobsToRun[0].jobName) Completed"              
           Remove-Job $job
           $jobsRunning[[array]::IndexOf($jobsRunning,$j)] = $null
           $jobsRunning = @($jobsRunning | Where{$_ -ne $null})
       }
       if ($job.state -eq "failed"){ #failed jobs do something here
           $j = $jobsRunning | Where{$_.jobName -eq $job.Name}
           Write-verbose " '--> Job" ($j.jobName) "Failed"              
           Remove-Job $job
           $jobsRunning[[array]::IndexOf($jobsRunning,$j)] = $null
           $jobsRunning = $jobsRunning | Where{$_ -ne $null}            
       }
   }
   while(($jobsToRun.count -gt 0) -and ( $jobs.count -lt $maxJobs)){ #within max threading, kick in new jobs.
       $i=0
       $jobsRunning += $jobsToRun[0]            
      # Write-Verbose "-----> Job $($jobsToRun[0].jobName) Starting"              
       Start-Job -Name $jobsToRun[0].jobName `
           -filepath $jobsToRun[0].filepath `
           -ArgumentList $jobsToRun[0].args | Out-Null
   
       Write-Verbose "-----> Job $($jobsToRun[0].jobName) Started"              
       $jobsToRun[0] = $null
       $jobsToRun = @($jobsToRun | Where{$_ -ne $null})
       $jobs = @(get-job |? {$_.name -like "$JobPrefix*"})
       Start-Sleep -Seconds 5
   }
   Start-Sleep -Seconds 15
} while(($jobsToRun.count -gt 0) -or ($jobsRunning.count -gt 0)) 



}
END{

Write-Output $results
}


}

function start-multiRunspaces #v2
{
[cmdletBinding()]
<#
version: 1.0

#>
Param(
[Parameter(Mandatory=$true,Position=0)]$Scriptblock, #script used for backgroud job
[Parameter(Mandatory=$true)]$jobslist, #used to build up the jobs,and will pass to the script as $args[0]
$MaxThreads = 10,
$JobSleepTimer= 60,
$BufferSleepTime=1,
[switch]$outputResults=$false, #default only do the scriptblock, NO output.
$Args  #more variable can be parsed to $scriptblock.
)
BEGIN{
$ParaHash=@{
		MaxThreads = $MaxThreads
		SleepTimer = $JobSleepTimer
			}
$result =@()  # write-output result, final
$Jobs = @() #All runspace jobs
$CurrentJobI=0  # current job number, or index of Joblists
$jobsrunningCount=0

$ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $ISS,$Host)
$RunspacePool.Open()

$jobscompleted = $jobsrunning=@()
$jobsFailed = @()


}
PROCESS{
   $Vtime=Get-Date
   Write-Verbose "<- $($vtime.ToString()) ->    Starting to create runspaces pool..."
#$i=0
do{
     #$Vtime=Get-Date
     #write-verbose "<- $($vtime.ToString()) ->  Jobs running in the pool is $jobsrunningCount, Current Job Index is $CurrentJobI"
     while (($jobsrunningCount -lt $MaxThreads) -and ($CurrentJobI -lt $jobslist.count)){  
            #invoke new runspaces when running jobs less than max and current job index less than total jobs.
            $PowershellThread = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($jobslist[$CurrentJobI])
             <#foreach($k in $ParaHash.Keys){
                         $PowershellThread.AddParameter($k,$ParaHash.$k) | Out-Null
                           } #>
	         # Specify runspace to use to run concurrent and simualtaneous sessions
	        $PowershellThread.RunspacePool = $RunspacePool
	        # Create Runspace collection to define that each Runspace should begin running
	        #$Vtime=Get-Date
           # Write-Verbose "<- $($vtime.ToString()) ->  Creating $($jobslist[$CurrentJobI])..  ."
           #Write-Verbose "$($jobslist[$CurrentJobI]) added to joblists  ."
          $jobs += New-Object -TypeName PSObject -Property @{
		                                      Handle = $PowerShellThread.BeginInvoke()
		                                      Thread  = $PowerShellThread
                                              Jobname =$jobslist[$CurrentJobI]    
	                                } #/New-Object
             
 
              $jobsrunningCount++
              $CurrentJobI++

        } 

     $Vtime=Get-Date
     Write-Verbose "<- $($vtime.ToString()) -> Current running jobs:  $jobsrunningCount;  $CurrentJobI of $($jobslist.count) ."

    $Cjobs=$jobs| Where-Object {$_.Handle.iscompleted -eq $true} 
    if($Cjobs.count -gt 0){
    if($Cjobs.count -eq $jobs.count){
          $jobs=@()
          $jobsrunningCount=0
    }
    else{
       $nJobs = (Compare-Object -ReferenceObject $jobs -DifferenceObject $Cjobs | Where-Object SideIndicator -EQ '<=' ).InputObject
       $jobsrunningCount=$jobs.count - $Cjobs.count

       if($nJobs.count -gt 0){       
       $jobs=@() #Claim as array
       $jobs+=$nJobs|select Handle,Thread,jobname
       }
    }

    if($outputResults -and ($cJobs.count -gt 0 )) { # return results
       $Vtime=Get-Date
       Write-Verbose "<- $($vtime.ToString()) ->  $($jobs.count) jobs running, $($cJobs.count) completed, collecting resutls"

     $cJobs |Foreach-Object{
		      $Vtime=Get-Date
              Write-Verbose "<- $($vtime.ToString()) -> writing $($_.jobname) to result. $($cJobs.count) completed"
                  $runspace_jobs=$_.Thread.EndInvoke($_.Handle)
				  $result+=$runspace_jobs
                  #$_.Thread.Dispose()
                  if(-not $?)
                  {
                         Write-Error " $($_.jobname) failed to be disposed!!!"

                  }
                                              }

     $cJobs.Thread.dispose()
         }
    else{
      $cJobs.Thread.dispose()
          }

}



Start-Sleep -Seconds $JobSleepTimer
#Write-Host "$i"
}while($CurrentJobI -lt $jobslist.count) 





$Vtime=Get-Date

Write-Verbose "<- $($vtime.ToString()) ->  All jobs completed."




}
END{
# Clean up:
   if($result){ write-output $result}
	$RunspacePool.Close() | Out-Null
    $RunspacePool.Dispose() | Out-Null
}
}


function start-multiRunspaces #V1, build Joblist, fire them up, then process the completed Jobs one by one
{ 
[cmdletBinding()]
Param(
[Parameter(Mandatory=$true,Position=0)]$Scriptblock, #script used for backgroud job
[Parameter(Mandatory=$true)]$jobslist, #used to build up the jobs,and will pass to the script as arg[0]
$MaxThreads = 10,
$JobSleepTimer= 60,
$BufferSleepTime=1,
[switch]$outputResults=$false, #default only do the scriptblock, NO output.
$Args
)

BEGIN{
$ParaHash=@{
		MaxThreads = $MaxThreads
		SleepTimer = $JobSleepTimer
			}
<#
if(Test-Path $ScriptPath){
      $scriptBlock = [scriptblock]::Create((Get-content $ScriptPath))
    
}
else{
    Write-Error "Failed to import $ScriptPath, erroring out."
}
#>

$Jobs = @() #All runspace jobs

$ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $ISS,$Host)
$RunspacePool.Open()



$jobscompleted = $jobsrunning=@()
$jobsFailed = @()


}
PROCESS{
$Vtime=Get-Date
Write-Verbose "<- $($vtime.ToString()) ->    Starting to create runspaces pool..."
foreach($j in $jobslist){
# add $i as argument
			$PowershellThread = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($j)
									
             foreach($k in $ParaHash.Keys){
                         $PowershellThread.AddParameter($k,$ParaHash.$k) | Out-Null
                           }
	         # Specify runspace to use to run concurrent and simualtaneous sessions
	        $PowershellThread.RunspacePool = $RunspacePool
                                    
	                                # Create Runspace collection to define that each Runspace should begin running
	         [Collections.Arraylist]$jobs += New-Object -TypeName PSObject -Property `
                                            @{
		                                      Runspace = $PowerShellThread.BeginInvoke()
		                                      Thread  = $PowerShellThread
                                              Jobname =$j     
	                                } #/New-Object
}

$Vtime=Get-Date

Write-Verbose "<- $($vtime.ToString()) ->  $($jobs.count) runspaces created in the runspacepool."




}
END{
$result =@()
while($jobs){  #Collect instance results:
	

$njobs=$jobs| Where-Object {$_.runspace.iscompleted -ne $true} 
$c=$jobs.Count - $njobs.Count

if  ($outputResults) {
$jobs| Where-Object {$_.runspace.iscompleted -eq $true} | ForEach-Object{
					if ($outputResults) {$runspace_jobs=$_.Thread.EndInvoke($_.Runspace)
					                 $result+=$runspace_jobs}
                      $_.Thread.Dispose()

}

}
else{
($jobs| Where-Object {$_.runspace.iscompleted -eq $true}).Thread.dispose()
}

$jobs=$njobs

Start-Sleep -Seconds $JobSleepTimer
$Vtime=Get-Date
write-verbose "<- $($vtime.ToString()) ->  $c runspaces completed"

# Clean up:

}


    write-output $result
	$RunspacePool.Close() | Out-Null
    $RunspacePool.Dispose() | Out-Null


}
}
$test = @(1,2,4,5,7,9,2,40,12,9,2)
$testc = @("c1","c2","c3","c4","c5","c6","c7","c8","c9","c10","c11","c12","c13","c14","c15","c16","c17","c18","c19","c20","c21","c22","c23")

$scripblock={
Write-output $args[0]
 $rnd = Get-Random -Minimum 1 -Maximum 5
    Out-File -FilePath "c:\users\leo\test\test.txt" -Append   -InputObject $args[0]

 Start-Sleep -Seconds $rnd

if($args.count -gt 0){
   foreach($a in $args){
     # write-output $args[$a]
   # Out-File -FilePath "c:\users\leo\test\test.txt" -Append   -InputObject $args[$a]

  }
 }

}
#$a=start-multiRunspaces -Scriptblock $scripblock -jobslist $testc -Verbose -MaxThreads 3 -JobSleepTimer 1

$b=start-MultiJobs -Scriptblock $scripblock -jobslist $testc -Verbose -MaxThreads 3 -JobPrefix "tets" 
$a=start-multiRunspaces -Scriptblock $scripblock -jobslist $testc -Verbose -MaxThreads 4 -outputResults -JobSleepTimer 1
$b = start-MultiJobs -Scriptblock $scripblock -jobslist $testc -Verbose -MaxThreads 3 -JobPrefix "Mytest_" -JobSleepTimer 1
