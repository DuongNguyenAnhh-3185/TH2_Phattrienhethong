# BỘ TÀI LIỆU SLIDE THUYẾT TRÌNH VÀ GHI CHÚ DIỄN GIẢ (SPEAKER NOTES)
## ĐỀ TÀI: PHÂN TÍCH VÀ LẬP PHƯƠNG ÁN TÍCH HỢP CLOUD CHO HỆ THỐNG QUẢN LÝ TÀI LIỆU (DMS)
### NỀN TẢNG: FLUTTER & GOOGLE FIREBASE CLOUD PLATFORM

---

## 🎯 CẤU TRÚC TỔNG QUAN BỘ SLIDE (9 SLIDES CHUẨN)

- **Slide 1:** Giới thiệu đề tài & Đội ngũ thực hiện
- **Slide 2:** Hiện trạng & Thách thức của Hệ thống DMS On-Premises
- **Slide 3:** Giải pháp Cloud & Tổng quan Hệ sinh thái Google Firebase
- **Slide 4:** Thiết kế Kiến trúc Hệ thống mới & Luồng dữ liệu (Data Pipeline)
- **Slide 5:** Hướng dẫn Thiết lập Firebase Console & Cấu hình FlutterFire
- **Slide 6:** Chiến lược Bảo mật Toàn diện (Auth + Security Rules)
- **Slide 7:** Demo Tính năng Ứng dụng Thực tế (Flutter Client)
- **Slide 8:** Hiệu quả Kinh tế, Đánh giá Hiệu năng & Hướng phát triển Tương lai
- **Slide 9:** Kết luận & Phiên Hỏi - Đáp (Q&A)

---

## SLIDE 1: GIỚI THIỆU ĐỀ TÀI & ĐỘI NGŨ THỰC HIỆN

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề chính (Bold 40pt):** CHUYỂN DỊCH HẠ TẦNG CLOUD CHO HỆ THỐNG QUẢN LÝ TÀI LIỆU (DMS)
* **Tiêu đề phụ (22pt):** Giải pháp Tích hợp Tối ưu với Flutter & Nền tảng Serverless Google Firebase
* **Thông tin nhóm:**
  - *Nhóm thực hiện:* Nhóm Kiến trúc Giải pháp Di động & Đám mây
  - *Vai trò:* Cloud Solutions Architect & Full-stack Mobile Engineer
  - *Công nghệ chủ đạo:* Flutter 3.x • Firebase Auth • Cloud Firestore • Firebase Storage • Google Cloud
* **Hình ảnh minh họa:** Logo Flutter kết hợp biểu tượng Cloud Firebase rực sáng kết nối tới các thiết bị di động, tablet, laptop.

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 1.5 phút)
> *"Kính thưa Thầy/Cô và các bạn đồng nghiệp,*
> 
> *Trong kỷ nguyên làm việc số và học tập kết hợp (Hybrid Work & Learning), việc quản trị, lưu trữ và chia sẻ tài liệu một cách an toàn, nhanh chóng và không giới hạn địa lý đã trở thành nhu cầu sống còn của mọi tổ chức. Hôm nay, nhóm chúng em xin đại diện với vai trò là Kiến trúc sư Giải pháp Đám mây và Kỹ sư phần mềm Full-stack, mang đến bài thuyết trình: **'Phân tích và Lập phương án tích hợp Cloud cho Hệ thống Quản lý Tài liệu (DMS)'**.*
> 
> *Bài thuyết trình sẽ đi qua toàn bộ hành trình: từ việc mổ xẻ những điểm nghẽn nghiêm trọng của hạ tầng máy chủ cục bộ truyền thống, cho tới việc thiết kế kiến trúc Serverless hiện đại bằng Firebase và triển khai sản phẩm hoàn chỉnh trên Flutter. Xin kính mời quý vị cùng theo dõi."*

---

