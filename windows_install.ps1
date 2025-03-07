# Enable error handling
$ErrorActionPreference = "Stop"

# Check for winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Output "Using winget for installation."
    winget install --silent --accept-source-agreements --accept-package-agreements NASM.NASM
    winget install --silent --accept-source-agreements --accept-package-agreements Python.Python.3.11
    winget install --silent --accept-source-agreements --accept-package-agreements SoftwareFreedomConservancy.QEMU
    winget install --silent --accept-source-agreements --accept-package-agreements DimitriVanHeesch.Doxygen
}
else {
    Write-Output "winget not found. Checking for Chocolatey..."

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Output "Chocolatey not found. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Output "Failed to install Chocolatey. Please install dependencies manually."
            exit 1
        }
        Write-Output "Chocolatey installed successfully."
        $env:Path += ";C:\ProgramData\chocolatey\bin"
    }

    Write-Output "Installing dependencies using Chocolatey..."
    choco install nasm -y
    choco install qemu -y
    choco install cmake -y
    choco install doxygen.install -y
    choco install python -y
}

# Ensure Python packages are installed
python -m pip install --upgrade pip
python -m pip install sh pyelftools PyFatFS
