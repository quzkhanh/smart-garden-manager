# 🌱 Smart Garden IoT Controller (ESP32)

Hướng dẫn chi tiết kết nối phần cứng, nạp code và cấu hình cho hệ thống vườn thông minh.

---

## 1. Danh sách linh kiện (Hardware)

| Linh kiện               | Số lượng | Ghi chú                                        |
| :---------------------- | :------: | :--------------------------------------------- |
| **ESP32 DevKit V1**     |    1     | Board điều khiển chính (có sẵn WiFi/Bluetooth) |
| **Cảm biến độ ẩm đất**  |    3     | Loại Capacitive (điện dung) chống rỉ sét       |
| **Cảm biến DHT22**      |    3     | Đọc nhiệt độ và độ ẩm không khí                |
| **Relay 3 Kênh**        |    3     | Bật/tắt Máy bơm, Quạt, Phun sương              |
| **Màn hình TFT ST7789** |    0     | Hiển thị trạng thái (240x240, SPI)             |
| **Nút nhấn**            |    0     | Điều khiển Bơm, Quạt, Phun sương, Mode         |
| **Nguồn 5V**            |    2     | Cấp nguồn cho các thiết bị                     |
| **Bơm nước MINI 12V**   |    3     | Phục vụ tưới cây                               |
| **Quạt 12V**            |    3     | Thông gió / làm mát                            |
| **Phun sương**          |    3     | Phun hơi nước                                  |

---

## 2. Sơ đồ đấu nối (Pin Mapping)

### Cảm biến (Input)

| Cảm biến              | Pin ESP32 | Loại          |
| :-------------------- | :-------- | :------------ |
| Cảm biến Độ ẩm Đất    | `GPIO 34` | Analog Input  |
| Cảm biến DHT22 (DATA) | `GPIO 4`  | Digital Input |

### Relay (Output)

| Thiết bị               | Pin ESP32 | Ghi chú     |
| :--------------------- | :-------- | :---------- |
| Relay Máy bơm          | `GPIO 25` | Active HIGH |
| Relay Quạt             | `GPIO 26` | Active HIGH |
| Relay Phun sương / Đèn | `GPIO 27` | Active HIGH |

### Màn hình TFT ST7789 (SPI)

| Chân TFT | Pin ESP32                 |
| :------- | :------------------------ |
| CS       | `GPIO 5`                  |
| DC       | `GPIO 16`                 |
| RST      | `GPIO 17`                 |
| SDA      | `GPIO 23` (MOSI mặc định) |
| SCL      | `GPIO 18` (SCK mặc định)  |

### Nút nhấn (INPUT_PULLUP)

| Nút                   | Pin ESP32 | Chức năng                           |
| :-------------------- | :-------- | :---------------------------------- |
| Nút Bơm               | `GPIO 12` | Bật/tắt máy bơm                     |
| Nút Phun sương        | `GPIO 13` | Bật/tắt phun sương                  |
| Nút Quạt              | `GPIO 33` | Bật/tắt quạt                        |
| Nút Mode              | `GPIO 32` | Chuyển AUTO ↔ MANUAL                |
| Nút BOOT (Reset WiFi) | `GPIO 0`  | Giữ 5 giây → Reset WiFi + mở portal |

---

## 3. Cài đặt phần mềm (Software)

### 3.1. Cài đặt Arduino IDE

