[cmdletBinding()]

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
             <#foreach($k in $ParaHash.Keys){
                         $PowershellThread.AddParameter($k,$ParaHash.$k) | Out-Null
                           } #>
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
