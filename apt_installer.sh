#!/bin/bash

# Update package lists
apt update

# Check and install necessary packages
packages=(
    cmake texinfo nasm qemu-system-x86 python3-parted doxygen libparted-dev
)

for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        echo "Installing $pkg..."
        apt install -y "$pkg"
    else
        echo "$pkg is already installed. Skipping."
    fi
done

# Ensure pip3 is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Installing..."
    apt install -y python3-pip
fi

# Check and install necessary Python packages
python_packages=(sh pyelftools PyFatFS)

for pypkg in "${python_packages[@]}"; do
    if ! python3 -c "import $pypkg" &> /dev/null; then
        echo "Installing Python package: $pypkg"
        pip3 install "$pypkg"
    else
        echo "Python package $pypkg is already installed. Skipping."
    fi
done
