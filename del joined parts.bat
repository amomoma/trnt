@echo off
setlocal enabledelayedexpansion

for %%f in (*.part.0001) do (
    set "full=%%f"
    set "base=!full:~0,-10!"

    if exist "!base!" (
        echo Deleting parts for "!base!" ...
        del /q "!base!.part.000*"
    ) else (
        echo Skipping "!base!" - joined file not found.
    )
)

echo Cleanup complete.
pause
