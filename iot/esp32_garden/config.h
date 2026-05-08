/**
 * Smart Garden IoT Configuration
 * 
 * Generated for your project: smart-garden-manager
 * 
 * NOTE: Email, Password và Area ID được cấu hình qua WiFi Manager portal!
 * Khi ESP32 khởi động lần đầu (hoặc sau reset WiFi), truy cập
 * portal "SmartGarden_Setup" và điền:
 *   - WiFi nhà bạn
 *   - Email + Password tài khoản trên App
 *   - Area ID từ màn hình App
 * UID sẽ được tự động lấy từ Firebase Auth.
 */

// 1. WiFi Settings (Optional Fallback)
// Bỏ trống nếu muốn dùng tính năng WiFi Manager (Cấu hình qua điện thoại)
#define WIFI_SSID "" 
#define WIFI_PASSWORD ""

// 2. Firebase Project Settings
#define FIREBASE_API_KEY "AIzaSyDPPIGYq0jibTJVX7hGN1vvEMnHrsFXdb0"
#define FIREBASE_URL "https://smart-garden-manager.firebaseio.com"
#define FIREBASE_PROJECT_ID "smart-garden-manager"

// 3. Sensor Thresholds
#define SOIL_MOISTURE_MIN 35
#define SOIL_MOISTURE_MAX 75
