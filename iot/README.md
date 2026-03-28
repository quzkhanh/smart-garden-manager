# Smart Garden IoT Controller (ESP32)

Hướng dẫn kết nối phần cứng và nạp code cho hệ thống vườn thông minh.

## 1. Danh sách linh kiện (Hardware)
| Linh kiện | Số lượng | Ghi chú |
| :--- | :---: | :--- |
| **ESP32 DevKit V1** | 1 | Board điều khiển chính (có sẵn WiFi/Bluetooth) |
| **Cảm biến độ ẩm đất** | 1 | Loại Capacitive (điện dung) chống rỉ sét |
| **Cảm biến DHT11/DHT22** | 1 | Đọc nhiệt độ và độ ẩm không khí |
| **Relay 2-4 Kênh** | 1 | Dùng để bật/tắt Máy bơm, Quạt, Đèn |
| **Nguồn 12V + Hạ áp LM2596** | 1 | Cấp nguồn cho bơm và hạ áp 5V cấp cho ESP32 |
| **Bơm nước MINI 12V** | 1 | Phục vụ tưới cây |

## 2. Sơ đồ đấu nối (Pin Mapping)
| Cảm biến/Thiết bị | Pin ESP32 | Loại Pin |
| :--- | :--- | :--- |
| Cảm biến Độ ẩm Đất | `GPIO 34` | Analog Input |
| Cảm biến DHT22 | `GPIO 4` | Digital Input |
| **Relay 1 (Máy bơm)** | `GPIO 18` | Digital Output |
| **Relay 2 (Quạt)** | `GPIO 19` | Digital Output |
| **Relay 3 (Đèn)** | `GPIO 21` | Digital Output |

## 3. Cài đặt phần mềm (Software)
1. Cài đặt **Arduino IDE** mới nhất.
2. Thêm Board ESP32: `File > Preferences > Additional Boards Manager URLs` dán link: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`.
3. Cài đặt thư viện: `Sketch > Include Library > Manage Libraries...`
   - Tìm và cài đặt `Firebase ESP Client` (bởi Mobizt).
   - Tìm và cài đặt `DHT sensor library` (bởi Adafruit).
   - Tìm và cài đặt `WiFiManager` (bởi tzapu).

## 4. Nạp code
1. Copy file `config.h.example` thành `config.h`.
2. Điền thông tin Firebase của bạn vào `config.h` (Không cần điền WiFi nữa).
3. Mở file `esp32_garden.ino`, chọn đúng Board `ESP32 Dev Module`.
4. Nhấn nút nạp code (Upload).

## 5. Cách cấu hình WiFi qua Portal (Tại trường hoặc nhà mới)
Nếu ESP32 không tìm thấy WiFi cũ, nó sẽ phát ra một mạng WiFi tên là **`SmartGarden_Setup`**.
1. Dùng điện thoại kết nối vào WiFi **`SmartGarden_Setup`**.
2. Một trang web cấu hình sẽ tự động hiện ra (Nếu không, hãy truy cập `192.168.4.1`).
3. Nhấn **Configure WiFi**, chọn mạng WiFi mới và nhập mật khẩu.
4. Nhấn **Save**, ESP32 sẽ tự khởi động lại và kết nối.

> [!TIP]
> **Nút Reset WiFi**: Nếu muốn xóa WiFi cũ để cài lại, hãy nhấn giữ nút **BOOT** (GPIO 0) trên ESP32 trong vòng 5 giây. Đèn LED trên board sẽ nhấp nháy báo hiệu đã reset.

---
> [!IMPORTANT]
> - Hãy kiểm tra kỹ điện áp trước khi đấu nối. ESP32 hoạt động ở **3.3V**, các Relay thường dùng **5V**. Tránh đấu trực tiếp 12V vào ESP32 sẽ làm cháy board.
