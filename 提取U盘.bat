@echo off
set KeyFile=compresscode.mem
set LibName=OneTouch

set FilePath=E:\
Set FileName=%FilePath%%KeyFile%
if exist %FileName% goto :StartFind

set FilePath=F:\
Set FileName=%FilePath%%KeyFile%
if exist %FileName% goto :StartFind

set FilePath=G:\
Set FileName=%FilePath%%KeyFile%
if exist %FileName% goto :StartFind

set FilePath=H:\
Set FileName=%FilePath%%KeyFile%
if exist %FileName% goto :StartFind

set FilePath=I:\
Set FileName=%FilePath%%KeyFile%
if exist %FileName% goto :StartFind

set FilePath=J:\
Set FileName=%FilePath%%KeyFile%
if exist %FileName% goto :StartFind

echo ��ʾ��û�з��ֱ���USB��
pause
exit

:StartFind

dir %FilePath%%LibName%_20*.EXE.BK /o-d /b > Lib.txt
echo �ļ��б�
type Lib.txt

for /f %%M in (Lib.txt) do (
set FileName=%%M
goto :OKExit
)

:OKExit
del Lib.txt
set FileName=%FilePath%%FileName%
echo ����Ŀ�꣺%FileName%
start %FileName%
