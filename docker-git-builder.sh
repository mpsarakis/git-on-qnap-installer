#!/bin/bash
# ------------------------------------------------------------------------------
# Script Name: docker-git-builder.sh
#
# Description:
#   This script orchestrates the process of building and installing a specified
#   version of Git into a designated toolchain directory using a Docker container
#   as the build environment. This approach is useful when you want to ensure a
#   consistent build environment or when the target system lacks the native
#   build dependencies for Git.
#
# Prerequisites:
#   - Docker must be installed and running.
#   - The host system must have internet connectivity to download Git sources,
#     Docker images, and repository configurations.
#   - The following files must reside in the same directory as this script:
#         * build-git.sh      : The script to build Git inside the Docker container.
#         * CentOS-Base.repo  : A custom repository configuration to replace the
#                               default CentOS repository (useful if the default
#                               repo is deprecated).
#         * git-wrapper       : A wrapper script to launch Git with proper
#                               environment variables for a relocatable installation.
#
# Usage:
#   Simply execute this script:
#       ./docker-git-builder.sh
#
# Configuration Variables:
#   - GIT_INSTALL_DIR: Destination directory where Git will be installed.
#   - GIT_VERSION    : The version of Git to build (e.g., "2.45.3").
#   - DOCKER_IMAGE   : The Docker image to be used as the build environment.
#
# Process Overview:
#   1. Validate the existence of the destination toolchain directory and create it if necessary.
#   2. Verify that Docker is installed and accessible.
#   3. Remove any existing Docker container with the designated name to avoid conflicts.
#   4. Launch a Docker container in detached mode using the specified image.
#   5. Copy the Git build script and custom repository configuration into the container.
#   6. Execute the Git build script inside the container, passing the Git version and
#      installation directory as parameters.
#   7. Clean up by removing the build script from the container.
#   8. Stop and remove the Docker container.
#   9. Install the Git wrapper by copying it from the host into the Git installation directory.
#
# Inspired from an original work by Michael Huang
# https://sdhuang32.github.io/install-git-on-qts/
#
# Author: MPS
# Date: 07/02/2025
# Version: 1.0
# ------------------------------------------------------------------------------
 
set -e  # Exit immediately if any command fails
 
##########################
# Configuration
##########################
# Destination Directory where Git will be installed.
GIT_INSTALL_DIR="/share/Public/toolchain/git"

# Define Git version to build.
#  2.45.3 is the latest version compatible with glibc v2.17.
#  QNAP is on glibc v2.21 but I could not find any build container this version, so I stick to v2.17.
#  GIT releases list can be found here:
#  https://mirrors.edge.kernel.org/pub/software/scm/git/
GIT_VERSION="2.45.3"

# Docker image to be used for the build.
# This image should contain the necessary tools and libraries for building Git.
DOCKER_IMAGE="sdhuang32/c7-systemd"

##########################
# Variables
##########################
# Determine the base directory where this script resides.
BASE_DIR=$(cd "$(dirname "$0")" && pwd)
# Name of the build script that is to be copied into the container.
BUILD_SCRIPT_NAME="build-git.sh"
# Full path to the build script.
BUILD_SCRIPT="${BASE_DIR}/${BUILD_SCRIPT_NAME}"
# Name assigned to the Docker container used for the build process.
CONTAINER_NAME="git-builder"

##########################
# MAIN PROGRAM
##########################
echo "Starting Git build and installation process..."

# Ensure that the toolchain installation directory exists.
if [ ! -d "$GIT_INSTALL_DIR" ]; then
    echo "Creating toolchain directory at $GIT_INSTALL_DIR..."
    mkdir -p "$GIT_INSTALL_DIR"
fi

# Check if Docker is available in the system.
if ! command -v docker &>/dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    exit 1
fi

# Remove a stale container with the same name if it exists.
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Removing existing container with name $CONTAINER_NAME..."
    docker rm -f "$CONTAINER_NAME"
fi

# Start a new Docker container in detached mode.
echo "Starting Docker container $CONTAINER_NAME using image $DOCKER_IMAGE..."
docker run --name "$CONTAINER_NAME" --privileged \
    -v "$GIT_INSTALL_DIR:$GIT_INSTALL_DIR" -d "$DOCKER_IMAGE" tail -f /dev/null

# Copy the build script into the container's /root/ directory.
echo "Copying build script to container..."
docker cp "$BUILD_SCRIPT" "$CONTAINER_NAME:/root/${BUILD_SCRIPT_NAME}"

# Modify the repository configuration.
# The following command copies a custom CentOS repository configuration file into
# the container to override the default configuration since the original one is deprecated.
docker cp "${BASE_DIR}/CentOS-Base.repo" "$CONTAINER_NAME:/etc/yum.repos.d/CentOS-Base.repo"

# Execute the build script inside the container.
# The build script receives the Git version and the Git installation directory as arguments.
echo "Executing build script inside the container..."
docker exec -t "$CONTAINER_NAME" bash "/root/${BUILD_SCRIPT_NAME}" ${GIT_VERSION} ${GIT_INSTALL_DIR}

# Clean up by removing the build script from the container.
echo "Cleaning up build script from container..."
docker exec -t "$CONTAINER_NAME" rm -f "/root/${BUILD_SCRIPT_NAME}"

# (Optional) Update system PATH in /etc/profile if needed.
# Uncomment the following lines if you wish to add the Git binary directory to the PATH.
# if ! grep -q "$GIT_INSTALL_DIR/bin" /etc/profile; then
#    echo "Adding $GIT_INSTALL_DIR/bin to PATH in /etc/profile..."
#    echo "PATH=$GIT_INSTALL_DIR/bin:\$PATH" >> /etc/profile
# fi

# Stop and remove the Docker container.
echo "Stopping and removing Docker container $CONTAINER_NAME..."
docker stop "$CONTAINER_NAME"
docker rm "$CONTAINER_NAME"

##########################
# Install Git Wrapper
##########################
# The 'git-wrapper' file should be located in the same directory as this script.
# It will be copied to the Git installation directory (renamed to "git") so that
# Git runs with the proper environment (setting GIT_TEMPLATE_DIR and GIT_EXEC_PATH)
# relative to the installation location.
echo "Installing Git wrapper..."
if [ -f "${BASE_DIR}/git-wrapper" ]; then
    cp "${BASE_DIR}/git-wrapper" "${GIT_INSTALL_DIR}/git"
    chmod +x "${GIT_INSTALL_DIR}/git"
    echo "Git wrapper installed successfully at ${GIT_INSTALL_DIR}/git"
else
    echo "Warning: git-wrapper not found in ${BASE_DIR}. Please ensure the file exists."
fi

echo "Git build and installation completed successfully."
