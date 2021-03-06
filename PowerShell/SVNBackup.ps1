$RepositoryPath = "d:\svn\" 
$RepoBackupPath = "d:\svn-backups\"     
$svnAdminexe = "c:\Program Files (x86)\VisualSVN Server\bin\svnadmin"
$DaysToKeepBackups = 7
$7zipexe = "d:\svn\7za.exe"
$tempFolder = "d:\temp\"


function CreateTempDir ([string]$repoName)
{
    #create a dir in the system temp dir for svn to copy the repository into
	#before zipping it
	
	$newDir = "Not Found"
	
	$repoTempCopyPath = $tempFolder + $repoName

    #delete it first if it exists
	if ( [System.IO.Directory]::Exists($repoTempCopyPath) )
	{ 
		Remove-Item -path $repoTempCopyPath -recurse -force
		##[System.IO.Directory]::Delete($repoTempCopyPath, $true)
	}

    #then create it
	if( ![System.IO.Directory]::Exists($repoTempCopyPath)) 
	{ 
		$newDir = [System.IO.Directory]::CreateDirectory($repoTempCopyPath)
	}
	
	$newDir.FullName
}

function RunSVNhotcopy ([string]$repoToCopyPath, [string]$repoTempCopyPath)
{	
	
	$exe = $svnAdminexe
	$param1 = "hotcopy"
	$param2 = "--clean-logs"
	
	& $exe $param1 $repoToCopyPath $repoTempCopyPath $param2 
}

function ZipDir ([string]$_dirToZip, [object]$_zipName)
{
    $startDate = Get-Date
    #add zip extension if not present
	if (-not $_zipName.EndsWith(".7z")) {$_zipName += ".7z"} 

    #make sure directory to zip exists
	if (test-path $_dirToZip)
	{
    	#make sure zip file doesnt already exist
		if (-not (test-path $_zipName)) 
		{ 
			$param = "a"
			& $7zipexe $param $_zipName $_dirToZip
		}
	}
	else 
	{
		"ERROR: Path does not exist -- $_dirToZip"
	}
    $endDate = Get-Date
    $seconds = ($endDate - $startDate).Seconds
    "time taken for zipDir: $seconds"
}

function CleanBackupDirs ([string]$backupPathtoClean, [int]$daysToKeep)
{
	$startTime = Get-Date
	" ... cleaning $backupPathtoClean"
	foreach ($backupFile in Get-ChildItem -Path $backupPathtoClean) 
	{
		if ( Test-Path $backupFile.FullName )
		{ 
			$y = ((Get-Date) - $backupFile.CreationTime).Days
        	if ($y -gt $daysToKeep -and $backupFile.PsISContainer -ne $True)
            {
				" ...... Deleting $backupFile : " + $backupFile.CreationTime			
				$backupFile.Delete()
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
		" ... Running SVN Hotcopy"
		RunSVNhotcopy $repositoryDir.FullName $tempDir
		
		$newBackupPath = ""
		# Create a Folder in the backup path for each repository if needed
		if($RepoBackupPath.EndsWith("\"))
		{
			$newBackupPath = $RepoBackupPath + $repositoryDir.Name	
		}
		else
		{
			$newBackupPath = $RepoBackupPath + "\" + $repositoryDir.Name	
		}
		if( ![System.IO.Directory]::Exists($newBackupPath)) 
		{ 
			" ... Creating Backup Directory $newBackupPath"
			[System.IO.Directory]::CreateDirectory($newBackupPath)
		}
		if(!$newBackupPath.EndsWith("\")){$newBackupPath = $newBackupPath + "\"}
		
		# Zip the the backup into a zip file with datetime stamp
		$timeStamp = Get-Date -uformat "%Y_%m_%d_%H%M%S"
		$zipNamePath = $newBackupPath + $repositoryDir.Name + "_" + $timeStamp + ".7z"
		" ... Zipping Repository Backup to $zipNamePath"
		ZipDir $tempDir $zipNamePath 
		
		# next step is to clean old zipped backups
		if ($DaysToKeepBackups -gt 0)
		{
			CleanBackupDirs $newBackupPath $DaysToKeepBackups
		}
		$directoryEnd = Get-Date
		$dirTimeSec = ($directoryEnd - $directoryStart).Seconds
		"Time taken to backup $repositoryDir : $dirTimeSec"
	}

}
$scriptEndTime = Get-Date
$scriptSeconds = ($scriptEndTime - $scriptStartTime).Seconds
"Time taken for script to run: $scriptSeconds"
#Wait to make sure every zip completes compressing. This is important if you schedule this 
# to run as a windows task
Start-sleep -Seconds 5 

"*******************************************************"
"* END: All SVN Repositories Archived"
"*******************************************************"

Exit(0)