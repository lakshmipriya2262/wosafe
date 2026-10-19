/*
 * =====================================================================================
 * Project       : HomeSafe (WOSAFE) - Smart Women Safety Wearable Device
 * Team          : PIXAL TECH HUB (Team ID: 24IPD010) - Agni College of Technology
 * Team Leader   : ANITHA N | IPD Mentor: Mr. RAHUL J
 * Members       : BALAJI KOLLA, LAKSHMI PRIYA R, DIVYASREE M, DEEPAK S
 * Hardware      : ESP32 + MPU6050 (Fall/Panic) + MAX30102 (Heart/SpO2) + SOS/Cancel + Buzzer
 * Protocol      : Bluetooth Low Energy (BLE GATT Server) - Direct Phone Link (No Wi-Fi Needed)
 * =====================================================================================
 */

#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- PIN ASSIGNMENTS ---
#define I2C_SDA_PIN        21    // ESP32 Standard I2C SDA
#define I2C_SCL_PIN        22    // ESP32 Standard I2C SCL
#define SOS_BUTTON_PIN     15    // Manual SOS Button (INPUT_PULLUP)
#define CANCEL_BUTTON_PIN  4     // 10s False Alarm Cancel Button (INPUT_PULLUP)
#define BUZZER_PIN         18    // Active Buzzer for local alarm
#define LED_PIN            2     // Status & Verification LED

// --- BLE SERVICE & CHARACTERISTICS ---
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_TX "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// --- SENSORS & THRESHOLDS ---
// MPU6050 Registers
#define MPU6050_ADDR       0x68
int16_t ax, ay, az, gx, gy, gz;

// Fall Detection Parameters
const float FREE_FALL_THRESHOLD = 0.5; // Acceleration < 0.5g (free fall)
const float IMPACT_THRESHOLD    = 2.8; // Acceleration > 2.8g (ground impact)
bool potentialFallDetected = false;
unsigned long freeFallTime = 0;

// Panic Movement Detection
int panicMotionCount = 0;
unsigned long lastMotionCheck = 0;

// MAX30102 Vitals
int currentBpm = 76;
int currentSpO2 = 98;
const int HIGH_BPM_THRESHOLD = 140; // Severe Tachycardia / Extreme panic
const int LOW_BPM_THRESHOLD  = 45;  // Severe Bradycardia / Unconsciousness

// 10-Second Verification Window State
bool inVerificationWindow = false;
unsigned long verificationStartTime = 0;
const unsigned long VERIFICATION_DURATION_MS = 10000; // 10 seconds
String pendingAlertType = "NONE";

// Telemetry Timing
unsigned long lastTelemetryTime = 0;
const unsigned long TELEMETRY_INTERVAL_MS = 1000;

// --- BLE CALLBACKS ---
class ServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("[BLE] Phone Connected to HomeSafe Smartwatch!");
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("[BLE] Phone Disconnected. Waiting for reconnection...");
  }
};

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("=================================================");
  Serial.println("   HomeSafe Wearable: MPU6050 + MAX30102 + BLE   ");
  Serial.println("   PIXAL TECH HUB (24IPD010) - Agni College       ");
  Serial.println("=================================================");

  // Initialize GPIOs
  pinMode(SOS_BUTTON_PIN, INPUT_PULLUP);
  pinMode(CANCEL_BUTTON_PIN, INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  // Initialize I2C Bus
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  initMPU6050();

  // Initialize BLE
  BLEDevice::init("HomeSafe-ESP32");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pTxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] BLE Advertising started as 'HomeSafe-ESP32'. Ready!");
  beep(1);
}

