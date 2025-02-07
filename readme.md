# Git Build and Installation via Docker

This project provides a set of scripts to build and install a specified version of Git into a custom destination directory using Docker. This solution is especially useful for systems that require a reproducible build environment or when native build dependencies are unavailable.

Depending on QTS release (and glibc version), there is a git max release that can be installed, so don't necessarily expect to be able to install the latest one... For instance, for QTS 5.2.3.3006, git v2.45.3 is the latest possible (still from Jan 2025, so I found that ok vs. the "real" latest v2.48.1)

This is for x86 QNAP.

## Overview

The process leverages a Docker container to create a consistent build environment. The main steps are as follows:

1. **Docker Container Launch:**  
   A Docker container is started using a pre-built image that includes the necessary tools and libraries to build Git.
   
2. **Script Injection:**  
   The Git build script (`build-git.sh`) and a custom CentOS repository configuration (`CentOS-Base.repo`) are copied into the container.
   
3. **Git Build Process:**  
   Inside the container, the build script compiles and installs Git into the designated destination directory.
   
4. **Git Wrapper Installation:**  
   A Git wrapper (`git-wrapper`) is installed into the destination directory. This wrapper sets environment variables (`GIT_TEMPLATE_DIR` and `GIT_EXEC_PATH`) to ensure Git locates its helper programs and template files correctly, making the installation relocatable.
   
5. **Cleanup:**  
   The Docker container is stopped and removed after the build process completes.

## Prerequisites

- **Docker:**  
  Docker must be installed and running on your system.

- **Internet Connectivity:**  
  The host machine needs access to the internet to download Git sources, Docker images, and repository configurations.

- **Required Files:**  
  Ensure that the following files are present in the same directory as the main script:
  - `docker-git-builder.sh` – The orchestrating script.
  - `build-git.sh` – The script that builds Git inside the Docker container.
  - `CentOS-Base.repo` – Custom repository configuration to override default CentOS repos.
  - `git-wrapper` – The wrapper script to launch Git with proper environment variables.

## Installation and Usage

1. **Clone the Repository:**

   ```bash
   git clone <repository-url>
   cd <repository-directory>

2. **Review and Update Configuration:**

Open `docker-git-builder.sh` and adjust the configuration variables as needed:

- **GIT_INSTALL_DIR:** Destination directory for Git installation (e.g., `/share/Public/toolchain/git`).
- **GIT_VERSION:** The Git version to build (e.g., `2.45.3`).
- **DOCKER_IMAGE:** The Docker image to be used for the build (e.g., `sdhuang32/c7-systemd`).

3. **Run the Main Script:**

Execute the script to start the build process:
`./docker-git-builder.sh`

The script will:
- Create the destination directory if it does not exist.
- Launch a Docker container and copy the build scripts into it.
- Build and install Git inside the container.
- Install the Git wrapper into the installation directory.
- Clean up by stopping and removing the Docker container.

## Configuration Details
- **GIT_INSTALL_DIR:**
The directory where Git will be installed (e.g., `/share/Public/toolchain/git`).

- **GIT_VERSION:**
The version of Git to build (e.g., `2.45.3`).

- **DOCKER_IMAGE:**
The Docker image used for building Git (e.g., `sdhuang32/c7-systemd`).

Other internal variables (e.g., `BUILD_SCRIPT_NAME`, `CONTAINER_NAME`) are managed automatically by the script.

## Git Wrapper
The `git-wrapper` script is designed to ensure that Git runs with the proper environment by setting the following variables at runtime:
- **GIT_TEMPLATE_DIR:** Points to the directory containing Git templates.
- **GIT_EXEC_PATH:** Points to the directory containing Git's helper executables.
This wrapper is copied into the Git installation directory and renamed to `git`. When you run Git, the wrapper dynamically sets these variables so that Git locates its resources correctly regardless of where the installation is moved.

## Troubleshooting
- **Docker Issues:**
Ensure Docker is installed and that you have sufficient permissions to run Docker commands.

- **Missing Files:**
Verify that `build-git.sh`, `CentOS-Base.repo`, and `git-wrapper` exist in the repository root.

- **Permission Errors:**
Make sure you have write access to the destination directory (`GIT_INSTALL_DIR`).

## Author
MPS

## Acknowledgements
Inspired from an original work by Michael Huang
https://sdhuang32.github.io/install-git-on-qts/