1. Tải và cài đặt [Arduino IDE](https://www.arduino.cc/en/software) mới nhất.
2. Thêm Board ESP32:  
   `File > Preferences > Additional Boards Manager URLs` → dán link:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Vào `Tools > Board > Boards Manager`, tìm **esp32** và cài đặt.

### 3.2. Cài đặt thư viện

Vào `Sketch > Include Library > Manage Libraries...`, tìm và cài các thư viện sau:

| Thư viện               | Tác giả  | Mục đích                     |
| :--------------------- | :------- | :--------------------------- |
| `Firebase ESP Client`  | Mobizt   | Kết nối Firestore            |
| `DHT sensor library`   | Adafruit | Đọc cảm biến DHT22           |
| `WiFiManager`          | tzapu    | Cấu hình WiFi qua web portal |
| `Adafruit GFX Library` | Adafruit | Thư viện đồ họa cơ bản       |
| `Adafruit ST7789`      | Adafruit | Driver màn hình TFT          |

---

## 4. Nạp code lần đầu

### Bước 1: Sửa `config.h`

Mở file `config.h` và điền thông tin Firebase của bạn:

```c
// Firebase Project Settings (lấy từ Firebase Console > Project Settings)
#define FIREBASE_API_KEY "AIzaSy..."
#define FIREBASE_URL "https://your-project-id.firebaseio.com"
#define FIREBASE_PROJECT_ID "your-project-id"

// Tài khoản Firebase Auth cho thiết bị
#define USER_EMAIL "your-device-email@gmail.com"
#define USER_PASSWORD "your-password"
```

> [!NOTE]
> **Bạn KHÔNG cần điền WiFi, Area ID hay User UID trong file này!**  
> Tất cả đều được cấu hình qua WiFi Manager portal sau khi nạp code.

### Bước 2: Nạp code

1. Mở file `esp32_garden.ino` trong Arduino IDE.
2. Chọn Board: `Tools > Board > ESP32 Dev Module`.
3. Chọn đúng cổng COM: `Tools > Port`.
4. Nhấn **Upload** (→) để nạp code.

---

## 5. Cấu hình WiFi + Area ID + User UID qua Portal

Đây là tính năng quan trọng nhất — **bạn chỉ cần nạp code 1 lần**, sau đó mọi cấu hình đều qua web portal.

### 5.1. Khi nào portal tự mở?

- **Lần đầu** sau khi nạp code (chưa có WiFi nào được lưu).
- **Khi WiFi cũ không khả dụng** (đổi router, đổi mật khẩu WiFi...).
- **Sau khi nhấn giữ nút BOOT 5 giây** (reset thủ công).

### 5.2. Các bước cấu hình

```
┌─────────────────────────────────────────────────────────┐
│  ESP32 khởi động → Không có WiFi → Phát mạng WiFi AP   │
│  Tên mạng: "SmartGarden_Setup" (không mật khẩu)        │
└───────────────────────┬─────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│  1. Dùng điện thoại/laptop kết nối WiFi                 │
│     "SmartGarden_Setup"                                 │
│                                                         │
│  2. Trang web cấu hình tự hiện ra                       │
│     (Nếu không, truy cập http://192.168.4.1)            │
└───────────────────────┬─────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│  3. Nhấn "Configure WiFi" và điền:                      │
│                                                         │
│     📶 WiFi SSID:     [tên mạng WiFi nhà bạn]          │
│     🔑 WiFi Password: [mật khẩu WiFi]                  │
│     🌱 Area ID:       [ID khu vực trên Firestore]       │
│     👤 User UID:      [UID tài khoản Firebase Auth]     │
│                                                         │
│  4. Nhấn "Save"                                         │
└───────────────────────┬─────────────────────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│  ESP32 tự khởi động lại → Kết nối WiFi → Firebase      │
│  Dữ liệu được lưu vào NVS, không mất khi tắt nguồn!   │
└─────────────────────────────────────────────────────────┘
```

### 5.3. Lấy Area ID và User UID ở đâu?

#### Cách 1: Từ ứng dụng Flutter

1. Mở app Smart Garden → Đăng nhập.
2. Vào **Hồ sơ (Profile)** → User UID hiển thị ở đây.
3. Vào màn hình **Dashboard** → chọn khu vực → Area ID hiển thị trong phần cài đặt khu vực.

#### Cách 2: Từ Firebase Console

1. Truy cập [Firebase Console](https://console.firebase.google.com).
2. **User UID**: Vào `Authentication > Users` → copy cột **User UID**.
3. **Area ID**: Vào `Firestore Database > users > {uid} > areas` → copy **Document ID** của khu vực muốn kết nối.

---

## 6. Cách hoạt động

### 6.1. Luồng dữ liệu

```
┌──────────┐    Sensors     ┌──────────────┐   Firestore   ┌──────────────┐
│  DHT22   │───────────────▶│              │──────────────▶│              │
│  Soil    │   (mỗi 30s)   │    ESP32     │               │  Firebase    │
│          │                │              │◀──────────────│  Cloud       │
└──────────┘                │              │  Poll devices │              │
                            │              │   (mỗi 5s)   │              │
┌──────────┐   Nút nhấn    │              │               │              │
│  Buttons │───────────────▶│              │──────────────▶│              │
│  (x4)    │  Toggle relay  │              │  Sync relay   │              │
└──────────┘                └──────┬───────┘               └──────┬───────┘
                                   │                              │
                            ┌──────▼───────┐               ┌──────▼───────┐
                            │  Relay x3    │               │  Flutter App │
                            │  TFT Display │               │  (Remote)    │
                            └──────────────┘               └──────────────┘
```

### 6.2. Chu kỳ hoạt động

| Tác vụ                       | Chu kỳ   | Mô tả                      |
| :--------------------------- | :------- | :------------------------- |
| Đọc cảm biến + đẩy Firestore | 30 giây  | Nhiệt độ, độ ẩm, độ ẩm đất |
| Poll trạng thái thiết bị     | 5 giây   | Nhận lệnh bật/tắt từ App   |
| Refresh màn hình TFT         | 2 giây   | Cập nhật hiển thị          |
| Quét nút nhấn                | Liên tục | Debounce 200ms             |

### 6.3. Nút nhấn vật lý

- **Nút Bơm/Quạt/Phun sương**: Nhấn 1 lần → đổi trạng thái relay → tự động đồng bộ lên Cloud.
- **Nút Mode**: Chuyển giữa AUTO và MANUAL (hiện tại lưu cục bộ).
- **Nút BOOT (GPIO 0)**: Giữ 5 giây → **Reset WiFi + xóa cấu hình** → mở lại portal.

---

## 7. Xử lý sự cố (Troubleshooting)

### ESP32 không kết nối được WiFi

1. Giữ nút **BOOT** 5 giây để reset WiFi.
2. Kết nối lại portal `SmartGarden_Setup` và nhập đúng tên + mật khẩu WiFi.
3. Kiểm tra router có chặn thiết bị mới không.

### Dữ liệu không lên Firestore

1. Kiểm tra Serial Monitor (115200 baud) xem có lỗi gì.
2. Xác nhận **Area ID** và **User UID** đã nhập đúng trong portal.
3. Kiểm tra `FIREBASE_API_KEY` trong `config.h` có đúng không.
4. Xác nhận tài khoản `USER_EMAIL` đã được tạo trong Firebase Authentication.

### Muốn đổi Area ID hoặc User UID

1. Giữ nút **BOOT** 5 giây → ESP32 restart và phát WiFi `SmartGarden_Setup`.
2. Kết nối portal → nhập lại Area ID + User UID mới → Save.
3. **Không cần nạp lại code!** Giá trị được lưu trong bộ nhớ NVS.

### Cảm biến đọc sai giá trị

- DHT22 đọc `NaN`: Kiểm tra dây nối GPIO 4, thêm điện trở pull-up 10K giữa DATA và VCC.
- Độ ẩm đất luôn 0% hoặc 100%: Kiểm tra kết nối GPIO 34, cảm biến có bị ngập nước không.

### Màn hình TFT không hiển thị

- Kiểm tra dây SPI: CS (GPIO 5), DC (GPIO 16), RST (GPIO 17).
- Xác nhận đã cấp nguồn 3.3V cho module TFT.

---

## 8. Cấu trúc file

```
iot/esp32_garden/
├── esp32_garden.ino     # Code chính (WiFi, Firebase, Sensors, Relay, Display)
├── config.h             # Cấu hình Firebase (KHÔNG commit lên Git!)
└── README.md            # File này
```

> [!IMPORTANT]
>
> - File `config.h` chứa **API key và mật khẩu** → đã được thêm vào `.gitignore`, **KHÔNG commit lên GitHub**.
> - Kiểm tra kỹ điện áp trước khi đấu nối. ESP32 hoạt động ở **3.3V**, Relay thường dùng **5V**. **Tuyệt đối không đấu 12V trực tiếp vào ESP32** sẽ làm cháy board.

> [!TIP]
> Sau khi nạp code lần đầu, mọi thay đổi WiFi, Area ID, User UID đều thực hiện qua **WiFi Manager portal** — không cần mở Arduino IDE nữa!
