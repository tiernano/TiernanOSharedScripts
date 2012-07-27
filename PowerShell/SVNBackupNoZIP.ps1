$RepositoryPath = "d:\svn" 
$RepoBackupPath = "d:\svn-backups\"     
$svnAdminexe = "c:\Program Files (x86)\VisualSVN Server\bin\svnadmin"
$DaysToKeepBackups = 7
$tempFolder = "d:\temp\"


function CreateTempDir ([string]$repoName)
{
    #create a dir in the system temp dir for svn to copy the repository into
	#before zipping it
	
	$newDir = "Not Found"
	$timeStamp = Get-Date -uformat "%Y_%m_%d_%H%M%S"
	$backupPath = $RepoBackupPath + $repositoryDir.Name + "_" + $timeStamp
		

    #delete it first if it exists
	if ( [System.IO.Directory]::Exists($backupPath) )
	{ 
		Remove-Item -path $repoTempCopyPath -recurse -force
		##[System.IO.Directory]::Delete($backupPath , $true)
	}

    #then create it
	if( ![System.IO.Directory]::Exists($backupPath)) 
	{ 
		$newDir = [System.IO.Directory]::CreateDirectory($backupPath)
	}
	#"Created Temp Dir: $newDir.FullName"
	$newDir.FullName
}

function RunSVNhotcopy ([string]$repoToCopyPath, [string]$repoTempCopyPath)
{	
	
	$exe = $svnAdminexe
	$param1 = "hotcopy"
	$param2 = "--clean-logs"
	
	& $exe $param1 $repoToCopyPath $repoTempCopyPath $param2 
}


function CleanBackupDirs ([string]$backupPathtoClean, [int]$daysToKeep)
{
	$startTime = Get-Date
	" ... cleaning $backupPathtoClean"
	foreach ($backupFile in Get-ChildItem -Path $backupPathtoClean) 
	{
		if ( $backupFile.Attributes -eq "Directory") 
		{ 
			$y = ((Get-Date) - $backupFile.CreationTime).Days
        	if ($y -gt $daysToKeep)
            {
				" ...... Deleting $backupFile : " + $backupFile.CreationTime			
				Remove-Item -path $backupFile.FullName -recurse -force
			}
			else
			{
				" ...... Keeping $backupFile : " + $backupFile.CreationTime			
			}
		}
	}
	$endTime = Get-Date
	$seconds = ($endTime - $startTime).seconds
	"Time taken for CelanBackupDirs: $seconds"
}

$scriptStartTime = Get-Date
#Loop though each Dir in the repository dir
foreach ($repositoryDir in Get-ChildItem -Path $RepositoryPath) 
{
	# if the item is a directory, then process it.
	if ($repositoryDir.Attributes -eq "Directory")
	{
		$directoryStart = Get-Date
		"$directoryStart Processing Repository: $repositoryDir"
		$tempDir = ""
		" ... Creating Temp Directory"
	        $tempDir = CreateTempDir $repositoryDir.Name
		" ... Running SVN Hotcopy to $tempDir"
		RunSVNhotcopy $repositoryDir.FullName $tempDir
		
		
		# next step is to clean old zipped backups
		if ($DaysToKeepBackups -gt 0)
		{
			CleanBackupDirs $RepoBackupPath $DaysToKeepBackups
		}
		$directoryEnd = Get-Date
		$dirTimeSec = ($directoryEnd - $directoryStart).Seconds
		"Time taken to backup $repositoryDir : $dirTimeSec"
	}

}
$scriptEndTime = Get-Date
$scriptSeconds = ($scriptEndTime - $scriptStartTime).Seconds
"Time taken for script to run: $scriptSeconds"


"*******************************************************"
"* END: All SVN Repositories Archived"
"*******************************************************"

Exit(0)