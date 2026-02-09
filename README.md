# WPE WebKit Custom Build

This repository provides a automated build system and CI/CD pipeline for **WPE WebKit**, the WebKit port optimized for embedded devices. It is designed to produce high-performance, lightweight web engine binaries suitable for resource-constrained environments.

## Purpose

Compiling WebKit from source is a resource-intensive and time-consuming task. This project:
- Automates the build process using **GitHub Actions**.
- Optimizes build speed with **ccache**.
- Packages the necessary headers, libraries, and executables into a single archive.
- Provides a pre-configured setup specifically tested for modern WPE features (e.g., `WPEPlatform`).

## Installation

To use the pre-compiled binaries from the GitHub Releases, follow these steps on a compatible Linux system (Ubuntu 22.04+ recommended).

### 1. Install Runtime Dependencies

Ensure your system has the required libraries to run the WebKit engine:

```bash
sudo apt-get update && sudo apt-get install -y 
  libglib2.0-0 libsoup-3.0-0 libssl3 libgnutls28-dev 
  libsecret-1-0 libgcrypt20 libtasn1-6 
  libepoxy0 libegl1 libgles2 libxkbcommon0 
  libjpeg8 libpng16-16 libwebp7 
  libharfbuzz0b libfreetype6 libfontconfig1 
  libicu70 libxml2 libhyphen0 libenchant-2-2 
  libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 
  libgstreamer-plugins-bad1.0-0 
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good 
  libsqlite3-0 libjxl0.7 libavif13 libwoff2-1.0-1 
  libopenjp2-7 liblcms2-2 libatk1.0-0 libatk-bridge2.0-0 
  libdrm2 libgbm1 flite libxslt1.1 
  bubblewrap xdg-dbus-proxy libseccomp2 
  libmanette-0.2-0 libevdev2 libinput10 libudev1 
  libwayland-client0 libwayland-egl1
```

### 2. Extract the Archive

Download the `wpe-webkit-amd64.tar.gz` from the Releases page and extract it to your root directory. The files are configured to reside in `/usr/local`.

```bash
sudo tar -xzf wpe-webkit-amd64.tar.gz -C /
```

### 3. Update Library Cache

After extracting the `.so` files, update the system's dynamic linker cache:

```bash
sudo ldconfig
```

## Building from Source

If you wish to build the project yourself locally:

1. Clone the repository.
2. Ensure you have at least 16GB of RAM and significant disk space.
3. Run the build script:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
The script will install build-time dependencies, download source code, and compile the libraries using Ninja.

## Verification

You can verify the installation by checking if `pkg-config` can locate the WPE WebKit metadata:

```bash
pkg-config --cflags --libs wpe-webkit-2.0
```

## License

This project is licensed under the [MIT License](LICENSE).
