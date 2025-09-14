<?php
/*
 * Govee LAN Control Plugin - Backend API Handler
 * File: /opt/fpp/plugins/govee-lan-control/api.php
 * 
 * This script handles all API requests from the plugin frontend
 * and communicates with Govee devices via UDP
 */

// Include FPP common functions
require_once('/opt/fpp/www/common.php');

// Set headers for API responses
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Handle OPTIONS requests for CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

class GoveeController {
    private $settings;
    private $logFile;
    
    public function __construct() {
        $this->logFile = '/tmp/govee-plugin.log';
        $this->loadSettings();
    }
    
    /**
     * Load plugin settings from FPP settings system
     */
    private function loadSettings() {
        global $settings;
        
        $this->settings = [
            'deviceIP' => $settings['govee_deviceIP'] ?? '192.168.1.100',
            'devicePort' => intval($settings['govee_devicePort'] ?? 4003),
            'timeout' => intval($settings['govee_timeout'] ?? 5),
            'debug' => boolval($settings['govee_debug'] ?? false)
        ];
    }
    
    /**
     * Save settings to FPP settings system
     */
    public function saveSettings($newSettings) {
        global $settings;
        
        foreach ($newSettings as $key => $value) {
            if (isset($this->settings[str_replace('govee_', '', $key)])) {
                $settings[$key] = $value;
                WriteSettingToFile($key, $value);
            }
        }
        
        $this->loadSettings();
        $this->log("Settings saved: " . json_encode($this->settings));
        
        return ['success' => true, 'message' => 'Settings saved successfully'];
    }
    
    /**
     * Log messages to file and FPP log
     */
    private function log($message) {
        $timestamp = date('Y-m-d H:i:s');
        $logEntry = "[$timestamp] Govee Plugin: $message\n";
        
        // Write to plugin log file
        file_put_contents($this->logFile, $logEntry, FILE_APPEND | LOCK_EX);
        
        // Also log to FPP system log if debug is enabled
        if ($this->settings['debug']) {
            LogEntry('Govee Plugin', $message);
        }
    }
    
    /**
     * Send UDP command to Govee device
     */
    private function sendUDPCommand($command) {
        $ip = $this->settings['deviceIP'];
        $port = $this->settings['devicePort'];
        $timeout = $this->settings['timeout'];
        
        $this->log("Sending command to $ip:$port - " . json_encode($command));
        
        try {
            // Create UDP socket
            $socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
            if (!$socket) {
                throw new Exception("Failed to create socket: " . socket_strerror(socket_last_error()));
            }
            
            // Set socket timeout
            socket_set_option($socket, SOL_SOCKET, SO_SNDTIMEO, ['sec' => $timeout, 'usec' => 0]);
            socket_set_option($socket, SOL_SOCKET, SO_RCVTIMEO, ['sec' => $timeout, 'usec' => 0]);
            
            // Prepare command
            $commandJson = json_encode($command);
            
            // Send command
            $result = socket_sendto($socket, $commandJson, strlen($commandJson), 0, $ip, $port);
            
            if ($result === false) {
                throw new Exception("Failed to send command: " . socket_strerror(socket_last_error($socket)));
            }
            
            // Try to read response (some Govee devices send acknowledgments)
            $response = '';
            $from = '';
            $port_from = 0;
            
            $bytesReceived = @socket_recvfrom($socket, $response, 1024, 0, $from, $port_from);
            
            socket_close($socket);
            
            $this->log("Command sent successfully. Response: " . ($response ?: 'No response'));
            
            return [
                'success' => true,
                'bytes_sent' => $result,
                'response' => $response,
                'message' => 'Command sent successfully'
            ];
            
        } catch (Exception $e) {
            if (isset($socket)) {
                socket_close($socket);
            }
            
            $this->log("Error sending command: " . $e->getMessage());
            
            return [
                'success' => false,
                'error' => $e->getMessage(),
                'message' => 'Failed to send command'
            ];
        }
    }
    
    /**
     * Turn device on
     */
    public function turnOn() {
        $command = ["msg" => ["cmd" => "turn", "data" => ["value" => 1]]];
        return $this->sendUDPCommand($command);
    }
    
    /**
     * Turn device off
     */
    public function turnOff() {
        $command = ["msg" => ["cmd" => "turn", "data" => ["value" => 0]]];
        return $this->sendUDPCommand($command);
    }
    
    /**
     * Set brightness (0-100)
     */
    public function setBrightness($brightness) {
        $brightness = max(0, min(100, intval($brightness)));
        $command = ["msg" => ["cmd" => "brightness", "data" => ["value" => $brightness]]];
        return $this->sendUDPCommand($command);
    }
    
    /**
     * Set RGB color
     */
    public function setColorRGB($r, $g, $b) {
        $r = max(0, min(255, intval($r)));
        $g = max(0, min(255, intval($g)));
        $b = max(0, min(255, intval($b)));
        
        $command = [
            "msg" => [
                "cmd" => "colorwc",
                "data" => [
                    "color" => ["r" => $r, "g" => $g, "b" => $b],
                    "colorTemInKelvin" => 0
                ]
            ]
        ];
        
        return $this->sendUDPCommand($command);
    }
    
    /**
     * Set color temperature (2000-9000K)
     */
    public function setColorTemp($temp) {
        $temp = max(2000, min(9000, intval($temp)));
        
        $command = [
            "msg" => [
                "cmd" => "colorwc",
                "data" => [
                    "color" => ["r" => 0, "g" => 0, "b" => 0],
                    "colorTemInKelvin" => $temp
                ]
            ]
        ];
        
        return $this->sendUDPCommand($command);
    }
    