## SLIDE 2: HIỆN TRẠNG & THÁCH THỨC CỦA HỆ THỐNG DMS ON-PREMISES

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** BẪY HẠ TẦNG TRUYỀN THỐNG: 4 ĐIỂM NGHẼN CỐ HỮU CỦA ON-PREMISES
* **4 Khối cảnh báo trực quan (Red/Orange Cards with Danger Icons):**
  1. **Nghẽn trần dung lượng đĩa vật lý (Storage Capacity Bottlenecks):** Ổ cứng cục bộ / NAS có giới hạn cố định; chi phí mua mới và mở rộng mảng đĩa RAID tốn kém, gây gián đoạn hệ thống (Downtime).
  2. **Tắc nghẽn I/O & Băng thông (I/O & Bandwidth Saturation):** Khi nhiều người tải/upload tệp lớn (PDF, video bài giảng), máy chủ trung gian bị bão hòa CPU/RAM và quá tải cổng mạng (1Gbps LAN bottleneck).
  3. **Rủi ro mất trắng dữ liệu (Disaster & Ransomware Risk):** Hỏng hóc vật lý SPoF (cháy nguồn, chết ổ đĩa), thiếu cơ chế sao lưu ngoài vùng (Off-site DR), dễ bị mã độc tống tiền xâm nhập mạng nội bộ.
  4. **Bất tiện truy cập từ xa (Remote Access Friction):** Bắt buộc phải kết nối qua VPN nội bộ chậm chạp, độ trễ cao và trải nghiệm người dùng kém cỏi ngoài văn phòng/trường học.

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 2 phút)
> *"Thưa quý vị, hầu hết các hệ thống quản lý tài liệu trước đây đều được cài đặt trên một máy chủ nội bộ hoặc một ổ cứng mạng NAS đặt tại văn phòng. Mô hình này ban đầu có vẻ tiết kiệm, nhưng khi số lượng tài liệu chạm mốc hàng chục nghìn file và người dùng tăng lên, nó lập tức biến thành 'cơn ác mộng' vận hành với 4 điểm nghẽn chính:*
> 
> *Thứ nhất là **Dung lượng**: Dung lượng ổ cứng vật lý luôn có hạn. Khi đĩa đầy tới 90%, hệ thống có nguy cơ sập hoàn toàn. Việc mua thêm ổ đĩa đắt đỏ và phải dừng hệ thống để cấu hình lại RAID.*
> 
> *Thứ hai là **Tắc nghẽn I/O**: Mọi file người dùng upload đều phải chui qua máy chủ backend để ghi xuống đĩa. Khi 50 người cùng tải file báo cáo 50MB, card mạng máy chủ bị bão hòa, ổ đĩa quay 100% công suất gây treo ứng dụng.*
> 
> *Thứ ba là **Rủi ro mất dữ liệu**: Không có cơ chế tự động nhân bản đa vùng. Nếu ổ cứng cháy hoặc bị dính ransomware qua mạng LAN, tổ chức có thể mất toàn bộ dữ liệu lịch sử.*
> 
> *Và cuối cùng là **Khả năng làm việc từ xa**: Người dùng phải bật VPN nội bộ rất chậm chạp. Đó là lý do tại sao chúng ta bắt buộc phải tiến hành chuyển dịch dịch vụ lên Cloud."*

---

