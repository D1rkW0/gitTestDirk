@echo off
echo.
echo ================= CreateHashAndCopy =================
if %1.==--help. goto Help
if %1.==-h.     goto Help
if %1.==--?.    goto Help
if %1.==-?.     goto Help
if %1.==/help.  goto Help
if %1.==/?.     goto Help
goto Initialize

:Help
echo Author:  Dirk Wolff, EKHC IWSP Technical Advisor
echo Version: 1.0   ---   Date: 2014-07-09
echo.
echo Usage:   CreateHashAndCopy [HashAlgorithm] [SourceFolder] [TargetFolder]
echo.
REM            Arg1 = %1,  Arg2 = %2,  Arg3 = %3 (for usage in this batch script)
echo Command Line Arguments expected: 
echo   [HashAlgorithm]    (optional: default=MD5)
echo     .. Hash-Algorithm according to FSUM options (but without "-") and 
echo        without Quotes ("md5").     Examples:  MD5 / SHA256 / SHA1
rem         (optional: if empty [""] or environment variable %hash% is not set, MD5 algorithm is used)
echo.
echo   [SourceFolder]     (optional: default=current folder)
echo     .. Source Folder (for which Checksums/Hashes should be created and saved in
echo        Checksums-File
echo.
echo   [TargetFolder]     (optional: if not given, files/folders will not be copied)
echo     .. Target/Destination Folder (into which files should be copied and 
echo        crosschecked for correctness)
echo.
echo Notes: - Optional arguments must be given as empty strings [""], if other 
echo          arguments follow.  
echo        - If Source/Target Folders contain spaces, add quotation marks [".."] 
echo          around them.
echo.
echo Requirements:
echo Script must be started from a folder, which contains fsum.exe, or the path to fsum.exe must be included in the global PATH variable.
echo.
goto End

:Initialize
REM Prepend path to fsum.exe to current environment (path variable) - works if started with fsum being in current folder
IF EXIST "%cd%\fsum.exe" set path=%cd%;%path%
fsum 2>NUL
if ERRORLEVEL 0 goto ReadHashAlgorithm

REM fsum.exe is not found in path or current directory, so try to locate it elsewhere:
IF EXIST "C:\Backup\fsum-program\fsum.exe" set path=C:\Backup\fsum-program;%path%
IF EXIST "%CD:~0,2%\fsum-program\fsum.exe" set path=%CD:~0,%\fsum-program;%path%
:: maybe add other options, where fsum.exe could be found
fsum 2>NUL
if ERRORLEVEL 0 goto ReadHashAlgorithm
echo Error: fsum.exe cannot be found in the system search path (%%path%%) or current
echo directory, but is needed for creating checksums/hashes.    Exiting Script...
goto End

:ReadHashAlgorithm
REM Read [HashAlgorithm] (Arg1) or set default value:
IF NOT DEFINED hash set hash=MD5
if %1.==.   goto CheckSourceFolder
if %1.=="". goto CheckSourceFolder
:: Argument1 [HashAlgorithm] is not empty, so use it:
set hash=%~1

:CheckSourceFolder
REM Check existance of Source Folder:
echo   Hash-Algorithm: %hash%
if %2.==.   goto HiddenFiles
if %2.=="". goto HiddenFiles
if EXIST %2 goto SwitchToSourceFolder
echo   Error: Source Folder %2 does not exist. Files cannot be checked.
echo   Exiting Script...
goto End

:SwitchToSourceFolder
REM Change Drive+Directory to match Source Folder (which is to check).
cd /D %2

:HiddenFiles
REM Create a list of hidden files and folders (to see if anything needs to be included)
echo   Source Folder:  %cd%
echo   1) Creating list of hidden+system files...  (please wait)
IF EXIST _HiddenAndSystemFiles.txt    del _HiddenAndSystemFiles.txt
IF EXIST _No_HiddenAndSystemFiles.txt del _No_HiddenAndSystemFiles.txt
echo ; List of Hidden+System files in folder:   *%cd%> _HiddenAndSystemFiles.txt
:: dir  /A:HS /S    >> _HiddenAndSystemFiles.txt 2>NUL
dir     /A:HS /S /B >> _HiddenAndSystemFiles.txt 2>NUL
::      /A:HS    Attributes: H..hidden, S..System Files
::      /S       Displays files in specified directory and all subdirectories.
::      /R       Display alternate data streams of the file. [Invalid option under WinXP !]
::      /B       Uses bare format (no heading information or summary).
if ERRORLEVEL 1 ( echo ; *** No hidden or system files found.>> _HiddenAndSystemFiles.txt ) ELSE goto DeleteOldHashfile
ren _HiddenAndSystemFiles.txt _No_HiddenAndSystemFiles.txt

