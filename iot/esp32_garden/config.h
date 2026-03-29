/**
 * Smart Garden IoT Configuration
 * 
 * Generated for your project: smart-garden-manager
 */

// 1. WiFi Settings (Optional Fallback)
// Bỏ trống nếu muốn dùng tính năng WiFi Manager (Cấu hình qua điện thoại)
#define WIFI_SSID "" 
#define WIFI_PASSWORD ""

// 2. Firebase Project Settings
#define FIREBASE_API_KEY "AIzaSyDPPIGYq0jibTJVX7hGN1vvEMnHrsFXdb0"
#define FIREBASE_URL "https://smart-garden-manager.firebaseio.com"

// 3. User Authentication
// Firebase Console > Authentication > Users 
// để tạo một tài khoản email/mật khẩu riêng cho thiết bị này.
#define USER_EMAIL "hquan04hhbg@gmail.com"
#define USER_PASSWORD "quanparkgiang"

// 4. Area & User Identification
// Sau khi đăng nhập vào App, vào Firestore tìm UID của mình 
// và ID của khu vực vườn muốn điều khiển rồi điền vào đây nhé.
#define AREA_ID "ID_KHU_VƯC_TRÊN_FIRESTORE"
#define USER_UID "UID_CỦA_USER"

// 5. Sensor Thresholds
#define SOIL_MOISTURE_MIN 35
#define SOIL_MOISTURE_MAX 75
