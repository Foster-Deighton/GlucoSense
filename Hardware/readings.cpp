#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// Define hardware pins
#define GLUCOSE_SENSOR_PIN 34  // Analog input for glucose sensor
#define MOSFET_CONTROL_PIN  25  // Digital output for MOSFET (heat pad control)

// BLE Parameters
#define DEVICE_NAME "GlucoseMonitor"
#define SERVICE_UUID "aaa" // UUID for the service (not shared for security reasons)
#define CHARACTERISTIC_UUID "bbb" // UUID for the characteristic (not shared for security reasons)
#define COMMAND_CHARACTERISTIC_UUID "ccc" // UUID for command characteristic (not shared for security reasons)

// BLE Server and Characteristics
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
BLECharacteristic* pCommandCharacteristic = nullptr;

// Heat Pad Control
bool heatPadState = false;
bool measureGlucose = false; // Flag to trigger measurement

// Function to read glucose sensor data
int readGlucoseSensor() {
    return analogRead(GLUCOSE_SENSOR_PIN); // Read analog value from sensor
}

// Function to control heat pad
void setHeatPad(bool state) {
    digitalWrite(MOSFET_CONTROL_PIN, state ? HIGH : LOW);
    heatPadState = state;
}

// BLE Callbacks for connection handling
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        Serial.println("Device connected.");
    }
    void onDisconnect(BLEServer* pServer) {
        Serial.println("Device disconnected. Restarting advertising...");
        BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
        pAdvertising->start();
    }
};

// Callback for receiving command from the app
class CommandCallback : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        if (value == "START") {
            measureGlucose = true;
        }
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(GLUCOSE_SENSOR_PIN, INPUT);
    pinMode(MOSFET_CONTROL_PIN, OUTPUT);
    setHeatPad(false); // Ensure heat pad is off initially

    // Initialize BLE
    BLEDevice::init(DEVICE_NAME);
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService* pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pCommandCharacteristic = pService->createCharacteristic(
        COMMAND_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pCommandCharacteristic->setCallbacks(new CommandCallback());
    pService->start();
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    Serial.println("BLE Initialized. Waiting for connections...");
}

void loop() {
    if (measureGlucose) {
        Serial.println("Starting glucose measurement...");
        for (int i = 0; i < 20; i++) {
            int glucoseLevel = readGlucoseSensor();
            Serial.print("Glucose Level: ");
            Serial.println(glucoseLevel);
            
            // Send glucose data via BLE
            pCharacteristic->setValue(glucoseLevel);
            pCharacteristic->notify();
            
            // Example: Activate heat pad if glucose is below threshold
            if (glucoseLevel < 200) { // Example threshold
                setHeatPad(true);
            } else {
                setHeatPad(false);
            }
            
            delay(1000); // Adjust delay as needed
        }
        measureGlucose = false; // Reset flag after burst
        Serial.println("Glucose measurement complete.");
    }
}
