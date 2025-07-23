#!/bin/bash

# Claude Code Usage Monitor - macOS LaunchAgent Setup Script
# This script automates the setup of the LaunchAgent for macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for macOS only."
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_status "Claude Code Usage Monitor - macOS Setup"
echo "========================================"
echo

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.7 or later."
    exit 1
fi

PYTHON_PATH=$(which python3)
print_status "Found Python 3 at: $PYTHON_PATH"

# Check if monitor.py exists
MONITOR_SCRIPT="$PROJECT_ROOT/monitor.py"
if [ ! -f "$MONITOR_SCRIPT" ]; then
    print_error "monitor.py not found at: $MONITOR_SCRIPT"
    print_error "Please ensure you're running this script from the correct directory."
    exit 1
fi

print_status "Found monitor.py at: $MONITOR_SCRIPT"

# Create LaunchAgents directory if it doesn't exist
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
if [ ! -d "$LAUNCH_AGENTS_DIR" ]; then
    print_warning "Creating LaunchAgents directory..."
    mkdir -p "$LAUNCH_AGENTS_DIR"
fi

# Generate the plist file with correct paths
PLIST_TEMPLATE="$SCRIPT_DIR/com.claudecode.usage.monitor.plist"
PLIST_DEST="$LAUNCH_AGENTS_DIR/com.claudecode.usage.monitor.plist"

print_status "Generating LaunchAgent configuration..."

# Create the plist with actual paths
cat > "$PLIST_DEST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claudecode.usage.monitor</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_PATH</string>
        <string>$MONITOR_SCRIPT</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>StartInterval</key>
    <integer>18000</integer>
    
    <key>StandardOutPath</key>
    <string>/tmp/claude-usage-monitor.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/claude-usage-monitor.error</string>
    
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

print_status "LaunchAgent configuration created at: $PLIST_DEST"

# Set correct permissions
chmod 644 "$PLIST_DEST"

# Unload existing service if it exists
if launchctl list | grep -q "com.claudecode.usage.monitor"; then
    print_warning "Existing service found. Unloading..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Load the new service
print_status "Loading LaunchAgent..."
if launchctl load "$PLIST_DEST"; then
    print_status "LaunchAgent loaded successfully!"
else
    print_error "Failed to load LaunchAgent. Please check the error messages above."
    exit 1
fi

# Verify it's running
sleep 2
if launchctl list | grep -q "com.claudecode.usage.monitor"; then
    print_status "Service is running!"
    echo
    echo "The Claude Code Usage Monitor will now run automatically every 5 hours."
    echo
    echo "Useful commands:"
    echo "  - Check status:  launchctl list | grep claude"
    echo "  - View logs:     tail -f /tmp/claude-usage-monitor.log"
    echo "  - View errors:   tail -f /tmp/claude-usage-monitor.error"
    echo "  - Stop service:  launchctl unload ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist"
    echo "  - Start service: launchctl load ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist"
else
    print_error "Service doesn't appear to be running. Check the error log:"
    echo "  tail -f /tmp/claude-usage-monitor.error"
fi

echo
print_status "Setup complete!"