## SLIDE 3: GIẢI PHÁP CLOUD & HỆ SINH THÁI GOOGLE FIREBASE

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** ĐỘT PHÁ VỚI NỀN TẢNG CLOUD SERVERLESS: HỆ SINH THÁI FIREBASE
* **Bảng so sánh mô hình Cloud:** Public Cloud (Tối ưu) vs Private Cloud vs Hybrid Cloud.
* **4 Trụ cột Dịch vụ của Google Firebase được chọn:**
  - 🔑 **Firebase Authentication:** Quản lý phiên đăng nhập Google Single Sign-On (SSO) an toàn, chuẩn OAuth 2.0 / OpenID Connect, không cần tự lưu mật khẩu.
  - ⚡ **Cloud Firestore:** Cơ sở dữ liệu NoSQL phân tán, độ trễ dưới 1 giây, tự động nhân bản đa vùng (Multi-Region), lắng nghe dữ liệu thời gian thực (Real-time Snapshot Streams).
  - 🗄️ **Firebase Cloud Storage:** Lưu trữ tệp nhị phân trên hạ tầng Google Cloud Storage (GCS), độ bền bỉ đạt **99.999999999% (11 số 9)**, hỗ trợ tải tiếp tục khi mất mạng (Resumable Uploads) và tích hợp Edge CDN.
  - ⚙️ **Cloud Functions:** Xử lý nền sự kiện (Serverless Event Triggers): tự động tạo thumbnail, quét virus, trích xuất ký tự OCR qua Google Vision API.

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 1.5 phút)
> *"Để giải quyết triệt để bài toán trên, chúng em lựa chọn giải pháp **Public Cloud** với hệ sinh thái **Google Cloud Platform & Firebase**. Lý do là Firebase cung cấp mô hình **Serverless** hoàn chỉnh dành cho ứng dụng di động và web.*
> 
> *Bốn trụ cột của hệ thống bao gồm:*
> *Thứ nhất: **Firebase Authentication** giúp người dùng đăng nhập chỉ bằng 1 chạm thông qua tài khoản Google SSO của trường học hoặc doanh nghiệp. Chúng ta hoàn toàn không cần xây dựng bảng lưu mật khẩu, triệt tiêu nguy cơ lộ lọt thông tin.*
> *Thứ hai: **Cloud Firestore** lưu trữ toàn bộ metadata của tài liệu như tên file, kích thước, ngày tạo. Firestore có tính năng Real-time snapshot cực kỳ mạnh mẽ, khi có file mới tải lên, toàn bộ máy người dùng sẽ tự cập nhật ngay lập tức.*
> *Thứ ba: **Firebase Cloud Storage** kế thừa sức mạnh của Google Cloud Storage, cam kết độ bền 11 số 9 – nghĩa là về mặt lý thuyết, rủi ro mất 1 file là 1 trên hàng trăm tỷ năm. Nó còn hỗ trợ cơ chế tải tệp ngắt quãng tiếp tục lại nếu mạng 4G chập chờn.*
> *Và cuối cùng là **Cloud Functions** đóng vai trò xử lý nền tự động mà không cần chạy server 24/7."*

---

## SLIDE 4: KIẾN TRÚC HỆ THỐNG MỚI & LUỒNG HOẠT ĐỘNG (DATA PIPELINE)

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** KIẾN TRÚC DIRECT-TO-CLOUD & LUỒNG DỮ LIỆU THỜI GIAN THỰC
* **Sơ đồ kiến trúc (Architecture Diagram):**
  - Trực quan hóa tương tác giữa **Flutter Client** <-> **Firebase Auth**, **Cloud Storage** và **Cloud Firestore**.
* **Đặc điểm kiến trúc then chốt (Key Callouts):**
  - **Tải tệp trực tiếp (Direct Upload Pipeline):** Thiết bị Flutter gửi luồng byte trực tiếp tới Cloud Storage Bucket mà KHÔNG qua máy chủ trung gian -> Triệt tiêu điểm nghẽn I/O.
  - **Phân tách Rõ ràng:** Binary File -> Cloud Storage; Metadata -> Cloud Firestore.
  - **Đồng bộ phản ứng (Reactive Real-time Flow):** Sử dụng Dart Stream để giao diện tự render mà không cần F5 hoặc polling liên tục.

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 2 phút)
> *"Xin mời Thầy Cô và các bạn chú ý vào sơ đồ kiến trúc trên Slide 4. Đây chính là bước đột phá kỹ thuật lớn nhất của giải pháp.*
> 
> *Ở mô hình cũ, file phải đi qua Backend server rồi mới xuống ổ đĩa, làm máy chủ backend trở thành nút thắt cổ chai. Nhưng trong kiến trúc Cloud mới này, ứng dụng Flutter client sau khi xác thực Google sẽ **tải thẳng tệp tin lên Firebase Cloud Storage**.*
> 
> *Luồng hoạt động diễn ra theo 4 bước nhịp nhàng:*
> *Bước 1: Người dùng nhấn chọn đăng nhập Google, Firebase Auth phát hành token JWT.*
> *Bước 2: Người dùng chọn file trên máy, hệ thống kiểm tra file dưới 25MB rồi đẩy trực tiếp lên Cloud Storage tại đường dẫn `documents/{userId}/{timestamp}_{filename}`. Quá trình này có thanh tiến trình % hiển thị trực tiếp.*
> *Bước 3: Ngay khi upload xong, Storage trả về Download URL có chữ ký bảo mật. Client lập tức ghi metadata vào collection `documents` của Cloud Firestore.*
> *Bước 4: Nhờ cơ chế Snapshot Stream, Firestore tự động bắn sự kiện về Flutter UI. Thẻ Card tài liệu mới lập tức xuất hiện lung linh trên màn hình mà không cần tải lại trang."*

