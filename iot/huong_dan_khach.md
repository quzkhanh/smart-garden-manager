# 🔧 Hướng dẫn cấu hình lại ESP32 Smart Garden

## ❌ Nguyên nhân lỗi "không gửi được dữ liệu"

**Firebase Security Rules** yêu cầu: ESP32 phải đăng nhập **đúng tài khoản** của người dùng mới được ghi dữ liệu vào path của người đó.

Code cũ hardcode email/password của **người phát triển**, nhưng lại ghi vào path của **khách hàng** → Firebase từ chối (permission-denied).

## ✅ Code mới đã sửa gì?

| Trước | Sau |
|---|---|
| Nhập: WiFi + Area ID + **User UID** | Nhập: WiFi + **Email** + **Password** + Area ID |
| ESP32 đăng nhập bằng tài khoản dev | ESP32 đăng nhập bằng **tài khoản của khách** |
| Khách phải tự tìm UID (khó) | UID được **tự động lấy** từ Firebase Auth |

## 📋 Các bước cấu hình mới

### Bước 1: Nạp code mới vào ESP32
Nạp lại file `esp32_garden.ino` + `config.h` đã cập nhật.

### Bước 2: Reset WiFi (nếu đã cấu hình trước đó)
Giữ nút **BOOT** trên ESP32 trong **5 giây** → ESP32 sẽ tự restart và mở portal WiFi.

### Bước 3: Kết nối WiFi portal
1. Dùng điện thoại kết nối WiFi: **`SmartGarden_Setup`**
2. Trang cấu hình sẽ tự mở ra

### Bước 4: Điền thông tin
| Trường | Nhập gì | Ví dụ |
|---|---|---|
| **WiFi SSID** | Tên WiFi nhà bạn | `WiFi_NhaToi` |
| **WiFi Password** | Mật khẩu WiFi | `12345678` |
| **Firebase Email** | Email đã đăng ký trên App | `myemail@gmail.com` |
| **Firebase Password** | Mật khẩu tài khoản App | `mypassword123` |
| **Area ID** | ID khu vực từ App | `abc123xyz` |

### Bước 5: Lấy Area ID từ App
Mở App → vào trang chính → bấm vào khu vực vườn → xem ID hiển thị (hoặc vào Firebase Console > Firestore > `users/{uid}/areas` → copy document ID).

### Bước 6: Kiểm tra
Mở **Serial Monitor** (baud 115200) → xem log:
```
=== SMART GARDEN DEBUG ===
WiFi: WiFi_NhaToi
IP: 192.168.1.100
Auth Email: myemail@gmail.com
Auth UID: aBcDeFgHiJkLmNoPqRsTuV    ← Tự động lấy!
Target Area: abc123xyz
Path: users/aBcDeFgHiJkLmNoPqRsTuV/areas/abc123xyz
Firebase Ready: YES
=========================

>>> Updating sensors to: users/aBcDeFgHiJkLmNoPqRsTuV/areas/abc123xyz
OK: Sensors updated!
OK: History saved!
```

> [!WARNING]
> Nếu thấy dòng `FAIL updateSensors: ...` → đọc thông báo lỗi và gửi lại cho người phát triển App.

## 🔍 Các lỗi thường gặp

| Log lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `FAIL: permission denied` | Email/password sai hoặc tài khoản chưa tồn tại | Kiểm tra lại email và mật khẩu |
| `FAIL: document not found` | Area ID sai | Kiểm tra lại Area ID từ App |
| `Firebase Ready: NO` | WiFi yếu hoặc sai email/password | Reset WiFi và nhập lại |
| `AUTH UID: (trống)` | Email/password không đúng | Đăng ký lại tài khoản trên App |
