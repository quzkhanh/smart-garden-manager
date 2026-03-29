# SMART GARDEN - TÀI LIỆU ĐỒ ÁN TỐT NGHIỆP

## 1. GIỚI THIỆU

### 1.1 Mục tiêu
Dự án Smart Garden là hệ thống quản lý vườn thông minh phát triển trên điện thoại di động và phần cứng IoT, nhằm tự động hóa quy trình chăm sóc cây trồng, giám sát các thông số môi trường ở thời gian thực và cung cấp khả năng điều khiển thiết bị từ xa qua ứng dụng.

### 1.2 Phạm vi
- **Nền tảng hỗ trợ**: Android, iOS, Web (thông qua Flutter).
- **Khả năng giám sát**: Nhiệt độ, Độ ẩm không khí, Độ ẩm đất.
- **Điều khiển thiết bị**: Máy bơm nước, Phun sương, Quạt thông gió, Đèn chiếu sáng.
- **Chế độ hoạt động**: Tự động và Thủ công.

## 2. TỔNG QUAN HỆ THỐNG

Hệ thống Smart Garden bao gồm ba thành phần chính phối hợp hoạt động:

1. **Phần cứng IoT**: Bao gồm vi điều khiển ESP32, các cảm biến thu thập tín hiệu ngoại vi và các rơ-le (Relay) đóng mạch điện cho các thiết bị chấp hành.
2. **Ứng dụng di động (Client)**: Ứng dụng phát triển trên bộ mã nguồn Flutter cung cấp giao diện hiển thị thống kê, biểu đồ biến thiên thời gian thực và tương tác điều khiển các trạm IoT.
3. **Hạ tầng Đám mây (Backend)**: Nền tảng Firebase cung cấp cơ chế lưu trữ NoSQL (Firestore/Realtime Database), đồng bộ dữ liệu thời gian thực và quản lý xác thực người dùng (Phone AuthOTP / QR Code).

## 3. KIẾN TRÚC HỆ THỐNG

### 3.1 Kiến trúc tổng thể (System Architecture)
Hệ thống Smart Garden tuân thủ mô hình Client-Server kết hợp cơ chế Pub/Sub (Publish/Subscribe) thông qua nền tảng Firebase. Toàn bộ kiến trúc được chia làm 3 node lõi:

- **IoT Node (Trạm cảm biến & điều khiển ESP32)**:
  - Đóng vai trò là publisher đẩy dữ liệu môi trường (Nhiệt độ, Độ ẩm) lên nền tảng đám mây.
  - Đóng vai trò subscriber lắng nghe trạng thái của các thiết bị chấp hành (Bơm nước, Quạt, Đèn) được điều khiển từ Cloud để trực tiếp đóng cắt rơ-le phần cứng.
- **Cloud Backend (Firebase Ecosystem)**:
  - Đóng vai trò trung gian duy trì kết nối WebSocket thời gian thực.
  - Quản lý định danh người dùng và xác thực qua Firebase Authentication.
  - Đảm bảo an ninh truy cập dữ liệu thông qua cơ chế Firebase Security Rules.
- **Client App (Ứng dụng người dùng)**:
  - Ứng dụng theo dõi và kiểm soát, tự động cập nhật UI (Rebuild) khi có tín hiệu thay đổi trạng thái từ Firebase Stream.

### 3.2 Kiến trúc thiết kế ứng dụng (App Architecture)
Ứng dụng phía Client được xây dựng trên ngôn ngữ Dart và framework Flutter, theo biến thể của mô hình MVVM kết hợp giải pháp State Management:

- **Lớp Data/Services (Model Layer)**:
  - `services/`: Xử lý trực tiếp các logic giao tiếp với Firebase SDK. 
  - Nhiệm vụ Parser: chuyển đổi dữ liệu thô (JSON/Map) từ Firebase thành Data Transfer Object (DTO) hoặc các đối tượng Class thông qua các hàm mapper (`fromMap()` / `toMap()`).
- **Lớp State Management (ViewModel Layer)**:
  - Giải pháp `Provider` (hoạt động dựa trên `InheritedWidget` của Flutter) kết hợp `ChangeNotifier` để quản lý trạng thái phân mảnh.
  - Trung tâm logic là `GardenProvider` và `AuthProvider`. `GardenProvider` còn phụ trách việc khởi chạy luồng Timer cục bộ `Timer.periodic`, đóng vai trò là đồng hồ đếm ngược tự động khóa chu kỳ sự kiện (đặc biệt khi điều khiển các thiết bị hẹn giờ ngắt cục bộ trên Application).
- **Lớp Presentation (View Layer)**:
  - Giao diện người dùng được module hóa mạnh trong `screens/` và `widgets/`.
  - Toàn bộ View hoàn toàn độc lập với luồng kết nối Data, nó chỉ tiêu thụ dữ liệu sinh ra bởi `Provider` dưới cơ chế Reactive, đảm bảo thiết kế Responsive trên các form factor khác nhau (điện thoại, máy tính bảng, màn hình Web).