:DeleteOldHashfile
IF EXIST "_Checksums_%hash%.md5.txt" del "_Checksums_%hash%.md5.txt"
IF EXIST "_Checksums_%hash%.md5.txt" goto DeleteOldHashfile

:CreateHashes
echo   2) Creating Checksums/Hashes of all files in source folder... (please wait)
REM insert current path into new document
echo ; CurrentPath: 		*%cd%> "_Checksums_%hash%.md5.txt"
echo ; StartTime:   		*%date% %time%>> "_Checksums_%hash%.md5.txt"
echo ; >> "_Checksums_%hash%.md5.txt"
REM create checksums and save them in file: "_Checksums_%hash%.md5.txt"
fsum -%hash% -r *.* >> "_Checksums_%hash%.md5.txt" 2>NUL
echo ; >> "_Checksums_%hash%.md5.txt"
echo ; EndTime:     		*%date% %time%>> "_Checksums_%hash%.md5.txt"

:CheckTargetFolder
REM Source folder = current folder (from argument %1)
REM Target folder = given in argument %2  (if empty, CopyingFiles will be skipped)
if %3.==.   goto End
if %3.=="". goto End
if EXIST %3 goto CopyingFiles
REM Try to create target folder:
md %3
if EXIST %3 goto CopyingFiles
echo   Error: Target Folder %3 does not exist. Files cannot be copied.
goto End

:CopyingFiles
echo   3) Now copying files...  (please wait)
:: echo   Source Folder:  %cd%
echo   Destination:    %3
xcopy    *.* %3 /S /V /C /G    /K    /Y > _xcopy.log 2>NUL
:: xcopy *.* %3 /S /V /C /G    /K /O /Y > _xcopy.log 2>NUL
:: xcopy *.* %3 /E /V /C /G /H /K /O /Y > _xcopy.log 2>NUL
REM copy logfile:
xcopy    _xcopy.log %3 /C /G    /K    /Y >NUL 2>NUL
REM Arguments explained:
::  /S           Copies directories and subdirectories except empty ones.
::  /E           Copies directories and subdirectories, including empty ones.
::               Same as /S /E. May be used to modify /T.
::  /V           Verifies the size of each new file.
::  /C           Continues copying even if errors occur.
::  /G           Allows the copying of encrypted files to destination that does
::               not support encryption.
::  /H           Copies hidden and system files also.
::  /K           Copies attributes. Normal Xcopy will reset read-only attributes.
::  /O           Copies file ownership and ACL information.
::  /Y           Suppresses prompting to confirm you want to overwrite an
::               existing destination file.

:VerifyingFiles
echo Change Drive+Directory to match Target/Destination Folder (for checking copied files).
echo.
cd /D %3
echo   4) Verifying copied files...  (please wait)
fsum.exe -c     "_Checksums_%hash%.md5.txt" > _FileCrosscheck.txt 2>NUL
::  report only failed files:
::  fsum.exe -c -jf "_Checksums_%hash%.md5.txt" > _FileCrosscheck.txt 2>NUL
if ERRORLEVEL 1 ( echo   Some errors occurred. For details see file: _FileCrosscheck.txt ) ELSE echo   All files were copied correctly.

:End
echo ============ CreateHashAndCopy: Finished ============
