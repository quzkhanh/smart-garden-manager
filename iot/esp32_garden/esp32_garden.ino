/**
 * Smart Garden IoT Controller (ESP32) - TÍCH HỢP PHẦN CỨNG BẠN BÈ
 * 
 * Features:
 * 1. WiFiManager: Config WiFi + Area ID + User UID (lưu NVS)
 * 2. Màn hình TFT cấu hình offline (ST7789)
 * 3. Bấm nút cứng -> Relay đổi trạng thái -> Đồng bộ Cloud
 * 4. Nhận lệnh từ Cloud -> Đổi trạng thái Relay
 * 5. Đẩy Sensors lên Cloud định kỳ
 */

#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <WiFiManager.h>
#include <Preferences.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <SPI.h>

// Helper logic for JSON parsing (required by Firebase library)
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// 1. User config
#include "config.h"

// 2. Hardware mapping (DỮ LIỆU TỪ MẠCH CŨ)
#define DHTPIN 4
#define DHTTYPE DHT22
#define SOIL_PIN 34

#define PUMP_PIN 25 // Thay vì 18
#define FAN_PIN 26  // Thay vì 19
#define MIST_PIN 27 // (Đèn/Phun sương) Thay vì 21

#define TFT_CS    5
#define TFT_DC    16
#define TFT_RST   17

#define BTN_PUMP 12
#define BTN_MIST 13
#define BTN_FAN 33
#define BTN_MODE 32
#define RESET_PIN 0      // BOOT button Wifi Manager

// Global Objects
DHT dht(DHTPIN, DHTTYPE);
Adafruit_ST7789 tft = Adafruit_ST7789(TFT_CS, TFT_DC, TFT_RST);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig fb_config;
WiFiManager wm;
Preferences preferences;

// --- NVS-stored parameters ---
String nvsAreaId = "";
String nvsUserUid = "";

unsigned long lastSensorUpdate = 0;
unsigned long lastDevicePoll = 0;
unsigned long lastDisplayUpdate = 0;
unsigned long buttonDownTime = 0;

// Trạng thái cục bộ (Cache)
bool isPumpOn = false;
bool isFanOn = false;
bool isMistOn = false;
int modeAuto = 0; // 0: AUTO, 1: MANUAL

bool needsCloudDeviceSync = false;
float currentTemp = 0.0;
float currentHumi = 0.0;
int currentSoil = 0;

// WiFiManager custom parameter callbacks
bool shouldSaveConfig = false;

void saveConfigCallback() {
  shouldSaveConfig = true;
}

// === NVS Helper Functions ===

void loadConfigFromNVS() {
  preferences.begin("garden", true); // read-only
  nvsAreaId = preferences.getString("area_id", "");
  nvsUserUid = preferences.getString("user_uid", "");
  preferences.end();
  
  Serial.println("=== NVS Config ===");
  Serial.println("Area ID: " + nvsAreaId);
  Serial.println("User UID: " + nvsUserUid);
}

void saveConfigToNVS(const char* areaId, const char* userUid) {
  preferences.begin("garden", false); // read-write
  preferences.putString("area_id", areaId);
  preferences.putString("user_uid", userUid);
  preferences.end();
  
  nvsAreaId = String(areaId);
  nvsUserUid = String(userUid);
  
  Serial.println("=== Saved to NVS ===");
  Serial.println("Area ID: " + nvsAreaId);
  Serial.println("User UID: " + nvsUserUid);
}

bool isConfigValid() {
  return nvsAreaId.length() > 0 && nvsUserUid.length() > 0;
}

