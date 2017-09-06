 <#.SYNOPSIS
    start multiple runspacepool, controls multithreding script block. 
    .DESCRIPTION
    Multithreading scripts, can setup MAX number of threads with or without return results.
    High performance than background jobs, avoided iterating through groups HUGH performance increase.
    .PARAMETER jobslist
       The jobs list/task will be run.
       This is the target, or the list of mutiple threading will kick in based on.Also, this is the first args/$args[0]
       will be parsed to the scriptblock/scriptpath.
    .PARAMETER ScriptBlock
       The commands to run.
       Enclose the commands in curly braces { } to create a script block.
       This parameter is required.
    .PARAMETER ScriptPath
       Enter the path and file name of the script, it converts the contents of the specified script
       file to a script block, transmits the script block to the remote computer, and runs it
       on the remote computer.
     .PARAMETER outputResults
       Will return/output results or not.
       By default it's off.
     .PARAMETER MaxThreads
       Maximum threads will run concurently, default is 10
     .PARAMETER JobSleepTimer
       How many seconds until next loop to add more threads.
     .PARAMETER ArgHash
       By default, jobslist will be parsed to scriptblock, however, extra hashtable can be parsed to scriptblock
       as parameters of the scriptblock running in the mutiple threads.
     
     Example 1
      $testc = @("c1","c2","c3","c4","c5","c6","c7","c8","c9","c10","c11","c12","c13","c14","c15","c16","c17","c18","c19","c20","c21","c22","c23")
      $ParaHash=@{
                a1 = "a1"
                a2 = "a2"
			        }

      $scripblock={
           write-output $args[0]
         #mkdir "c:\users\leo\test\$($args[0])"
         $rnd = Get-Random -Minimum 1 -Maximum 15
         Start-Sleep -Seconds $rnd
          } 

    $a=start-multiRunspaces -Scriptblock $scripblock -jobslist $testc -Verbose -MaxThreads 4 -outputResults -JobSleepTimer 1
    Example 2

     start-multirunspace.ps1 -ScriptPath C:\powershell\task1.ps1 -jobslist $testc -Verbose -MaxThreads 300 -JobSleepTimer 1 -outputResults -ArgHash $ParaHash


 #>
[cmdletBinding()]
Param(
[parameter(ParameterSetName = 'ScriptBlock')]
[ScriptBlock]$ScriptBlock,
[string]$ScriptPath,
[Parameter(Mandatory=$true)]$jobslist, #used to build up the jobs,and will pass to the script as $args[0]
$MaxThreads = 10,
$JobSleepTimer= 30,
$BufferSleepTime=1,
[switch]$outputResults=$false, #default only do the scriptblock, NO output.
[System.Collections.Hashtable]$ArgHash  #more variable can be parsed to $scriptblock.
)
BEGIN{
$ParaHash=@{
		MaxThreads = $MaxThreads
		SleepTimer = $JobSleepTimer
			}
if($ArgHash){
        foreach ($a in $ArgHash.Keys){
               $ParaHash.add($a,$ArgHash.$a)
        }
}

###---$result =@()  # write-output result, final
$Jobs = @() #All runspace jobs
$CurrentJobI=0  # current job number, or index of Joblists
$jobsrunningCount=0

$ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $ISS,$Host)
$RunspacePool.Open()

$Alljobscompleted = $jobsrunning = $ThisCompletedJobs = @()
$jobsFailed = @()


}
PROCESS{
   $Vtime=Get-Date
   Write-Verbose "<- $($vtime.ToString()) ->    Starting to create runspaces pool..."
#$i=0
do{
     while (($jobsrunningCount -lt $MaxThreads) -and ($CurrentJobI -lt $jobslist.count)){  
            #invoke new runspaces when running jobs less than max and current job index less than total jobs.
            $PowershellThread = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($jobslist[$CurrentJobI])
             foreach($k in $ParaHash.Keys){
                         $PowershellThread.AddParameter($k,$ParaHash.$k) | Out-Null
                           }
	         # Specify runspace to use to run concurrent and simualtaneous sessions
	        $PowershellThread.RunspacePool = $RunspacePool
	        # Create Runspace collection to define that each Runspace should begin running
    if($outputResults){
          $Object = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
          $jobs += New-Object -TypeName PSObject -Property @{
		                                      Handle = $PowerShellThread.BeginInvoke($Object,$Object)
		                                      Thread  = $PowerShellThread
                                              result =$Object   
	                                } #/New-Object
              $jobsrunningCount++
              $CurrentJobI++
    }    
       else
      { 
          $jobs += New-Object -TypeName PSObject -Property @{
		                                      Handle = $PowerShellThread.BeginInvoke()
		                                      Thread  = $PowerShellThread
	                                } #/New-Object
              $jobsrunningCount++
              $CurrentJobI++
        
        }
        } 
     $cjobs=$jobs| Where-Object {$_.Handle.iscompleted -eq $true}
     if($cjobs.count -gt 0){
         if ($Alljobscompleted.count -eq 0 ){
             $ThisCompletedJobs = $cjobs
         }
         else{
            $ThisCompletedJobs= (Compare-Object -ReferenceObject $cjobs  -DifferenceObject $Alljobscompleted | Where-Object SideIndicator -EQ '<=').InputObject
          }
         if($ThisCompletedJobs.handle.count -gt 0){
             $Alljobscompleted+=$ThisCompletedJobs
             $ThisCompletedJobs.Thread.dispose()
             $jobsrunningCount=$jobsrunningCount-$ThisCompletedJobs.handle.count
          }
  
      } 
  

Start-Sleep -Seconds $JobSleepTimer
     $Vtime=Get-Date
     Write-Verbose "<- $($vtime.ToString()) -> Current running jobs: $jobsrunningCount;  $($Alljobscompleted.count) / $($jobslist.count) ."

}while(($CurrentJobI -lt $jobslist.count) -or ($jobsrunningCount-gt 0))



$Vtime=Get-Date

Write-Verbose "<- $($vtime.ToString()) ->  All jobs completed."

}
END{
# Clean up:
  if($outputResults){
  write-output $jobs.result
   }
	$RunspacePool.Close() | Out-Null
    $RunspacePool.Dispose() | Out-Null
}