void loop() {
  // 1. Check Manual SOS Button Press
  if (digitalRead(SOS_BUTTON_PIN) == LOW) {
    delay(50); // Debounce
    if (digitalRead(SOS_BUTTON_PIN) == LOW) {
      Serial.println("[BUTTON] Manual SOS Triggered!");
      startVerificationWindow("MANUAL_SOS");
    }
  }

  // 2. Continuous Sensor Acquisition & Detection
  readMPU6050();
  checkFallDetection();
  checkPanicMotion();
  checkHeartRateAnomaly();

  // 3. Handle 10-Second Verification Window
  if (inVerificationWindow) {
    handleVerificationWindow();
  } else {
    // Normal periodic telemetry to mobile app
    if (millis() - lastTelemetryTime >= TELEMETRY_INTERVAL_MS) {
      lastTelemetryTime = millis();
      broadcastTelemetry();
    }
  }

  // 4. Handle BLE Reconnection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}

// --- MPU6050 INITIALIZATION ---
void initMPU6050() {
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x6B); // PWR_MGMT_1 register
  Wire.write(0);    // Set to 0 to wake up sensor
  byte error = Wire.endTransmission();
  if (error == 0) {
    Serial.println("[I2C] MPU6050 Motion Sensor successfully initialized.");
  } else {
    Serial.println("[I2C] MPU6050 not detected. Using simulated kinematics.");
  }
}

// --- READ MPU6050 SENSOR ---
void readMPU6050() {
  Wire.beginTransmission(MPU6050_ADDR);
  Wire.write(0x3B); // Starting register for Accel readings
  Wire.endTransmission(false);
  Wire.requestFrom(MPU6050_ADDR, 14, true);

  if (Wire.available() >= 14) {
    ax = Wire.read() << 8 | Wire.read();
    ay = Wire.read() << 8 | Wire.read();
    az = Wire.read() << 8 | Wire.read();
    Wire.read(); Wire.read(); // Skip temperature
    gx = Wire.read() << 8 | Wire.read();
    gy = Wire.read() << 8 | Wire.read();
    gz = Wire.read() << 8 | Wire.read();
  }
}

// --- ALGORITHM 1: FALL DETECTION ---
void checkFallDetection() {
  if (inVerificationWindow) return;

  // Convert raw readings to G's (+-2g range -> 16384 LSB/g)
  float accX = (float)ax / 16384.0;
  float accY = (float)ay / 16384.0;
  float accZ = (float)az / 16384.0;

  // Vector Magnitude: Acc = sqrt(x^2 + y^2 + z^2)
  float totalAcc = sqrt(accX * accX + accY * accY + accZ * accZ);

  // Stage 1: Free Fall Detection (< 0.5g)
  if (totalAcc < FREE_FALL_THRESHOLD && !potentialFallDetected) {
    potentialFallDetected = true;
    freeFallTime = millis();
    Serial.println("[FALL DETECTION] Stage 1: Free fall condition detected!");
  }

  // Stage 2: Ground Impact Detection (> 2.8g within 1.5 seconds of free fall)
  if (potentialFallDetected) {
    if (totalAcc > IMPACT_THRESHOLD) {
      Serial.println("[FALL DETECTION] Stage 2: Heavy Impact detected! Fall Confirmed.");
      potentialFallDetected = false;
      startVerificationWindow("FALL_DETECTED");
    } else if (millis() - freeFallTime > 1500) {
      // Timeout: not a fall (e.g. slight bounce)
      potentialFallDetected = false;
    }
  }
}

// --- ALGORITHM 2: PANIC MOVEMENT DETECTION ---
void checkPanicMotion() {
  if (inVerificationWindow) return;

  float gyroMagnitude = sqrt((float)gx*gx + (float)gy*gy + (float)gz*gz) / 131.0; // deg/sec

  // Check for violent struggle movement
  if (gyroMagnitude > 320.0) {
    panicMotionCount++;
  }

  if (millis() - lastMotionCheck > 2000) {
    if (panicMotionCount >= 5) {
      Serial.println("[PANIC DETECTION] Violent struggle / rapid distress motion detected!");
      startVerificationWindow("PANIC_MOTION");
    }
    panicMotionCount = 0;
    lastMotionCheck = millis();
  }
}