void updateDisplay() {
  tft.fillScreen(ST77XX_BLACK);
  tft.setTextSize(2);
  
  // Kiểm tra xem đã cấu hình chưa
  if (!isConfigValid()) {
    tft.setTextColor(ST77XX_YELLOW);
    tft.setCursor(10, 40);
    tft.println("SETUP REQUIRED");
    tft.setTextColor(ST77XX_WHITE);
    tft.setTextSize(1);
    tft.setCursor(10, 80);
    tft.println("Hold BOOT 5s to");
    tft.setCursor(10, 95);
    tft.println("open WiFi portal.");
    tft.setCursor(10, 120);
    tft.println("Connect to WiFi:");
    tft.setTextColor(ST77XX_CYAN);
    tft.setCursor(10, 140);
    tft.println("SmartGarden_Setup");
    tft.setTextColor(ST77XX_WHITE);
    tft.setCursor(10, 165);
    tft.println("Then fill Area ID");
    tft.setCursor(10, 180);
    tft.println("and User UID.");
    return;
  }
  
  // Tiêu đề
  tft.setTextColor(ST77XX_YELLOW);
  tft.setCursor(30, 5);
  tft.print(Firebase.ready() ? "CONNECTED" : "CONNECTING");
  tft.drawLine(0, 35, 240, 35, ST77XX_WHITE);
  
  // Cảm biến
  tft.setTextColor(ST77XX_RED);   tft.setCursor(10, 50);  tft.print("Temp:  "); tft.print(currentTemp, 1); tft.print(" C");
  tft.setTextColor(ST77XX_CYAN);  tft.setCursor(10, 90);  tft.print("Humid: "); tft.print(currentHumi, 1); tft.print(" %");
  tft.setTextColor(ST77XX_GREEN); tft.setCursor(10, 130); tft.print("Soil:  "); tft.print(currentSoil); tft.print(" %");
  
  tft.drawLine(0, 165, 240, 165, ST77XX_WHITE);
  
  // Trạng thái Relay
  tft.setTextColor(ST77XX_WHITE); 
  tft.setCursor(10, 180); tft.print("MODE: "); tft.setTextColor(modeAuto==0?ST77XX_BLUE:ST77XX_MAGENTA); tft.print(modeAuto==0?"AUTO":"MAN");
  
  tft.setTextColor(ST77XX_WHITE); 
  tft.setCursor(130, 180); tft.print("FAN:"); tft.setTextColor(isFanOn?ST77XX_GREEN:ST77XX_RED); tft.print(isFanOn?"ON":"OFF");
  
  tft.setTextColor(ST77XX_WHITE); 
  tft.setCursor(10, 215); tft.print("PUM:"); tft.setTextColor(isPumpOn?ST77XX_GREEN:ST77XX_RED); tft.print(isPumpOn?"ON":"OFF");
  
  tft.setTextColor(ST77XX_WHITE); 
  tft.setCursor(130, 215); tft.print("MIS:"); tft.setTextColor(isMistOn?ST77XX_GREEN:ST77XX_RED); tft.print(isMistOn?"ON":"OFF");
}

void applyHardwareRelay() {
  digitalWrite(PUMP_PIN, isPumpOn ? HIGH : LOW);
  digitalWrite(FAN_PIN, isFanOn ? HIGH : LOW);
  digitalWrite(MIST_PIN, isMistOn ? HIGH : LOW);
}

// Ghi dữ liệu cảm biến (Fix cấu trúc JSON cho Firestore REST API)
void updateSensors(float t, float h, int soil) {
  if (!Firebase.ready() || !isConfigValid()) return;

  String path = "users/" + nvsUserUid + "/areas/" + nvsAreaId;
  
  // Tạo JSON đúng chuẩn REST API của Firestore Document (mapValue -> fields -> ...)
  FirebaseJson json;
  
  // Xây dựng mảng "sensors"
  FirebaseJsonArray sensorsArr;
  
  FirebaseJson tMap, hsMap, sMap;
  
  tMap.set("mapValue/fields/type/stringValue", "temperature");
  tMap.set("mapValue/fields/value/doubleValue", t);
  tMap.set("mapValue/fields/unit/stringValue", "°C");
  sensorsArr.add(tMap);
  
  hsMap.set("mapValue/fields/type/stringValue", "air_humidity");
  hsMap.set("mapValue/fields/value/doubleValue", h);
  hsMap.set("mapValue/fields/unit/stringValue", "%");
  sensorsArr.add(hsMap);
  
  sMap.set("mapValue/fields/type/stringValue", "soil_moisture");
  sMap.set("mapValue/fields/value/doubleValue", (double)soil);
  sMap.set("mapValue/fields/unit/stringValue", "%");
  sensorsArr.add(sMap);
  
  json.set("fields/sensors/arrayValue/values", sensorsArr);

  // Ghi Firestore
  Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str(), json.raw(), "sensors");
  
  // History
  FirebaseJson hist;
  hist.set("fields/type/stringValue", "temperature");
  hist.set("fields/value/doubleValue", t);
  hist.set("fields/timestamp/integerValue", String((uint64_t)Firebase.getCurrentTime() * 1000));
  String h_path = path + "/history";
  Firebase.Firestore.createDocument(&fbdo, FIREBASE_PROJECT_ID, "", h_path.c_str(), hist.raw());
}

