# Ứng Dụng Quản Lý Tài Liệu Học Tập (Cashew Docs)
> **Dự án mẫu thực hiện theo Kiến trúc & Tư duy Thiết kế mã nguồn mở Cashew**  
> Tham khảo mã nguồn mở Cashew: [https://github.com/jameskokoska/Cashew](https://github.com/jameskokoska/Cashew)

---

## 1. Giới thiệu tổng quan
Ứng dụng **Quản lý Tài liệu Học tập** được xây dựng bằng **Flutter**, kế thừa và mô phỏng lại mô hình kiến trúc chuẩn mực của ứng dụng mã nguồn mở **Cashew**:
- **Local-First & Offline-First**: Toàn bộ dữ liệu tài liệu, bài giảng, bài tập, môn học được lưu trữ cục bộ bằng **Drift (SQLite)** trên thiết bị, mang lại tốc độ tức thì và bảo mật tuyệt đối.
- **Reactive Data Flow (Phản ứng theo luồng)**: Dữ liệu giao diện luôn đồng bộ tự động với database thông qua cơ chế `Stream` của Drift (tương tự `watchAll()`), loại bỏ hoàn toàn việc gọi `setState` hay reload thủ công.
- **Separation of Concerns (SoC)**: Phân tách rõ ràng giữa Schema Tables, DAOs (Data Access Objects), Data Transfer Objects (DTOs), State Providers và UI Views/Widgets.
- **Multi-Criteria Filter & Search**: Bộ lọc đa tiêu chí linh hoạt (tìm kiếm từ khóa, lọc theo môn học, loại tài liệu, thẻ tag, trạng thái yêu thích và sắp xếp).

---

## 2. Cấu trúc thư mục theo chuẩn Cashew

```
lib/
├── database/                # Tầng cơ sở dữ liệu cục bộ (Drift / SQLite)
│   ├── connection/          # Thiết lập kết nối native SQLite
│   │   └── native.dart
│   ├── daos/                # Data Access Objects (Tách biệt truy vấn nghiệp vụ)
│   │   ├── document_dao.dart
│   │   ├── document_dao.g.dart
│   │   ├── subject_dao.dart
│   │   └── subject_dao.g.dart
│   ├── tables.dart          # Định nghĩa cấu trúc các bảng (Subjects, Documents)
│   ├── database.dart        # Lớp AppDatabase trung tâm, Migrations & Initial Seed Data
│   └── database.g.dart      # Mã nguồn sinh tự động bởi Drift
├── models/                  # Domain Models, Enums & DTOs
│   ├── document_type.dart   # Enum phân loại: Bài giảng, Bài tập, Tham khảo, Đề thi
│   ├── document_filter.dart # Model đóng gói bộ lọc đa tiêu chí
│   └── document_with_subject.dart # DTO ghép cặp Document & Subject (Join)
├── state/                   # Tầng Quản lý trạng thái (Provider / ChangeNotifier)
│   ├── document_provider.dart
│   └── subject_provider.dart
├── views/                   # Tầng Giao diện người dùng (Screens / Pages)
│   ├── home/
│   │   ├── home_page.dart
│   │   └── widgets/
│   │       ├── document_list_tile.dart
│   │       ├── filter_bottom_sheet.dart
│   │       ├── statistics_card.dart
│   │       └── subject_horizontal_list.dart
│   ├── document/
│   │   ├── document_detail_page.dart
│   │   └── edit_document_page.dart
│   └── subject/
│       └── manage_subjects_page.dart
├── widgets/                 # Reusable UI components dùng chung toàn hệ thống
│   ├── confirm_delete_dialog.dart
│   ├── custom_text_field.dart
│   ├── document_type_badge.dart
│   ├── empty_state_view.dart
│   └── search_bar_widget.dart
├── utils/                   # Tiện ích bổ trợ, Định dạng & Theme
│   ├── app_colors.dart      # Bảng màu hiện đại (Material 3)
│   ├── app_theme.dart       # Cấu hình Light/Dark Theme
│   ├── date_formatter.dart  # Định dạng thời gian (Intl)
│   └── file_helper.dart     # Nhận diện định dạng tệp, kích thước & icon
└── main.dart                # Khởi tạo Drift DB, ProviderScope, Theme & Root Routing
```

---

## 3. Hướng dẫn cài đặt & Chạy ứng dụng

### 3.1. Cài đặt các gói phụ thuộc
```bash
flutter pub get
```

### 3.2. Sinh mã nguồn tự động với build_runner (nếu chỉnh sửa database/tables)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3.3. Chạy kiểm thử tự động (Unit Test & Widget Test)
```bash
flutter test
```
*Kết quả:* Tất cả 4 bài kiểm thử kiểm tra tính đúng đắn của CRUD, bộ lọc đa tiêu chí và tính độc lập của tầng giao diện đều vượt qua (100% Passed).

### 3.4. Khởi chạy ứng dụng
```bash
flutter run
```
Ứng dụng hỗ trợ đa nền tảng: Android, iOS, Windows, macOS, Linux.

---

## 4. Báo cáo giải trình kiến trúc Cashew

### 4.1. Lợi ích của kiến trúc kiểu Cashew
1. **Phản ứng tức thời (Reactive UI)**: Bất kỳ thay đổi nào xuống SQLite (`insert`, `update`, `delete`) qua DAO sẽ tự động phát tín hiệu qua Stream. Toàn bộ Widget lắng nghe Stream sẽ tự render lại mà không cần callback phức tạp.
2. **Khả năng kiểm thử độc lập (Testability)**: Do tách biệt triệt để DAO khỏi UI, chúng ta có thể kiểm thử toàn bộ nghiệp vụ thêm/sửa/xóa/lọc dữ liệu bằng `NativeDatabase.memory()` (In-memory SQLite) mà không phụ thuộc vào thiết bị thật hay màn hình hiển thị.
3. **Dễ bảo trì & Mở rộng (Maintainability & Scalability)**: Khi muốn bổ sung thêm trường dữ liệu hoặc tính năng (như gắn thêm hạn chót bài tập, đánh dấu tiến độ đọc sách), lập trình viên chỉ cần cập nhật Schema trong `tables.dart` và chạy `build_runner`.
