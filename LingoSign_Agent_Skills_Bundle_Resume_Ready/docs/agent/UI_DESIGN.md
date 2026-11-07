# LingoSign — hướng dẫn giao diện

Ngày 03/11/2026. Áp dụng UI UX Pro Max theo yêu cầu người dùng:
https://github.com/nextlevelbuilder/ui-ux-pro-max-skill

Skill được cài tại `C:/Users/Admin/.codex/skills/ui-ux-pro-max`. Đã đọc SKILL.md, pro-rules và quick-reference về accessibility/touch/performance. Truy vấn `accessible learning mobile app --design-system` gợi ý Flat Design và teal; áp dụng phần style/palette phù hợp app, không dùng các mục marketing/social proof. Đã truy vấn stack Flutter cho animation/accessibility/responsive.

- Material 3, màu semantic theo ColorScheme cho sáng/tối; primary teal, nền dịu, surface có viền, góc bo 18–28dp.
- Typography: heading đậm, body có khoảng cách dòng 1.5; font hệ thống hỗ trợ tiếng Việt, không tải font qua mạng khi chạy app.
- Nội dung giới hạn 760dp trên màn hình rộng. Bố cục kiểm tra ở 390×844 và 320×740 với font 200%.
- Nút camera cao tối thiểu 56dp, nằm trước preview; lỗi quyền/camera hiển thị gần nút thao tác.
- Khung camera chờ tăng chiều cao theo text scaling để không cắt chữ; luồng camera thực tế không dùng animation crossfade giữ hai camera đồng thời.
- Chuyển trang fade 240ms easeOutCubic; tắt hiệu ứng này khi hệ thống bật reduced motion. Switch, button và điều hướng dùng feedback Material.
- Lịch sử dạng thẻ, ảnh bo góc, nút có tooltip, giữ phân trang và xem ảnh lớn. Không thêm dữ liệu nhận diện giả.
- Từ điển có heading, empty state, debounce tìm kiếm 250ms và nút xóa. Timer được hủy khi dispose, provider truy vấn autoDispose.
- Cài đặt gom chức năng thành thẻ, giữ nguyên ý nghĩa công tắc đồng bộ và chế độ tối theo phiên.

Kiểm chứng: format PASS, analyze sạch, toàn bộ 46 Flutter tests PASS (bao gồm search debounce/clear/dispose, phone/large-text/reduced-motion, camera/history/sync). Đã render và xem ảnh màn hình chính không có dữ liệu camera tại `build/ui-preview/home.png`. Đây là widget render; chưa nghiệm thu trực tiếp trên điện thoại thật. Ảnh preview được sinh trong build và không cần commit. Test ảnh dùng Segoe UI nếu có trên Windows, MaterialIcons từ bundle; CI môi trường khác vẫn kiểm tra layout với font test mặc định.

Skill đã cài có thể được nhận diện tự động ở lượt tiếp theo. Không đổi model, schema hoặc giao thức máy chủ trong lượt UI này.


## User reference update — 2026-11-03

Applied supplied indigo/amber mobile reference to shared theme, app bar, navigation indicator, rounded section banners and illustrated dictionary cards. Retained semantic dark colors and reduced-motion handling. Skill design-system search education/mobile/cards supplied spacing/accessibility guidance; reference colors take precedence over its orange palette suggestion. Source chart cropped into 36 native-resolution images padded to108px; no synthesized hand geometry. Original source retained. Catalog does not assert a language system or original license that was not provided. Digits cannot launch model practice. All56 Flutter tests and analysis pass; Android APK builds. Emulator unavailable for installation this turn.


### Silent Moon dark palette and artwork

Source: [Silent Moon, Welcome Sleep](https://www.figma.com/design/TQXf1Q6g7ba5krRQGuYUKc/Meditation-app-UI--Community-?node-id=3-2912). The four local SVG layers in assets/silent_moon come from node 3:2990. LingoSign uses the original composition on the idle camera and authentication header. Dark navy #03174C and periwinkle controls are adapted to Material 3.
