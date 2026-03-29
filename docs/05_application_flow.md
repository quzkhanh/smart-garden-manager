# 5. LUỒNG HOẠT ĐỘNG ỨNG DỤNG (APPLICATION FLOW)

## 5.1 Luồng người dùng (User Flow)
1. **Mở App & Kiểm tra Auth**: Tiến trình khởi chạy. Tuyến đường `app_router.dart` phân nhóm trang tiếp cận. Giao thức bảo mật (Auth Guard) kiểm tra phiên Database nội bộ: nếu Session Token trống hoặc vô hiệu lực $\rightarrow$ Redirect luồng qua trang đăng nhập gốc `/login`. Xác nhận mã số User theo dạng Phone Number / OTP Code thành công  $\rightarrow$ Redirect quay về phiên hoạt động Dashboard chính `/home`.
2. **Theo dõi Dashboard**: `Home Screen` được load qua Layout tương thích tỷ lệ màn hình (Responsive Grid). Hệ thống truy vấn API đợt 1 để thu lại danh sách các lô trồng vườn có quyền truy cập, các thông số nhiệt quan trọng, thẻ đỏ nhắc nhở cảnh báo hệ thống (Alerts).
3. **Kích hoạt Chi tiết khu vực**: Từ List thẻ, User chạm Card một khu vực  $\rightarrow$ Module mở route `/area_detail`. Trên không gian này hiển thị trải nghiệm giám sát chiều dọc: Vùng thiết lập biểu đồ theo luồng dữ liệu 24H để xem (Read), kết hợp phân vùng phía dưới hiển thị hàng công tắc thiết bị (Pump, led mạch) thu nhận thao tác điều khiển (Write action).
4. **Tham số hệ thống / Đăng Xuất**: User vào Tab Cài đặt (Settings) đổi Mode UI Sáng/Tối hoặc xóa Token ra lệnh đăng xuất tài khoản an toàn với Confirmation Box.

## 5.2 Luồng dữ liệu: Thao tác điều khiển (Command Data Flow)
- Hành động: Người dùng chạm nút Toggle bật môtơ nước trực tiếp (Không dùng chế độ Auto).
- View Event Cục Bộ (`device_tile.dart` Widget) truyền tín hiệu sự kiện hành vi `onTap` ngược xuống Model Controller bên trong `GardenProvider`.
- Áp dụng kỹ thuật Optimistic Base Update: Biến state lưu trữ tại App bị đánh dấu thay đổi cờ thành "Đang bật môtơ" mà không đợi Data từ Cloud. Lệnh này kích hoạt Rebuild View ngay tức thì với Animation 0 độ trễ khiến nút trượt Switch chuyển màu sang On trải nghiệm mượt mà siêu tốc.
- Luồng Background Network song song khởi chạy: `GardenProvider` ủy nhiệm gửi hàm `async DeviceUpdate()` với Field Boolean tương ứng đến SDK Firebase tại file (`services/`).
- Document của Device tại mốc Firestore thay đổi tính chất, kích nốt một luồng Broadcast Stream trên Internet đi tới thiết bị đích (ESP32 IoT Subscriber). Trạm Viễn thông nhúng ESP32 tiếp nhận khối Payload này và áp mức điện áp Cao (High) vào các chân số điều khiển pin Rơ-le số 1. Quá trình mạng thực tiễn trễ tầm ~600 - 1500 ms. 

## 5.3 Luồng dữ liệu: Thu dữ liệu quan trắc (Telemetry Flow)
- Trạm thụ cảm nhiệt độ IoT (Node ESP32) thực hiện phân giải Analog thu thập điện tính thay đổi của biến trở Độ ẩm đất của Soil sensor tại vườn ngoài thực địa.
- Lập trình vi điều khiển định kỳ ở mỗi chu kỳ Sleep Cycle, mạch thực khởi báo JSON Payload nén đẩy qua thư viện viễn thông Wifi thẳng Endpoint CSDL Firebase Cloud.
- Node Database Engine nhận Packet, xác minh token và cho biến đổi Data Field ngay trên Firestore lưu lại lịch sử Time-series. 
- Ngay lập tức nền tảng Backend này ném đi một Callback `onSnapshot()` ngược về Stream mạng TCP WebSocket của ứng dụng di động đang lắng nghe. Event kích thay đổi View của Component cảm biến nhiệt lượng (Sensor ProgressBar) để cho thanh Bar thụt vào theo % biến hoặc biểu đồ cuộn ra một Pixel điểm mới lập nên đồ thị thời gian thực theo thời gian.
