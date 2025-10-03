#!/bin/bash
# Script to check C++11 ABI in the compiled library

echo "=== Checking C++11 ABI in libwebrtc ==="
echo

# Find the static library
LIB_PATH=$(find /opt/libwebrtc/out -name "libwebrtc.a" -o -name "libwebrtc.so" 2>/dev/null | head -1)
INSTALLED_LIB=$(find /usr/local/lib -name "libwebrtc.a" -o -name "libwebrtc.so" 2>/dev/null | head -1)

if [ -z "$LIB_PATH" ] && [ -z "$INSTALLED_LIB" ]; then
    echo "Error: libwebrtc library not found!"
    exit 1
fi

# Use whichever we found
LIB="${LIB_PATH:-$INSTALLED_LIB}"
echo "Library found at: $LIB"
echo

# Check for C++11 ABI symbols
echo "=== Checking for C++11 ABI symbols ==="
echo "Looking for __cxx11 namespace (indicates new ABI)..."
if nm -C "$LIB" 2>/dev/null | grep -q "__cxx11"; then
    echo "✓ Found __cxx11 symbols (NEW C++11 ABI)"
    echo "Sample symbols:"
    nm -C "$LIB" 2>/dev/null | grep "__cxx11" | head -5
else
    echo "✗ No __cxx11 symbols found (OLD pre-C++11 ABI)"
fi
echo

echo "Looking for old ABI string symbols..."
if nm -C "$LIB" 2>/dev/null | grep -E "std::basic_string|std::string" | grep -v "__cxx11" | head -1 >/dev/null; then
    echo "✓ Found old ABI string symbols"
    echo "Sample symbols:"
    nm -C "$LIB" 2>/dev/null | grep -E "std::basic_string|std::string" | grep -v "__cxx11" | head -3
else
    echo "✗ No old ABI string symbols found"
fi
echo

# Check pkg-config file
echo "=== Checking LibWebRTC.pc ==="
if [ -f "/usr/local/lib/pkgconfig/LibWebRTC.pc" ]; then
    echo "Cflags from pkg-config:"
    grep "Cflags:" /usr/local/lib/pkgconfig/LibWebRTC.pc
    if grep -q "_GLIBCXX_USE_CXX11_ABI=0" /usr/local/lib/pkgconfig/LibWebRTC.pc; then
        echo "⚠ pkg-config specifies OLD ABI (_GLIBCXX_USE_CXX11_ABI=0)"
    elif grep -q "_GLIBCXX_USE_CXX11_ABI=1" /usr/local/lib/pkgconfig/LibWebRTC.pc; then
        echo "✓ pkg-config specifies NEW ABI (_GLIBCXX_USE_CXX11_ABI=1)"
    else
        echo "ℹ pkg-config does not specify ABI (will use compiler default)"
    fi
else
    echo "pkg-config file not found"
fi
echo

# Check CMake config
echo "=== Checking LibWebRTCConfig.cmake ==="
if [ -f "/usr/local/lib/cmake/LibWebRTC/LibWebRTCConfig.cmake" ]; then
    echo "LIBWEBRTC_DEFINITIONS from CMake config:"
    grep "LIBWEBRTC_DEFINITIONS" /usr/local/lib/cmake/LibWebRTC/LibWebRTCConfig.cmake
    if grep -q "_GLIBCXX_USE_CXX11_ABI=0" /usr/local/lib/cmake/LibWebRTC/LibWebRTCConfig.cmake; then
        echo "⚠ CMake config specifies OLD ABI (_GLIBCXX_USE_CXX11_ABI=0)"
    elif grep -q "_GLIBCXX_USE_CXX11_ABI=1" /usr/local/lib/cmake/LibWebRTC/LibWebRTCConfig.cmake; then
        echo "✓ CMake config specifies NEW ABI (_GLIBCXX_USE_CXX11_ABI=1)"
    else
        echo "ℹ CMake config does not specify ABI (will use compiler default)"
    fi
else
    echo "CMake config file not found"
fi
echo

# Check GN args that were used
echo "=== GN Build Arguments Used ==="
if [ -f "/opt/libwebrtc/out/webrtc/build/out/Debug/args.gn" ] || [ -f "/opt/libwebrtc/out/webrtc/build/out/Release/args.gn" ]; then
    ARGS_FILE=$(find /opt/libwebrtc/out/webrtc -name "args.gn" | head -1)
    echo "args.gn found at: $ARGS_FILE"
    cat "$ARGS_FILE"
else
    echo "args.gn not found"
fi
