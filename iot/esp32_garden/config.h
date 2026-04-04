/**
 * Smart Garden IoT Configuration
 * 
 * Generated for your project: smart-garden-manager
 * 
 * NOTE: AREA_ID và USER_UID không cần điền ở đây nữa!
 * Chúng được cấu hình qua WiFi Manager portal và lưu vào bộ nhớ NVS.
 * Khi ESP32 khởi động lần đầu (hoặc sau reset WiFi), truy cập
 * portal "SmartGarden_Setup" và điền Area ID + User UID tại đó.
 */

// 1. WiFi Settings (Optional Fallback)
// Bỏ trống nếu muốn dùng tính năng WiFi Manager (Cấu hình qua điện thoại)
#define WIFI_SSID "" 
#define WIFI_PASSWORD ""

// 2. Firebase Project Settings
#define FIREBASE_API_KEY "AIzaSyDPPIGYq0jibTJVX7hGN1vvEMnHrsFXdb0"
#define FIREBASE_URL "https://smart-garden-manager.firebaseio.com"
#define FIREBASE_PROJECT_ID "smart-garden-manager"

// 3. User Authentication
// Firebase Console > Authentication > Users 
// để tạo một tài khoản email/mật khẩu riêng cho thiết bị này.
#define USER_EMAIL "hquan04hhbg@gmail.com"
#define USER_PASSWORD "quanparkgiang"

// 4. Sensor Thresholds
#define SOIL_MOISTURE_MIN 35
#define SOIL_MOISTURE_MAX 75
