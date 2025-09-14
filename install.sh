#!/bin/bash
#
# Govee LAN Control Plugin - Installation Script
# File: install.sh
#
# This script installs the Govee LAN Control plugin for Falcon Player
#

PLUGIN_DIR="/opt/fpp/plugins/govee-lan-control"
PLUGIN_NAME="Govee LAN Control"

echo "========================================="
echo "Installing $PLUGIN_NAME Plugin"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check if FPP directory exists
if [ ! -d "/opt/fpp" ]; then
    echo "Error: Falcon Player (FPP) directory not found!"
    echo "Please ensure FPP is properly installed."
    exit 1
fi

# Create plugin directory
echo "Creating plugin directory..."
mkdir -p "$PLUGIN_DIR"

# Set proper permissions
echo "Setting permissions..."
chown -R fpp:fpp "$PLUGIN_DIR"
chmod -R 755 "$PLUGIN_DIR"

# Create main plugin files
echo "Creating plugin configuration..."
cat > "$PLUGIN_DIR/plugin.json" << 'EOF'
{
  "pluginName": "Govee LAN Control",
  "pluginVersion": "1.0.0",
  "pluginAuthor": "FPP Community",
  "pluginDescription": "Control Govee lights via LAN API from Falcon Player",
  "pluginLicense": "GPL",
  "pluginURL": "https://github.com/FalconChristmas/fpp-plugin-govee-lan",
  "pluginConfigurable": 1,
  "pluginConflicts": [],
  "pluginProvides": ["govee-control"],
  "pluginRequires": [],
  "settings": {
    "govee_deviceIP": {
      "name": "govee_deviceIP",
      "description": "Govee Device IP Address",
      "type": "string",
      "default": "192.168.1.100",
      "restart": 0
    },
    "govee_devicePort": {
      "name": "govee_devicePort", 
      "description": "Govee Device Port",
      "type": "int",
      "default": 4003,
      "restart": 0
    },
    "govee_timeout": {
      "name": "govee_timeout",
      "description": "Connection Timeout (seconds)",
      "type": "int", 
      "default": 5,
      "restart": 0
    },
    "govee_debug": {
      "name": "govee_debug",
      "description": "Enable Debug Logging",
      "type": "bool",
      "default": 0,
      "restart": 0
    }
  },
  "commands": {
    "Govee Turn On": {
      "name": "Govee Turn On",
      "args": [],
      "description": "Turn Govee lights on"
    },
    "Govee Turn Off": {
      "name": "Govee Turn Off", 
      "args": [],
      "description": "Turn Govee lights off"
    },
    "Govee Set Brightness": {
      "name": "Govee Set Brightness",
      "args": [
        {
          "name": "brightness",
          "type": "int",
          "description": "Brightness (0-100)",
          "default": 100
        }
      ],
      "description": "Set Govee light brightness"
    },
    "Govee Set Color": {
      "name": "Govee Set Color",
      "args": [
        {
          "name": "red",
          "type": "int", 
          "description": "Red (0-255)",
          "default": 255
        },
        {
          "name": "green",
          "type": "int",
          "description": "Green (0-255)", 
          "default": 255
        },
        {
          "name": "blue",
          "type": "int",
          "description": "Blue (0-255)",
          "default": 255
        }
      ],
      "description": "Set Govee light RGB color"
    },
    "Govee Set Temperature": {
      "name": "Govee Set Temperature",
      "args": [
        {
          "name": "temperature",
          "type": "int",
          "description": "Color Temperature (2000-9000K)",
          "default": 4000
        }
      ],
      "description": "Set Govee light color temperature"
    }
  }
}
EOF

# Create command handler script
echo "Creating command handler..."
cat > "$PLUGIN_DIR/commands.sh" << 'EOF'
#!/bin/bash
#
# Govee LAN Control Plugin - Commands Handler
#

PLUGINDIR="/opt/fpp/plugins/govee-lan-control"
LOGFILE="/tmp/govee-plugin.log"
API_ENDPOINT="http://localhost/plugin.php?plugin=govee-lan-control&file=api.php"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee Plugin] $1" >> "$LOGFILE"
}

# Function to make API call
call_api() {
    local action="$1"
    local data="$2"
    local method="${3:-POST}"
    
    if [ "$method" = "GET" ]; then
        curl -s -X GET "$API_ENDPOINT?action=$action" 2>/dev/null
    else
        curl -s -X POST "$API_ENDPOINT?action=$action" \
             -H "Content-Type: application/json" \
             -d "$data" 2>/dev/null
    fi
}