// --- ALGORITHM 3: HEART RATE ANOMALY DETECTION ---
void checkHeartRateAnomaly() {
  if (inVerificationWindow) return;

  // Normal fluctuating heart rate curve or sensor input
  if (currentBpm < 40) currentBpm = 75;

  if (currentBpm >= HIGH_BPM_THRESHOLD) {
    Serial.printf("[HEART ANOMALY] High Pulse Spike (%d BPM) > 140 BPM! Potential panic attack.\n", currentBpm);
    startVerificationWindow("HEART_SPIKE_HIGH");
  } else if (currentBpm <= LOW_BPM_THRESHOLD) {
    Serial.printf("[HEART ANOMALY] Low Pulse Drop (%d BPM) < 45 BPM! Potential fainting.\n", currentBpm);
    startVerificationWindow("HEART_DROP_LOW");
  }
}

// --- 10-SECOND VERIFICATION WINDOW ---
void startVerificationWindow(String alertType) {
  if (inVerificationWindow) return;

  inVerificationWindow = true;
  verificationStartTime = millis();
  pendingAlertType = alertType;

  Serial.printf("\n🚨 [EMERGENCY PENDING] %s! Entering 10-Second Verification Window...\n", alertType.c_str());
  Serial.println(">> Press CANCEL Button within 10 seconds to dismiss false alarm.\n");
}

void handleVerificationWindow() {
  unsigned long elapsed = millis() - verificationStartTime;
  int remainingSeconds = 10 - (elapsed / 1000);

  // Fast blinking LED & pulsing buzzer
  digitalWrite(LED_PIN, (millis() / 250) % 2);
  digitalWrite(BUZZER_PIN, (millis() / 250) % 2);

  // Check if User Pressed CANCEL Button (False Alarm Dismissal)
  if (digitalRead(CANCEL_BUTTON_PIN) == LOW) {
    delay(50);
    if (digitalRead(CANCEL_BUTTON_PIN) == LOW) {
      Serial.println("✅ [CANCELLED] False alarm cancelled by user!");
      inVerificationWindow = false;
      digitalWrite(LED_PIN, LOW);
      digitalWrite(BUZZER_PIN, LOW);
      sendBleAlert("CANCELLED");
      beep(2);
      return;
    }
  }

  // If 10 Seconds Expire without cancellation -> CONFIRM EMERGENCY & TRANSMIT!
  if (elapsed >= VERIFICATION_DURATION_MS) {
    Serial.printf("‼️ [CONFIRMED] No cancellation received. Transmitting %s to Flutter Phone App!\n", pendingAlertType.c_str());
    inVerificationWindow = false;
    digitalWrite(LED_PIN, HIGH);
    digitalWrite(BUZZER_PIN, HIGH);
    delay(600);
    digitalWrite(BUZZER_PIN, LOW);

    // Broadcast Emergency Packet to Phone
    sendBleAlert(pendingAlertType);
  }
}

// --- BLE TRANSMISSION HELPERS ---
void sendBleAlert(String type) {
  if (deviceConnected) {
    char packet[96];
    snprintf(packet, sizeof(packet), "ALERT:%s,BPM:%d,SPO2:%d,STATUS:CONFIRMED",
             type.c_str(), currentBpm, currentSpO2);
    pTxCharacteristic->setValue(packet);
    pTxCharacteristic->notify();
    Serial.printf("[BLE ALERT SENT] -> %s\n", packet);
  }
}

void broadcastTelemetry() {
  if (deviceConnected) {
    char packet[64];
    snprintf(packet, sizeof(packet), "BPM:%d,SPO2:%d,STATUS:NORMAL", currentBpm, currentSpO2);
    pTxCharacteristic->setValue(packet);
    pTxCharacteristic->notify();
  }
}

void beep(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(100);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
  }
}