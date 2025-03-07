# Enable error handling
$ErrorActionPreference = "Stop"

# Function to check if a command exists in PATH
function Test-CommandExists {
    param (
        [string]$Command
    )
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

# Check for winget
if (Test-CommandExists "winget") {
    Write-Output "Using winget for installation."

    $packages = @{
        "nasm"   = "NASM.NASM"
        "python" = "Python.Python.3.11"
        "qemu"   = "SoftwareFreedomConservancy.QEMU"
        "doxygen"= "DimitriVanHeesch.Doxygen"
    }

    foreach ($cmd in $packages.Keys) {
        if (-not (Test-CommandExists $cmd)) {
            Write-Output "Installing $cmd..."
            winget install --silent --accept-source-agreements --accept-package-agreements $packages[$cmd]
        }
        else {
            Write-Output "$cmd is already installed and available in PATH."
        }
    }
}
else {
    Write-Output "winget not found. Checking for Chocolatey..."

    if (-not (Test-CommandExists "choco")) {
        Write-Output "Chocolatey not found. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        if (-not (Test-CommandExists "choco")) {
            Write-Output "Failed to install Chocolatey. Please install dependencies manually."
            exit 1
        }
        Write-Output "Chocolatey installed successfully."
        $env:Path += ";C:\ProgramData\chocolatey\bin"
    }

    Write-Output "Installing dependencies using Chocolatey..."
    $packages = @{
        "nasm"   = "nasm"
        "python" = "python"
        "qemu"   = "qemu"
        "doxygen"= "doxygen.install"
        "gcc"    = "mingw --version=13.2.0"
    }

    foreach ($cmd in $packages.Keys) {
        if (-not (Test-CommandExists $cmd)) {
            Write-Output "Installing $cmd..."
            choco install $packages[$cmd] -y
        }
        else {
            Write-Output "$cmd is already installed and available in PATH."
        }
    }
}

# Ensure Python is installed before proceeding with pip
if (Test-CommandExists "python") {
    Write-Output "Ensuring required Python packages are installed..."
    python -m pip install --upgrade pip
    python -m pip install sh pyelftools PyFatFS
}
else {
    Write-Output "Python is not installed. Please install it manually."
    exit 1
}