# Command handlers
case "$1" in
    "Govee Turn On")
        log_message "Command: Turn On"
        result=$(call_api "power" '{"power": true}')
        echo "$result"
        ;;
        
    "Govee Turn Off")
        log_message "Command: Turn Off"  
        result=$(call_api "power" '{"power": false}')
        echo "$result"
        ;;
        
    "Govee Set Brightness")
        brightness="${2:-100}"
        log_message "Command: Set Brightness to $brightness"
        result=$(call_api "brightness" "{\"brightness\": $brightness}")
        echo "$result"
        ;;
        
    "Govee Set Color")
        red="${2:-255}"
        green="${3:-255}"
        blue="${4:-255}"
        log_message "Command: Set Color RGB($red,$green,$blue)"
        result=$(call_api "color" "{\"r\": $red, \"g\": $green, \"b\": $blue}")
        echo "$result"
        ;;
        
    "Govee Set Temperature")
        temp="${2:-4000}"
        log_message "Command: Set Temperature to $temp K"
        result=$(call_api "temperature" "{\"temperature\": $temp}")
        echo "$result"
        ;;
        
    *)
        echo "Unknown command: $1"
        echo "Available commands:"
        echo "  - Govee Turn On"
        echo "  - Govee Turn Off" 
        echo "  - Govee Set Brightness <0-100>"
        echo "  - Govee Set Color <r> <g> <b>"
        echo "  - Govee Set Temperature <2000-9000>"
        exit 1
        ;;
esac
EOF

# Make command script executable
chmod +x "$PLUGIN_DIR/commands.sh"

# Create README
echo "Creating documentation..."
cat > "$PLUGIN_DIR/README.md" << 'EOF'
# Govee LAN Control Plugin for Falcon Player

This plugin allows you to control Govee lights directly from Falcon Player using the LAN Control API.

## Features

- **GUI Control**: Web-based interface for easy light management
- **FPP Integration**: Commands available in sequences and events
- **Real-time Control**: Instant power, brightness, and color control
- **Effects**: Built-in strobe, rainbow, and fade effects
- **Network Scanning**: Automatic device discovery
- **Logging**: Comprehensive activity logging

## Installation

1. Copy plugin files to `/opt/fpp/plugins/govee-lan-control/`
2. Set proper permissions: `sudo chown -R fpp:fpp /opt/fpp/plugins/govee-lan-control`
3. Restart FPP or refresh plugins
4. Access via "Content Setup" → "Plugins" → "Govee LAN Control"

Or install directly from GitHub:
```bash
cd /opt/fpp/plugins
git clone https://github.com/lgnstrwbrry-ai/govee-api-control govee-lan-control
sudo chown -R fpp:fpp govee-lan-control
sudo chmod +x govee-lan-control/commands.sh
```

## Configuration

1. **Device IP**: Enter your Govee device's IP address
2. **Port**: Usually 4003 (default Govee LAN API port)
3. **Timeout**: Connection timeout in seconds
4. **Debug**: Enable detailed logging

## Usage

### Web Interface
- Access through FPP's plugin interface
- Use sliders, buttons, and presets for immediate control
- Monitor status and view logs in real-time

### Commands in Sequences
Add these commands to your sequences:
- `Govee Turn On`
- `Govee Turn Off`
- `Govee Set Brightness 75`
- `Govee Set Color 255 0 0` (Red)
- `Govee Set Temperature 3000`

### Event Scripts
Use in event scripts:
```bash
/home/fpp/media/plugins/govee-lan-control/commands.sh "Govee Turn On"
```

## Device Discovery

Use the "Scan Network" button to find Govee devices on your local network.

## Troubleshooting

1. **Connection Issues**: 
   - Verify device IP address
   - Check network connectivity
   - Ensure Govee device has LAN API enabled

2. **Commands Not Working**:
   - Check plugin logs
   - Verify device compatibility
   - Test connection using web interface

3. **Logs Location**: `/tmp/govee-plugin.log`

## Supported Devices

Most Govee devices with LAN API support, including:
- LED Strips (H6159, H6163, etc.)
- Bulbs
- Light Bars
- Immersion TV Backlights

## API Endpoints

- `GET api.php?action=status` - Device status
- `POST api.php?action=power` - Power control
- `POST api.php?action=brightness` - Brightness control
- `POST api.php?action=color` - Color control
- `POST api.php?action=temperature` - Color temperature

## License

GPL v3 - See LICENSE file for details
EOF

# Install dependencies if needed
echo "Checking dependencies..."
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    apt-get update && apt-get install -y curl
fi

# Create log file with proper permissions
touch /tmp/govee-plugin.log
chown fpp:fpp /tmp/govee-plugin.log
chmod 644 /tmp/govee-plugin.log

# Set final permissions
chown -R fpp:fpp "$PLUGIN_DIR"
chmod 644 "$PLUGIN_DIR"/*.json "$PLUGIN_DIR"/*.md "$PLUGIN_DIR"/*.php
chmod 755 "$PLUGIN_DIR"/*.sh

echo ""
echo "========================================="
echo "$PLUGIN_NAME Plugin Installation Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Access FPP web interface"
echo "2. Go to Content Setup → Plugins"
echo "3. Find '$PLUGIN_NAME' and click to configure"
echo "4. Set your Govee device IP address"
echo "5. Test the connection"
echo ""
echo "Plugin files installed to: $PLUGIN_DIR"
echo "Log file location: /tmp/govee-plugin.log"
echo ""
echo "For support and documentation, see:"
echo "$PLUGIN_DIR/README.md"
echo ""