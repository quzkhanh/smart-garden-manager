# 4. PHÂN TÍCH SOURCE CODE

## 4.1 Tệp Root Khởi chạy: `main.dart` & `app.dart`
- **Vai trò**: Điểm bắt đầu (Application Entry Point) của ứng dụng Flutter toàn cục.
- **Luồng xử lý**:
  1. Yêu cầu phần cứng hệ điều hành cam kết ổn định hàm nền tảng đồ họa: `WidgetsFlutterBinding.ensureInitialized()`.
  2. Nạp cấu hình backend đám mây, khởi kết nối Backend Services: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  3. Cài đặt `MultiProvider` để khởi tạo hàng loạt thực thể State Management (`AuthProvider`, `LocaleProvider`, `SettingsProvider`), tiêm khối dữ liệu này vào Cây Render gốc của Flutter. Tiến hành khởi chạy Class cấu hình tổng thể `SmartGardenApp` (`app.dart`).
- **Dependency**: `firebase_core`, `provider`, `flutter/material.dart`.

## 4.2 Các Screen Hiển thị (VD: `area_detail_screen.dart`)
- **Vai trò**: Trình bày View chuyên dụng hiển thị Data cho người tương tác đồng thời truyền sự kiện nhấn trả ngược vào Background (View Controller).
- **Luồng xử lý**: Widget theo dõi dữ liệu thay đổi từ State Manager sinh mã `context.watch<GardenProvider>()`. Layout sử dụng LayoutBuilder động làm tỷ lệ hiển thị List vs Grid co giãn với màn thiết bị. Khi người gọi nhấn vào Device Component, Screen không gọi Firebase trực tiếp, thay vào đó truyền Data ID thiết bị điều hướng sang khối hàm tác vụ `.toggleDevice()` của khối Provider.
- **Dependency**: `go_router`, thư mục `widgets/` nội bộ.

## 4.3 Khối Data Service: thư mục `services/`
- **Vai trò**: Cầu nối duy nhất đi ra khỏi thế giới mạng ứng dụng ngoại vi (Network Outbound). Phủ nhận hoàn toàn sự xuất hiện của logic Database bên trong UI code.
- **Luồng xử lý**: Nhận yêu cầu Data Command API (Ví dụ: Id Area, id thiết bị cần bật/tắt). Nó chuyển dịch hàm cập nhật Documents thành các tham số Firebase thông qua class gốc duy nhất `FirebaseFirestore.instance`. Tại sự kiện tải trang, khi thư viện Firebase xuất Stream (sự kiện dữ liệu trực tuyến), Service thực thi vòng lặp `.map()` chuyển mảng JSON động phi kiểu thành các đối tượng Class Model cực mạnh kiểu (Strongly-typed object) để tránh lỗi Runtime.
- **Dependency**: `cloud_firestore`, `firebase_database`, `firebase_auth`.

## 4.4 Khối State Management: `garden_provider.dart`
- **Vai trò**: Cung cấp trung tâm xử lý dữ liệu phức tạp cho thiết bị (Business Controller) quản lý quy trình Timer cục bộ đếm giờ tự trị.
- **Luồng xử lý**: Kế thừa mixin `ChangeNotifier` của Flutter Foundation. Cung cấp vòng lặp Tick hẹn giờ trong nền sử dụng thủ thuật `Timer.periodic`. Trong quá trình người dùng chuyển đổi thiết bị tắt/mở theo lịch Local-side app, tiến trình đếm ngược không đẩy từng giây thời gian lên Cloud. Thay vào đó nó chạy nền nội tại. Đến mốc 0 giây cuối cùng, nó mới kích mảng yêu cầu update() đến Firebase để đóng trạm. Suốt hệ sinh thái vòng lặp nếu có cập nhật mảng biến, lệnh `notifyListeners()` phát tín hiệu báo cho UI Tree thực thi vẽ đồ họa theo nội dung cập nhật.
- **Dependency**: `provider`, `Dart::async` (Timer), Models.
