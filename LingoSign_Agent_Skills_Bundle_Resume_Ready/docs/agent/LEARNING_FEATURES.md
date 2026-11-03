# Luyện tập, tiến độ, từ điển và ôn tập — 03/11/2026

## Cách dùng

- Mở tab **Học tập** để xem tiến độ và các bài gần đây; bấm Bắt đầu bài luyện. Màn Nhận diện cũng có nút Luyện tập và kiểm tra.
- Chọn một chữ cái trong nhãn model hoặc Ngẫu nhiên. Có luyện nhanh 1 câu, bài 5 câu và 10 câu.
- Camera lấy dự đoán tốt nhất trong 1 giây. Nhãn không xác định, nhãn điều khiển hoặc độ tin cậy dưới 60% không tiêu thụ câu hỏi. Kết quả hợp lệ được đối chiếu với nhãn yêu cầu.
- Sau một đáp án, app chờ nút Câu tiếp theo; giữ tay không trả lời nhiều câu tự động. Có Bỏ qua và tổng kết câu đúng/sai/bỏ qua/thời gian. Camera không đóng giữa các câu.
- Từng lượt trả lời và bài chưa hoàn thành được lưu SQLite; trang Học tập xem lại được sau restart. Chưa có chức năng tiếp tục một bài dở; có thể tạo bài mới.
- Khi mở bài luyện từ Nhận diện, camera nhận diện được đóng trước để không lưu đáp án luyện vào lịch sử nhận diện. Khi app vào nền, bài luyện tắt camera; bấm Mở lại camera để tiếp tục. Không tự kích hoạt camera khi trở lại app.
- Tỷ lệ đúng = số câu đúng / số câu đã chấm; câu bỏ qua riêng. Số ngày luyện lấy ngày local của từng lượt trả lời. Biểu đồ thanh hiển thị tối đa 14 ngày có câu đã chấm gần nhất. Độ tin cậy model không phải tỷ lệ trả lời đúng hay accuracy được đo trên tập dữ liệu.
- Trong Lịch sử, tìm theo nhãn/mã bằng Enter, chọn ngày hoặc Yêu thích; các điều kiện được áp dụng trong SQLite trước phân trang. Chạm hàng để xem chi tiết, yêu thích, đánh dấu Nhận diện sai và lưu ghi chú. Chạm ảnh để phóng to. Dự đoán gốc được giữ nguyên; phản hồi không tự huấn luyện model.
- Bản ghi nhận diện mới lưu confidence từ model; bản cũ hoặc tải từ máy chủ không có confidence hiện Không có dữ liệu.

## Nội dung từ điển chờ người dùng

Người dùng xác nhận có ảnh/video và sẽ cung cấp. Hiện `assets/dictionary/catalog.json` có entries rỗng, không đưa nội dung/ngôn ngữ ký hiệu chưa xác minh vào app. Code đã hỗ trợ chủ đề, ý nghĩa, hệ ký hiệu, hướng dẫn, ảnh/video offline, nguồn/giấy phép và nút Luyện ký hiệu này. Nút này chỉ bật khi modelLabel thuộc nhãn chữ cái model thực tế.

Khi có nội dung, đặt file trực tiếp trong `assets/dictionary/` và điền catalog theo cấu trúc sau (thay tất cả giá trị mô tả trước khi sử dụng):

```json
{
  "version": "2",
  "sourceUrl": "URL nguồn nội dung được xác minh",
  "licenseName": "Giấy phép hoặc văn bản đồng ý sử dụng",
  "entries": [{
    "code": "MÃ_KÝ_HIỆU",
    "label": "Tên hiển thị",
    "description": "Ý nghĩa",
    "category": "Chủ đề",
    "signSystem": "Hệ ngôn ngữ ký hiệu đã xác minh",
    "instructions": "Hướng dẫn thực hiện do người cung cấp xác minh",
    "imageAsset": "assets/dictionary/ten-anh.png",
    "videoAsset": "assets/dictionary/ten-video.mp4",
    "modelLabel": null
  }]
}
```

Ảnh/video có thể null. Chỉ gán modelLabel khi nội dung thực sự tương ứng nhãn của model (ví dụ A); không gán tùy ý cho chào hỏi/sinh hoạt. Tăng version khi cập nhật, chạy lại app để bundle các asset mới. Nguồn/giấy phép bắt buộc với catalog có entries. Danh mục được nạp vào SQLite trước khi tìm kiếm; đường dẫn media chỉ chấp nhận trong assets/dictionary, không chấp nhận `..`. Video dùng plugin chính thức video_player, khởi tạo khi mở trang chi tiết, có phát/dừng/tua và tắt khi app vào nền hoặc trang bị đóng. Media chưa được kiểm chứng native vì đang chờ nội dung.

## Dữ liệu và đồng bộ

Schema v7 giữ các bảng cũ, thêm learning_sessions (snapshot câu hỏi + đáp án) và history_reviews (confidence, yêu thích, phản hồi, ghi chú), cùng metadata JSON của từ điển. Migration v4→v7 có test thực sự và bảo toàn lịch sử. Mỗi lượt lưu/upsert là transaction; không thay model hoặc tự tạo accuracy.

Bài luyện, metadata ôn tập và nội dung từ điển hiện **lưu local**. Máy chủ M3 vẫn chỉ đồng bộ metadata lịch sử nhận diện như trước; không tự mở rộng dữ liệu gửi đi hoặc gửi ảnh/video. Muốn đồng bộ bài luyện/phản hồi giữa thiết bị cần thêm giao thức và cập nhật phạm vi đồng thuận riêng.

## Kiểm thử

Đã kiểm tra từng giai đoạn trước khi xây giai đoạn kế tiếp: nghiệp vụ/lưu bài luyện (3 tests), tính tiến độ (tổng 4 learning tests), bộ lọc/metadata lịch sử (1 test và toàn bộ 51 test), sau đó từ điển và migration. Các lần chạy cuối được ghi ở PROGRESS.md. Các lỗi phát hiện được sửa trước nghiệm thu.

Test bổ sung gồm confidence thấp/unknown, skip, giữ đáp án chờ next, bài 5 câu hoàn tất, background lúc đang mở camera, công thức tỷ lệ đúng, metadata nguồn/media từ điển, khóa luyện cho nhãn không hỗ trợ, filter kết hợp trước pagination, giữ confidence gốc, lưu/đọc sau restart và migration v4. Cần kiểm thử Android camera/video thật với nội dung do người dùng cung cấp; không tuyên bố kết quả native hay độ chính xác mới.
