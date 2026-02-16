@echo off
setlocal enabledelayedexpansion

for %%f in (*.part.0001) do (
    set "full=%%f"
    set "base=!full:~0,-10!"
    echo Joining "!base!" ...
    copy /b "!base!.part.*" "!base!"
)

pause
