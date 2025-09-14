#!/bin/bash
#
# Quick Setup Script for Govee LAN Control Plugin
# Run this script to quickly install the plugin with correct FPP paths
#

PLUGIN_DIR="/home/fpp/media/plugins/govee-lan-control"
PLUGIN_NAME="Govee LAN Control"

echo "========================================="
echo "Quick Setup: $PLUGIN_NAME Plugin"
echo "========================================="

# Check if running as root or fpp user
if [ "$EUID" -eq 0 ] || [ "$(whoami)" = "fpp" ]; then
    echo "✓ Running with appropriate permissions"
else
    echo "⚠ Warning: Should run as root or fpp user for proper permissions"
fi

# Check if FPP media directory exists
if [ ! -d "/home/fpp/media" ]; then
    echo "❌ Error: FPP media directory not found!"
    echo "Please ensure Falcon Player is properly installed."
    exit 1
fi

# Create plugin directory structure
echo "📁 Creating plugin directory..."
mkdir -p "$PLUGIN_DIR"

# Create the main plugin files that need to be manually copied
echo ""
echo "🔧 Plugin directory created at: $PLUGIN_DIR"
echo ""
echo "📋 Next steps to complete installation:"
echo ""
echo "1. Copy these files to $PLUGIN_DIR:"
echo "   - index.php (from the HTML artifact)"
echo "   - api.php (from the PHP backend artifact)" 
echo "   - plugin.json (from the configuration artifact)"
echo "   - commands.sh (from the commands artifact)"
echo ""

# Create a simple test to verify FPP environment
echo "2. 🧪 Testing FPP environment..."

if [ -f "/opt/fpp/www/common.php" ]; then
    echo "   ✓ FPP common.php found"
else
    echo "   ⚠ FPP common.php not found - plugin may need path adjustments"
fi

if command -v curl &> /dev/null; then
    echo "   ✓ curl is available"
else
    echo "   ⚠ curl not found - installing..."
    if [ "$EUID" -eq 0 ]; then
        apt-get update && apt-get install -y curl
        echo "   ✓ curl installed"
    else
        echo "   ❌ Need root access to install curl"
    fi
fi

# Set up basic directory permissions
echo ""
echo "3. 🔒 Setting up permissions..."
chown -R fpp:fpp "$PLUGIN_DIR" 2>/dev/null || echo "   ⚠ Could not set ownership (run as root if needed)"
chmod 755 "$PLUGIN_DIR" 2>/dev/null || echo "   ⚠ Could not set permissions"

# Create log file
touch /tmp/govee-plugin.log 2>/dev/null
chown fpp:fpp /tmp/govee-plugin.log 2>/dev/null
chmod 644 /tmp/govee-plugin.log 2>/dev/null

echo ""
echo "4. 📄 After copying files, set executable permissions:"
echo "   chmod +x $PLUGIN_DIR/commands.sh"
echo ""

echo "5. 🔄 Restart FPP or refresh plugins in the web interface"
echo ""

echo "6. 🌐 Access plugin at: FPP Web UI → Content Setup → Plugins → $PLUGIN_NAME"
echo ""

# Create a simple verification script
cat > "$PLUGIN_DIR/verify.sh" << 'EOF'
#!/bin/bash
echo "Verifying Govee Plugin Installation..."
echo "Plugin directory: $(pwd)"
echo "Files present:"
ls -la
echo ""
echo "Required files check:"
[ -f "index.php" ] && echo "✓ index.php" || echo "❌ index.php missing"
[ -f "api.php" ] && echo "✓ api.php" || echo "❌ api.php missing" 
[ -f "plugin.json" ] && echo "✓ plugin.json" || echo "❌ plugin.json missing"
[ -f "commands.sh" ] && echo "✓ commands.sh" || echo "❌ commands.sh missing"
echo ""
if [ -x "commands.sh" ]; then
    echo "✓ commands.sh is executable"
else
    echo "⚠ commands.sh needs execute permission: chmod +x commands.sh"
fi
EOF

chmod +x "$PLUGIN_DIR/verify.sh"

echo "✨ Quick setup complete!"
echo ""
echo "🔍 To verify installation after copying files:"
echo "   cd $PLUGIN_DIR && ./verify.sh"
echo ""
echo "📚 Full documentation will be in $PLUGIN_DIR/README.md"
echo "📝 Logs will be written to /tmp/govee-plugin.log"
echo ""
echo "========================================="