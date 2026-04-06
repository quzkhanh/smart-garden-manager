# 🌱 Smart Garden — Tổng hợp Chức năng Đã Hoàn thành

> Tài liệu mô tả chi tiết toàn bộ các tính năng đã được implement trong hệ thống **Smart Garden** — bao gồm **Ứng dụng di động Flutter**, **Web App Firebase Hosting**, và **Firmware ESP32 IoT Controller**.
> 
> Cập nhật lần cuối: **06/04/2026**

---

## Mục lục

1. [Xác thực & Quản lý Phiên](#1-xác-thực--quản-lý-phiên)
2. [Trang chủ & Dashboard](#2-trang-chủ--dashboard)
3. [Quản lý Khu vực (Area)](#3-quản-lý-khu-vực-area)
4. [Giám sát Cảm biến](#4-giám-sát-cảm-biến)
5. [Điều khiển Thiết bị](#5-điều-khiển-thiết-bị)
6. [Hệ thống Tự động hóa (Automation)](#6-hệ-thống-tự-động-hóa-automation)
7. [Cấu hình Khu vực (Area Config)](#7-cấu-hình-khu-vực-area-config)
8. [Hệ thống Cảnh báo (Alerts)](#8-hệ-thống-cảnh-báo-alerts)
9. [Quản lý Thiết bị Đăng nhập](#9-quản-lý-thiết-bị-đăng-nhập)
10. [Thời tiết](#10-thời-tiết)
11. [Cài đặt Ứng dụng](#11-cài-đặt-ứng-dụng)
12. [Firmware ESP32 IoT](#12-firmware-esp32-iot)
13. [Kiến trúc & Kỹ thuật](#13-kiến-trúc--kỹ-thuật)

---

## 1. Xác thực & Quản lý Phiên

### 1.1. Đăng nhập bằng Email/Password
- **Đăng nhập**: Nhập email + mật khẩu → xác thực qua `Firebase Auth signInWithEmailAndPassword`.
- **Đăng ký tài khoản mới**: Checkbox "Đăng ký" trên form → `createUserWithEmailAndPassword`, yêu cầu xác nhận mật khẩu.
- **Nút hiện/ẩn mật khẩu**: `IconButton` toggle `obscureText` cho cả ô password lẫn confirm password → UX cải thiện, không cần gõ lại khi sai.
- **Xử lý lỗi chi tiết**: Map từng `FirebaseAuthException.code` sang thông báo tiếng Việt cụ thể (tài khoản không tồn tại, mật khẩu sai, email đã tồn tại, mật khẩu quá yếu, credential không hợp lệ...).
- **Dialog lỗi animating**: Sử dụng widget `AnimatedErrorDialog` tùy chỉnh với icon cảnh báo + animation bounce.

### 1.2. Quên mật khẩu
- **Màn hình riêng** (`ForgotPasswordScreen`): Nhập email → gọi `Firebase Auth sendPasswordResetEmail`.
- **Link reset gốc Firebase**: Người dùng nhận email chứa link đặt lại mật khẩu native, không dùng custom action code.
- **Xử lý lỗi riêng**: `user-not-found`, `invalid-email`, v.v.

### 1.3. Đăng nhập bằng Số điện thoại (OTP)
- **Nhập số điện thoại VN**: Ô input với prefix `🇻🇳 +84`, chỉ cho phép nhập số, giới hạn 11 ký tự.
- **Chuẩn hóa E.164**: Tự động chuyển `0912345678` → `+84912345678`.
- **Kiểm tra quyền truy cập**: Trước khi gửi OTP, query Firestore collection `allowed_phones` để xác nhận số đã được Admin cấp phép.
- **Validate format**: Regex kiểm tra đầu số mạng VN hợp lệ (03x, 05x, 07x, 08x, 09x).
- **Gửi OTP**: `Firebase Auth verifyPhoneNumber` → chuyển sang `OtpScreen`.
- **Auto-verification** (Android): Tự động nhận OTP và đăng nhập không cần nhập tay (`verificationCompleted` callback).
- **Màn hình nhập OTP** (`OtpScreen`): Dùng widget `Pinput` cho UX nhập 6 ký tự OTP mượt mà.

### 1.4. Đăng nhập bằng QR Code (Cross-device)
- **Sinh mã QR phiên**: Tạo session ID duy nhất `sg-{sha256_hash}`, lưu vào Firestore collection `qr_sessions` với status `pending` + TTL 120s.
- **Hiển thị QR**: Dùng `qr_flutter` render QR code chứa session ID trên `QrLoginScreen`.
- **Realtime listener**: Stream Firestore document, khi `status` chuyển sang `approved` → tự động `signInAnonymously` + gắn `masterUid` từ `approvedBy` field.
- **Quét QR xác nhận** (`QrScannerScreen`): Thiết bị đã đăng nhập mở camera bằng `MobileScannerController`, quét mã → ghi `status: 'approved'` + `approvedBy: currentUser.uid` vào Firestore.
- **UI scanner chuyên nghiệp**: Custom overlay `_ScanOverlayPainter` vẽ khung viền rounded + corner lines, đổi màu theo trạng thái (trắng → vàng → xanh). Hỗ trợ bật/tắt đèn flash.
- **Lưu master UID**: Qua `SharedPreferences`, session QR share data garden của user gốc.

### 1.5. Quản lý phiên đăng nhập
- **Ghi thông tin thiết bị**: Khi đăng nhập thành công, tự động lưu device info (tên, platform, trạng thái online, thời gian) vào Firestore `users/{uid}/logged_devices/{deviceId}`.
- **Remote kick-out**: `DeviceProvider` lắng nghe realtime — nếu document thiết bị hiện tại bị xóa (bị đá ra từ thiết bị khác), tự động `forceLogout` với thông báo "Phiên đăng nhập đã hết hạn...".
- **Xóa device khi logout**: Khi logout chủ động, xóa document thiết bị hiện tại khỏi Firestore.

### 1.6. Onboarding Tutorial
- **Màn hình hướng dẫn** (`OnboardingScreen`): Nhiều slide giới thiệu tính năng app, có animation.
- **Lần đầu mở app**: Kiểm tra `SharedPreferences is_first_time`, nếu `true` → hiện onboarding.
- **Truy cập lại từ Settings**: Có nút "Hướng dẫn sử dụng" trong Settings, navigate `/onboarding`.
- **Truy cập từ Login**: Nút "Hướng dẫn" ở cuối form login.

### 1.7. Chuyển đổi giữa các phương thức đăng nhập
- **Toggle Email ↔ Điện thoại**: Nút chuyển đổi bên dưới form login, `AnimatedSwitcher` chuyển mượt.
- **Nút mở QR Login**: Nút riêng "Đăng nhập bằng QR".
- **Quay lại**: `goBackToPhone()` reset state về `unauthenticated`, hủy listener QR/OTP.

---

## 2. Trang chủ & Dashboard

### 2.1. Dashboard tổng quan
- **Lời chào theo thời gian**: Hiển thị "Chào buổi sáng/chiều/tối/khuya" dựa trên `DateTime.now().hour`, hỗ trợ i18n.
- **Grid metrics 3x2**: Layout lưới 6 ô thông tin (tỷ lệ 1:3 chiều ngang):
  - **Tổng khu vực** (Areas count)
  - **Trạng thái thời tiết** (Mô tả + icon)
  - **Tổng thiết bị** (Devices count)
  - **Nhiệt độ hiện tại** (°C)
  - **Cảnh báo chưa đọc** (Badge đỏ khi > 0)
  - **Vị trí GPS** (Tên thành phố, format gọn)
- **Tooltip tap-to-show**: Mỗi ô metric có `Tooltip` hiển thị label đầy đủ khi tap.

### 2.2. Danh sách khu vực
- **Danh sách area cards**: Hiển thị tất cả khu vực của user từ Firestore realtime.
- **Responsive layout**:
  - Mobile (`< 600px`): `SliverList` dọc
  - Tablet (`600-800px`): `SliverGrid` 2 cột
  - Desktop (`> 800px`): `SliverGrid` 3 cột
- **Empty state**: Icon lá + thông báo "Chưa có khu vực nào" + hướng dẫn tạo mới.
- **FAB thêm khu vực**: `FloatingActionButton` mở dialog `AddAreaDialog`.
- **Pull-to-refresh**: `RefreshIndicator` gọi `refreshData()` (cập nhật thời tiết).
- **Staggered animation**: Mỗi card fadeIn với delay tăng dần (`300 + index * 80 ms`).

### 2.3. Area Card
- Widget `AreaCard` hiển thị:
  - Tên khu vực
  - Badge chế độ Auto/Manual
  - Danh sách sensor (nhiệt độ, độ ẩm, độ ẩm đất) với progress bar
  - Số thiết bị đang bật / tổng
  - Tap → navigate `/area/{areaId}`

### 2.4. Thêm khu vực mới
- **Dialog `AddAreaDialog`**: Nhập tên + chọn loại thiết bị ban đầu.
  - Hỗ trợ 5 loại thiết bị: Máy bơm (pump), Quạt (fan), Đèn (light), Phun sương (mist), Van nước (valve).
  - Mỗi thiết bị chọn bằng checkbox, tự động đặt tên tiếng Việt.
- **Default devices**: Nếu không chọn → tự tạo Máy bơm 1 + Quạt thông gió.
- **Sensor mặc định**: Mỗi area mới có 3 sensor: temperature (25°C), air_humidity (60%), soil_moisture (45%).

---

## 3. Quản lý Khu vực (Area)

### 3.1. Màn hình chi tiết khu vực (`AreaDetailScreen`)
- **AppBar**: Hiển thị tên khu vực + subtitle "Chi tiết khu vực". Nút cài đặt → `/area/{areaId}/config`.
- **Responsive layout desktop**: Màn `> 800px` chia 2 cột (1:2 ratio) — bên trái Mode + Sensor, bên phải Chart + Device Control.

### 3.2. Toggle chế độ vận hành
- **Switch Auto/Manual**: `Switch.adaptive` chuyển đổi `isAutoMode`.
- **Label động**: Hiển thị text + màu tương ứng (xanh lá = Auto, cam = Manual).
- **Optimistic UI**: Update local state + Firestore async:
  ```
  areas/{areaId} → update { isAutoMode: true/false }
  ```

### 3.3. Xóa khu vực
- **Dialog xác nhận `DeleteAreaDialog`**: Cảnh báo xóa sẽ mất toàn bộ dữ liệu.
- **Xóa Firestore document**: `areas/{areaId}.delete()`.
- **Navigate back**: Sau xóa quay về trang chủ.

---

## 4. Giám sát Cảm biến

### 4.1. Hiển thị realtime
- **Widget `SensorBar`**: Thanh tiến trình cho từng loại sensor:
  - **temperature**: Icon nhiệt kế, unit °C, range 0-50
  - **air_humidity**: Icon giọt nước, unit %, range 0-100
  - **soil_moisture**: Icon cỏ, unit %, range 0-100
- **Màu sắc theo giá trị**: Gradient bar thay đổi từ xanh → cam → đỏ theo ngưỡng.
- **Percentage tính tự động**: `sensor.percentage` dựa trên range tương ứng.

### 4.2. Biểu đồ lịch sử 24h
- **Widget `SensorChartCard`**: Card chứa biểu đồ FL Chart.
- **Stream Firestore**: Query `areas/{areaId}/history` với filter `type` + `timestamp > 25h ago`, sắp xếp tăng dần.
- **Biểu đồ đường** (`LineChart`): Render từ `SensorReading` list, trục X = thời gian, trục Y = giá trị.
- **Tab chuyển sensor**: Cho phép xem từng loại sensor riêng (nhiệt độ / độ ẩm / độ ẩm đất).
- **Base chart widget** (`SensorChartBase`): Widget cơ sở với styling FL Chart thống nhất.

---

## 5. Điều khiển Thiết bị

### 5.1. DeviceTile — Widget điều khiển
- **Hiển thị**: Icon theo type (pump → 💧, fan → 🌀, light → 💡, mist → 🌫, valve → 🚰), tên thiết bị, trạng thái ON/OFF.
- **Toggle switch**: Bật/tắt thiết bị bằng Switch, **chỉ active khi ở Manual mode**.
- **Auto mode locked**: Khi `isAutoMode = true`, switch disabled, hiển thị badge "AUTO".

### 5.2. Bật/tắt thiết bị (Manual Mode)
- **Optimistic update**: Toggle local `device.isOn` → notify UI → sync Firestore async.
- **Firestore sync**: Ghi lại toàn bộ mảng `devices` vào document area:
  ```
  areas/{areaId} → update { devices: [...] }
  ```

### 5.3. Hẹn giờ thiết bị (Timer)
- **Dialog `TimerPickerDialog`**: Chọn thời lượng hẹn giờ (phút/giờ), UI dạng cuộn (CupertinoPicker style).
- **Set timer**: `device.setTimer(duration)` → lưu `timerEndTime = now + duration`.
- **Countdown realtime**: `GardenProvider` chạy `Timer.periodic(1s)` kiểm tra tất cả devices:
  - Nếu `hasActiveTimer && timerRemaining == 0` → auto toggle + clear timer.
  - Nếu còn timer active → `notifyListeners()` mỗi giây để cập nhật UI countdown.
- **Widget hiển thị timer** (`DeviceTimerWidgets`): Badge countdown mm:ss, nút hủy timer.
- **Cancel timer**: Xóa `timerDuration + timerEndTime`, sync Firestore.

### 5.4. Thêm/xóa thiết bị
- **Dialog `AddDeviceDialog`**: Nhập tên + chọn type → thêm vào mảng `devices` của area.
- **Xóa thiết bị**: Dialog xác nhận → `removeWhere` khỏi mảng → sync Firestore.

---

## 6. Hệ thống Tự động hóa (Automation)

### 6.1. Mô hình Automation Rule (V2)
- **Đa điều kiện (Multi-condition)**: Mỗi rule có list `RuleConditionBlock`, mỗi block gồm:
  - `triggerType`: `sensor` hoặc `weather`
  - `triggerKey`: loại cảm biến (`moisture`, `temperature`) hoặc thời tiết (`rain`, `temp`)
  - `condition`: `greaterThan`, `lessThan`, `equals`
  - `thresholdValue`: ngưỡng so sánh
- **Toán tử logic**: `LogicalOperator.and` hoặc `.or` — kết hợp giữa các điều kiện.
- **Đa hành động (Multi-action)**: List `RuleActionBlock`, mỗi block gắn `deviceId` + `actionOn` (bật/tắt).
- **Backward compatible**: Tự động migrate từ schema V1 (single condition/action) lên V2 khi parse.

### 6.2. Đánh giá tự động (`_evaluateAutomations`)
- **Trigger bởi thời tiết**: Mỗi lần fetch weather (15 phút/lần), duyệt qua tất cả areas ở Auto mode.
- **Sensor-based**: So sánh giá trị sensor hiện tại với ngưỡng trong condition.
- **Weather-based**: Kiểm tra mô tả thời tiết (chứa "rain"?) hoặc so sánh nhiệt độ.
- **AND/OR logic**: Nếu tất cả conditions đúng (AND) hoặc bất kỳ (OR) → execute actions.
- **Tránh toggle thừa**: Chỉ thay đổi device khi `device.isOn != action.actionOn`.
- **Sync sau khi thay đổi**: `_syncAreaDevices()` cập nhật Firestore.

### 6.3. Rule Builder Sheet (`RuleBuilderSheet`)
- **Bottom sheet full-height**: Modal cho phép tạo/sửa automation rule.
- **Thêm điều kiện**: Chọn trigger type, trigger key, operator, threshold.
- **Thêm hành động**: Chọn device + trạng thái ON/OFF.
- **Toggle AND/OR**: Chuyển toán tử logic giữa các điều kiện.
- **Enable/disable rule**: Switch bật/tắt rule mà không xóa.
- **CRUD đầy đủ**: `addRule`, `updateRule`, `deleteRule` — all synced to Firestore.

---

## 7. Cấu hình Khu vực (Area Config)

### 7.1. Màn hình cấu hình (`AreaConfigScreen`)
- **Đổi tên khu vực**: TextField với `LengthLimitingTextInputFormatter(40)`, icon label.
- **Ngưỡng độ ẩm đất**: Slider 10-90%, nhãn hiện hành hiển thị badge giá trị xanh lá.
  - Mô tả: "Máy bơm sẽ kích hoạt khi giá trị xuống dưới ngưỡng này".
- **Nhiệt độ tối đa**: Slider 20-45°C, nhãn badge cam.
  - Mô tả: "Quạt/phun sương sẽ kích hoạt khi nhiệt độ vượt ngưỡng này".
- **Lịch chiếu sáng**: 
  - Banner gradient hiển thị `ON time → OFF time` trực quan.
  - 2 nút chọn giờ (`ConfigTimeButton`) mở `showTimePicker`.
  - `ConfigDurationRow`: Tính và hiển thị tổng số giờ chiếu sáng.
- **Range labels**: Widget `ConfigRangeLabels` hiển thị min/max ở hai đầu slider.

### 7.2. Lưu cấu hình
- **Nút Save sticky**: `ConfigSaveBar` cố định ở bottom, chỉ active khi `_hasChanges = true`.
- **Optimistic update**: Ghi `AreaConfig` mới vào local model + Firestore:
  ```
  areas/{areaId} → update { name, config: { soil_moisture_threshold, max_temperature, light_on_hour, light_on_minute, light_off_hour, light_off_minute } }
  ```
- **SnackBar feedback**: Thông báo thành công (xanh lá) hoặc lỗi (đỏ) với icon.

### 7.3. Danger Zone
- **Xóa khu vực**: Nút đỏ nổi bật → dialog `DeleteAreaDialog` → xóa Firestore document → quay về trang chủ.

---

## 8. Hệ thống Cảnh báo (Alerts)

### 8.1. Realtime alerts
- **Firestore stream**: Lắng nghe `users/{uid}/alerts`, sắp xếp theo `time` giảm dần.
- **Model `Alert`**: `id`, `title`, `message`, `severity` (low/medium/high), `time`, `isRead`, `areaId`.
- **Badge trên navbar**: Hiển thị số cảnh báo chưa đọc (`unreadCount`) trên icon Bell với badge đỏ.

### 8.2. Màn hình cảnh báo (`AlertsScreen`)
- **Filter tabs**: 3 chip lọc — Tất cả / Chưa đọc / Đã đọc.
  - Chip "Chưa đọc" có badge count khi `> 0`.
  - `AnimatedContainer` cho transition mượt khi chuyển filter.
- **Alert cards** (`AlertCard`): Card hiển thị severity icon + title + message + time.
  - Tap → `markAsRead`.
- **Swipe to delete**: `Dismissible` direction `endToStart`, background đỏ với icon thùng rác.
  - SnackBar xác nhận sau xóa.
- **Xóa tất cả đã đọc**: Nút "Xóa đã đọc" chỉ hiện trên tab "Đã đọc" khi `readCount > 0`.
  - Dialog xác nhận → `batch.delete` tất cả alerts đã đọc.
- **Mark all as read**: Batch update `isRead: true` cho tất cả chưa đọc.

---

## 9. Quản lý Thiết bị Đăng nhập

### 9.1. Danh sách thiết bị (`DevicesScreen`)
- **Firestore realtime**: Stream `users/{uid}/logged_devices`, sắp xếp theo `lastActive`.
- **Device card**: Hiển thị:
  - Icon theo platform (smartphone / laptop / tablet / cpu)
  - Tên thiết bị (multiline, `maxLines: 2`)
  - Badge "Thiết bị này" cho current device
  - Trạng thái online/offline (chấm xanh/xám)
  - Platform text
  - Thời gian hoạt động cuối (X phút/giờ/ngày trước + dd/MM HH:mm chi tiết)
- **Đổi tên thiết bị**: Dialog rename → `update { name }`.
- **Đá thiết bị khác**: Nút "Đăng xuất thiết bị" (chỉ hiện cho non-current) → `delete` document → trigger remote kick-out.

### 9.2. Quét QR để xác nhận đăng nhập
- **Nút "Quét QR đăng nhập"**: Navigate sang `QrScannerScreen`.
- **Flow**: Camera scan → validate prefix `sg-` → check Firestore `qr_sessions` → approve session → auto-dismiss.
- **UI states**: Instruction → Processing (spinner) → Success (✅ animation + auto-close).

### 9.3. Pull-to-refresh
- `RefreshIndicator` gọi `_listenToDevices()` lại + delay 1s cho visual feedback.

---

## 10. Thời tiết

### 10.1. Lấy dữ liệu thời tiết
- **API**: OpenWeatherMap (`api.openweathermap.org/data/2.5`).
  - `fetchCurrentWeather`: Thời tiết hiện tại.
  - `fetchForecast`: Dự báo 5 segment tiếp theo (~15 giờ).
- **GPS location**: Dùng `Geolocator` lấy vị trí hiện tại.
  - Fallback Hà Nội (`21.0285, 105.8542`) nếu không có quyền hoặc plugin error (web).
- **Đa ngôn ngữ**: Truyền `lang=vi/en` vào API query theo locale hiện tại.

### 10.2. Hiển thị
- **Dashboard metrics**: Nhiệt độ, mô tả thời tiết, tên thành phố (format gọn, bỏ suffix "City/Thành phố/Tỉnh").
- **Weather icon mapping**: `LucideIcons.sun`/`cloud`/`cloudRain`/`cloudLightning` theo `condition`.
- **Auto-refresh**: Timer 15 phút, cũng refresh khi pull-to-refresh.
- **Trigger automation**: Sau mỗi lần fetch weather → `_evaluateAutomations()`.

---

## 11. Cài đặt Ứng dụng

### 11.1. Thông tin người dùng
- **Card thông tin**: Avatar icon + phone number (hoặc placeholder).
- **UID display**: Hiển thị Firebase UID dạng monospace + nút Copy to clipboard.
- **Area IDs display**: Liệt kê tất cả area ID kèm tên khu vực + nút copy (để dùng cho cấu hình ESP32).

### 11.2. Đa ngôn ngữ (i18n)
- **2 ngôn ngữ**: Tiếng Việt 🇻🇳 và English 🇺🇸.
- **Hệ thống dịch thủ công**: `AppLocalizations` load map string từ file `vi.dart` / `en.dart`, gọi bằng `l10n.t('key')`.
- **Locale Provider**: `LocaleProvider` + `ChangeNotifier` → rebuild toàn app khi đổi ngôn ngữ.
- **Selected indicator**: AnimatedContainer highlight + check icon cho ngôn ngữ đang active.

### 11.3. Giao diện sáng/tối (Theme)
- **3 chế độ**: Sáng / Tối / Theo hệ thống.
- **SettingsProvider**: Lưu `ThemeMode`, `MaterialApp` watch provider để apply `themeMode`.
- **Theme system hoàn chỉnh** (`AppTheme`):
  - Font: **Google Fonts Inter** cho toàn bộ TextTheme (11 style từ `headlineLarge` → `labelSmall`).
  - Light theme: Background `#F8FAF5`, surface trắng `#FFFFFF`, text `#1A1C1E`, border nhạt.
  - Dark theme: Background `#14161A`, surface `#1E2128`, text `#E8EAED`, border tối.
  - Material 3 enabled, custom `colorScheme`, `switchTheme`, `inputDecorationTheme`, `cardTheme`, `bottomNavigationBarTheme`.
- **Theme toggle indicator**: Widget `ThemeToggleIndicator` trên login screen — icon mặt trời/trăng.
- **Selected indicator**: AnimatedContainer highlight + border cho theme đang active.

### 11.4. Hướng dẫn sử dụng
- Nút "Hướng dẫn" → navigate `/onboarding` để xem lại tutorial.

### 11.5. Đăng xuất
- **Dialog xác nhận**: 2 nút — Xác nhận (đỏ) + Hủy (outlined).
- **Logout flow**: Xóa device login → xóa `master_uid` khỏi SharedPreferences → `FirebaseAuth.signOut` → reset state → redirect `/login`.

---

## 12. Firmware ESP32 IoT

### 12.1. Cấu hình WiFi (WiFiManager Portal)
- **WiFiManager captive portal**: Tên AP mặc định `SmartGarden_Setup`.
- **Custom portal UI**: CSS tùy chỉnh (dark theme, bo góc, nút xanh lá) + hướng dẫn bằng tiếng Việt.
- **2 custom fields**: Area ID (Firestore) + User UID (Firebase Auth) — nhập qua portal.
- **Lưu NVS (Non-Volatile Storage)**: `Preferences` library lưu `area_id` + `user_uid` tồn tại qua reboot.
- **Reset WiFi**: Giữ nút BOOT 5 giây → `wm.resetSettings()` + `ESP.restart()` → mở lại portal.
- **Validation**: `isConfigValid()` kiểm tra cả 2 field không rỗng trước khi chạy logic chính.

### 12.2. Đọc cảm biến
- **DHT22** (pin 4): Đọc nhiệt độ + độ ẩm không khí mỗi 30 giây.
- **Soil Moisture** (pin 34, analog): `analogRead` → `map(0-4095, 100-0)` → `constrain(0-100)`.
- **Validate**: Bỏ qua nếu `isnan(temp)` hoặc `isnan(humi)`.

### 12.3. Đẩy dữ liệu lên Cloud
- **Sensor update** (30s/lần): Tạo JSON theo chuẩn Firestore REST API (`mapValue/fields/...`):
  - Ghi mảng `sensors` (temperature, air_humidity, soil_moisture) vào `users/{uid}/areas/{areaId}`.
  - Ghi document `history` cho temperature với `timestamp` (epoch ms).
- **API**: `Firebase.Firestore.patchDocument` và `createDocument`.

### 12.4. Điều khiển Relay
- **3 relay outputs**:
  - `PUMP_PIN (25)`: Máy bơm
  - `FAN_PIN (26)`: Quạt thông gió
  - `MIST_PIN (27)`: Phun sương / Đèn
- **Logic Active HIGH**: `digitalWrite(PIN, isOn ? HIGH : LOW)`.

### 12.5. Đồng bộ 2 chiều với Cloud
- **Poll devices (5s/lần)**: `getDocument` → duyệt mảng `devices` → so sánh type (`pump/fan/light/mist`) → cập nhật relay nếu khác local state.
- **Sync nút bấm lên Cloud**: Khi nhấn nút cứng:
  1. Toggle local state
  2. Set flag `needsCloudDeviceSync`
  3. `syncRelaysToCloud()`: GetDocument → sửa `isOn` cho đúng device type → PatchDocument
  4. Reset poll timer (tránh cloud trả cache cũ)
- **Tránh conflict**: Nếu đang sync nút bấm (`needsCloudDeviceSync`), skip `pollDevices()`.

### 12.6. Nút bấm vật lý
- **4 nút** (INPUT_PULLUP):
  - `BTN_PUMP (12)`: Toggle máy bơm
  - `BTN_FAN (33)`: Toggle quạt
  - `BTN_MIST (13)`: Toggle phun sương
  - `BTN_MODE (32)`: Toggle Auto/Manual (local)
- **Debounce**: `delay(200)` chống dội nút.
- **Flow**: Đọc nút → đảo state → `applyHardwareRelay()` → `updateDisplay()` → set flag sync Cloud.

### 12.7. Màn hình TFT (ST7789 240x240)
- **Hiển thị realtime**:
  - Trạng thái kết nối: "CONNECTED" / "CONNECTING"
  - Nhiệt độ (đỏ), Độ ẩm (cyan), Độ ẩm đất (xanh lá)
  - Mode: AUTO (xanh) / MAN (hồng)
  - Trạng thái 3 relay: PUM/FAN/MIS — ON (xanh) / OFF (đỏ)
- **Màn hình setup**: Khi chưa cấu hình, hiện hướng dẫn kết nối WiFi + nhập Area ID/UID.
- **Refresh**: Cập nhật display mỗi 2 giây.

---

## 13. Kiến trúc & Kỹ thuật

### 13.1. State Management
- **Provider pattern**: `ChangeNotifier` + `ChangeNotifierProxyProvider` cho dependency injection.
  - `AuthProvider`: Firebase Auth state machine (unauthenticated → otpSent → verifying → qrWaiting → authenticated).
  - `GardenProvider`: Proxy qua AuthProvider (lấy UID) + LocaleProvider (lấy language).
  - `AlertProvider`: Proxy qua AuthProvider.
  - `DeviceProvider`: Proxy qua AuthProvider.
  - `SettingsProvider`: ThemeMode.
  - `LocaleProvider`: Locale.

### 13.2. Routing
- **GoRouter** với `ShellRoute`:
  - Bottom nav shell: Home `/`, Alerts `/alerts`, Devices `/devices`, Settings `/settings`.
  - Standalone routes: `/login`, `/otp`, `/qr-login`, `/forgot-password`, `/onboarding`.
  - Parameterized: `/area/:areaId`, `/area/:areaId/config`.
- **Auth redirect**: `refreshListenable` listen AuthProvider → auto-redirect dựa trên `AuthState`.
- **Navigation bar custom**: `_MainShell` với `_NavItem` widgets, icons Lucide, badge animation, selected state highlight.

### 13.3. Realtime Data
- **Firestore snapshots**: Areas, Alerts, Logged Devices — tất cả dùng `.snapshots()` stream.
- **Optimistic UI**: Toggle/update local state ngay → async sync Firestore → rollback nếu lỗi (implicit qua snapshot re-sync).

### 13.4. Design System
- **Color palette** (`AppColors`):
  - Primary: `#2E7D32` (Green), `#66BB6A` (Green Light)
  - Secondary: `#2196F3` (Blue)
  - Alert levels: Low (cyan), Medium (amber), High (red)
  - Surface/Background/Text riêng cho light + dark
  - Login gradient: 2 bộ gradient cho light/dark
- **Widget library tái sử dụng**:
  - `AppCard`: Card container thống nhất padding + border
  - `AppButton`: Primary button with loading state
  - `LoadingSkeleton` + `CardSkeleton`: Shimmer loading placeholders
  - `EmptyState`: Icon + text cho danh sách rỗng
  - `SensorBar`, `SensorChart`, `DeviceTile`, `AlertCard`, `AreaCard`
  - `LanguageSwitcher`, `ThemeToggleIndicator`

### 13.5. Animation
- **flutter_animate**: FadeIn, SlideY, Scale effects cho hầu hết widgets.
- **AnimatedContainer**: Transition mượt cho nav items, filter chips, language/theme options.
- **AnimatedCrossFade**: Show/hide nav labels.
- **AnimatedSwitcher**: Chuyển đổi Email ↔ Phone form.
- **Staggered delays**: Danh sách items với delay tăng dần.

### 13.6. Device Info Utility
- **`DeviceInfoUtil`**: Cross-platform device identification:
  - Android: `device_info_plus` → model + board
  - iOS: `utsname.machine`
  - Web: `userAgent`
  - Unique ID từ hash device + platform

### 13.7. Firebase Services
- **Firebase Auth**: Phone OTP, Email/Password, Anonymous (QR), Password Reset.
- **Cloud Firestore**: `users/{uid}/areas`, `users/{uid}/alerts`, `users/{uid}/logged_devices`, `allowed_phones`, `qr_sessions`.
- **Firebase Hosting**: Web app deployed.
- **Firebase ESP Client** (ESP32): Firestore REST API qua C++ SDK.

### 13.8. Multi-platform Support
- **Flutter targets**: Android, iOS, Web, Linux, macOS, Windows.
- **Custom launcher icon**: Sprout design, cấu hình qua `flutter_launcher_icons`.
- **Responsive**: Breakpoints 600px / 800px cho mobile / tablet / desktop layouts.

---

## Tóm tắt Thống kê

| Chỉ tiêu | Giá trị |
|---|---|
| Tổng số màn hình | **10** (Login, OTP, QR Login, Forgot Password, Onboarding, Home, Area Detail, Area Config, Alerts, Devices, Settings) |
| Phương thức đăng nhập | **4** (Email, Phone OTP, QR Code, Anonymous) |
| Ngôn ngữ hỗ trợ | **2** (Tiếng Việt, English) |
| Theme | **3** mode (Light, Dark, System) |
| Loại sensor | **3** (Nhiệt độ, Độ ẩm KK, Độ ẩm đất) |
| Loại thiết bị | **5** (Pump, Fan, Light, Mist, Valve) |
| Nút vật lý ESP32 | **4** (Pump, Fan, Mist, Mode) + 1 Reset |
| Providers | **6** (Auth, Garden, Alert, Device, Settings, Locale) |
| Firebase services | **4** (Auth, Firestore, Hosting, ESP Client) |
| Reusable widgets | **15+** |
| Dependencies chính | **18** packages |
