# 7. HƯỚNG DẪN CÀI ĐẶT VÀ TRIỂN KHAI

## 7.1 Chuẩn bị môi trường (Prerequisites)
Để khởi build ứng dụng trên nhánh lập trình local, Developer bắt buộc bổ sung các bộ Platform/Service tương ứng:
- Base Framework: Tải bản phân phối **Flutter SDK** từ Official Site (Phiên Bản >= 3.11). Kiểm tra cài đặt và cấp biến Environment PATH hệ điều hành. Chạy `$ flutter doctor`.
- Base Engine Language: Công cụ phát hành **Dart SDK**.
- Cổng tích hợp Code Hardware IDE: VSCode PlatformIO hoặc trình Arduino bản mới C++ Extension chuẩn để build file nhúng IoT.
- Môi trường phần mềm xuất bản tuỳ chỉnh (Phát triển ứng dụng Mobile Client OS gốc): Cài đặt Android Studio chuẩn bị Emulator Simulator kèm Android SDK Tools cho quy trình build ra `.apk`, hoặc cung cấp cấu hình hệ sinh thái hệ điều hành macOS thiết lập nền Xcode 14+ để đóng gói `.ipa` cho iDevices iOS.
- **Firebase Platform**: Đã thiết lập cấp kết nối Google Firebase Project trên console. Đã gen file phân phối dịch vụ `google-services.json` dán vào nhánh gốc Android App config. 

## 7.2 Tiến trình chạy bộ dự án thử nghiệm (Dev Build)
Nằm trong vị trí Terminal thư mục Root của bộ source App.
1. **Init Plugins**: Gọi thực thi `$ flutter pub get`. Trình quản lý Packet tải toàn bộ các kho thư viện đồ họa và module tích hợp khai báo trước tại danh sách yêu cầu `pubspec.yaml` (bao gồm `provider, firestore, ui-kits`..v..).
2. **Kích hoạt IoT Firmware (Optional)**: Tại tệp mã nguồn C++ `iot/esp32_garden/esp32_garden.ino`: Điều chỉnh biến Global Network `<WIFI_SSID>` và tham số bảo mật `<WIFI_PASSWORD>` tích hợp Private Key Auth kết xuất từ Firebase Admin SDK, Build file Flash và lưu xuất qua cổng dây thiết lập COM qua cổng nạp vi mạch.
3. **Debug Stream Realtime Simulation** (Build Môi trường giao diện Sandbox Live Reload):
   - Môi trường Sandbox cấp qua Web Chrome: `$ flutter run -d chrome`.
   - Kết nối trình chiếu App trên máy ảo OS ảo Android Native Emulator: `$ flutter run -d android`.

## 7.3 Hoàn thiện quy trình Deploy (Production Build Release)
Sau bước kiểm thử Dev, thực thi thuật toán phân loại và nén cấu trúc ảnh tài nguyên tĩnh, đóng gói thành Binary Base Output phát hành:
- Build cho nền tảng App Android Cực nhẹ (Lưu trữ và phân phối ngoài PlayStore):
  `$ flutter build apk --release`
- Output Android App Release File (`.apk`) được sinh trả về tại đường dẫn cố định cục bộ Local Machine `build/app/outputs/flutter-apk/app-release.apk`. Có thể cung cấp gửi cho người dùng thiết bị đầu cuối.

## 7.4 Triển khai tự động nền tảng mạng (Web App Cloud Deployment)
Cho những mảng thiết bị màn lớn quản trị mà không yêu cầu App Cài Máy, phát hành giải pháp Single Page App trên giao diện chuẩn Web Hosting:
- Cài đặt Base CLI Google Service: `$ npm install -g firebase-tools`
- Uỷ quyền lệnh CLI lên tài khoản Account Dev: `$ firebase login`
- Ra bộ Script phân kênh toàn ứng dụng Dart Code thành tĩnh cấp thấp HTML/Javascript (Obfuscated Code): `$ flutter build web --release`
- Lấy kết quả build từ Node gốc truyền tải tự động Cloud Caching Hosting: `$ firebase deploy --only hosting` 
Tệp được gửi đi. Đám mây Hosting Firebase cung cấp tự sinh ra Global Domain URL chứa chuẩn Public SSL (`https`) hoạt động đầy đủ mô hình kết nối Web.
