# Quản trị trên gói Firebase Spark

Mở Cài đặt → Khu vực quản trị bằng tài khoản có role admin.
Các màn dùng Firestore SDK trực tiếp và kiểm tra quyền bằng Firestore rules.

Hai mục Người dùng và Bài học hiển thị bằng nút chọn có nhãn ở đầu màn.
Danh sách Người dùng mặc định là Tất cả và lắng nghe toàn bộ hồ sơ Firestore
cùng phân quyền, tự cập nhật khi có thay đổi. Hồ sơ đã xóa vẫn được loại khỏi danh sách.
Ngày 25/11/2026 đã nhập đủ 3 tài khoản Authentication hiện tại vào Firestore.
Tài khoản đăng ký/đăng nhập từ app tự tạo hồ sơ nếu chưa có.
Nếu tạo tài khoản mới trực tiếp trong Firebase Console và muốn hiển thị ngay
trước lần đăng nhập đầu tiên, chạy từ thư mục Flutter:

```powershell
./tool/admin/sync-auth-users.ps1
```

Script sử dụng phiên Firebase CLI có quyền quản lý dự án, chỉ lấy UID/email/tên/
trạng thái disabled, không xuất mật khẩu và giữ nguyên các hồ sơ đang có.
Nhãn Online đo app đang ở foreground và có heartbeat được Firestore xác nhận.
Mỗi thiết bị gửi heartbeat 45 giây; rời app hoặc đăng xuất gửi Offline.
Khi mất mạng hoặc app bị tắt đột ngột, trạng thái hết hạn sau 90 giây, giao diện
đánh giá lại mỗi 15 giây. Nhiều thiết bị dùng chung tài khoản sẽ Online nếu còn
ít nhất một thiết bị hoạt động. Thiết bị cần cập nhật app mới để gửi heartbeat.
Người dùng có nút Xem, Sửa hồ sơ, Phân quyền, Ẩn/Hiện lại và Xóa.
Lọc Đang hiển thị, Đã ẩn hoặc Tất cả để quản lý người dùng.
Xóa người dùng giữ tài liệu đánh dấu deleted trong Firestore và khóa quyền
học tập/đồng bộ để hồ sơ không tự tạo lại khi đăng nhập. Tài khoản Firebase
Authentication và lịch sử vẫn được giữ. Tài khoản quản trị hiện tại và các
quản trị viên khác được bảo vệ khỏi ẩn/xóa qua các nút này.
Bài học có nút Thêm bài học, Xem, Sửa, Xóa, kèm số câu và trạng thái.

## Cập nhật

Từ thư mục Flutter chạy:

```powershell
npx --yes firebase-tools deploy --only firestore:rules --project danentang-f803c
./tool/sync_server/run-app.ps1 -Reinstall
```

Không cần triển khai Cloud Functions. Mã Functions cũ còn ở functions/ để
tham khảo, app hiện tại không gọi hàm đó.

## Dữ liệu

- Firebase quản lý bản nháp, xuất bản, ẩn, xóa ký hiệu, danh mục, bộ bài và nhật ký.
- Người dùng là hồ sơ trong collection users. Có thể thêm hồ sơ bằng UID lấy từ
  Authentication, sửa tên/email hồ sơ, xóa hồ sơ, sửa vai trò và khóa quyền học tập/
  đồng bộ. Thay đổi email hồ sơ không đổi email đăng nhập Authentication.
- Hồ sơ của tài khoản đang đăng nhập được cập nhật tự động khi mở phiên.
  Các tài khoản cũ cần mở lại app mới để tạo hồ sơ, hoặc quản trị viên thêm theo UID.
- Tài khoản Authentication tạo/xóa/đổi mật khẩu trong Firebase Console.
- Lịch sử Firebase đọc theo UID, phân trang 30 bản ghi. Có thể xem chi tiết, sửa
  mô tả summary và xóa sự kiện. Payload đồng bộ là dữ liệu gốc độc lập với summary.
  Xóa sự kiện không xóa dữ liệu đã được tải về một thiết bị khác.
- Bật Dữ liệu SQLite trên thiết bị để tạo, sửa, xuất bản, ẩn và xóa nội dung
  cục bộ. Bản cục bộ được ưu tiên so với catalog cloud đã tải trên thiết bị đó.
- Nút xem lịch sử SQLite đọc các bản ghi tài khoản hiện tại trên thiết bị,
  cho sửa ghi chú và xóa qua repository hiện có.
- SQLite của thiết bị người dùng khác chỉ có thể xem khi họ đã đồng bộ dữ liệu
  lên Firebase và quản trị viên biết UID.

## Nghiệm thu

Dùng ba vai trò để kiểm tra người học không ghi admin_*, quản lý nội dung chỉ
ghi nháp, quản trị viên CRUD được nội dung và phân quyền. Mở hai phiên chỉnh sửa
cùng mục để kiểm tra revision cũ bị từ chối. Xuất bản B,A,B, mở Học tập để kiểm tra
thứ tự. Lưu nháp lại và xác nhận người học vẫn dùng bản xuất bản cũ. Kiểm tra
xóa/ẩn và nội dung SQLite vẫn tồn tại sau refresh Firebase.