---

## SLIDE 5: HƯỚNG DẪN THIẾT LẬP FIREBASE CONSOLE CHO DỰ ÁN NHÓM

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** THIẾT LẬP FIREBASE CONSOLE & TÍCH HỢP FLUTTER CHỈ VỚI 5 BƯỚC
* **5 Bước thiết lập bài bản dạng Timeline / Quy trình:**
  1. **Bước 1: Tạo Firebase Project:** Đặt tên dự án (VD: `dms-cloud-management`), chọn Vùng dữ liệu `asia-southeast1` (Singapore) để tối ưu độ trễ cho người dùng Việt Nam.
  2. **Bước 2: Kích hoạt Google Auth Provider:** Vào mục Authentication -> Sign-in method -> Bật 'Google' và liên kết email hỗ trợ dự án.
  3. **Bước 3: Khởi tạo Cloud Firestore:** Chọn Production Mode, chọn vị trí lưu trữ đa vùng (nam5 / asia-southeast1).
  4. **Bước 4: Khởi tạo Firebase Cloud Storage:** Tạo Default Bucket (`gs://...`), chuẩn bị áp dụng cấu hình Security Rules.
  5. **Bước 5: Đồng bộ với Flutter qua FlutterFire CLI:**
     * Chạy lệnh CLI: `dart pub global activate flutterfire_cli`
     * Chạy lệnh cấu hình: `flutterfire configure --project=dms-cloud-management`
     * Tự động sinh file `firebase_options.dart` hỗ trợ Android, iOS, Web, Windows mà không cần copy thủ công `google-services.json`.

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 1.5 phút)
> *"Để triển khai phương án này vào thực tế, quy trình thiết lập trên Firebase Console được tiêu chuẩn hóa rất nhanh gọn:*
> 
> *Đầu tiên, chúng ta tạo một Project trên Firebase Console và lưu ý chọn vùng dữ liệu Singapore `asia-southeast1` để có đường truyền quang biển nhanh nhất về Việt Nam.*
> *Tiếp theo, chỉ cần 1 cú click chuột để bật Google Provider trong mục Authentication.*
> *Sau đó, khởi tạo Firestore Database và Storage Bucket.*
> *Điểm đặc biệt trong dự án của nhóm là chúng em áp dụng công cụ chính thức **FlutterFire CLI**. Chỉ với một dòng lệnh `flutterfire configure`, toàn bộ cấu hình, API Key và Client ID của các nền tảng Android, iOS, Web, Windows đều được tự động sinh ra trong file `firebase_options.dart`. Điều này giúp dự án nhóm hoạt động đồng bộ 100%, loại bỏ lỗi lệch file `google-services.json` giữa các thành viên."*

---

## SLIDE 6: CHIẾN LƯỢC BẢO MẬT TOÀN DIỆN (AUTH & SECURITY RULES)

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** BẢO MẬT ĐA LỚP: HÀNG RÀO FIREBASE SECURITY RULES
* **So sánh 2 khối quy tắc bảo mật thực tế:**
  - **Khối 1: Firestore Security Rules (`firestore.rules`)**
    ```javascript
    match /documents/{docId} {
      allow read, delete: if request.auth != null 
                          && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.fileSize <= 26214400;
    }
    ```
  - **Khối 2: Storage Security Rules (`storage.rules`)**
    ```javascript
    match /documents/{userId}/{fileName} {
      allow read, delete: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId
                    && request.resource.size <= 25 * 1024 * 1024
                    && request.resource.contentType.matches('application/pdf|image/.*|...');
    }
    ```
