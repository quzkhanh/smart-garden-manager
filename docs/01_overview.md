# 1. TỔNG QUAN HỆ THỐNG (OVERVIEW)

## 1.1 Giới thiệu hệ thống
Dự án Smart Garden là hệ thống quản lý vườn thông minh đa nền tảng, thiết kế chuyên biệt để tự động hóa quy trình chăm sóc cây trồng, giám sát các thông số môi trường ở thời gian thực và cung cấp khả năng điều khiển thiết bị thiết yếu (bơm, quạt, chiếu sáng) từ xa thông qua ứng dụng di động.

## 1.2 Mục tiêu ứng dụng
- Tối ưu hóa số lượng nhân công trong việc chăm sóc vườn quy mô nhỏ và vừa.
- Cung cấp giao diện trực quan, rõ ràng, giúp người dùng theo dõi chính xác biến động của vườn (Độ ẩm, nhiệt độ).
- Chuyển đổi linh hoạt giữa việc chăm sóc truyền thống (Thủ công - bật/tắt do tương tác qua mạng) sang tự động hóa (Hẹn giờ hoặc kích hoạt máy bơm dựa trên độ ẩm khô).

## 1.3 Phạm vi
- **Nền tảng hỗ trợ**: Ứng dụng xây dựng Cross-platform, hoạt động mượt mà trên Android, iOS và Web Browser.
- **Khả năng quan trắc**: Nhiệt độ không khí (°C), Độ ẩm không khí (%), Độ ẩm đất (%).
- **Thiết bị khả dụng điều khiển**: Máy bơm nước (Water Pump), Phun sương (Mist), Quạt thông gió (Fan), Đèn chiếu sáng (Light).
- **Phân mảnh IoT**: Hệ thống mạch nhúng vi điều khiển ESP32 xử lý vi phân logic tại trạm phần cứng và giao tiếp mạng truyền dẫn.

## 1.4 Công nghệ sử dụng
- **Phần cứng (IoT)**: Vi điều khiển WiFi ESP32, Relay 5V/12V, Cảm biến ánh sáng/nhiệt độ/độ ẩm. Ngôn ngữ C/C++.
- **Phần mềm Front-end**: Dart language, Flutter Framework phân giải mã UI (Phiên bản >= 3.11).
- **Hạ tầng Đám mây (Backend/Cloud)**: Firebase Platform (Bao gồm Cloud Firestore / Realtime DB, Firebase Authentication).
