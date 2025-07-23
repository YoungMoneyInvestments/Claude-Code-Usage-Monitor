# macOS Automation for Claude Code Usage Monitor

This guide explains how to set up automatic monitoring of Claude Code usage on macOS using `launchd`.

## Overview

The macOS automation uses `launchd` (the native macOS service manager) to run the Claude Code Usage Monitor at regular intervals. This ensures your usage is tracked automatically without manual intervention.

### Why Automated Monitoring is Important

Claude implements a 5-hour rolling rate limit system. Automated monitoring helps you:
- **Track the 5-hour reset cycle** - Know exactly when your rate limits will refresh
- **Optimize your usage patterns** - Plan intensive coding sessions around the 5-hour windows
- **Monitor rate limit recovery** - See in real-time as your available usage regenerates
- **Avoid hitting limits unexpectedly** - Get early awareness when approaching rate limits
- **Maximize productivity** - Time your work sessions to align with fresh rate limit periods

By running the monitor automatically every 5 hours, it checks your usage status precisely when the rate limit cycle refreshes, helping you stay aware of your available capacity.

## Prerequisites

- macOS 10.10 or later
- Python 3.7 or later
- Claude Code Usage Monitor installed and configured
- Access to modify LaunchAgents (user-level permissions)

## Setup Instructions

### 1. Clone and Configure the Monitor

First, ensure you have the Claude Code Usage Monitor set up:

```bash
git clone https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor.git
cd Claude-Code-Usage-Monitor
pip install -r requirements.txt
```

### 2. Configure the LaunchAgent

1. Copy the template plist file:
   ```bash
   cp macos-automation/com.claudecode.usage.monitor.plist ~/Library/LaunchAgents/
   ```

2. Edit the plist file to match your system:
   ```bash
   nano ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
   ```

3. Update the following placeholders:
   - Replace `/path/to/Claude-Code-Usage-Monitor/monitor.py` with the actual path to your monitor.py file
   - The `StartInterval` is set to 18000 seconds (5 hours) to match Claude's rate limit cycle

### 3. Load the LaunchAgent

```bash
launchctl load ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
```

### 4. Verify It's Running

Check the status:
```bash
launchctl list | grep claude
```

Check the logs:
```bash
tail -f /tmp/claude-usage-monitor.log
tail -f /tmp/claude-usage-monitor.error
```

## Configuration Options

### Plist Parameters

- **Label**: Unique identifier for the service (don't change this)
- **ProgramArguments**: Command to execute (python3 path and script path)
- **RunAtLoad**: Start automatically when the system boots
- **StartInterval**: How often to run in seconds (18000 = 5 hours)
- **StandardOutPath**: Where to save standard output logs
- **StandardErrorPath**: Where to save error logs
- **KeepAlive**: Whether to restart if the process dies (set to false for interval-based execution)

### Adjusting Run Frequency

To change how often the monitor runs, modify the `StartInterval` value:
- 3600 = every hour
- 7200 = every 2 hours
- 10800 = every 3 hours
- 18000 = every 5 hours (default - matches Claude's rate limit cycle)
- 86400 = once per day

## Managing the Service

### Stop the service
```bash
launchctl unload ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
```

### Start the service
```bash
launchctl load ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
```

### Restart the service
```bash
launchctl unload ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
launchctl load ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
```

### Remove the service
```bash
launchctl unload ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
rm ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist
```

## Troubleshooting

### Service not starting
1. Check the error log: `cat /tmp/claude-usage-monitor.error`
2. Verify the Python path: `which python3`
3. Ensure the monitor.py path is correct
4. Check file permissions: `ls -la ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist`

### Permission issues
If you get permission errors, ensure:
- The plist file is owned by your user: `chown $(whoami) ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist`
- The plist has correct permissions: `chmod 644 ~/Library/LaunchAgents/com.claudecode.usage.monitor.plist`

### Monitor not running at expected intervals
1. Check if the service is loaded: `launchctl list | grep claude`
2. Review system logs: `log show --predicate 'subsystem == "com.apple.xpc.launchd"' --info --last 1h | grep claude`

## Alternative: Using cron

If you prefer using cron instead of launchd:

1. Open crontab:
   ```bash
   crontab -e
   ```

2. Add the following line (runs every 5 hours):
   ```
   0 */5 * * * /usr/bin/python3 /path/to/Claude-Code-Usage-Monitor/monitor.py >> /tmp/claude-usage-monitor.log 2>&1
   ```

Note: macOS may prompt you to grant cron full disk access in System Preferences > Security & Privacy > Privacy > Full Disk Access.

## Security Considerations

- The monitor runs with user-level permissions
- Log files are stored in `/tmp` which is cleared on reboot
- No sensitive data is stored in the plist file
- Consider adjusting log file permissions if they contain sensitive information

## Contributing

If you find issues or have improvements for the macOS automation setup, please submit a pull request or open an issue in the main repository.