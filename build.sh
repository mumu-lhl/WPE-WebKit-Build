#!/bin/bash
set -e

sudo apt-get update && sudo apt-get install -y \
  build-essential cmake ninja-build meson pkg-config \
  ccache \
  ruby ruby-dev python3 python3-pip \
  gperf unifdef \
  libglib2.0-dev \
  libsoup-3.0-dev \
  libssl-dev libgnutls28-dev \
  libsecret-1-dev \
  libgcrypt20-dev libtasn1-dev \
  libepoxy-dev \
  libegl1-mesa-dev libgles2-mesa-dev \
  libxkbcommon-dev \
  libjpeg-dev libpng-dev libwebp-dev \
  libharfbuzz-dev libharfbuzz-icu0 libfreetype6-dev libfontconfig1-dev \
  libicu-dev libxml2-dev \
  libhyphen-dev libenchant-2-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-bad1.0-dev \
  gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
  libsqlite3-dev \
  libjxl-dev \
  libavif-dev \
  libwoff-dev \
  libopenjp2-7-dev \
  liblcms2-dev \
  libatk1.0-dev libatk-bridge2.0-dev \
  libdrm-dev libgbm-dev \
  flite1-dev \
  libxslt1-dev \
  gobject-introspection libgirepository1.0-dev \
  libsystemd-dev \
  bubblewrap xdg-dbus-proxy libseccomp-dev \
  libmanette-0.2-dev libevdev-dev \
  libinput-dev libudev-dev \
  libwayland-dev wayland-protocols \
  debhelper devscripts

pip3 install gi-docgen

# Create a working directory
mkdir -p ~/wpe-build && cd ~/wpe-build

# Set installation prefix (use /usr/local or a custom path)
export WPE_PREFIX=/usr/local

# If DESTDIR is set, add it to relevant paths so subsequent builds can find dependencies
if [ -n "$DESTDIR" ]; then
  export PKG_CONFIG_PATH="$DESTDIR$WPE_PREFIX/lib/pkgconfig:$DESTDIR$WPE_PREFIX/lib/x86_64-linux-gnu/pkgconfig:$DESTDIR$WPE_PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  export CMAKE_PREFIX_PATH="$DESTDIR$WPE_PREFIX${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
  export LD_LIBRARY_PATH="$DESTDIR$WPE_PREFIX/lib:$DESTDIR$WPE_PREFIX/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

# Configure ccache
export CCACHE_DIR=~/.ccache
export CCACHE_MAXSIZE=10G
ccache -M $CCACHE_MAXSIZE

# === 1. Build libwpe ===
if [ ! -d "libwpe-1.16.3" ]; then
  wget https://wpewebkit.org/releases/libwpe-1.16.3.tar.xz
  tar xf libwpe-1.16.3.tar.xz
fi
cd libwpe-1.16.3
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$WPE_PREFIX \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
ninja -C build
sudo DESTDIR="${DESTDIR:-}" ninja -C build install
cd ..

# === 2. Build WPEBackend-fdo (OPTIONAL - only for legacy fallback) ===
# Skip this step if you enable ENABLE_WPE_PLATFORM in step 3.
# Only needed for older WPE WebKit builds or as a fallback.
# wget https://wpewebkit.org/releases/wpebackend-fdo-1.16.1.tar.xz
# tar xf wpebackend-fdo-1.16.1.tar.xz
# cd wpebackend-fdo-1.16.1
# meson setup build \
#   --prefix=$WPE_PREFIX \
#   --buildtype=release
# ninja -C build
# sudo ninja -C build install
# cd ..

# === 3. Build WPE WebKit ===
# This is the largest component and takes significant time/resources
if [ ! -d "wpewebkit-2.50.4" ]; then
  wget https://wpewebkit.org/releases/wpewebkit-2.50.4.tar.xz
  tar xf wpewebkit-2.50.4.tar.xz
fi
cd wpewebkit-2.50.4

# Configure with recommended options for flutter_inappwebview
# See "Optional Features and Dependencies" section above for all flags
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$WPE_PREFIX \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DPORT=WPE \
  -DENABLE_DOCUMENTATION=OFF \
  -DENABLE_INTROSPECTION=OFF \
  -DENABLE_BUBBLEWRAP_SANDBOX=ON \
  -DENABLE_WEBDRIVER=OFF \
  -DENABLE_MINIBROWSER=OFF \
  -DUSE_AVIF=ON \
  -DUSE_WOFF2=ON \
  -DUSE_JPEGXL=ON \
  -DENABLE_WPE_PLATFORM=ON \
  -DENABLE_WPE_PLATFORM_HEADLESS=ON \
  -DUSE_LIBBACKTRACE=OFF

# The last two flags enable the modern WPEPlatform backend (recommended).
# If omitted, the plugin will fall back to legacy WPEBackend-FDO.

# If you're missing optional dependencies, disable them:
#   -DUSE_JPEGXL=OFF           # if libjxl-dev not installed
#   -DUSE_AVIF=OFF             # if libavif-dev not installed
#   -DUSE_WOFF2=OFF            # if libwoff-dev not installed
#   -DUSE_LCMS=OFF             # if liblcms2-dev not installed
#   -DENABLE_SPEECH_SYNTHESIS=OFF  # if flite1-dev not installed
#   -DUSE_ATK=OFF              # if libatk1.0-dev not installed
#   -DENABLE_JOURNALD_LOG=OFF  # if libsystemd-dev not installed

# Build (use -j to limit parallelism if you have limited RAM)
# Each WebKit build process uses ~1.5GB RAM
ninja -C build -j$(nproc)

# Install
sudo DESTDIR="${DESTDIR:-}" ninja -C build install
cd ..

# Show ccache stats
ccache -s

# === 4. Update library cache ===
sudo ldconfig