// Đẩy trạng thái relay hiện tại (nếu nút bấm cứng bị nhấn) lên Cloud
void syncRelaysToCloud() {
  if (!Firebase.ready() || !isConfigValid()) return;
  String path = "users/" + nvsUserUid + "/areas/" + nvsAreaId;
  
  // 1. Phải GetDocument trước để lấy ID, Name của Devices về, tránh ghi đè làm mất Info
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str(), "devices")) {
    FirebaseJson& json = fbdo.jsonObject();
    FirebaseJsonData data;
    
    if (json.get(data, "fields/devices/arrayValue/values")) {
       FirebaseJsonArray devices;
       data.getArray(devices);
       
       // Duyệt qua từng device, thấy "type" nào khớp thì sửa "isOn"
       for(size_t i=0; i<devices.size(); i++){
          FirebaseJsonData d_val;
          devices.get(d_val, i);
          FirebaseJson d_obj;
          d_val.getJSON(d_obj);
          
          FirebaseJsonData d_type;
          d_obj.get(d_type, "mapValue/fields/type/stringValue");
          String type = d_type.stringValue;
          
          if(type == "pump") {
            d_obj.set("mapValue/fields/isOn/booleanValue", isPumpOn);
          } else if(type == "fan") {
            d_obj.set("mapValue/fields/isOn/booleanValue", isFanOn);
          } else if(type == "light" || type == "mist") {
            d_obj.set("mapValue/fields/isOn/booleanValue", isMistOn);
          }
          
          devices.set(i, d_obj);
       }
       
       // Đóng gói mảng vào lệnh Patch
       FirebaseJson patchJson;
       patchJson.set("fields/devices/arrayValue/values", devices);
       
       Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str(), patchJson.raw(), "devices");
       Serial.println("Synced physical button press to Cloud!");
    }
  }
}

void pollDevices() {
  if (!Firebase.ready() || needsCloudDeviceSync || !isConfigValid()) return;

  String path = "users/" + nvsUserUid + "/areas/" + nvsAreaId;
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str(), "devices")) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData data;
    
    if (json.get(data, "fields/devices/arrayValue/values")) {
       FirebaseJsonArray devices;
       data.getArray(devices);
       
       bool changed = false;
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
          
          if(type == "pump" && isOn != isPumpOn) { isPumpOn = isOn; changed = true; }
          if(type == "fan" && isOn != isFanOn) { isFanOn = isOn; changed = true; }
          if((type == "light" || type == "mist") && isOn != isMistOn) { isMistOn = isOn; changed = true; }
       }
       
       if (changed) {
         applyHardwareRelay();
         updateDisplay();
       }
    }
  }
}

void checkPhysicalButtons() {
  bool btnPressed = false;

  // Lấy mẫu nhanh không thư viện (Delay nhỏ chống dội)
  if (digitalRead(BTN_PUMP) == LOW) {
    delay(200); // debounce
    isPumpOn = !isPumpOn;
    btnPressed = true;
  }
  if (digitalRead(BTN_FAN) == LOW) {
    delay(200); 
    isFanOn = !isFanOn;
    btnPressed = true;
  }
  if (digitalRead(BTN_MIST) == LOW) {
    delay(200); 
    isMistOn = !isMistOn;
    btnPressed = true;
  }
  if (digitalRead(BTN_MODE) == LOW) {
    delay(200); 
    modeAuto = !modeAuto; // 0 hoặc 1
    // Chưa biết Cloud có mode không, tạm lưu cục bộ.
    updateDisplay();
  }

  if (btnPressed) {
    applyHardwareRelay();
    updateDisplay();
    needsCloudDeviceSync = true;
  }
}