    /**
     * Get device status
     */
    public function getDeviceStatus() {
        $command = ["msg" => ["cmd" => "devStatus", "data" => []]];
        return $this->sendUDPCommand($command);
    }
    
    /**
     * Scan network for Govee devices
     */
    public function scanNetwork() {
        $this->log("Starting network scan for Govee devices");
        
        // Get network range
        $networkInfo = shell_exec("ip route | grep -E '192\.168\.' | head -1");
        preg_match('/(\d+\.\d+\.\d+)\.\d+\/\d+/', $networkInfo, $matches);
        
        if (!isset($matches[1])) {
            return [
                'success' => false,
                'error' => 'Could not determine network range',
                'devices' => []
            ];
        }
        
        $networkBase = $matches[1];
        $devices = [];
        $port = 4003;
        
        // Scan common IP ranges
        for ($i = 1; $i <= 254; $i++) {
            $ip = "$networkBase.$i";
            
            // Quick UDP port check
            $socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
            if ($socket) {
                socket_set_option($socket, SOL_SOCKET, SO_SNDTIMEO, ['sec' => 1, 'usec' => 0]);
                
                $testCommand = json_encode(["msg" => ["cmd" => "scan", "data" => []]]);
                $result = @socket_sendto($socket, $testCommand, strlen($testCommand), 0, $ip, $port);
                
                if ($result !== false) {
                    // Try to get response
                    $response = '';
                    $from = '';
                    $port_from = 0;
                    $bytesReceived = @socket_recvfrom($socket, $response, 1024, 0, $from, $port_from);
                    
                    if ($bytesReceived > 0) {
                        $devices[] = [
                            'ip' => $ip,
                            'port' => $port,
                            'response' => $response
                        ];
                        $this->log("Found potential Govee device at $ip");
                    }
                }
                
                socket_close($socket);
            }
        }
        
        $this->log("Network scan completed. Found " . count($devices) . " devices");
        
        return [
            'success' => true,
            'devices' => $devices,
            'message' => 'Scan completed'
        ];
    }
    
    /**
     * Test connection to device
     */
    public function testConnection() {
        $this->log("Testing connection to device");
        return $this->getDeviceStatus();
    }
    
    /**
     * Get plugin logs
     */
    public function getLogs($lines = 50) {
        if (file_exists($this->logFile)) {
            $logs = shell_exec("tail -n $lines {$this->logFile}");
            return [
                'success' => true,
                'logs' => $logs ?: 'No logs available'
            ];
        } else {
            return [
                'success' => false,
                'error' => 'Log file not found',
                'logs' => ''
            ];
        }
    }
    
    /**
     * Clear logs
     */
    public function clearLogs() {
        if (file_exists($this->logFile)) {
            file_put_contents($this->logFile, '');
            $this->log("Logs cleared");
        }
        
        return ['success' => true, 'message' => 'Logs cleared'];
    }
}

// Main API handler
try {
    $govee = new GoveeController();
    $method = $_SERVER['REQUEST_METHOD'];
    $action = $_GET['action'] ?? '';
    
    switch ($method) {
        case 'GET':
            switch ($action) {
                case 'settings':
                    echo json_encode(['success' => true, 'settings' => $govee->settings]);
                    break;
                    
                case 'status':
                    echo json_encode($govee->getDeviceStatus());
                    break;
                    
                case 'scan':
                    echo json_encode($govee->scanNetwork());
                    break;
                    
                case 'test':
                    echo json_encode($govee->testConnection());
                    break;
                    
                case 'logs':
                    $lines = intval($_GET['lines'] ?? 50);
                    echo json_encode($govee->getLogs($lines));
                    break;
                    
                default:
                    echo json_encode(['success' => false, 'error' => 'Unknown action']);
                    break;
            }
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                echo json_encode(['success' => false, 'error' => 'Invalid JSON input']);
                break;
            }
            
            switch ($action) {
                case 'settings':
                    echo json_encode($govee->saveSettings($input));
                    break;
                    
                case 'power':
                    $power = $input['power'] ?? false;
                    if ($power) {
                        echo json_encode($govee->turnOn());
                    } else {
                        echo json_encode($govee->turnOff());
                    }
                    break;
                    
                case 'brightness':
                    $brightness = $input['brightness'] ?? 100;
                    echo json_encode($govee->setBrightness($brightness));
                    break;
                    
                case 'color':
                    if (isset($input['r'], $input['g'], $input['b'])) {
                        echo json_encode($govee->setColorRGB($input['r'], $input['g'], $input['b']));
                    } else {
                        echo json_encode(['success' => false, 'error' => 'RGB values required']);
                    }
                    break;
                    
                case 'temperature':
                    $temp = $input['temperature'] ?? 4000;
                    echo json_encode($govee->setColorTemp($temp));
                    break;
                    
                case 'command':
                    // Generic command sender
                    if (isset($input['command'])) {
                        echo json_encode($govee->sendUDPCommand($input['command']));
                    } else {
                        echo json_encode(['success' => false, 'error' => 'Command required']);
                    }
                    break;
                    
                default:
                    echo json_encode(['success' => false, 'error' => 'Unknown action']);
                    break;
            }
            break;
            
        case 'DELETE':
            switch ($action) {
                case 'logs':
                    echo json_encode($govee->clearLogs());
                    break;
                    
                default:
                    echo json_encode(['success' => false, 'error' => 'Unknown action']);
                    break;
            }
            break;
            
        default:
            echo json_encode(['success' => false, 'error' => 'Method not allowed']);
            break;
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}

?>