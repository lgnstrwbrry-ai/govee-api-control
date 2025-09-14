#!/bin/bash
#
# Govee Quick Control Scripts for FPP Sequencer
# These are lightweight scripts for direct sequencer integration
#

# =============================================================================
# govee-on.sh - Turn Govee lights ON
# Usage: ./govee-on.sh [device_ip] [port]
# =============================================================================

#!/bin/bash
# File: govee-on.sh

# Default settings (can be overridden by command line arguments)
DEVICE_IP="${1:-192.168.1.100}"
DEVICE_PORT="${2:-4003}"
TIMEOUT=3

# Command to turn lights ON
COMMAND='{"msg":{"cmd":"turn","data":{"value":1}}}'

# Log function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee ON] $1" >> /tmp/govee-sequencer.log
}

# Send UDP command
send_command() {
    local result
    result=$(echo -n "$COMMAND" | timeout $TIMEOUT nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_action "SUCCESS: Lights turned ON ($DEVICE_IP:$DEVICE_PORT)"
        echo "Govee lights turned ON"
        return 0
    else
        log_action "ERROR: Failed to turn lights ON ($DEVICE_IP:$DEVICE_PORT) - Exit code: $exit_code"
        echo "ERROR: Failed to turn Govee lights ON"
        return 1
    fi
}

# Main execution
log_action "Turning lights ON - Target: $DEVICE_IP:$DEVICE_PORT"
send_command

# =============================================================================
# govee-off.sh - Turn Govee lights OFF  
# Usage: ./govee-off.sh [device_ip] [port]
# =============================================================================

#!/bin/bash
# File: govee-off.sh

# Default settings (can be overridden by command line arguments)
DEVICE_IP="${1:-192.168.1.100}"
DEVICE_PORT="${2:-4003}"
TIMEOUT=3

# Command to turn lights OFF
COMMAND='{"msg":{"cmd":"turn","data":{"value":0}}}'

# Log function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee OFF] $1" >> /tmp/govee-sequencer.log
}

# Send UDP command
send_command() {
    local result
    result=$(echo -n "$COMMAND" | timeout $TIMEOUT nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_action "SUCCESS: Lights turned OFF ($DEVICE_IP:$DEVICE_PORT)"
        echo "Govee lights turned OFF"
        return 0
    else
        log_action "ERROR: Failed to turn lights OFF ($DEVICE_IP:$DEVICE_PORT) - Exit code: $exit_code"
        echo "ERROR: Failed to turn Govee lights OFF"
        return 1
    fi
}

# Main execution
log_action "Turning lights OFF - Target: $DEVICE_IP:$DEVICE_PORT"
send_command

# =============================================================================
# govee-brightness.sh - Set brightness
# Usage: ./govee-brightness.sh <brightness> [device_ip] [port]
# =============================================================================

#!/bin/bash
# File: govee-brightness.sh

# Check if brightness parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <brightness> [device_ip] [port]"
    echo "Brightness: 0-100"
    exit 1
fi

BRIGHTNESS="$1"
DEVICE_IP="${2:-192.168.1.100}"
DEVICE_PORT="${3:-4003}"
TIMEOUT=3

# Validate brightness value
if ! [[ "$BRIGHTNESS" =~ ^[0-9]+$ ]] || [ "$BRIGHTNESS" -lt 0 ] || [ "$BRIGHTNESS" -gt 100 ]; then
    echo "ERROR: Brightness must be a number between 0 and 100"
    exit 1
fi

# Command to set brightness
COMMAND="{\"msg\":{\"cmd\":\"brightness\",\"data\":{\"value\":$BRIGHTNESS}}}"

# Log function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee BRIGHTNESS] $1" >> /tmp/govee-sequencer.log
}

