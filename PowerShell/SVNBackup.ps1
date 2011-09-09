## Original code for this was taken from CodeProject (http://www.codeproject.com/KB/powershell/SVNBackupPower.aspx) 
## written by TexasMensch. I needed to do some tweaks, and added the timing parts. 
## Next task is to add 7zip compression and maybe some logging of some sort.

$RepositoryPath = "d:\svn\" #your SVN folder
$RepoBackupPath = "d:\svn-backups\"  # where you want files backed up
$svnAdminexe = "c:\Program Files (x86)\VisualSVN Server\bin\svnadmin" # location of SVN Admin
$DaysToKeepBackups = 7 # Days you want files kept


function CreateTempDir ([string]$repoName)
{
    
	$newDir = "Not Found"
	
	$repoTempCopyPath = "D:\temp\" + $repoName #creating temp folder on since it has more free space than C

    #delete it first if it exists
	if ( [System.IO.Directory]::Exists($repoTempCopyPath) )
	{ 
		Remove-Item -path $repoTempCopyPath -recurse -force
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
	if (-not $_zipName.EndsWith(".zip")) {$_zipName += ".zip"} 

    #make sure directory to zip exists
	if (test-path $_dirToZip)
	{
    	#make sure zip file doesnt already exist
		if (-not (test-path $_zipName)) 
		{ 
			set-content $_zipName ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18)) 
			(dir $_zipName).IsReadOnly = $false   
								
			#create zip file object    
			$_zipName = (new-object -com shell.application).NameSpace($_zipName);
		
			#Zippy Long stockings
			$_zipName.copyHere($_dirToZip);
			
			#the copyHere function is asyncronous so we need to check the file count
			#to see when its done. Since we are compressing a Directory the count will be 1
			#when its done. If you zip one file at a time then the count will the number files
			# zipped 
		
			do {
					$zipCount = $_zipName.Items().count
			 		"Waiting for compression to complete ..."
					Start-sleep -Seconds 2
			   }
			While($_zipName.Items().count -lt 1)
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
		$zipNamePath = $newBackupPath + $repositoryDir.Name + "_" + $timeStamp + ".zip"
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
	$scriptEndTime = Get-Date
	$scriptSeconds = ($scriptEndTime - $scriptStartTime).Seconds
	"Time taken for script to run: $scriptSeconds"
}

#Wait to make sure every zip completes compressing. This is important if you schedule this 
# to run as a windows task
Start-sleep -Seconds 5 

"*******************************************************"
"* END: All SVN Repositories Archived"
"*******************************************************"

Exit(0)