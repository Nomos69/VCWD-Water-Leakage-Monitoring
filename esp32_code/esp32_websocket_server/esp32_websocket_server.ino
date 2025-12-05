/*
 * ESP32 Water Flow Sensor + WebSocket Server
 * 
 * WIRING:
 * - Flow Sensor RED wire    -> ESP32 3.3V or 5V
 * - Flow Sensor BLACK wire  -> ESP32 GND  
 * - Flow Sensor YELLOW wire -> ESP32 GPIO 13
 */

#include <WiFi.h>
#include <WebSocketsServer.h>

// ========== CHANGE THESE TO YOUR WIFI CREDENTIALS ==========
const char* ssid = "WdoZ";
const char* password = "PwKQCEFw";
// ===========================================================

const char* SENSOR_ID = "S001";

// Water Flow Sensor Pin - Try GPIO 13 (more reliable for interrupts)
#define SENSOR_PIN 13

// WebSocket server on port 81
WebSocketsServer webSocket = WebSocketsServer(81);

// Flow sensor variables
volatile int pulseCount = 0;
float flowRate = 0.0;
float totalLiters = 0.0;
unsigned long lastTime = 0;

// Interrupt function to count pulses
void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(num);
        Serial.printf("[%u] Connected from %d.%d.%d.%d\n", num, ip[0], ip[1], ip[2], ip[3]);
        sendFlowData(num);
      }
      break;
    case WStype_TEXT:
      Serial.printf("[%u] Received: %s\n", num, payload);
      break;
  }
}

void sendFlowData(uint8_t clientNum) {
  String jsonData = "{\"sensorId\":\"" + String(SENSOR_ID) + "\",\"flowRate\":" + String(flowRate, 2) + "}";
  webSocket.sendTXT(clientNum, jsonData);
}

void broadcastFlowData() {
  String jsonData = "{\"sensorId\":\"" + String(SENSOR_ID) + "\",\"flowRate\":" + String(flowRate, 2) + "}";
  webSocket.broadcastTXT(jsonData);
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n=================================");
  Serial.println("ESP32 Water Flow Sensor Server");
  Serial.println("=================================");
  Serial.print("Sensor Pin: GPIO ");
  Serial.println(SENSOR_PIN);
  
  // Setup flow sensor pin
  pinMode(SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(SENSOR_PIN), pulseCounter, FALLING);
  
  // Connect to WiFi
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n*** WiFi Connected! ***");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi FAILED!");
  }
  
  // Start WebSocket server
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  Serial.println("WebSocket started on port 81");
  Serial.println("=================================");
  Serial.println("Reading sensor every second...\n");
  
  // Initialize timer
  lastTime = millis();
}

void loop() {
  webSocket.loop();
  
  // Print every second
  if (millis() - lastTime >= 1000) {
    
    // Read pulse count
    noInterrupts();
    int count = pulseCount;
    pulseCount = 0;
    interrupts();
    
    // Calculate flow rate (7.5 pulses = 1 L/min for most sensors)
    flowRate = count / 7.5;
    totalLiters += (flowRate / 60.0);
    
    // Print status
    Serial.print("Pulses: ");
    Serial.print(count);
    Serial.print(" | Flow: ");
    Serial.print(flowRate, 2);
    Serial.print(" L/min | Total: ");
    Serial.print(totalLiters, 2);
    Serial.println(" L");
    
    // Send to Flutter
    broadcastFlowData();
    
    lastTime = millis();
  }
}