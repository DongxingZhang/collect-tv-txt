@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
 
REM Ҫɨ���Ŀ¼��Ϊ�������루δ��ֵ��Ĭ��Ϊbat�ļ�����Ŀ¼��
CD /d "%~dp0"
 
FOR /F "delims=" %%a IN ('DIR /A /B *.mkv1') DO (
    SET FILE_NAME=%%~na
    SET FILE_NAME_EXT=%%~xa
    ECHO "%%a" "!FILE_NAME!.mkv"
    RENAME "%%a" "!FILE_NAME!.mkv"
    
    REM ����ʹ��������2��
    REM ECHO "%%a" "%%~na(����)%%~xa"
    REM RENAME "%%a" "%%~na(����)%%~xa"
)
PAUSE&