void setup() {
  Serial.begin(115200);
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(MIST_PIN, OUTPUT);
  
  pinMode(BTN_PUMP, INPUT_PULLUP);
  pinMode(BTN_FAN, INPUT_PULLUP);
  pinMode(BTN_MIST, INPUT_PULLUP);
  pinMode(BTN_MODE, INPUT_PULLUP);
  pinMode(RESET_PIN, INPUT_PULLUP);
  
  digitalWrite(PUMP_PIN, LOW); // Active HIGH (Bơm lúc đầu tắt = LOW)
  digitalWrite(FAN_PIN, LOW);
  digitalWrite(MIST_PIN, LOW);

  tft.init(240, 240);
  tft.setRotation(2);
  tft.fillScreen(ST77XX_BLACK);
  tft.setTextSize(2);
  tft.setTextColor(ST77XX_WHITE);
  tft.setCursor(20, 100);
  tft.println("WIFI CONNECTING...");

  // === Load cấu hình từ NVS ===
  loadConfigFromNVS();

  // === WiFiManager với custom parameters ===
  // Tạo 2 trường custom: Area ID và User UID
  WiFiManagerParameter custom_area_id("area_id", "Area ID (Firestore)", nvsAreaId.c_str(), 64);
  WiFiManagerParameter custom_user_uid("user_uid", "User UID (Firebase Auth)", nvsUserUid.c_str(), 64);
  
  wm.addParameter(&custom_area_id);
  wm.addParameter(&custom_user_uid);
  wm.setSaveParamsCallback(saveConfigCallback);
  
  // Hiển thị hướng dẫn trên portal
  wm.setCustomHeadElement(
    "<style>"
    "body{background:#1a1a2e;color:#e0e0e0;font-family:'Segoe UI',sans-serif;}"
    ".wrap{max-width:400px;margin:0 auto;}"
    "input[type='text'],input[type='password']{background:#16213e;border:1px solid #0f3460;color:#e0e0e0;padding:10px;border-radius:8px;width:100%;box-sizing:border-box;}"
    "button,.D{background:#2ecc71;border:none;color:#fff;padding:12px 24px;border-radius:8px;cursor:pointer;font-size:16px;width:100%;margin:4px 0;}"
    "button:hover,.D:hover{background:#27ae60;}"
    ".msg{background:#16213e;border-left:4px solid #2ecc71;padding:10px;margin:10px 0;border-radius:4px;font-size:13px;}"
    "</style>"
    "<div class='msg'>🌱 <b>Smart Garden Setup</b><br>"
    "Nhập WiFi, Area ID và User UID.<br>"
    "Lấy Area ID và UID từ App hoặc Firestore Console.</div>"
  );

  wm.autoConnect("SmartGarden_Setup");
  
  // Nếu portal đã được mở và user nhấn Save → lưu NVS
  if (shouldSaveConfig) {
    saveConfigToNVS(custom_area_id.getValue(), custom_user_uid.getValue());
    Serial.println("Config saved from WiFi portal!");
  }

  // Kiểm tra config hợp lệ
  if (!isConfigValid()) {
    Serial.println("WARNING: Area ID or User UID is empty!");
    Serial.println("Hold BOOT button 5s to re-open WiFi portal.");
  }
  
  fb_config.api_key = FIREBASE_API_KEY;
  fb_config.database_url = FIREBASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  fb_config.token_status_callback = tokenStatusCallback;
  
  Firebase.begin(&fb_config, &auth);
  Firebase.reconnectWiFi(true);
  dht.begin();
  
  updateDisplay();
}


void loop() {
  // Check for reset button (hold 5s) → Reset WiFi + mở lại portal
  if (digitalRead(RESET_PIN) == LOW) {
    if (buttonDownTime == 0) buttonDownTime = millis();
    else if (millis() - buttonDownTime > 5000) { 
      Serial.println("Resetting WiFi settings and reopening portal...");
      wm.resetSettings(); 
      ESP.restart(); 
    }
  } else buttonDownTime = 0;

  // Nếu chưa cấu hình → không chạy logic chính
  if (!isConfigValid()) {
    if (millis() - lastDisplayUpdate > 5000) {
      lastDisplayUpdate = millis();
      updateDisplay(); // Hiển thị hướng dẫn setup
    }
    delay(100);
    return;
  }

  // Quét phím cơ mượt mà
  checkPhysicalButtons();

  if (needsCloudDeviceSync) {
    syncRelaysToCloud();
    needsCloudDeviceSync = false;
    lastDevicePoll = millis(); // Reset lại timer để không đọc cloud ngay lập tức (tránh lỗi cache cloud trả về trạng thái cũ)
  }

  // Poll devices 5s/lần
  if (millis() - lastDevicePoll > 5000 || lastDevicePoll == 0) {
    lastDevicePoll = millis();
    pollDevices();
  }

  // Đọc sensors 30s/lần 
  if (millis() - lastSensorUpdate > 30000 || lastSensorUpdate == 0) {
    lastSensorUpdate = millis();
    currentTemp = dht.readTemperature();
    currentHumi = dht.readHumidity();
    
    // Mạch bạn: 0 - 4095, 100% -> 0% (như code cũ map(val,0,4095,100,0))
    int soilRaw = analogRead(SOIL_PIN);
    currentSoil = map(soilRaw, 0, 4095, 100, 0); 
    currentSoil = constrain(currentSoil, 0, 100);
    
    if(!isnan(currentTemp) && !isnan(currentHumi)) {
      updateSensors(currentTemp, currentHumi, currentSoil);
    }
  }
  
  // Refresh display every 2 seconds
  if (millis() - lastDisplayUpdate > 2000) {
    lastDisplayUpdate = millis();
    updateDisplay();
  }
  
  delay(10);
}