# Send UDP command
send_command() {
    local result
    result=$(echo -n "$COMMAND" | timeout $TIMEOUT nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_action "SUCCESS: Brightness set to $BRIGHTNESS% ($DEVICE_IP:$DEVICE_PORT)"
        echo "Govee brightness set to $BRIGHTNESS%"
        return 0
    else
        log_action "ERROR: Failed to set brightness ($DEVICE_IP:$DEVICE_PORT) - Exit code: $exit_code"
        echo "ERROR: Failed to set Govee brightness"
        return 1
    fi
}

# Main execution
log_action "Setting brightness to $BRIGHTNESS% - Target: $DEVICE_IP:$DEVICE_PORT"
send_command

# =============================================================================
# govee-color.sh - Set RGB color
# Usage: ./govee-color.sh <red> <green> <blue> [device_ip] [port]
# =============================================================================

#!/bin/bash
# File: govee-color.sh

# Check if RGB parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <red> <green> <blue> [device_ip] [port]"
    echo "RGB values: 0-255"
    echo "Examples:"
    echo "  $0 255 0 0      # Red"
    echo "  $0 0 255 0      # Green" 
    echo "  $0 0 0 255      # Blue"
    echo "  $0 255 255 255  # White"
    exit 1
fi

RED="$1"
GREEN="$2"
BLUE="$3"
DEVICE_IP="${4:-192.168.1.100}"
DEVICE_PORT="${5:-4003}"
TIMEOUT=3

# Validate RGB values
for color in "$RED" "$GREEN" "$BLUE"; do
    if ! [[ "$color" =~ ^[0-9]+$ ]] || [ "$color" -lt 0 ] || [ "$color" -gt 255 ]; then
        echo "ERROR: RGB values must be numbers between 0 and 255"
        exit 1
    fi
done

# Command to set color
COMMAND="{\"msg\":{\"cmd\":\"colorwc\",\"data\":{\"color\":{\"r\":$RED,\"g\":$GREEN,\"b\":$BLUE},\"colorTemInKelvin\":0}}}"

# Log function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee COLOR] $1" >> /tmp/govee-sequencer.log
}

# Send UDP command
send_command() {
    local result
    result=$(echo -n "$COMMAND" | timeout $TIMEOUT nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_action "SUCCESS: Color set to RGB($RED,$GREEN,$BLUE) ($DEVICE_IP:$DEVICE_PORT)"
        echo "Govee color set to RGB($RED,$GREEN,$BLUE)"
        return 0
    else
        log_action "ERROR: Failed to set color ($DEVICE_IP:$DEVICE_PORT) - Exit code: $exit_code"
        echo "ERROR: Failed to set Govee color"
        return 1
    fi
}

# Main execution
log_action "Setting color to RGB($RED,$GREEN,$BLUE) - Target: $DEVICE_IP:$DEVICE_PORT"
send_command

# =============================================================================
# govee-preset.sh - Quick color presets
# Usage: ./govee-preset.sh <preset_name> [device_ip] [port]
# =============================================================================

#!/bin/bash
# File: govee-preset.sh

# Check if preset parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <preset_name> [device_ip] [port]"
    echo ""
    echo "Available presets:"
    echo "  red, green, blue, white, yellow, purple, orange, pink, cyan, magenta"
    echo "  warm, cool, off"
    echo ""
    echo "Examples:"
    echo "  $0 red"
    echo "  $0 warm"
    echo "  $0 off"
    exit 1
fi

PRESET="$1"
DEVICE_IP="${2:-192.168.1.100}"
DEVICE_PORT="${3:-4003}"
TIMEOUT=3

# Define color presets
case "$PRESET" in
    "red")     RED=255; GREEN=0;   BLUE=0   ;;
    "green")   RED=0;   GREEN=255; BLUE=0   ;;
    "blue")    RED=0;   GREEN=0;   BLUE=255 ;;
    "white")   RED=255; GREEN=255; BLUE=255 ;;
    "yellow")  RED=255; GREEN=255; BLUE=0   ;;
    "purple")  RED=128; GREEN=0;   BLUE=128 ;;
    "orange")  RED=255; GREEN=165; BLUE=0   ;;
    "pink")    RED=255; GREEN=192; BLUE=203 ;;
    "cyan")    RED=0;   GREEN=255; BLUE=255 ;;
    "magenta") RED=255; GREEN=0;   BLUE=255 ;;
    "warm")    RED=255; GREEN=180; BLUE=120 ;;
    "cool")    RED=180; GREEN=220; BLUE=255 ;;
    "off")     RED=0;   GREEN=0;   BLUE=0   ;;
    *)
        echo "ERROR: Unknown preset '$PRESET'"
        echo "Available: red, green, blue, white, yellow, purple, orange, pink, cyan, magenta, warm, cool, off"
        exit 1
        ;;
