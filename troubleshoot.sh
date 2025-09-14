#!/bin/bash
#
# Govee Plugin Troubleshooting Script
# Run this to diagnose plugin detection issues
#

echo "========================================="
echo "Govee Plugin Troubleshooting"
echo "========================================="
echo ""

PLUGIN_DIR="/opt/fpp/plugins/govee-lan-control"

# Check if plugin directory exists
echo "1. 📁 Checking plugin directory..."
if [ -d "$PLUGIN_DIR" ]; then
    echo "   ✓ Plugin directory exists: $PLUGIN_DIR"
    echo "   📋 Directory contents:"
    ls -la "$PLUGIN_DIR"
else
    echo "   ❌ Plugin directory NOT found: $PLUGIN_DIR"
    echo "   🔧 Create directory with: sudo mkdir -p $PLUGIN_DIR"
    exit 1
fi

echo ""

# Check required files
echo "2. 📄 Checking required files..."
REQUIRED_FILES=("plugin.json" "index.php" "api.php" "commands.sh")

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PLUGIN_DIR/$file" ]; then
        echo "   ✓ $file exists"
        
        # Check file permissions
        PERMS=$(stat -c "%a" "$PLUGIN_DIR/$file")
        echo "     Permissions: $PERMS"
        
        # Check file size
        SIZE=$(stat -c "%s" "$PLUGIN_DIR/$file")
        if [ "$SIZE" -gt 0 ]; then
            echo "     Size: $SIZE bytes ✓"
        else
            echo "     Size: $SIZE bytes ❌ (file is empty!)"
        fi
        
    else
        echo "   ❌ $file is MISSING"
    fi
done

echo ""

# Check plugin.json syntax
echo "3. 🔍 Validating plugin.json..."
if [ -f "$PLUGIN_DIR/plugin.json" ]; then
    if python3 -m json.tool "$PLUGIN_DIR/plugin.json" > /dev/null 2>&1; then
        echo "   ✓ plugin.json syntax is valid"
        
        # Show key plugin info
        echo "   📊 Plugin Information:"
        python3 -c "
import json
with open('$PLUGIN_DIR/plugin.json', 'r') as f:
    data = json.load(f)
    print(f'     Name: {data.get(\"pluginName\", \"Unknown\")}')
    print(f'     Version: {data.get(\"pluginVersion\", \"Unknown\")}')
    print(f'     Configurable: {data.get(\"pluginConfigurable\", \"Unknown\")}')
    if 'configFiles' in data:
        print(f'     Config Files: {data[\"configFiles\"]}')
    if 'menuItem' in data:
        print(f'     Menu Item: {data[\"menuItem\"]}')
" 2>/dev/null || echo "     ⚠ Could not parse plugin info"
        
    else
        echo "   ❌ plugin.json has SYNTAX ERRORS!"
        echo "   🔧 Check the JSON syntax in plugin.json"
        python3 -m json.tool "$PLUGIN_DIR/plugin.json" 2>&1 | head -5
    fi
else
    echo "   ❌ plugin.json not found"
fi

echo ""

# Check permissions and ownership
echo "4. 🔒 Checking permissions and ownership..."
if [ -d "$PLUGIN_DIR" ]; then
    OWNER=$(stat -c "%U:%G" "$PLUGIN_DIR")
    PERMS=$(stat -c "%a" "$PLUGIN_DIR")
    echo "   Directory owner: $OWNER"
    echo "   Directory permissions: $PERMS"
    
    if [ "$OWNER" = "fpp:fpp" ] || [ "$OWNER" = "root:root" ]; then
        echo "   ✓ Directory ownership looks good"
    else
        echo "   ⚠ Directory should be owned by fpp:fpp or root:root"
        echo "   🔧 Fix with: sudo chown -R fpp:fpp $PLUGIN_DIR"
    fi
fi

echo ""

# Check FPP plugin system
echo "5. 🖥️  Checking FPP environment..."
if [ -f "/opt/fpp/www/common.php" ]; then
    echo "   ✓ FPP common.php found"
else
    echo "   ❌ FPP common.php not found - is FPP installed correctly?"
fi

if [ -d "/opt/fpp/www/plugin.php" ] || [ -f "/opt/fpp/www/plugin.php" ]; then
    echo "   ✓ FPP plugin system available"
else
    echo "   ⚠ FPP plugin system may not be available"
fi

# Check if other plugins exist
PLUGIN_COUNT=$(find /opt/fpp/plugins -maxdepth 1 -type d | wc -l)
echo "   📊 Total plugin directories: $((PLUGIN_COUNT - 1))"

echo ""

# Check logs
echo "6. 📝 Checking logs..."
if [ -f "/tmp/fpp.log" ]; then
    echo "   📄 Recent FPP log entries related to plugins:"
    grep -i "plugin" /tmp/fpp.log | tail -5 2>/dev/null || echo "     No plugin-related entries found"
else
    echo "   ⚠ FPP log not found at /tmp/fpp.log"
fi

if [ -f "/tmp/govee-plugin.log" ]; then
    echo "   📄 Govee plugin log:"
    tail -5 /tmp/govee-plugin.log 2>/dev/null || echo "     Log file empty"
else
    echo "   ℹ️  Govee plugin log not created yet"
fi

echo ""

# Provide recommendations
echo "7. 💡 Recommendations:"
echo ""

if [ ! -f "$PLUGIN_DIR/plugin.json" ]; then
    echo "   🔧 Create plugin.json file with proper configuration"
fi

if [ ! -f "$PLUGIN_DIR/index.php" ]; then
    echo "   🔧 Create index.php file with the plugin interface"
fi

echo "   🔄 After making changes:"
echo "      - Restart FPP daemon: sudo systemctl restart fppd"
echo "      - Or restart the Pi: sudo reboot"
echo "      - Check FPP web interface → Content Setup → Plugins"
echo ""

echo "   🌐 Plugin should appear at:"
echo "      http://your-fpp-ip/plugin.php?plugin=govee-lan-control&file=index.php"
echo ""

echo "   📞 If still not working:"
echo "      - Check FPP logs: tail -f /tmp/fpp.log"
echo "      - Verify FPP version supports plugins"
echo "      - Ensure plugin is in /home/fpp/media/plugins/"
echo ""

echo "========================================="
echo "Troubleshooting complete!"
echo "========================================="