### 3.3 Chi tiết luồng Dữ liệu (Dòng chảy Data Flow)

Chu kỳ chuyển dịch dữ liệu (Event-driven Flow) diễn ra đồng bộ nhưng gián tiếp qua trung tâm Firebase:
1. **User Action**: Người dùng thao tác kích hoạt giao diện (Ví dụ: Nhấn bật công tắc máy bơm rơ-le).
2. **State & Optimistic UI Update**: App tương tác vào hàm điều phối nội bộ của `GardenProvider`. Trong khối mã của provider, trạng thái được cập nhật ảo (để View cập nhật biểu tượng tức thời tạo độ trễ bằng 0). Ở dưới nền, `GardenProvider` gọi đến `FirebaseService` để truyền bản tin `update()` cập nhật Firestore Document.
3. **Broadcasting (Pub/Sub)**: Máy chủ Firestore nhận lệnh, lập tức cập nhật tài liệu Field liên quan. Đồng thời gửi gói Notification qua WebSocket đi tới tất cả các thiết bị Client đang subscribe tài liệu này (bao gồm cả các user song song và phần cứng ESP32).
4. **IoT Execution**: Mạch ESP32 nhận biến cố thay đổi của Document tương ứng, kiểm tra cờ (Flag) và xuất logic kích hoạt chân tín hiệu (Pin) điều tiết nhịp rơ-le bơm nước thực.

## 4. CẤU TRÚC SOURCE CODE

Toàn bộ ứng dụng Flutter tập trung bên trong không gian làm việc `lib/` với cách định danh tổ chức Module theo Feature (tính năng) và Layer, tuân thủ nguyên tắc Single Responsibility:

```text
lib/
├── main.dart             # Điểm khởi động gốc. Lệnh thiết lập môi trường (FirebaseOptions) và tiêm danh sách Providers vào Application Runtime.
├── app.dart              # Nơi chứa config MaterialApp.router, quản lý Theme hệ thống và khởi tạo Localizations chuẩn của App.
├── routes/               # Chứa `app_router.dart`, phụ trách bản đồ GoRouter với luồng định hướng và Auth Guard Router (Bảo mật điều hướng).
├── models/               # Khai báo cấu trúc các thực thể dữ liệu Object (Dữ liệu tĩnh thuần).
│   ├── area.dart         # Model định nghĩa thông tin khu vực giám sát vườn.
│   ├── device.dart       # Model định nghĩa cấu trúc thiết bị và thuộc tính hẹn giờ tương hỗ.
│   └── sensor.dart       # Model định mức cảm biến, giá trị tức thời và các ràng buộc Max/Min.
├── providers/            # Các kho chứa Business Logic và Reactive State chủ lực của ứng dụng.
│   ├── auth_provider.dart    # Hàm xử lý đăng nhập Authentication, lưu giữ Token phiên.
│   ├── garden_provider.dart  # Trọng tâm giám sát thiết bị, quản lý cơ chế Countdown Timer Client-side độc lập.
│   └── locale_provider.dart  # Nơi chứa thông số quản trị đa ngôn ngữ (Chuyển đổi nóng).
├── services/             # Lớp đóng gói hàm truy vấn, giao tiếp với Firebase Auth, Realtime/Firestore (CRUD).
├── screens/              # Không gian chứa các Page/Screen gốc dành cho hiển thị.
│   ├── login/            # Màn hình cho người dùng điền số điện thoại hoặc cấp mã OTP.
│   ├── home/             # Bảng điều khiển Dashboard trung tâm kết nối danh sách Area.
│   └── area_detail/      # Giao diện thông số trực quan biểu đồ, cùng bộ nút nhấn điều khiển rơ-le cục bộ vùng.
├── widgets/              # Thư viện UI Component được tách biệt dễ dàng tái sử dụng nhiều nơi.
│   ├── common/           # Skeleton loading tĩnh, bộ thẻ chuẩn chung AppCard.
│   ├── sensor_chart.dart # Mô đun vẽ đồ thị dữ liệu sử dụng bộ engine fl_chart.
│   └── device_tile.dart  # Thành tố Widget ListView dành riêng cho nút điều khiển tự động.
├── data/                 # Thư viện Data Mock giả lập để phát triển và kiểm thử App trước khi đẩy Production với Firebase.
├── theme/                # Quy định phong cách thiết kế, phông chữ (GoogleFonts), Token màu sắc và chế độ ban đêm (Dark Mode).
├── utils/                # Các hàm tĩnh tiện ích format giờ giấc, chuẩn hóa ký tự string.
└── l10n/                 # File quản trị thư viện bộ dịch văn bản Tiếng Anh (en) / Tiếng Việt (vi).
```

## 5. PHÂN TÍCH CHI TIẾT

