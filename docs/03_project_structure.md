# 3. CẤU TRÚC THƯ MỤC PROJECT

## 3.1 Cấu trúc mã nguồn
Toàn bộ mã nguồn cốt lõi làm nên hệ điều khiển và ứng dụng sinh thái đồ họa Flutter chuyên dụng được quy hoạch gọn gàng trong thư mục dự án `lib/`. Cách định vị tệp nhằm cô lập nhóm code theo Feature (tính năng) và Layer (lớp), thực thi chặt chẽ nguyên tắc Single Responsibility (Trách nhiệm Đơn nhất).

## 3.2 Mapping Folder → Chức năng
```text
lib/
├── main.dart             # Tập lệnh nhập cảnh (Entry point). Boot up môi trường Firebase và khai báo cấu trúc Providers toàn cục cung cấp cho ứng dụng nhánh.
├── app.dart              # Gốc Widget MaterialApp. Cung cấp tham chiếu toàn tuyến cho GoRouter (điều hướng URL), cấu hình Theme, Localizations.
├── routes/               # Quản lý đường dẫn màn hình (Navigation). Chứa `app_router.dart` - cầu nối liên kết url đến các trang gốc và module Auth Guard Router xử lý cấm truy cập nếu sai thông tin xác thực.
├── models/               # Bộ khai báo cấu trúc thực thể Object thuần OOP của khu vườn.
│   ├── area.dart         # Cấu trúc vùng trồng, id phân vùng độc lập.
│   ├── device.dart       # Cấu trúc đối tượng phần cứng, có đi kèm bộ định lượng hẹn giờ Timer tự trị.
│   └── sensor.dart       # Cấu trúc dải số thu thập đo đạc tại các mốc của cảm biến.
├── providers/            # Không gian định lưu Reactive State và Business Logic lõi.
│   ├── auth_provider.dart    # Hàm nhận mã OTP điện thoại, Quản trị vòng đời Token phiên (Login session).
│   ├── locale_provider.dart  # Giải quyết cắm ngôn ngữ tức thời.
│   └── garden_provider.dart  # Mô tơ khởi đạo của Dashboard, giải quyết Timer chạy ngầm ứng dụng (bật/tắt tự động môtơ tại client quy mô mà người dùng nhìn thấy).
├── services/             # Lớp trung gian Firebase tương tác mạng lưới. File quy chuẩn API/CRUD dành cho mảng Cloud Data kết nối. Thụ lý thao tác Read, Write, Delete tới Cloud Firestore.
├── screens/              # Hệ khối giao diện người dùng chính biệt lập độc lập (Pages).
│   ├── login/            # Chứa chu trình nhập liệu Số ĐT / Mã cấp 2 OTP / Login QR.
│   ├── home/             # Màn Home Dashboard cấu trúc Grid liệt kê mốc Area.
│   └── area_detail/      # Thông số trạng thái sâu hơn hiển thị kèm Module điều tiết công tắc khu trồng.
├── widgets/              # Thư viện component chia nhỏ hỗ trợ lắp ghép giao diện lớn lặp lại nhiều vị trí khác nhau. 
│   ├── common/           # Khung AppCard base (Bo tròn thẻ xám) và file Loading tĩnh (Loading Skeleton shimmers).
│   ├── sensor_chart.dart # File riêng để tải API của engine `fl_chart` tái lập biểu đồ trục thời gian đồ họa sinh động.
│   └── device_tile.dart  # Form hiển thị Row thao tác Toggle cho phép kích bật, kèm màn hẹn giờ số tự tắt.
├── theme/                # Cung cấp Tokens giao diện: màu chủ thể hệ thống và kiểu chữ font family. Góp giao thức chế độ ThemeDark.
├── data/                 # Data mẫu giả lập (Mock file) hỗ trợ Design Debug trước khi có Internet đổ Data Firebase.
├── utils/                # Phân rã logic phụ trợ dạng pure function phi trạng thái phục vụ định dạng chuẩn hóa Chuỗi, DateTime. 
└── l10n/                 # File tài liệu phân bổ nguồn map bộ dịch chuỗi thông báo đa dạng tự định nghĩa cho hai cấu hình Tiếng Anh (en) / Tiếng Việt (vi).
```