esac

# Command to set color
COMMAND="{\"msg\":{\"cmd\":\"colorwc\",\"data\":{\"color\":{\"r\":$RED,\"g\":$GREEN,\"b\":$BLUE},\"colorTemInKelvin\":0}}}"

# Log function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee PRESET] $1" >> /tmp/govee-sequencer.log
}

# Send UDP command
send_command() {
    local result
    result=$(echo -n "$COMMAND" | timeout $TIMEOUT nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_action "SUCCESS: Preset '$PRESET' applied RGB($RED,$GREEN,$BLUE) ($DEVICE_IP:$DEVICE_PORT)"
        echo "Govee preset '$PRESET' applied"
        return 0
    else
        log_action "ERROR: Failed to apply preset '$PRESET' ($DEVICE_IP:$DEVICE_PORT) - Exit code: $exit_code"
        echo "ERROR: Failed to apply Govee preset '$PRESET'"
        return 1
    fi
}

# Main execution
log_action "Applying preset '$PRESET' RGB($RED,$GREEN,$BLUE) - Target: $DEVICE_IP:$DEVICE_PORT"
send_command

# =============================================================================
# Installation script to create individual files
# =============================================================================

#!/bin/bash
# File: create-sequencer-scripts.sh

SCRIPT_DIR="/home/fpp/media/plugins/govee-lan-control"
SCRIPT_DIR_ALT="/home/fpp/media/scripts"  # Alternative location for global access

echo "Creating Govee sequencer control scripts..."

# Create main plugin script directory
mkdir -p "$SCRIPT_DIR"

# Create alternative scripts directory for easier access
mkdir -p "$SCRIPT_DIR_ALT"

# Create govee-on.sh
cat > "$SCRIPT_DIR/govee-on.sh" << 'EOF'
#!/bin/bash
DEVICE_IP="${1:-192.168.1.100}"
DEVICE_PORT="${2:-4003}"
COMMAND='{"msg":{"cmd":"turn","data":{"value":1}}}'
echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee ON] Turning lights ON - $DEVICE_IP:$DEVICE_PORT" >> /tmp/govee-sequencer.log
echo -n "$COMMAND" | timeout 3 nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Govee lights turned ON"
else
    echo "ERROR: Failed to turn Govee lights ON"
fi
EOF

# Create govee-off.sh  
cat > "$SCRIPT_DIR/govee-off.sh" << 'EOF'
#!/bin/bash
DEVICE_IP="${1:-192.168.1.100}"
DEVICE_PORT="${2:-4003}"
COMMAND='{"msg":{"cmd":"turn","data":{"value":0}}}'
echo "$(date '+%Y-%m-%d %H:%M:%S') [Govee OFF] Turning lights OFF - $DEVICE_IP:$DEVICE_PORT" >> /tmp/govee-sequencer.log
echo -n "$COMMAND" | timeout 3 nc -u -w1 "$DEVICE_IP" "$DEVICE_PORT" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Govee lights turned OFF"
else
    echo "ERROR: Failed to turn Govee lights OFF"
fi
EOF

# Create copies in alternative location for easier access
cp "$SCRIPT_DIR/govee-on.sh" "$SCRIPT_DIR_ALT/"
cp "$SCRIPT_DIR/govee-off.sh" "$SCRIPT_DIR_ALT/"

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh
chmod +x "$SCRIPT_DIR_ALT"/*.sh

# Set proper ownership
chown -R fpp:fpp "$SCRIPT_DIR"
chown -R fpp:fpp "$SCRIPT_DIR_ALT"

echo "✅ Scripts created successfully!"
echo ""
echo "Scripts available at:"
echo "  $SCRIPT_DIR/govee-on.sh"
echo "  $SCRIPT_DIR/govee-off.sh"
echo "  $SCRIPT_DIR_ALT/govee-on.sh" 
echo "  $SCRIPT_DIR_ALT/govee-off.sh"
echo ""
echo "Usage in FPP Sequencer:"
echo "  Command: $SCRIPT_DIR_ALT/govee-on.sh"
echo "  Command: $SCRIPT_DIR_ALT/govee-off.sh 192.168.1.101"
echo ""
echo "Logs written to: /tmp/govee-sequencer.log"