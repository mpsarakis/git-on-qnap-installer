#!/bin/bash
# ------------------------------------------------------------------------------
# Git Build and Install Script
#
# This script downloads, compiles, and installs a specified version of Git
# from source using a user-defined installation prefix.
#
# Usage:
#   ./build-git.sh <git_version> <git_install_path>
#
# Example:
#   ./build-git.sh 2.45.3 /share/Public/toolchain/git
#
# Requirements:
#   - The 'yum' package manager (for installing build dependencies).
#   - Development tools and libraries: gcc, wget, make, curl-devel, expat-devel,
#     gettext-devel, openssl-devel, perl-devel, and zlib-devel.
#
# The script performs the following tasks:
#   1. Validates command-line arguments.
#   2. Installs required dependencies.
#   3. Cleans up any previous source tarballs, source directories, or install paths.
#   4. Downloads the specified Git tarball from the official mirror.
#   5. Extracts the downloaded tarball.
#   6. Configures, builds, and installs Git into the specified installation directory.
#   7. Verifies that Git was installed successfully.
#
# Note:
#   - The script removes any existing installation at the specified install path.
#     Use with caution!
#
# Author: MPS
# Date: 07/02/2025
# Version: 1.0
# ------------------------------------------------------------------------------
 
# Check that exactly 2 arguments are provided: Git version and installation path.
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <git_version> <git_install_path>"
    exit 1
fi

# Set variables based on command-line arguments.
GIT_VERSION="$1"            # e.g., "2.45.3"
GIT_INSTALL_PATH="$2"       # e.g., "/share/Public/toolchain/git"

# Base URL for Git tarballs.
BASE_URL="https://mirrors.edge.kernel.org/pub/software/scm/git/"

# Function to print headers for different sections.
log() {
    echo -e "\n###########################################"
    echo "# $1"
    echo "###########################################"
}

# ------------------------------------------------------------------------------
# Step 1: Install Required Packages
# ------------------------------------------------------------------------------
log "Install required packages"
yum install -y gcc wget make curl-devel expat-devel \
               gettext-devel openssl-devel perl-devel zlib-devel || { 
    echo "ERROR: Failed to install dependencies"; exit 1; 
}

# ------------------------------------------------------------------------------
# Step 2: Change to Home Directory
# ------------------------------------------------------------------------------
cd "$HOME" || { echo "ERROR: Unable to change to $HOME directory"; exit 1; }

# ------------------------------------------------------------------------------
# Step 3: Cleanup Old Files and Directories
# ------------------------------------------------------------------------------
log "Cleanup"
# Remove previously downloaded tarball if it exists.
[ -f git-sources.tar.gz ] && rm -f git-sources.tar.gz
# Remove previously extracted source directory if it exists.
[ -d git-sources ] && rm -rf git-sources
# Remove any existing installation directory at the specified install path.
[ -d "$GIT_INSTALL_PATH" ] && rm -rf "$GIT_INSTALL_PATH"

# ------------------------------------------------------------------------------
# Step 4: Download the Git Tarball
# ------------------------------------------------------------------------------
log "Fetch Git tarball"
TAR_GZ_NAME="git-${GIT_VERSION}.tar.gz"
wget "${BASE_URL}${TAR_GZ_NAME}" -O git-sources.tar.gz || {
    echo "ERROR: Failed to download Git version $GIT_VERSION"; exit 1;
}

# ------------------------------------------------------------------------------
# Step 5: Extract the Tarball
# ------------------------------------------------------------------------------
log "Uncompress sources"
if ! tar zxvf git-sources.tar.gz; then
    echo "WARNING: Failed to extract git-sources.tar.gz (ignoring for QNAP errors)";
fi

# ------------------------------------------------------------------------------
# Step 6: Build and Install Git
# ------------------------------------------------------------------------------
log "Build Git"
# Change into the extracted source directory (assuming its name starts with "git-").
cd git-*/ || { echo "ERROR: Failed to navigate to Git source directory"; exit 1; }
# Run the configure script with the user-defined installation prefix.
./configure --prefix="$GIT_INSTALL_PATH" || { echo "ERROR: Configure failed"; exit 1; }
# Build the software.
make all || { echo "WARNING: Make failed (ignoring for QNAP errors)"; }
# Install the built Git into the specified installation directory.
make install || { echo "WARNING: Make install failed (ignoring for QNAP errors)"; }

# ------------------------------------------------------------------------------
# Step 7: Verify the Installation
# ------------------------------------------------------------------------------
log "Verify installation destination path"
if ! "$GIT_INSTALL_PATH/bin/git" --version; then
    echo "ERROR: Git installation failed in destination path"; exit 1;
fi

echo "Git installed successfully at $GIT_INSTALL_PATH"
