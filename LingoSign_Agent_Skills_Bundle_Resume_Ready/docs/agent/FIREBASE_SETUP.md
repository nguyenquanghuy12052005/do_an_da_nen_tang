# Firebase cho LingoSign Android

1. Trên https://console.firebase.google.com/, đăng ký app Android với package **com.lingosign.lingosign_ai** và tải google-services.json.
2. Bật Email/Password ở Authentication → Sign-in method. Tạo Firestore Database mặc định.
3. Trong Firestore → Rules, xem lại và Publish nội dung firestore.rules. Quy tắc chỉ cho phép truy cập dữ liệu của UID đăng nhập.
4. Từ thư mục Flutter, chạy trong PowerShell:

    .\tool\sync_server\configure-firebase.ps1 -GoogleServicesJson 'C:\path\google-services.json'
    .\tool\sync_server\run-app.ps1 -Reinstall

Cấu hình sinh trong .sync-demo được Git bỏ qua. Launcher sẽ dùng Firebase thay server Python khi có cấu hình.

- Cài đặt → Đăng nhập → Tạo tài khoản. Đăng nhập lần đầu cần mạng.
- Bật đồng bộ. Tắt mạng, nhận diện chữ, làm bài luyện và xem hàng đợi. Mở lại app khi vẫn offline để kiểm tra SQLite giữ dữ liệu.
- Bật lại mạng. Chờ hàng đợi về 0, xem Firestore ở users/{uid}/syncEvents. Đăng nhập tài khoản khác để kiểm tra dữ liệu riêng. Thử tải về ở thiết bị khác với tài khoản ban đầu.
- Ảnh camera, yêu thích và ghi chú chỉ lưu trên thiết bị. Lịch sử khách không chuyển vào tài khoản mới.
