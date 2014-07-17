@echo off
REM -- Improved Batch Script Version without changing current directory --
echo.
echo ================= CreateHashAndCopy =================
if "%~1"=="--help" goto Help
if "%~1"=="-h"     goto Help
if "%~1"=="--?"    goto Help
if "%~1"=="-?"     goto Help
if "%~1"=="/help"  goto Help
if "%~1"=="/?"     goto Help
goto Initialize

:Help
echo Author:  Dirk Wolff, EKHC IWSP Technical Advisor
echo Version: 1.1   ---   Date: 2014-07-17
echo.
echo Usage:
echo CreateHashAndCopy [HashAlgorithm] [SourceFolder] [TargetFolder] [CopyMode]
REM                     Arg1 = %1,  Arg2 = %2,  Arg3 = %3, etc (for calling in this batch script)
echo.
echo where:
echo   [HashAlgorithm] (optional: default=-MD5 or as given by %%GlobalHashSettings%%)
echo     .. Hash-Algorithm according to original FSUM options.
echo        Examples:  -MD5  -SHA1  -SHA256  (and others, see fsum_ReadMe.txt)
echo        (Hashes can be combined when inclosed in quotes: "-MD5 -SHA1")
echo        Script reads environment variable %%GlobalHashSettings%%, if available.
echo.
echo   [SourceFolder]  (optional: default=current folder)
echo     .. Source Folder (for which Checksums/Hashes should be created and saved in
echo        an Checksum/Hash-File "_Checksums_*.md5.txt" [in .MD5-Format]
echo.
echo   [TargetFolder]  (optional: if not given, files/folders will not be copied)
echo     .. Target/Destination Folder (into which files should be copied and
echo        crosschecked for correctness)
echo.
echo   [CopyMode]      (optional; default: only changed files [/M])
echo     .. Possible Values:  /ALL, or the following xcopy options: /A /M /D
echo        /ALL    .. all files will be copied again (and no change of attributes).
echo        /A         Copies only files with the archive attribute set (i.e.
echo                   changed files), but doesn't change the attribute.
echo        /M         Copies only files with the archive attribute set (i.e.
echo                   changed files), turns off the archive attribute. [default!]
echo        /D:m-d-y   Copies files changed on or after the specified date (m-d-y).
echo        /D         If no date is given [/D]: copies only those files whose
echo                   source time is NEWER than the destination time.
echo     Note: Select only ONE Option! Only /D[:m-d-y] can be combined with /A or /M.
echo.
echo Notes: - Optional arguments must be given as empty strings [""], if other
echo          arguments follow.
echo        - If Source/Target Folders contain spaces, add quotation marks [".."]
echo          around them.
echo.
echo Requirements: SlavaSoft FSUM (Fast File Integrity Checker/Hash-Creator)
echo     FSUM Information:     http://www.slavasoft.com/fsum/index.htm
echo     FSUM Download:        http://www.slavasoft.com/zip/fsum.zip
echo     Freeware License:     http://www.slavasoft.com/fsum/license-agreement.htm
echo.
echo The Script must be started from a folder, which contains fsum.exe, or the path
echo to fsum.exe must be included in the global PATH variable. This Script will
echo search for fsum.exe in several default locations like "%WinDir%",
echo "%ProgramFiles%\fsum", or a folder "\fsum_HashUtility\" in the vicinity of
echo the folder where the script is started from.
echo.
goto :EOF

:Initialize
REM Check if fsum.exe can be started (i.e. either in current directory or already included in search path)
fsum.exe 2>NUL
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
REM fsum.exe is not found in search path or current directory, so try to locate it elsewhere:
REM If found, prepend location to current search path (environment variable %path%), and call fsum.exe to check.
REM If successful goto ReadHashAlgorithm.
::  Note: different commands can be placed in one line when separated by "&&"
IF EXIST "%WinDir%\fsum.exe"                ( set path=%WinDir%;%path%&&                fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "%ProgramFiles%\fsum\fsum.exe"     ( set path=%ProgramFiles%\fsum;%path%&&     fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "%ProgramFiles%\fsum_HashUtility\fsum.exe" ( set path=%ProgramFiles%\fsum_HashUtility;%path%&& fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "%CD:~0,2%\fsum_HashUtility\fsum.exe"  ( set path=%CD:~0,2%\fsum_HashUtility;%path%&&   fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "%cd%\fsum_HashUtility\fsum.exe"       ( set path=%cd%\fsum_HashUtility;%path%&&       fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "%cd%\..\fsum_HashUtility\fsum.exe"    ( set path=%cd%\..\fsum_HashUtility;%path%&&    fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "%cd%\..\..\fsum_HashUtility\fsum.exe" ( set path=%cd%\..\..\fsum_HashUtility;%path%&& fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
IF EXIST "C:\Backup\fsum_HashUtility\fsum.exe"  ( set path=C:\Backup\fsum_HashUtility;%path%&&  fsum.exe 2>NUL )
if %ERRORLEVEL%==0 goto ReadHashAlgorithm
::  If needed, add other options, where fsum.exe could be found

:ReCheckFSUM
fsum.exe 2>NUL  &&  if %ERRORLEVEL%==0 goto ReadHashAlgorithm
echo Error: fsum.exe is needed for creating checksums/hashes!
echo.
echo Explanation:
echo fsum.exe could not be found in the system search path (%%path%%) or the current   directory, or a subdirectory named "fsum_HashUtility".
echo Note: type "path" [enter] to see current search path, or "help path" for more   information.
echo.
echo fsum.exe can be downloaded from:     http://www.slavasoft.com/fsum/index.htm
echo.
echo Exiting Script...
goto End

:ReadHashAlgorithm
REM Set default value for HashAlgorithm, (use environment variable %GlobalHashSettings% if defined):
IF DEFINED     GlobalHashSettings set hash=%GlobalHashSettings:  = %
IF NOT DEFINED GlobalHashSettings set hash=-MD5
REM Check if Arg1 [HashAlgorithm] is not empty:
if "%~1"=="" goto SetOutputHashFileName
:: As Argument1 [HashAlgorithm] is not empty, use it (set %hash% variable):
set hash=%~1

:SetOutputHashFileName
REM Set name of output file (HashFile/ChecksumFile) [in .md5-format] (and eliminate spaces and "-")
set OutputHashFile=%hash:-=_%
set OutputHashFile=%OutputHashFile: =%
set OutputHashFile=_Checksums%OutputHashFile%.md5.txt

:CheckSourceFolder
REM Set current folder as default source folder:
set sourcefolder=%cd%
REM If Argument2 (Source Folder) is empty, use default and skip to next section (CheckTargetFolder):
if "%~2"=="" goto CheckTargetFolder
REM If Argument2 (Source Folder) is specified, check existance of Source Folder:
if EXIST "%~2" set sourcefolder=%~df2
if NOT EXIST "%~2" (
	echo   Error: Source Folder "%~df2" does not exist!
	echo   Files cannot be checked.                      Exiting Script...
	goto End
	)

:CheckTargetFolder
REM Source folder = current folder (or argument %2)
REM Target folder = given in argument %3  (if empty, CopyingFiles below will be skipped)
if "%~3"=="" goto GetCopyMode
if EXIST "%~df3" goto GetCopyMode
REM Target Folder does not yet exist. Try to create target folder:
md "%~df3" 2>NUL

:GetCopyMode
REM Read Arg4 / Arg5 (optional)
::  Note: If 2 Arguments are given here without quotes, then they are retrieved as Arg4 (%4) and Arg5 (%5)
::        But if they are combined in one Argument like "/A /D" then the second one will not be checked below for correctness.
set CopyMode=   && REM In this line: set CopyMode to a space character (to be not empty)
REM If Arg4 and Arg5 are empty, continue with next step (GetCopyModeEnd)
if "%~4%~5"=="" (set CopyMode=/M&& goto GetCopyModeEnd)
:ReadArg5
if "%~5"=="" goto ReadArg4
set tmpCopyMode=%~5
REM Check for Argument /ALL (overruling any other arguments given here)
if /I "%tmpCopyMode:~0,4%"=="/ALL" ( set CopyMode=ALL && set tmpCopyMode=ALL files/folders && goto GetCopyModeEnd )
REM Read given xcopy arguments
if /I "%tmpCopyMode:~0,2%"=="/A" set CopyMode=%tmpCopyMode% %CopyMode%
if /I "%tmpCopyMode:~0,2%"=="/M" set CopyMode=%tmpCopyMode% %CopyMode%
if /I "%tmpCopyMode:~0,2%"=="/D" set CopyMode=%tmpCopyMode% %CopyMode%
:ReadArg4
if "%~4"=="" goto GetCopyModeEnd
set tmpCopyMode=%~4
REM Check for Argument /ALL (overruling any other arguments given here)
if /I "%tmpCopyMode:~0,4%"=="/ALL" ( set CopyMode=ALL && set tmpCopyMode=ALL files/folders && goto GetCopyModeEnd )
REM Read given xcopy arguments
if /I "%tmpCopyMode:~0,2%"=="/A" set CopyMode=%tmpCopyMode% %CopyMode%
if /I "%tmpCopyMode:~0,2%"=="/M" set CopyMode=%tmpCopyMode% %CopyMode%
if /I "%tmpCopyMode:~0,2%"=="/D" set CopyMode=%tmpCopyMode% %CopyMode%
:GetCopyModeEnd
REM If no valid Arguments have been given, switch back to default behaviour (only changed files [/M])
if    "%CopyMode: =%"==""    set CopyMode=/M
:: if "%CopyMode:~0,1"==" "  set CopyMode=/M
if /I "%CopyMode: =%"=="/M"  set CopyMode=/M
IF "%CopyMode:~0,3%"=="ALL"    set CopyMode=  && REM Set CopyMode to space string, so that xcopy will have default behaviour (copying ALL files)
REM Update tmpCopyMode to show final arguments
IF "%CopyMode:~0,1%"=="/"      set tmpCopyMode=%CopyMode%
IF "%CopyMode%"=="/M"          set tmpCopyMode=%CopyMode% [default]

:DisplayParameters
echo Script was called with the following parameters:
echo   - Hash-Algorithm(s): %hash%
echo   - Source Folder:  "%sourcefolder%"
if "%~3"=="" (
   echo   - Destination:    [not specified]
   goto HiddenFiles
   )
if NOT EXIST "%~df3" (
   echo   - Destination:    %3 [not valid!]
   goto HiddenFiles
   )
echo   - Destination:    "%~df3"
echo   - CopyMode:       %tmpCopyMode%

:HiddenFiles
echo.
echo Executing Script:
REM Create a list of hidden files and folders (to see if anything needs to be included)
echo   1) Creating list of hidden+system files...                     (please wait)
IF EXIST "%sourcefolder%\_HiddenAndSystemFiles.txt"    del "%sourcefolder%\_HiddenAndSystemFiles.txt"
:: IF EXIST "%sourcefolder%\_No_HiddenAndSystemFiles.txt" del "%sourcefolder%\_No_HiddenAndSystemFiles.txt"
echo ; List of Hidden files in folder:   *%sourcefolder%>  "%sourcefolder%\_HiddenAndSystemFiles.txt"
dir "%sourcefolder%\*.*" /A:H /S /B >> "%sourcefolder%\_HiddenAndSystemFiles.txt" 2>NUL
::      /A:HS    Attributes: H..hidden, S..System Files
::      /S       Displays files in specified directory and all subdirectories.
::      /R       Display alternate data streams of the file. [Invalid option under WinXP !]
::      /B       Uses bare format (no heading information or summary).
if ERRORLEVEL 1 ( echo ; *** No hidden files found.>> "%sourcefolder%\_HiddenAndSystemFiles.txt" )
echo.                                              >> "%sourcefolder%\_HiddenAndSystemFiles.txt"
echo ; List of System files in folder:   *%cd%>> "%sourcefolder%\_HiddenAndSystemFiles.txt"
dir "%sourcefolder%\*.*" /A:S /S /B           >> "%sourcefolder%\_HiddenAndSystemFiles.txt" 2>NUL
if ERRORLEVEL 1 ( echo ; *** No system files found.>> "%sourcefolder%\_HiddenAndSystemFiles.txt" ) ELSE goto DeleteOldHashfile

:DeleteOldHashfile
REM Deleting old the checksum/hash file (i.e. if existing with the same name)
IF EXIST "%sourcefolder%\%OutputHashFile%" del "%sourcefolder%\%OutputHashFile%"
:: IF EXIST "%sourcefolder%\%OutputHashFile%" goto DeleteOldHashfile
REM If target folder is specified (i.e. if files will be copied), delete rename old _xcopy.log file to .bak
IF EXIST "%~df3" (
	IF EXIST "%sourcefolder%\_xcopy.log.bak" del "%sourcefolder%\_xcopy.log.bak" 2>NUL
	IF EXIST "%sourcefolder%\_xcopy.log"     ren "%sourcefolder%\_xcopy.log" "_xcopy.log.bak" 2>NUL
	)

:CreateHashes
echo   2) Creating Checksums/Hashes of all files in source folder...  (please wait)
REM insert current path into new document
echo ; CurrentPath:  	?SOURCE=*%sourcefolder%>  "%sourcefolder%\%OutputHashFile%"
echo ; ComputerName: 	?PCNAME=*%computername%>> "%sourcefolder%\%OutputHashFile%"
echo ; HashAlgorithm: 	?HASH..=*%hash:  = %>>    "%sourcefolder%\%OutputHashFile%"
echo ; StartTime:    	?STARTT=*%date% %time%>>  "%sourcefolder%\%OutputHashFile%"
echo ; >> "%sourcefolder%\%OutputHashFile%"
REM create checksums and save them in file: "%OutputHashFile%"
fsum.exe %hash% -r  "-d%sourcefolder%\."  "*.*"  >> "%sourcefolder%\%OutputHashFile%" 2>NUL
echo ; >> "%sourcefolder%\%OutputHashFile%"
echo ; EndTime:      	?ENDTIM=*%date% %time%>> "%sourcefolder%\%OutputHashFile%"

:CopyingFiles
REM Target folder = given in argument %3  (if empty, CopyingFiles will be skipped)
if "%~3"=="" goto End
if NOT EXIST "%~df3" (
	echo   Error: Target Folder "%~df3" could not be created. Files cannot be copied.
	goto End
)
echo   3) Now copying files...                                        (please wait)
:: echo      Source Folder:  "%sourcefolder%"
:: echo      Destination:    "%~df3"
:: echo      CopyMode:       %tmpCopyMode%
REM copy files and folders now
xcopy "%sourcefolder%\*.*"   "%~df3" %CopyMode% /S /V /C /G /Y >"%temp%\_xcopy.log" 2>NUL
REM copy the xcopy-logfile
xcopy    "%temp%\_xcopy.log" "%sourcefolder%" /G /Y >NUL 2>NUL
xcopy    "%temp%\_xcopy.log" "%~df3"          /G /Y >NUL 2>NUL
del      "%temp%\_xcopy.log"
REM Arguments explained:
::  /M           Copies only files with the archive attribute set,
::               turns off the archive attribute.
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
echo   4) Verifying copied files...                                   (please wait)
fsum.exe -c  "-d%~df3\."  "%~df3\%OutputHashFile%" > "%~df3\_FileCrosscheck.txt" 2>NUL
::  report only failed files:
::  fsum.exe -c -jf "%OutputHashFile%" > _FileCrosscheck.txt 2>NUL
if ERRORLEVEL 1 ( echo      Some errors occurred. For details see file: _FileCrosscheck.txt ) ELSE echo      Success: All files were copied correctly.

:End
echo ============ CreateHashAndCopy: Finished ============
REM Delete temporary variables
set hash=
set sourcefolder=
set CopyMode=
set tmpCopyMode=
set OutputHashFile=