* **3 Lớp phòng thủ chính:**
  1. *Nguyên tắc đặc quyền tối thiểu (Least Privilege):* Người dùng chỉ đọc và xóa được tài liệu do chính mình tạo ra.
  2. *Kiểm soát tải trọng (Payload Validation):* Giới hạn kích thước file tải lên tối đa 25MB trực tiếp từ tầng mạng.
  3. *Mã hóa mặc định:* Dữ liệu luôn được mã hóa hai đầu (TLS 1.3 in-transit và AES-256 at-rest).

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 1.5 phút)
> *"Một câu hỏi mà các chuyên gia bảo mật luôn đặt ra khi đưa hệ thống lên Cloud là: 'Làm sao đảm bảo người dùng A không xem hoặc xóa được tài liệu của người dùng B?'*
> 
> *Câu trả lời nằm ở **Firebase Security Rules** – cơ chế kiểm soát truy cập thực thi ngay tại biên hạ tầng của Google:*
> *Trên Firestore, chúng em thiết lập quy tắc: Chỉ cho phép đọc, sửa, xóa khi `request.auth.uid` trùng khớp với trường `userId` của tài liệu.*
> *Trên Storage, chúng em khóa chặt đường dẫn theo cấu trúc `documents/{userId}/{fileName}`. Đồng thời, hệ thống kiểm duyệt nghiêm ngặt: File phải dưới 25MB và chỉ chấp nhận các định dạng tệp văn phòng hoặc hình ảnh hợp lệ.*
> *Mọi nỗ lực can thiệp từ client xấu đều sẽ bị hạ tầng Google chặn đứng ngay từ tầng mạng với mã lỗi Permission Denied, mang lại sự an tâm tuyệt đối."*

---

## SLIDE 7: DEMO TÍNH NĂNG ỨNG DỤNG THỰC TẾ (FLUTTER CLIENT)

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** SẢN PHẨM HOÀN THIỆN: ỨNG DỤNG FLUTTER CLOUD DMS
* **Hình ảnh giao diện thực tế (Mockups / Screenshots):**
  - *Màn hình Đăng nhập (LoginScreen):* Thiết kế Glassmorphism sang trọng, nút bấm Google SSO tiêu chuẩn.
  - *Màn hình Dashboard (DocumentDashboardScreen):*
    * Header hiển thị Avatar Google, Tên và Email người dùng.
    * Thanh tiến trình Upload tương tác thực (`LinearProgressIndicator` chạy mượt mà từ 0% đến 100%).
    * Danh sách tài liệu dạng Card: Phân biệt rõ icon PDF (đỏ), Word (xanh dương), Excel (xanh lá), Ảnh (tím).
    * Nút Mở/Tải về và Nút Xóa tài liệu kèm hộp thoại xác nhận an toàn.
    * Ô tìm kiếm từ khóa phản ứng tức thì (Live search filter).

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 2 phút)
> *"Sau đây, nhóm xin kính mời Thầy Cô và các bạn cùng chiêm ngưỡng giao diện của ứng dụng Flutter mà nhóm đã xây dựng theo chuẩn Clean Architecture.*
> 
> *Khi mở ứng dụng, màn hình đăng nhập hiển thị thông tin giới thiệu hiện đại. Người dùng chỉ cần bấm 'Đăng nhập với Google', phiên xác thực diễn ra an toàn và chuyển ngay vào màn hình Dashboard.*
> *Tại Dashboard, thông tin cá nhân và avatar của người dùng được hiển thị rõ ràng.*
> *Khi nhấn nút tải tài liệu, bộ chọn file của hệ điều hành mở ra. Ngay khi chọn file báo cáo PDF, thanh tiến trình màu xanh xuất hiện và báo % tải lên theo thời gian thực.*
> *Khi tiến trình hoàn thành, thẻ tài liệu lập tức hiển thị với icon PDF màu đỏ trực quan, dung lượng được quy đổi dễ hiểu như 2.4 MB, cùng ngày giờ tải lên.*
> *Người dùng có thể bấm vào nút download để mở tài liệu ngay trên trình duyệt, hoặc bấm nút thùng rác để xóa vĩnh viễn tệp trên cả Storage và Firestore. Mọi thao tác đều cực kỳ mượt mà và trực quan."*

