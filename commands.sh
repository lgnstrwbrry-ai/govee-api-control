#!/bin/bash
#
# Govee LAN Control Plugin - Commands Handler
# File: /opt/fpp/plugins/govee-lan-control/commands.sh
#
# This script handles FPP command integration for Govee control
#

PLUGINDIR="/home/fpp/media/plugins/govee-lan-control"
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