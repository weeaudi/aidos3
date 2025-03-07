setlocal enabledelayedexpansion

:: Check for winget
where winget >nul 2>&1
if !ERRORLEVEL! == 0 (
    echo Using winget for installation.
    winget install --silent --accept-source-agreements --accept-package-agreements NASM.NASM
    winget install --silent --accept-source-agreements --accept-package-agreements Python.Python.3.11
    winget install --silent --accept-source-agreements --accept-package-agreements SoftwareFreedomConservancy.QEMU
    winget install --silent --accept-source-agreements --accept-package-agreements DimitriVanHeesch.Doxygen
) else (
    echo winget not found. Checking for Chocolatey...

    where choco >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Chocolatey not found. Installing Chocolatey...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        if !ERRORLEVEL! neq 0 (
            echo Failed to install Chocolatey. Please install dependencies manually.
            exit /b 1
        )
        echo Chocolatey installed successfully.
        set PATH=%PATH%;C:\ProgramData\chocolatey\bin
    )

    echo Installing dependencies using Chocolatey...
    choco install nasm -y
    choco install qemu -y
    choco install cmake -y
    choco install doxygen.install -y
    choco install python -y
)

:: Ensure Python packages are installed
python -m pip install --upgrade pip
python -m pip install sh pyelftools PyFatFS

endlocal