---

## SLIDE 8: ĐÁNH GIÁ CHI PHÍ, HIỆU NĂNG & HƯỚNG PHÁT TRIỂN TƯƠNG LAI

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** ĐÁNH GIÁ TÁC ĐỘNG & LỘ TRÌNH MỞ RỘNG (SCALABILITY ROADMAP)
* **Bảng so sánh Kinh tế & Hiệu năng:**
  - *Chi phí (CapEx vs OpEx):* Chi phí đầu tư phần cứng ban đầu giảm từ hàng chục triệu đồng xuống **0 ĐỒNG**. Gói miễn phí **Firebase Spark Plan** đáp ứng trọn vẹn giai đoạn thử nghiệm (5GB Storage, 1GB Firestore, 50,000 read/ngày).
  - *Hiệu năng:* Băng thông toàn cầu Google CDN tăng tốc độ tải file lên gấp **5 - 10 lần**, SLA cam kết 99.99%.
* **3 Hướng Mở rộng Tính năng trong Tương lai:**
  1. **OCR Trích xuất Văn bản Tự động:** Tích hợp Cloud Functions với Google Cloud Vision API để quét chữ từ file scan và ảnh.
  2. **Tìm kiếm Toàn văn (Full-text Search):** Tích hợp dịch vụ Typesense hoặc Algolia Extension để tìm kiếm nội dung bên trong tài liệu.
  3. **Phân quyền Cộng tác Nhóm (Team Sharing & Workspaces):** Mở rộng Firestore Schema hỗ trợ chia sẻ tài liệu giữa các người dùng với quyền View/Edit.

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 1.5 phút)
> *"Về mặt kinh tế và hiệu năng:*
> *Việc chuyển đổi sang Firebase giúp tổ chức tiết kiệm hoàn toàn vốn đầu tư ban đầu CapEx. Trong giai đoạn thử nghiệm hoặc quy mô trường học nhỏ, gói Spark Plan miễn phí hoàn toàn đáp ứng tốt nhu cầu lưu trữ. Khi quy mô tăng lên, mô hình Pay-as-you-go giúp chúng ta chỉ trả tiền cho dung lượng thực tế phát sinh, tiết kiệm hơn 60% tổng chi phí sở hữu (TCO) so với việc duy trì một phòng server riêng.*
> 
> *Về hướng phát triển tương lai, hạ tầng Cloud mở ra tiềm năng vô hạn:*
> *Chúng em đã thiết kế sẵn kiến trúc để dễ dàng cắm thêm Cloud Functions gọi Google Cloud Vision API để nhận diện chữ viết OCR tự động, và tích hợp thuật toán tìm kiếm toàn văn, biến ứng dụng thành một trợ lý học tập và làm việc thông minh toàn diện."*

---

## SLIDE 9: KẾT LUẬN & PHIÊN HỎI - ĐÁP (Q&A)

### 1. Bố cục hiển thị trên Slide (Visual Layout)
* **Tiêu đề Slide:** KẾT LUẬN VÀ GIẢI ĐÁP THẮC MẮC (Q&A)
* **3 Thông điệp Đúc kết Cốt lõi (Takeaway Messages):**
  - ✅ **Chuyển đổi số thành công:** Xóa bỏ hoàn toàn các điểm nghẽn I/O, dung lượng và rủi ro mất mát dữ liệu của hạ tầng On-Premises.
  - ✅ **Kiến trúc Serverless vững chắc:** Kết hợp hoàn hảo giữa Flutter Client và hệ sinh thái Firebase (Auth, Firestore, Storage) với độ bảo mật chuẩn doanh nghiệp.
  - ✅ **Trải nghiệm Người dùng Xuất sắc:** Đồng bộ thời gian thực, giao diện hiện đại, sẵn sàng triển khai đa nền tảng (Mobile, Web, Desktop).
