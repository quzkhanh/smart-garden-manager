# 6. CẤU TRÚC DATABASE (FIREBASE CLOUD)

## 6.1 Tổng quan kiến trúc
Toàn bộ lõi lưu trữ mạng sử dụng nền tảng Không cấu trúc NoSQL trực tiếp từ nhà cung cấp Dịch vụ Firebase Cloud Store (Firestore hoặc Realtime Database tuỳ thuộc mode cài đặt nền backend). Tính chất phi nối chéo (Schema-less) đòi hỏi dữ liệu được đóng gói quản trị dưới dạng Collections độc lập cùng vô số các Documents JSON lồng con cấp phân tầng (Subcollection Data Models).

## 6.2 Các thành phần thực thể Collection / Document chính

### Collection: `users`
- **Ý nghĩa & Vai trò**: Nơi lưu giữ chứng thực tài khoản phân quyền Firebase Auth.
- **Cấu trúc Document ID**: UID cá biệt khởi sinh tự động từ môi trường SDK.
- **Fields**: 
  - `phone_number`: (String) Chuỗi số điện thoại được định dạng mã E164 dùng định danh.
  - `role`: (String) Enum văn bản thể hiện đặc quyền bảo mật ('admin', 'member').
  - `created_at`: (Timestamp/Int) Máy chủ đánh dấu thời điểm tạo ban đầu.

### Collection: `areas`
- **Ý nghĩa & Vai trò**: Đại diện thiết lập cụm vườn riêng rẽ hay nhà kính trong trang trại hệ thống (Vườn 1 mốc Lan, Vườn 2 cà chua).
- **Cấu trúc Document ID**: ID do máy sinh.
- **Fields**:
  - `name`: (String) Tên hiển thị cụm vườn trên view Dashboard ứng dụng người dùng.
  - `mode`: (String) Khóa Enum chọn luồng hệ thống hoạt động hoàn toàn ('auto' hoặc 'manual'). Vùng cài auto sẽ nhận quy trình tưới độc lập mà app ko can thiệp ghi đè ở mốc time tưới tự động.

### Collection: `devices`
- **Ý nghĩa & Vai trò**: Thành phần kiểm soát định tuyến vật lý các máy công tác phần cứng tại luống/dải tưới.
- **Cấu trúc Document ID**: ID thiết bị phân phối từ MAC trạm.
- **Fields**:
  - `area_id`: (Reference String Key) ID Cụm vườn đang sở hữu công cụ thiết bị này.
  - `type`: (String) Phân tầng hệ thống thiết bị ('pump' - Bơm, 'light' - Bóng LED, 'fan' - Quạt gió).
  - `status`: (Boolean) Đặc trưng Trạng thái Toggle. (`true` = Đang Chạy Môtơ / `false` = Rơle cắt điện).
  - `timer_duration`: (Integer) Thuộc tính bổ sung quản lý phút đếm ngược (Countdown) cho mốc tự tắt.

### Collection: `sensors`
- **Ý nghĩa & Vai trò**: Nhật ký sổ bộ Sensor (Log data Time-Series). Cập nhật ghi đè luân hồi các mốc để App đọc biến lượng môi trường vẽ biểu diễn UI. Điểm tham chiếu của các sự cố Alert nếu tràn ngưỡng.
- **Cấu trúc Document ID**: ID Máy Cảm biến + Timestamp gốc.
- **Fields**:
  - `area_id`: Tham chiếu ngược về lô vườn gốc tại bảng Areas.
  - `temperature`: (Double) Tính chất chỉ định độ C lúc gửi yêu cầu.
  - `humidity`: (Double) Tính chất chỉ định độ ẩm không khí tỷ lệ phần trăm %.
  - `soil_moisture`: (Double) Phản hồi độ dẫn điện qua môi trường đất (Ẩm độ tưới) quy ra gốc phần trăm 0 tới 100%.

## 6.3 Mapping Quan hệ chia rẻ dữ liệu (Data Relationship Management)
- Do là mô hình NoSQL với yêu cầu truy xuất siêu tốc Stream API, không được sử dụng lệnh lồng kết chéo phức tạp làm chậm ứng dụng (SQL JOIN Table hạn chế).
- Kỹ thuật thay thế: Sử dụng giải pháp cấp References Model (Tham số truyền String Key `area_id`). Mỗi khi một Card "Cụm vườn" tại `areas` click yêu cầu truy vấn, app tự truy vấn các `devices` và `sensors` sử dụng mã lệnh so sánh Where: Field tham chiếu Area == ID cụm tương ứng. Điều này cấp Index một chiều rất nhanh cho Firestore để Load luồng phân bổ (Tải toàn bộ máy công tác và giá trị nhiệt độ của riêng 1 khu vườn đích phân cực duy nhất).
