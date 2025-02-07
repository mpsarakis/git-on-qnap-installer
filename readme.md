# Git Build and Installation via Docker

This project provides a set of scripts to build and install a specified version of Git into a custom toolchain directory using Docker. This solution is especially useful for systems that require a reproducible build environment or when native build dependencies are unavailable.

Inspired from an original work by Michael Huang
https://sdhuang32.github.io/install-git-on-qts/

## Overview

The process leverages a Docker container to create a consistent build environment. The main steps are as follows:

1. **Docker Container Launch:**  
   A Docker container is started using a pre-built image that includes the necessary tools and libraries to build Git.
   
2. **Script Injection:**  
   The Git build script (`build-git.sh`) and a custom CentOS repository configuration (`CentOS-Base.repo`) are copied into the container.
   
3. **Git Build Process:**  
   Inside the container, the build script compiles and installs Git into the designated toolchain directory.
   
4. **Git Wrapper Installation:**  
   A Git wrapper (`git-wrapper`) is installed into the toolchain directory. This wrapper sets environment variables (`GIT_TEMPLATE_DIR` and `GIT_EXEC_PATH`) to ensure Git locates its helper programs and template files correctly, making the installation relocatable.
   
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