* **Lời cảm ơn & Lời mời đặt câu hỏi:**
  - *"Xin trân trọng cảm ơn Thầy/Cô và các bạn đã chú ý lắng nghe!"*
  - *Mở phiên thảo luận và giải đáp thắc mắc.*

### 2. Ghi chú Thuyết trình (Speaker Notes - Thời lượng: 1.5 phút)
> *"Kính thưa Thầy Cô và các bạn,*
> 
> *Tổng kết lại, đề tài 'Phân tích và Lập phương án tích hợp Cloud cho Hệ thống Quản lý Tài liệu' không chỉ dừng lại ở mặt lý thuyết thiết kế giải pháp đám mây, mà đã được nhóm chúng em hiện thực hóa thành một sản phẩm phần mềm Flutter hoàn chỉnh, an toàn và sẵn sàng đưa vào sử dụng thực tế.*
> 
> *Nhóm chúng em xin gửi lời cảm ơn chân thành tới Thầy Cô đã định hướng và theo dõi bài thuyết trình. Giờ đây, nhóm rất mong nhận được những nhận xét quý báu và sẵn sàng trả lời các câu hỏi phản biện từ Hội đồng. Xin trân trọng cảm ơn!"*

---

## 💡 PHỤ LỤC: BỘ CÂU HỎI PHẢN BIỆN DỰ PHÒNG CHO PHIÊN Q&A (ANTICIPATED QUESTIONS)

| STT | Câu hỏi Phản biện có thể gặp | Gợi ý Câu trả lời ngắn gọn & Chuyên nghiệp |
| :--- | :--- | :--- |
| **Q1** | *Tại sao nhóm không dựng Backend Node.js/Java REST API riêng mà dùng Firebase trực tiếp từ Flutter?* | **Trả lời:** Với ứng dụng di động DMS, việc gọi trực tiếp Firebase Client SDK kèm **Security Rules** giúp loại bỏ máy chủ trung gian, tránh nghẽn I/O tải tệp lớn và tiết kiệm 100% chi phí duy trì server 24/7. Nếu cần xử lý nghiệp vụ phức tạp, Cloud Functions sẽ đóng vai trò Backend phi máy chủ khi cần. |
| **Q2** | *Nếu người dùng bị mất mạng khi đang upload file 20MB thì xử lý thế nào?* | **Trả lời:** Firebase Cloud Storage hỗ trợ cơ chế **Resumable Uploads**. Khi kết nối mạng phục hồi, SDK có khả năng tiếp tục đẩy các byte còn thiếu từ điểm ngắt quãng mà không cần người dùng phải tải lại từ đầu (0%). |
| **Q3** | *Làm sao ngăn chặn người dùng cố tình đổi đuôi file virus exe thành pdf để upload?* | **Trả lời:** Ở lớp Storage Rules, chúng ta kiểm tra `request.resource.contentType`. Ở lớp mở rộng tương lai, sự kiện `onFinalize()` của Cloud Functions sẽ kích hoạt dịch vụ quét mã độc (như ClamAV hoặc VirusTotal API) để tự động xóa file và gắn cờ cảnh báo nếu phát hiện mã độc. |
| **Q4** | *Nếu quy mô lên 100,000 người dùng, Firestore có bị nghẽn lượt đọc/ghi không?* | **Trả lời:** Cloud Firestore được thiết kế để tự động sharding và co giãn hàng triệu kết nối đồng thời. Giới hạn ghi trên 1 document là 1 write/giây, nhưng trong hệ thống DMS, mỗi tài liệu là một document riêng biệt nên hệ thống có thể xử lý hàng chục nghìn lượt ghi đồng thời trên toàn collection mà không bị nghẽn. |
