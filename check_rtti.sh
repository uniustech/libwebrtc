#!/bin/bash
# Script to check RTTI in the compiled library

echo "=== Checking RTTI in libwebrtc ==="
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

# Check for RTTI symbols
echo "=== Checking for typeinfo symbols (RTTI enabled) ==="
if nm -C "$LIB" 2>/dev/null | grep -i "typeinfo" | head -5; then
    echo "✓ Found typeinfo symbols (RTTI enabled)"
else
    echo "✗ No typeinfo symbols found (RTTI may be disabled)"
fi
echo

echo "=== Checking for vtable symbols ==="
if nm -C "$LIB" 2>/dev/null | grep -i "vtable" | head -5; then
    echo "✓ Found vtable symbols"
else
    echo "✗ No vtable symbols found"
fi
echo

echo "=== Checking for dynamic_cast usage ==="
if nm -C "$LIB" 2>/dev/null | grep -i "dynamic_cast" | head -3; then
    echo "✓ Found dynamic_cast usage (RTTI enabled)"
else
    echo "ℹ No explicit dynamic_cast symbols found (may be inlined)"
fi
echo

echo "=== Checking for __cxa_dynamic_cast (RTTI runtime) ==="
if nm -C "$LIB" 2>/dev/null | grep "__cxa_dynamic_cast" | head -3; then
    echo "✓ Found __cxa_dynamic_cast (RTTI runtime support)"
else
    echo "ℹ No __cxa_dynamic_cast found (may be in external libs)"
fi
echo

echo "=== Checking GN build arguments for RTTI ==="
if [ -f "/opt/libwebrtc/out/webrtc/src/out/Release/args.gn" ] || [ -f "/opt/libwebrtc/out/webrtc/src/out/Debug/args.gn" ]; then
    ARGS_FILE=$(find /opt/libwebrtc/out/webrtc -name "args.gn" | head -1)
    echo "args.gn found at: $ARGS_FILE"
    if grep -q "use_rtti.*true" "$ARGS_FILE"; then
        echo "✓ use_rtti=true found in build arguments"
    else
        echo "⚠ use_rtti=true not found in args.gn"
    fi
    echo "Full args.gn content:"
    cat "$ARGS_FILE"
else
    echo "args.gn not found"
fi
echo

echo "=== Summary ==="
TYPEINFO_COUNT=$(nm -C "$LIB" 2>/dev/null | grep -c "typeinfo" || echo "0")
VTABLE_COUNT=$(nm -C "$LIB" 2>/dev/null | grep -c "vtable" || echo "0")
echo "Typeinfo symbols: $TYPEINFO_COUNT"
echo "Vtable symbols: $VTABLE_COUNT"

if [ "$TYPEINFO_COUNT" -gt "0" ] && [ "$VTABLE_COUNT" -gt "0" ]; then
    echo "✅ RTTI appears to be ENABLED"
else
    echo "❌ RTTI may be DISABLED or not used"
fi