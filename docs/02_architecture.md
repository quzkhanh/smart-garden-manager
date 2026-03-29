# 2. KIẾN TRÚC HỆ THỐNG

## 2.1 Kiến trúc tổng thể hệ thống
Hệ thống Smart Garden tuân thủ mô hình Client-Server kết hợp cơ chế giao tiếp sự kiện Pub/Sub (Publish/Subscribe) thông qua nền tảng Firebase đám mây. Kiến trúc phân hóa thành 3 node trung tâm:

- **IoT Node (Trạm cảm biến & điều khiển ESP32)**:
  - Publisher: Theo định kỳ (chu kỳ hẹn giờ), đẩy luồng dữ liệu môi trường đã thu thập cấu trúc JSON lên nền tảng đám mây.
  - Subscriber: Thiết lập kênh kết nối dài hạn lắng nghe trạng thái của các tài liệu cấu hình thiết bị từ Cloud nhằm kích pin rơ-le phần cứng (Relay).
- **Cloud Backend (Firebase Ecosystem)**:
  - Đóng vai trò máy chủ dữ liệu kiêm Message Broker duy trì kết nối WebSocket thời gian thực chặn độ trễ cho cơ sở dữ liệu và Client.
  - Xác minh truy cập định danh người dùng qua phương thức Firebase Authentication API (Ví dụ định danh OTP SMS, QR Session).
  - Bảo đảm lớp an ninh cho các truy vấn đọc/ghi thông qua cơ chế Rules Validation (Firebase Security Rules).
- **Client App (Ứng dụng người dùng Flutter)**:
  - Ứng dụng điều khiển từ xa, tự động cập nhật lại các bộ phận cấu thành cửa sổ UI (Rebuild Widget Tree) ngay lập tức khi xuất hiện tín hiệu dòng chảy trạng thái (Stream data) từ phía Cloud.

## 2.2 Phân tích Layer (Kiến trúc phần mềm Client)
Ứng dụng phía Client được thiết kế trên mô hình khối MVVM (Model-View-ViewModel) nhờ quản lý dựa trên State Management. Các khối logic phân chia độc lập với tỷ lệ kết dính thấp, chia theo 3 lớp căn bản:

- **Lớp Data (Model & Services Layer)**:
  - Chịu trách nhiệm khởi tạo các kết nối phi đồng bộ (Asynchronous HTTP/WebSocket) trực tiếp với Firebase SDK. 
  - Nhiệm vụ chuyển đổi (Parser): Ép kiểu dữ liệu tự do (JSON/Map) nhận về không nguyên dạng từ API API thành cấu trúc Data Transfer Object (DTO) hoặc các đối tượng Class Dart cục bộ (Xử lý hàm `.fromMap()`, `.toMap()`). Lớp không giao tiếp hay tham gia mã giao diện.

- **Lớp Business Logic (ViewModel / State Management Layer)**:
  - Khởi tạo công nghệ `Provider` (Bản chất là kế thừa InheritedWidget của Flutter Framework).
  - Các lớp Provider đóng vai trò ViewModel. Giữ các trạng thái phân mảnh, xử lý các Business Logic và toán tử phức tạp (Ví dụ: đếm ngược Timer ở ứng dụng trước khi lệnh được cập nhật qua mạng, đánh giá điểm ngắt Threshold/Alert của cảm biến). Đóng vai là trung chuyển kiểm duyệt tương tác từ luồng nhìn để đẩy lệnh và cấp Stream trả về xuống UI.

- **Lớp Giao Diện (Presentation / UI Layer)**:
  - Cấu thành bởi vô số Widget/Screens lồng ghép tổ hợp. 
  - Giao diện người dùng có tính chất thụ động, giao diện sẽ phản ứng tự động theo chuỗi báo hiệu `notifyListeners()` từ mô tơ Business Logic. 

## 2.3 Giao tiếp giữa các thành phần
Các thành phần giao tiếp theo luồng thông tin một chiều trong vòng tuần hoàn (Unidirectional Data Flow):
`Luồng UI User (View Component)` kích hoạt tương tác chạm -> Bức điện được gọi ngầm về hàm chức năng trên thẻ `Business Logic/State` -> State tính toán và gọi hàm trừu tượng đưa tham số xuống thẻ `Lớp Data` -> Gửi Network Request qua giao thức tới API (Cloud) -> Backend ghi nhận Update và xuất Streams trả ngược lại -> Data bắn cờ thay đổi lên Lớp State -> State phát cờ cập nhật toàn không gian (`notifyListeners`) -> Cuối cùng UI Rebuild vẽ lại widget biểu diễn trạng thái đồ họa mới nhất.
