/**
 * Smart Garden IoT Controller (ESP32) - FULL SYNC VERSION
 * 
 * Features:
 * 1. WiFiManager: Config WiFi via Smart Phone portal
 * 2. Real-time Sync: Updates "sensors" array in Area doc (App status bars)
 * 3. 24h History: Pushes to "history" sub-collection (App charts)
 * 4. Device Listener: Polls "devices" array to toggle Relays (App controls)
 * 
 * Project: quzkhanh/smart-garden-manager
 */

#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <WiFiManager.h>

// Helper logic for JSON parsing (required by Firebase library)
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// 1. User config
#include "config.h"

// 2. Hardware mapping
#define DHTPIN 4
#define DHTTYPE DHT22
#define SOIL_PIN 34
#define PUMP_PIN 18
#define FAN_PIN 19
#define LIGHT_PIN 21
#define RESET_PIN 0      // BOOT button
#define STATUS_LED 2

// Global Objects
DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig fb_config;
WiFiManager wm;

unsigned long lastSensorUpdate = 0;
unsigned long lastDevicePoll = 0;
unsigned long buttonDownTime = 0;

void setup() {
  Serial.begin(115200);
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(LIGHT_PIN, OUTPUT);
  pinMode(RESET_PIN, INPUT_PULLUP);
  pinMode(STATUS_LED, OUTPUT);
  
  digitalWrite(PUMP_PIN, HIGH); // Default OFF (active low relay)
  digitalWrite(FAN_PIN, HIGH);
  digitalWrite(LIGHT_PIN, HIGH);

  wm.autoConnect("SmartGarden_Setup"); 
  
  fb_config.api_key = FIREBASE_API_KEY;
  fb_config.database_url = FIREBASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  fb_config.token_status_callback = tokenStatusCallback;
  
  Firebase.begin(&fb_config, &auth);
  Firebase.reconnectWiFi(true);
  dht.begin();
}

void updateSensors(float t, float h, int soil) {
  if (!Firebase.ready()) return;

  String path = "users/" + String(USER_UID) + "/areas/" + String(AREA_ID);
  
  // 1. Update Real-time Status Bars
  // Note: App's Area model contains "sensors" list.
  // We overwrite it with fresh values.
  FirebaseJson json;
  FirebaseJsonArray sensors;
  
  // Temperature sensor
  FirebaseJson s_temp;
  s_temp.set("type", "temperature");
  s_temp.set("value", t);
  s_temp.set("unit", "°C");
  sensors.add(s_temp);
  
  // Humidity sensor
  FirebaseJson s_humi;
  s_humi.set("type", "air_humidity");
  s_humi.set("value", h);
  s_humi.set("unit", "%");
  sensors.add(s_humi);
  
  // Soil moisture sensor
  FirebaseJson s_soil;
  s_soil.set("type", "soil_moisture");
  s_soil.set("value", (float)soil);
  s_soil.set("unit", "%");
  sensors.add(s_soil);

  json.set("sensors", sensors);

  // Use patchDocument to update ONLY the sensors list in Area doc
  if (Firebase.Firestore.patchDocument(&fbdo, "smart-garden-manager", "", path.c_str(), json.raw(), "sensors")) {
     Serial.println("Real-time sensors updated!");
  }

  // 2. Push History (for App Charts)
  FirebaseJson hist;
  hist.set("type", "temperature");
  hist.set("value", t);
  hist.set("timestamp", (uint64_t)Firebase.getCurrentTime() * 1000);
  String h_path = path + "/history";
  Firebase.Firestore.createDocument(&fbdo, "smart-garden-manager", "", h_path.c_str(), hist.raw());
}

void pollDevices() {
  if (!Firebase.ready()) return;

  String path = "users/" + String(USER_UID) + "/areas/" + String(AREA_ID);
  if (Firebase.Firestore.getDocument(&fbdo, "smart-garden-manager", "", path.c_str(), "devices")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData data;
    
    // Parse the devices list from the Firestore response
    // Response format: { "fields": { "devices": { "arrayValue": { "values": [ ... ] } } } }
    if (json.get(data, "fields/devices/arrayValue/values")) {
       FirebaseJsonArray devices;
       data.getArray(devices);
       
       for(size_t i=0; i<devices.size(); i++){
          FirebaseJsonData d_val;
          devices.get(d_val, i);
          FirebaseJson d_obj;
          d_val.getJSON(d_obj);
          
          FirebaseJsonData d_type, d_status;
          d_obj.get(d_type, "mapValue/fields/type/stringValue");
          d_obj.get(d_status, "mapValue/fields/isOn/booleanValue");
          
          String type = d_type.stringValue;
          bool isOn = d_status.boolValue;
          
          if(type == "pump") digitalWrite(PUMP_PIN, isOn ? LOW : HIGH);
          if(type == "fan") digitalWrite(FAN_PIN, isOn ? LOW : HIGH);
          if(type == "light") digitalWrite(LIGHT_PIN, isOn ? LOW : HIGH);
       }
    }
  }
}

void loop() {
  // Check for reset button (hold 5s)
  if (digitalRead(RESET_PIN) == LOW) {
    if (buttonDownTime == 0) buttonDownTime = millis();
    else if (millis() - buttonDownTime > 5000) { wm.resetSettings(); ESP.restart(); }
  } else buttonDownTime = 0;

  // Poll devices every 5 seconds (fast response)
  if (millis() - lastDevicePoll > 5000 || lastDevicePoll == 0) {
    lastDevicePoll = millis();
    pollDevices();
  }

  // Update sensors every 30 seconds
  if (millis() - lastSensorUpdate > 30000 || lastSensorUpdate == 0) {
    lastSensorUpdate = millis();
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    int soilRaw = analogRead(SOIL_PIN);
    int soilPercent = map(soilRaw, 4095, 1000, 0, 100);
    soilPercent = constrain(soilPercent, 0, 100);
    
    if(!isnan(t) && !isnan(h)) {
      updateSensors(t, h, soilPercent);
    }
  }
  
  delay(50);
}
