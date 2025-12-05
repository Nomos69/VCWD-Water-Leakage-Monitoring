/*
 * Arduino Water Flow Sensor Code
 * 
 * This is your original code - just upload it to your Arduino!
 * 
 * WIRING:
 * - Flow Sensor Signal -> Arduino Pin 2
 * - Flow Sensor VCC -> Arduino 5V
 * - Flow Sensor GND -> Arduino GND
 * 
 * - Arduino TX -> ESP32 RX2 (GPIO 16)
 * - Arduino GND -> ESP32 GND
 * 
 * The Arduino sends "FLOW:xx.xx" every second to the ESP32
 */

#define SENSOR_PIN 2
volatile int pulseCount = 0;
float flowRate = 0.0;
unsigned long oldTime = 0;

void pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(9600);
  pinMode(SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(SENSOR_PIN), pulseCounter, FALLING);
}

void loop() {
  if ((millis() - oldTime) > 1000) {
    detachInterrupt(digitalPinToInterrupt(SENSOR_PIN));
    flowRate = (pulseCount / 7.5);
    Serial.print("FLOW:");
    Serial.println(flowRate);
    pulseCount = 0;
    oldTime = millis();
    attachInterrupt(digitalPinToInterrupt(SENSOR_PIN), pulseCounter, FALLING);
  }
}
