REM goto folder to check.
cd "C:\Backup\Hand over documents Addise 2011-08-10"
REM insert current path into new document
cd > SHA256Checksums.md5.txt
REM create checksums and save them in file: SHA256Checksums.md5.txt
fsum -sha256 -r *.* >> SHA256Checksums.md5.txt


