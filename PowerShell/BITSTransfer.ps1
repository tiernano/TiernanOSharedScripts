$file = "https://github.com/tiernano/TiernanOSharedScripts/zipball/master"
$dest = "c:\temp\"
$job = Start-BitsTransfer -Source $file -Destination $dest -Asynchronous
while( ($job.JobState.ToString() -eq 'Transferring') -or ($job.JobState.ToString() -eq 'Connecting') )
{
    ($job.BytesTransferred / $job.BytesTotal) * 100
    Sleep 3
}

if($job.JobState.ToString() -eq 'Transferred')
{
    Complete-BitsTransfer $job
}