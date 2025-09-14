<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Govee LAN Control Plugin</title>
    <script src="/js/jquery-latest.min.js"></script>
    <script src="/js/fpp.js"></script>
    <style>
        .plugin-container {
            max-width: 800px;
            margin: 20px auto;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .control-section {
            background: white;
            padding: 20px;
            margin: 15px 0;
            border-radius: 6px;
            border: 1px solid #dee2e6;
        }
        
        .control-section h3 {
            margin-top: 0;
            color: #495057;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #495057;
        }
        
        .form-control {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ced4da;
            border-radius: 4px;
            font-size: 14px;
        }
        
        .btn {
            padding: 8px 16px;
            margin: 5px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.2s;
        }
        
        .btn-primary {
            background-color: #007bff;
            color: white;
        }
        
        .btn-primary:hover {
            background-color: #0056b3;
        }
        
        .btn-success {
            background-color: #28a745;
            color: white;
        }
        
        .btn-success:hover {
            background-color: #218838;
        }
        
        .btn-danger {
            background-color: #dc3545;
            color: white;
        }
        
        .btn-danger:hover {
            background-color: #c82333;
        }
        
        .btn-warning {
            background-color: #ffc107;
            color: #212529;
        }
        
        .btn-warning:hover {
            background-color: #e0a800;
        }
        
        .color-preset {
            display: inline-block;
            width: 40px;
            height: 40px;
            margin: 5px;
            border: 2px solid #ccc;
            border-radius: 6px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .color-preset:hover {
            transform: scale(1.1);
            border-color: #007bff;
        }
        
        .slider-container {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .slider {
            flex: 1;
            height: 8px;
            border-radius: 5px;
            background: #ddd;
            outline: none;
            -webkit-appearance: none;
        }
        
        .slider::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            background: #007bff;
            cursor: pointer;
        }
        
        .slider::-moz-range-thumb {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            background: #007bff;
            cursor: pointer;
            border: none;
        }
        
        .status-display {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
            border: 1px solid #dee2e6;
            font-family: monospace;
            white-space: pre-wrap;
            max-height: 200px;
            overflow-y: auto;
        }
        
        .device-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            background: #e9ecef;
            border-radius: 4px;
            margin-bottom: 15px;
        }
        
        .connection-status {
            padding: 5px 10px;
            border-radius: 4px;
            font-weight: bold;
            text-transform: uppercase;
            font-size: 12px;
        }
        
        .status-connected {
            background: #d4edda;
            color: #155724;
        }
        
        .status-disconnected {
            background: #f8d7da;
            color: #721c24;
        }
    </style>
</head>
<body>
    <div class="plugin-container">
        <h1>🏠 Govee LAN Control</h1>
        <p>Control your Govee lights directly from Falcon Player</p>
        
        <!-- Device Configuration -->
        <div class="control-section">
            <h3>📡 Device Configuration</h3>
            <div class="form-group">
                <label for="deviceIP">Device IP Address:</label>
                <input type="text" id="deviceIP" class="form-control" placeholder="192.168.1.100" value="192.168.1.100">
            </div>
            <div class="form-group">
                <label for="devicePort">Port:</label>
                <input type="number" id="devicePort" class="form-control" value="4003" min="1" max="65535">
            </div>
            <button class="btn btn-primary" onclick="saveSettings()">💾 Save Settings</button>
            <button class="btn btn-warning" onclick="scanDevices()">🔍 Scan Network</button>
            <button class="btn btn-primary" onclick="testConnection()">🔗 Test Connection</button>
            
            <div class="device-info">
                <span>Connection Status:</span>
                <span id="connectionStatus" class="connection-status status-disconnected">Disconnected</span>
            </div>
        </div>
        
        <!-- Power Control -->
        <div class="control-section">
            <h3>⚡ Power Control</h3>
            <button class="btn btn-success" onclick="turnOn()">🔆 Turn On</button>
            <button class="btn btn-danger" onclick="turnOff()">🔅 Turn Off</button>
        </div>
        
        <!-- Brightness Control -->
        <div class="control-section">
            <h3>☀️ Brightness Control</h3>
            <div class="slider-container">
                <label>Brightness:</label>
                <input type="range" id="brightnessSlider" class="slider" min="0" max="100" value="100" 
                       onchange="setBrightness(this.value)" oninput="updateBrightnessDisplay(this.value)">
                <span id="brightnessValue">100%</span>
            </div>
        </div>
        
        <!-- Color Control -->
        <div class="control-section">
            <h3>🎨 Color Control</h3>
            
            <!-- Color Presets -->
            <div>
                <label>Quick Colors:</label><br>
                <div class="color-preset" style="background: #ff0000" onclick="setColorRGB(255,0,0)" title="Red"></div>
                <div class="color-preset" style="background: #00ff00" onclick="setColorRGB(0,255,0)" title="Green"></div>
                <div class="color-preset" style="background: #0000ff" onclick="setColorRGB(0,0,255)" title="Blue"></div>
                <div class="color-preset" style="background: #ffffff; border-color: #000" onclick="setColorRGB(255,255,255)" title="White"></div>
                <div class="color-preset" style="background: #ffff00" onclick="setColorRGB(255,255,0)" title="Yellow"></div>
                <div class="color-preset" style="background: #ff00ff" onclick="setColorRGB(255,0,255)" title="Magenta"></div>
                <div class="color-preset" style="background: #00ffff" onclick="setColorRGB(0,255,255)" title="Cyan"></div>
                <div class="color-preset" style="background: #ffa500" onclick="setColorRGB(255,165,0)" title="Orange"></div>
                <div class="color-preset" style="background: #800080" onclick="setColorRGB(128,0,128)" title="Purple"></div>
                <div class="color-preset" style="background: #ffc0cb" onclick="setColorRGB(255,192,203)" title="Pink"></div>
            </div>
            
            <!-- RGB Sliders -->
            <div style="margin-top: 20px;">
                <div class="slider-container">
                    <label style="width: 50px;">Red:</label>
                    <input type="range" id="redSlider" class="slider" min="0" max="255" value="255" 
                           onchange="updateRGBColor()" oninput="updateRGBDisplay()">
                    <span id="redValue">255</span>
                </div>
                <div class="slider-container">
                    <label style="width: 50px;">Green:</label>
                    <input type="range" id="greenSlider" class="slider" min="0" max="255" value="255" 
                           onchange="updateRGBColor()" oninput="updateRGBDisplay()">
                    <span id="greenValue">255</span>
                </div>
                <div class="slider-container">
                    <label style="width: 50px;">Blue:</label>
                    <input type="range" id="blueSlider" class="slider" min="0" max="255" value="255" 
                           onchange="updateRGBColor()" oninput="updateRGBDisplay()">
                    <span id="blueValue">255</span>
                </div>
                <div style="margin-top: 10px;">
                    <label>Preview:</label>
                    <div id="colorPreview" style="width: 60px; height: 30px; border: 1px solid #ccc; border-radius: 4px; background: rgb(255,255,255);"></div>
                </div>
            </div>
            
            <!-- Color Temperature -->
            <div style="margin-top: 20px;">
                <div class="slider-container">
                    <label>Color Temperature:</label>
                    <input type="range" id="tempSlider" class="slider" min="2000" max="9000" value="4000" 
                           onchange="setColorTemp(this.value)" oninput="updateTempDisplay(this.value)">
                    <span id="tempValue">4000K</span>
                </div>
            </div>
        </div>
        
        <!-- Effects -->
        <div class="control-section">
            <h3>✨ Effects</h3>
            <button class="btn btn-primary" onclick="strobeEffect()">⚡ Strobe</button>
            <button class="btn btn-primary" onclick="rainbowEffect()">🌈 Rainbow</button>
            <button class="btn btn-primary" onclick="fadeEffect()">🌅 Fade</button>
            <button class="btn btn-danger" onclick="stopEffects()">⏹️ Stop Effects</button>
        </div>
        
        <!-- Status Display -->
        <div class="control-section">
            <h3>📊 Status & Log</h3>
            <button class="btn btn-primary" onclick="getDeviceStatus()">📋 Get Status</button>
            <button class="btn btn-warning" onclick="clearLog()">🗑️ Clear Log</button>
            <div id="statusLog" class="status-display">Plugin loaded. Configure device IP and test connection.</div>
        </div>
    </div>

    <script>
        // Global variables
        let currentSettings = {
            ip: '192.168.1.100',
            port: 4003
        };
        
        let effectInterval = null;
        
        // Load settings on page load
        $(document).ready(function() {
            loadSettings();
            logMessage('Govee LAN Control Plugin loaded successfully.');
        });
        
        // Utility Functions
        function logMessage(message) {
            const timestamp = new Date().toLocaleTimeString();
            const logElement = document.getElementById('statusLog');
            logElement.textContent += `[${timestamp}] ${message}\n`;
            logElement.scrollTop = logElement.scrollHeight;
        }
        
        function clearLog() {
            document.getElementById('statusLog').textContent = '';
        }
        
        function updateConnectionStatus(connected) {
            const statusElement = document.getElementById('connectionStatus');
            if (connected) {
                statusElement.textContent = 'Connected';
                statusElement.className = 'connection-status status-connected';
            } else {
                statusElement.textContent = 'Disconnected';
                statusElement.className = 'connection-status status-disconnected';
            }
        }
        
        // Settings Functions
        function saveSettings() {
            currentSettings.ip = document.getElementById('deviceIP').value;
            currentSettings.port = parseInt(document.getElementById('devicePort').value);
            
            // Save to localStorage (in real plugin, this would use FPP's settings system)
            localStorage.setItem('govee_settings', JSON.stringify(currentSettings));
            logMessage(`Settings saved: ${currentSettings.ip}:${currentSettings.port}`);
        }
        
        function loadSettings() {
            const saved = localStorage.getItem('govee_settings');
            if (saved) {
                currentSettings = JSON.parse(saved);
                document.getElementById('deviceIP').value = currentSettings.ip;
                document.getElementById('devicePort').value = currentSettings.port;
                logMessage('Settings loaded from storage.');
            }
        }
        
        // Communication Functions
        function sendGoveeCommand(command, callback) {
            // In a real plugin, this would use FPP's API to send UDP commands
            // For demonstration, we'll simulate the request
            logMessage(`Sending command: ${JSON.stringify(command)}`);
            
            // Simulate API call (in real plugin, replace with actual HTTP request to FPP API)
            setTimeout(() => {
                if (callback) callback(true);
                updateConnectionStatus(true);
            }, 100);
        }
        
        // Device Control Functions
        function turnOn() {
            callAPI('power', {power: true}, 'POST', (response) => {
                logMessage(response.success ? 'Lights turned ON' : `Failed to turn lights ON: ${response.error}`);
            });
        }
        
        function turnOff() {
            stopEffects();
            callAPI('power', {power: false}, 'POST', (response) => {
                logMessage(response.success ? 'Lights turned OFF' : `Failed to turn lights OFF: ${response.error}`);
            });
        }
        
        function setBrightness(value) {
            callAPI('brightness', {brightness: parseInt(value)}, 'POST', (response) => {
                logMessage(response.success ? `Brightness set to ${value}%` : `Failed to set brightness: ${response.error}`);
            });
        }
        
        function setColorRGB(r, g, b) {
            callAPI('color', {r: r, g: g, b: b}, 'POST', (response) => {
                logMessage(response.success ? `Color set to RGB(${r},${g},${b})` : `Failed to set color: ${response.error}`);
            });
            
            // Update sliders
            document.getElementById('redSlider').value = r;
            document.getElementById('greenSlider').value = g;
            document.getElementById('blueSlider').value = b;
            updateRGBDisplay();
        }
        
        function setColorTemp(temp) {
            callAPI('temperature', {temperature: parseInt(temp)}, 'POST', (response) => {
                logMessage(response.success ? `Color temperature set to ${temp}K` : `Failed to set color temperature: ${response.error}`);
            });
        }r":0,"g":0,"b":0},"colorTemInKelvin":parseInt(temp)}}};
            sendGoveeCommand(command, (success) => {
                logMessage(success ? `Color temperature set to ${temp}K` : 'Failed to set color temperature');
            });
        }
        
        // UI Update Functions
        function updateBrightnessDisplay(value) {
            document.getElementById('brightnessValue').textContent = value + '%';
        }
        
        function updateRGBDisplay() {
            const r = document.getElementById('redSlider').value;
            const g = document.getElementById('greenSlider').value;
            const b = document.getElementById('blueSlider').value;
            
            document.getElementById('redValue').textContent = r;
            document.getElementById('greenValue').textContent = g;
            document.getElementById('blueValue').textContent = b;
            document.getElementById('colorPreview').style.background = `rgb(${r},${g},${b})`;
        }
        
        function updateRGBColor() {
            const r = parseInt(document.getElementById('redSlider').value);
            const g = parseInt(document.getElementById('greenSlider').value);
            const b = parseInt(document.getElementById('blueSlider').value);
            setColorRGB(r, g, b);
        }
        
        function updateTempDisplay(value) {
            document.getElementById('tempValue').textContent = value + 'K';
        }
        
        // Effect Functions
        function strobeEffect() {
            stopEffects();
            let isOn = true;
            effectInterval = setInterval(() => {
                if (isOn) {
                    setColorRGB(255, 255, 255);
                } else {
                    setColorRGB(0, 0, 0);
                }
                isOn = !isOn;
            }, 200);
            logMessage('Strobe effect started');
        }
        
        function rainbowEffect() {
            stopEffects();
            let hue = 0;
            effectInterval = setInterval(() => {
                const rgb = hslToRgb(hue / 360, 1, 0.5);
                setColorRGB(Math.round(rgb[0] * 255), Math.round(rgb[1] * 255), Math.round(rgb[2] * 255));
                hue = (hue + 10) % 360;
            }, 100);
            logMessage('Rainbow effect started');
        }
        
        function fadeEffect() {
            stopEffects();
            let brightness = 100;
            let direction = -1;
            effectInterval = setInterval(() => {
                brightness += direction * 5;
                if (brightness <= 0 || brightness >= 100) {
                    direction *= -1;
                }
                setBrightness(brightness);
                document.getElementById('brightnessSlider').value = brightness;
                updateBrightnessDisplay(brightness);
            }, 100);
            logMessage('Fade effect started');
        }
        
        function stopEffects() {
            if (effectInterval) {
                clearInterval(effectInterval);
                effectInterval = null;
                logMessage('Effects stopped');
            }
        }
        
        // Utility Functions
        function hslToRgb(h, s, l) {
            let r, g, b;
            
            if (s === 0) {
                r = g = b = l;
            } else {
                const hue2rgb = (p, q, t) => {
                    if (t < 0) t += 1;
                    if (t > 1) t -= 1;
                    if (t < 1/6) return p + (q - p) * 6 * t;
                    if (t < 1/2) return q;
                    if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                    return p;
                };
                
                const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
                const p = 2 * l - q;
                r = hue2rgb(p, q, h + 1/3);
                g = hue2rgb(p, q, h);
                b = hue2rgb(p, q, h - 1/3);
            }
            
            return [r, g, b];
        }
        
        // Test and Scan Functions
        function testConnection() {
            logMessage('Testing connection...');
            callAPI('test', null, 'GET', (response) => {
                if (response.success) {
                    logMessage('Connection test successful');
                    updateConnectionStatus(true);
                } else {
                    logMessage(`Connection test failed: ${response.error}`);
                    updateConnectionStatus(false);
                }
            });
        }
        
        function scanDevices() {
            logMessage('Scanning network for Govee devices...');
            callAPI('scan', null, 'GET', (response) => {
                if (response.success) {
                    logMessage(`Scan complete. Found ${response.devices.length} devices:`);
                    response.devices.forEach((device, index) => {
                        logMessage(`- Device ${index + 1}: ${device.ip}:${device.port}`);
                    });
                    if (response.devices.length === 0) {
                        logMessage('No Govee devices found on network');
                    }
                } else {
                    logMessage(`Scan failed: ${response.error}`);
                }
            });
        }
        
        function getDeviceStatus() {
            callAPI('status', null, 'GET', (response) => {
                if (response.success) {
                    logMessage('Device status retrieved successfully');
                    if (response.response) {
                        logMessage(`Status response: ${response.response}`);
                    }
                    updateConnectionStatus(true);
                } else {
                    logMessage(`Failed to get device status: ${response.error}`);
                    updateConnectionStatus(false);
                }
            });
        }
    </script>
</body>
</html>