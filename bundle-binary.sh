#!/bin/bash
# bundle-binary.sh
# Run this script ONCE before archiving / distributing the app.
# It builds the Go binary and copies it into the Xcode project's
# Resources folder so Bundle.main.path(forResource:) can find it.

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
RESOURCES_DIR="$REPO_ROOT/mac-app/PortScannerApp/PortScannerApp/Resources"

echo "▶ Building Go binary..."
cd "$BACKEND_DIR"
go build -o port-scanner .
echo "  ✓ Built: $BACKEND_DIR/port-scanner"

echo "▶ Copying binary to Xcode Resources..."
mkdir -p "$RESOURCES_DIR"
cp port-scanner "$RESOURCES_DIR/port-scanner"
chmod +x "$RESOURCES_DIR/port-scanner"
echo "  ✓ Copied to: $RESOURCES_DIR/port-scanner"

echo ""
echo "✅ Done! The binary is now bundled."
echo "   In Xcode: Add Resources/port-scanner to the project"
echo "   (right-click PortScannerApp group → Add Files → select Resources/port-scanner)"
echo "   Then rebuild (⌘B) and the app will work as a standalone .app"