### 5.1 Xác Thực Hệ Thống (Auth)
- Hệ thống sử dụng Xác thực tĩnh và linh hoạt qua Firebase kết hợp hình thức: Số điện thoại (SMS OTP) và mã đăng nhập linh động QR Code.
- Cơ chế bảo vệ App (Auth Guard Router) tự động điều chuyển về trang Đăng nhập nếu nhận thấy phiên kết nối mất quyền.

### 5.2 Xử lý dữ liệu thời gian thực
- Cho phép chuyển đổi linh hoạt chế độ điều khiển khu vực (Manual / Auto). Tại Dashboard, ứng dụng thiết lập vòng lặp `Timer.periodic` mỗi 1 giây để xử lý bộ đếm ngược hẹn giờ (Countdown) của thiết bị trên ứng dụng.
- Dữ liệu thu hồi từ thiết bị phần cứng được đẩy liên tục vào App, thể hiện qua progress bar trực quan theo mức cảnh báo.

### 5.3 Biểu đồ trực quan
- Ứng dụng tích hợp thư viện `fl_chart`, trình diễn thông tin cảm biến nhiệt độ, ẩm độ dưới dạng biểu đồ đường liên tục chu kỳ 24 giờ qua dữ liệu lưu từ biến đổi Data.

## 6. LUỒNG HOẠT ĐỘNG

1. **Khởi tạo và Kết nối**: Trạm IoT được cấp nguồn, khởi tạo liên kết WiFi và Firebase Database, đo đạc môi trường và đẩy lên Server.
2. **Kịch bản UI (Frontend)**: Người dùng thực hiện quá trình truy vấn Đăng nhập hợp lệ, ứng dụng lấy danh mục dữ liệu cập nhật vẽ Dashboard.
3. **Thao tác Điều khiển**: Khi bấm công tắc (Toggle) bật Relay khu vực, State cập nhật xuống Firebase.
4. **Phản hồi hệ thống**: Sensor Node ESP32 lắng nghe thay đổi Data phía đám mây và thi hành nhịp Relay tương ứng.

## 7. DATABASE

Dự án thiết kế cấu trúc lưu trữ đám mây NoSQL phân theo Collections chuyên biệt:

- **Users**: Lưu trữ UID người dùng hợp lệ tham gia hệ thống.
- **Areas**: Thiết lập vùng vườn, thiết lập ngưỡng an toàn của cảm biến đo lường.
- **Devices**: Tình trạng Bật/Tắt định danh chi tiết thiết bị thuộc khu vực, trạng thái hẹn giờ.
- **Sensors**: Hồ sơ dữ liệu thu thập (Log Data), ghi nhận biểu đồ.
- **Alerts**: Các luồng báo cáo nhắc nhở nếu trạm ngoại vi bắt gặp sự cố hay môi trường suy giảm.

## 8. HƯỚNG DẪN SỬ DỤNG

1. Cấp nguồn điện 5V/12V (tuỳ chọn) cho hệ ESP32/Relay theo đúng tài liệu mạch.
2. Cài đặt App di động hoặc truy cập link Web Firebase Hosting.
3. Đăng nhập hệ thống qua chuẩn SMS OTP hoặc mã định danh QR trên điện thoại tham chiếu.
4. Điều hướng Tab Home để giám sát. Ấn vào phần thẻ "Chi tiết diện tích" để bắt đầu thủ công Mở thiết bị hoặc hẹn giờ kết thúc Bơm nước.
5. Kiểm tra thông tin "Cảnh báo" cũng như tinh chỉnh Setting Ngôn Ngữ, Giao diện tối sáng theo sở thích.

## 9. TRIỂN KHAI

### 9.1 Hệ thống phần cứng IoT
- Khởi động Arduino IDE hoặc VSCode PlatformIO, truyền biến môi trường Firebase trong file `iot/esp32_garden/esp32_garden.ino`. Tiến hành kết nối cổng rẽ Serial Port để Build và Flash.

### 9.2 Hệ thống ứng dụng
- Tại Terminal cài đặt các thư viện `flutter pub get`.
- Chạy hệ đa nền tảng Debug `flutter run -d chrome/linux`.
- Phát hành Ứng Dụng: Cấu trúc Build Mobile `flutter build apk` cho Android. Triển khai bản Client cho Web `firebase deploy --only hosting` khi cần thiết.

## 10. MỞ RỘNG

- Thuần thục tiến trình **Firebase Cloud Functions**: dời bộ dịch hẹn giờ lên hệ thống tự động phi máy chủ, giảm gánh nặng lưu trữ Local tại Client.
- Nâng cấp Push Notifications qua Cloud Messaging tự động nhắc nhở người dùng vườn cần chăm sóc thay vì phải mở Dashboard.
- Cấu trúc mở rộng phân quyền User/Admin chi tiết nhiều mức hơn nếu áp dụng thương mại hóa cho các Nông Trại diện tích lớn.
