@echo off
setlocal

:: Check if winget is available
where winget >nul 2>nul
if %errorlevel% neq 0 (
    echo winget is not installed or not in PATH.
    exit /b 1
)

:: List of required packages
set PACKAGES=cmake texinfo nasm qemu python3 doxygen

:: Install required packages using winget
for %%P in (%PACKAGES%) do (
    winget install --silent --accept-source-agreements --accept-package-agreements %%P
)

:: Install required Python packages
python -m pip install --upgrade pip
python -m pip install sh pyelftools PyFatFS

echo All dependencies installed.
