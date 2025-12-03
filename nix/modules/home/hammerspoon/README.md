# Hammerspoon Display Font Adjuster

Automatically adjusts JetBrains IDE font sizes based on your active display configuration. Detects whether you're using the built-in display or an external monitor and applies the appropriate font size.

## Features

- **Automatic Display Detection**: Detects built-in vs. external monitors
- **Font Size Adjustment**: Automatically adjusts IDE fonts when display configuration changes
- **Multi-IDE Support**: Works with all JetBrains IDEs (GoLand, WebStorm, IntelliJ, etc.)
- **Live Updates**: Updates fonts in running IDEs without restart
- **Configuration UI**: Easy-to-use GUI for customizing settings
- **Debug Mode**: Optional verbose logging for troubleshooting

## Quick Start

1. **Launch Hammerspoon**: The configuration loads automatically
2. **Configure Settings**: Press `Cmd+Alt+Ctrl+H` to open the configuration UI
3. **Adjust Font Sizes**: Set your preferred font sizes for different display modes
4. **Select IDEs**: Choose which JetBrains IDEs to monitor

## Debug Mode

Debug mode provides verbose logging and helps troubleshoot issues. It's **disabled by default** to keep your console clean.

### Enabling Debug Mode

Choose one of these methods:

#### 1. Via Configuration UI (Recommended)

1. Press `Cmd+Alt+Ctrl+H` to open settings
2. Check "Enable Debug Mode" under Debug Settings
3. Click "Save Configuration"
4. Reload Hammerspoon: `Cmd+Ctrl+Alt+R` or from menu

#### 2. Via IPC/Console

```bash
# Toggle debug mode
hs -c "toggleDebugMode()"

# Check debug mode status
hs -c "debugModeStatus()"
```

#### 3. Via Environment Variable

```bash
# Launch Hammerspoon with debug mode
DEBUG_MODE=true hs
```

### What Debug Mode Shows

When enabled, debug mode provides:

- **Startup Alert**: "Hammerspoon config loaded (Debug Mode ON)"
- **Verbose Logging**: All debug-level log messages
- **Display Detection Details**: Information about connected displays
- **Font Update Operations**: Details of IDE font changes
- **Configuration Changes**: Logs when settings are modified

### Debug Mode in Groovy Script

The JetBrains font adjustment script also supports debug mode:

```bash
# Enable debug mode for the Groovy script
export DEBUG_MODE=true

# Now when fonts are adjusted, you'll see detailed logs
```

Debug output includes:

- Font size source (temp file vs. environment variable)
- Font family being updated
- Color scheme modifications
- UI refresh operations
- Any errors encountered

## Configuration

### Font Sizes

- **Font Size with External Monitor**: Larger font for external displays (default: 15)
- **Font Size without External Monitor**: Smaller font for built-in display (default: 12)

### JetBrains IDE Patterns

Select which IDEs to monitor:

**Default Patterns** (check to enable):

- GoLand
- WebStorm
- RustRover
- IntelliJ IDEA
- PyCharm
- CLion
- DataGrip
- PhpStorm
- Rider
- AppCode

**Custom Patterns**: Add custom IDE patterns using wildcards (e.g., `AndroidStudio*`)

### Advanced Settings

- **Wake Delay**: Time (seconds) to wait before checking displays after system wake (default: 1.0)
- **Poll Interval**: How often to check for display changes as fallback (default: 5.0)

## Keyboard Shortcuts

- `Cmd+Alt+Ctrl+H`: Open configuration UI

## Troubleshooting

### Hotkey Not Working

1. Check Accessibility Permissions:
   - Go to System Settings > Privacy & Security > Accessibility
   - Ensure Hammerspoon is enabled
2. Enable debug mode to see if hotkey is detected
3. Try reloading Hammerspoon configuration

### Fonts Not Updating

1. **Enable debug mode** to see what's happening
2. Check if your IDE is in the patterns list
3. Verify JetBrains directory path:
   - Default: `~/Library/Application Support/JetBrains`
   - Debug mode will log if directory is not found
4. Ensure IDE configuration directories exist

### Display Detection Issues

1. Enable debug mode to see display detection logs
2. Check display signature changes in logs
3. Verify external monitor is properly connected
4. Try manually triggering: disconnect/reconnect monitor

## Architecture

### Components

1. **init.lua**: Main Hammerspoon configuration
   - Display detection and monitoring
   - Font size coordination
   - Configuration management
   - GUI interface

2. **change-jetbrains-fonts.groovy**: JetBrains IDE font adjuster
   - Updates fonts in running IDEs
   - No restart required
   - Updates UI and editor fonts

### Detection Methods

1. **Screen Watcher**: Primary method for detecting display changes
2. **Caffeine Watcher**: Detects system wake and lock/unlock events
3. **Polling Timer**: Fallback method to catch missed events (5-second interval)

### Font Update Flow

```text
Display Change Detected
  ↓
Determine Display Type
  ↓
Calculate Font Size
  ↓
Update JetBrains Config Files
  ↓
Apply to Running IDEs (via Groovy script)
  ↓
Refresh UI and Editors
```

## Log Levels

| Level   | When Shown          | Purpose                        |
|---------|---------------------|--------------------------------|
| Debug   | Debug mode only     | Detailed troubleshooting info  |
| Info    | Debug mode only     | General operational messages   |
| Warning | Always              | Potential issues               |
| Error   | Always              | Failures and errors            |

## IPC Commands

Hammerspoon IPC allows command-line interaction:

```bash
# Toggle debug mode
hs -c "toggleDebugMode()"

# Check debug status
hs -c "debugModeStatus()"

# Show configuration UI
hs -c "showConfigUI()"

# Manual font size update (for testing)
hs -c "screenChanged()"
```

## File Locations

- **Configuration**: `~/.hammerspoon/init.lua`
- **Groovy Script**: `~/.hammerspoon/change-jetbrains-fonts.groovy`
- **Settings Storage**: Hammerspoon persistent settings (managed automatically)
- **Temp Font Size**: `$TMPDIR/jetbrains-font-size.txt`
- **JetBrains Configs**: `~/Library/Application Support/JetBrains/[IDE]/options/other.xml`

## Best Practices

1. **Keep Debug Mode Off**: Only enable when troubleshooting
2. **Use Configuration UI**: Safer than manual config file editing
3. **Test Display Changes**: Connect/disconnect monitor to verify behavior
4. **Check Logs**: Use Console.app or `hs -c` to view Hammerspoon logs
5. **Backup Settings**: Configuration is stored in Hammerspoon settings

## Version Information

- **Lua Configuration**: 2.0
- **Groovy Script**: 2.0
- **Lua Version**: 5.3+
- **Hammerspoon**: Compatible with latest stable release

## License

Part of smykla-labs dotfiles configuration.
