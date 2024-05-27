@echo off
chcp 65001 > nul

echo Установка переменной host_ip
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4 Address"') do (
    set "host_ip=%%a"
    goto :next
)
:next

set NSSM_PATH=C:\Promtail\nssm-2.24\win64\nssm.exe

echo Открываю порт 9080 в брандмауэре Windows...
netsh advfirewall firewall add rule name="Promtail 9080" dir=in action=allow protocol=TCP localport=9080

echo Проверяю наличие службы Promtail...
%NSSM_PATH% stop Promtail
%NSSM_PATH% remove Promtail confirm

echo Устанавливаю службу Promtail...
%NSSM_PATH% install Promtail "C:\Promtail\promtail-windows-amd64.exe" --config.file=C:\Promtail\promtail.yml --config.expand-env=true

echo Запускаю службу Promtail...
%NSSM_PATH% start Promtail

echo Мои поздравления!!!

pause
