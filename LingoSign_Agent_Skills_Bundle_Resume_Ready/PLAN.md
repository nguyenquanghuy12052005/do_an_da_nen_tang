# LINGOSIGN AI — MASTER IMPLEMENTATION PLAN

> **Mục đích:** Kế hoạch kỹ thuật và checklist thực thi để phát triển đồ án Capstone **LingoSign AI** bằng **Flutter (Dart)** với sự hỗ trợ của **OpenAI Codex**.  
> **Phiên bản:** 1.0 · **Ngày lập:** 17/10/2026 · **Thời lượng:** 13 tuần · **Milestones:** Tuần 4, 8, 11, 13.  
> **Trạng thái:** `[ ] Chưa làm` · `[x] Hoàn thành` · `[~] Đang làm` (khi cập nhật checklist, ưu tiên `[ ]` / `[x]` để GitHub hiển thị đúng).

---

## 0. TÓM TẮT QUYẾT ĐỊNH

| Mục | Quyết định |
|---|---|
| Tên đồ án | **LingoSign AI — Ứng dụng nhận diện và hỗ trợ giao tiếp bằng ngôn ngữ ký hiệu** |
| Hướng nghiên cứu | **Ứng dụng AI On-Device vào nhận diện bộ ký hiệu giới hạn, kết hợp thiết kế Offline-First và đánh giá hiệu năng thực nghiệm** |
| Client | **Flutter + Dart**, mục tiêu Android và iOS |
| Kiến trúc | **Clean Architecture: Domain / Data / Presentation** |
| Quản lý trạng thái | **Riverpod** (chọn duy nhất một giải pháp, không trộn BLoC) |
| Local DB | **SQLite + Drift** (Drift là lớp truy cập SQLite, không phải một DB khác) |
| Cloud BaaS | **Supabase** (Auth, Postgres, Storage chỉ khi cần); **app chạy offline không phụ thuộc Supabase** |
| Nhận diện bàn tay | **MediaPipe Tasks Hand Landmarker** chạy on-device qua plugin/native adapter phù hợp |
| Suy luận mô hình | **TensorFlow Lite** qua `tflite_flutter` nếu model tương thích; nếu model đã đóng gói dưới dạng MediaPipe Task, dùng adapter thích hợp |
| Phát âm | **TTS on-device** nếu thiết bị có sẵn voice/engine cần thiết |
| Nhận âm thanh | **STT** là tính năng mở rộng, chỉ được gắn nhãn offline sau khi kiểm chứng engine/language pack trên máy thật |
| UI | Material 3, Dark/Light, accessibility, giao diện tiếng Việt |
| CI/CD | GitHub Actions + Fastlane + ký APK/AAB cho Android; iOS release tùy điều kiện macOS/Xcode/chứng chỉ |
| Test | Unit Test + Widget Test + Integration Test + thử nghiệm ngoài đời |
| Mục tiêu phiên bản 1.0 | **Camera → AI nhận diện ký hiệu trong tập được hỗ trợ → chữ → TTS**, từ điển + lịch sử + hoạt động offline + đồng bộ + release tự động |

**Nguyên tắc cốt lõi:** tạo một ứng dụng thật, tích hợp mô hình thật, có số liệu kiểm chứng thật. Không viết màn hình giả gọi là AI, không tự điền nhãn/độ chính xác giả, không hiển thị “dịch ngôn ngữ ký hiệu tự do” nếu mô hình chỉ nhận diện được một tập ký hiệu hạn chế.

### 0.1. Những điều phải làm rõ ngay trong tuần 1

- [ ] Xác nhận bộ dữ liệu thuộc **ngôn ngữ ký hiệu nào** (ví dụ: bộ ký hiệu Việt Nam theo vùng/nguồn cụ thể), số lớp `N`, danh sách nhãn, giấy phép và phạm vi sử dụng.
- [ ] Xác nhận hiện có **dataset**, **model đã huấn luyện**, hay cả hai. Có dataset **không đồng nghĩa** đã có model chạy được trên điện thoại.
- [ ] Ghi rõ model nhận **ảnh RGB**, **crop bàn tay**, **21 landmark của 1 tay**, **2 tay**, hay **chuỗi nhiều frame**; input tensor shape, dtype, normalization, output shape, label order.
- [ ] Có artifact `.tflite`/`.task` hoặc format khác? Nếu chưa, việc xuất/chuyển đổi thành model mobile là **phụ thuộc đầu vào bắt buộc**, không mặc định Codex tự huấn luyện lại.
- [ ] Chốt **bộ 10–30 ký hiệu** có trong dữ liệu cho bản MVP (con số là phạm vi gợi ý, không phải cam kết model nhận được 30 lớp).
- [ ] Kiểm tra có **máy Android thật** để đo hiệu năng; muốn kiểm chứng iOS phải có **Mac + Xcode + máy iPhone** hoặc môi trường macOS phù hợp.
- [ ] Thống nhất nhóm đối tượng dùng và mời người biết ngôn ngữ ký hiệu xác nhận độ đúng của nội dung; tránh tự phát minh bộ ký hiệu minh họa.

---

## 1. ĐỀ TÀI, NGƯỜI DÙNG, NỖI ĐAU VÀ ĐÓNG GÓP NGHIÊN CỨU

### 1.1. Người dùng mục tiêu

1. **Người Điếc/người khiếm thính sử dụng ngôn ngữ ký hiệu:** cần cách giao tiếp bổ trợ với người chưa biết ký hiệu.
2. **Người thân, giáo viên, đồng nghiệp và người hỗ trợ:** muốn hiểu một tập ký hiệu giao tiếp thường gặp.
3. **Người mới học ngôn ngữ ký hiệu:** cần từ điển trực quan và công cụ luyện tập cơ bản.

**Lưu ý tiếp cận cộng đồng:** Không mặc định tất cả người Điếc dùng cùng một ngôn ngữ ký hiệu, cũng không đồng nhất ngôn ngữ ký hiệu với những tư thế ngón tay rời rạc. Biểu cảm mặt, hướng chuyển động và ngữ cảnh có thể mang nghĩa ngôn ngữ.

### 1.2. Pain points

- Giao tiếp giữa người biết và không biết ngôn ngữ ký hiệu thường phải chuyển sang gõ chữ hoặc nhờ phiên dịch.
- Giải pháp nhận diện phụ thuộc cloud dễ bị ngắt khi mạng yếu, có lo ngại quyền riêng tư của video camera.
- Người học gặp khó khi tự đối chiếu ký hiệu mình thực hiện với mẫu.
- Nhiều sản phẩm demo chỉ nhận diện một frame, thiếu xử lý kết quả nhiễu, kiểm chứng trên máy thật, lịch sử và khả năng vận hành offline.

### 1.3. Giải pháp đề xuất và điểm khác biệt **cần chứng minh**

- **Local-first AI:** camera → tiền xử lý → model → kết quả ngay trên máy; **không gửi raw camera frames lên Supabase**.
- **Offline-first data:** từ điển, lịch sử và cài đặt hoạt động không mạng; đồng bộ dữ liệu người dùng khi có mạng.
- **Kết quả đáng tin cậy:** kết hợp `confidence threshold`, ổn định qua nhiều frame, nhãn “chưa chắc chắn” thay vì luôn dự đoán một ký hiệu.
- **Giao tiếp thuận tiện:** phụ đề lớn, nút phát TTS, lịch sử câu/từ, tùy chọn rung, dark mode, hỗ trợ thao tác một tay.
- **Thực nghiệm có kiểm soát:** báo cáo macro-F1, độ trễ inference, độ trễ end-to-end, FPS giao diện, tỷ lệ lỗi ở các điều kiện ánh sáng/nền khác nhau.

**Không khẳng định sản phẩm vượt tất cả ứng dụng hiện có khi chưa khảo sát và benchmark.** Điểm mới có thể là kết hợp **mô hình có sẵn + nhận diện offline + UX thích ứng + nghiên cứu thực nghiệm** cho một phạm vi từ vựng được định nghĩa rõ.

### 1.4. Câu hỏi nghiên cứu (Research Questions)

| Mã | Câu hỏi | Phép đo / bằng chứng |
|---|---|---|
| RQ1 | Mô hình có thể nhận diện bao nhiêu ký hiệu trong tập mục tiêu trên điện thoại? | Test set tách người thực hiện, precision/recall/F1, confusion matrix |
| RQ2 | Hệ thống camera→kết quả có đáp ứng tương tác gần thời gian thực? | p50/p95 inference ms, p50/p95 end-to-end ms, UI frame times |
| RQ3 | Khi mất mạng, phần tính năng cốt lõi còn hoạt động? | Kịch bản airplane mode và log kiểm thử |
| RQ4 | Bộ lọc thời gian/ngưỡng tự tin có làm giảm dự đoán nhấp nháy? | So sánh raw prediction và smoothing trên cùng tập thử |
| RQ5 | Người dùng có hoàn thành tác vụ cơ bản dễ dàng? | Task completion rate, thời gian thao tác, bảng hỏi ngắn, phản hồi định tính |

**Giả thuyết cần kiểm chứng:** Dùng một bộ lọc dự đoán theo thời gian sẽ giảm số lần đổi nhãn sai so với xuất kết quả trực tiếp từng frame, với chi phí tăng độ trễ chấp nhận được.

---

## 2. PHẠM VI SẢN PHẨM (KIỂM SOÁT SCOPE)

### 2.1. MVP: BẮT BUỘC

| ID | Chức năng | Mô tả hành vi người dùng | Offline | Ưu tiên |
|---|---|---|---|---|
| F01 | Onboarding & quyền truy cập | Giải thích AI, quyền camera/mic; tiếp tục không cần đăng ký | ✅ | P0 |
| F02 | Camera nhận diện | Mở camera, pause/resume, overlay bàn tay nếu model dùng landmark | ✅ | P0 |
| F03 | TFLite inference | Suy luận model thật, ánh xạ label, confidence, trạng thái unknown | ✅ | P0 |
| F04 | Phụ đề & phát âm | Hiện ký hiệu nhận diện, cho phép xác nhận và phát TTS | ✅* | P0 |
| F05 | Từ điển | Danh sách/tìm kiếm ký hiệu và mô tả, minh họa có bản quyền hợp lệ | ✅ | P0 |
| F06 | Lịch sử | Lưu kết quả đã xác nhận, xem/xóa, không tự lưu video camera | ✅ | P0 |
| F07 | Cài đặt | Theme, tốc độ phát, haptic, xóa dữ liệu, quyền riêng tư | ✅ | P1 |
| F08 | Supabase sync | Đồng bộ lịch sử/tiến độ đã cho phép; xử lý mạng mất/khôi phục | ✅** | P0 |
| F09 | Test & observability | Test, log lỗi không chứa ảnh/âm thanh cá nhân, benchmark | ✅ | P0 |
| F10 | CI/CD Release | Build signed APK/AAB bằng pipeline bảo vệ secrets | N/A | P0 |

\* TTS offline phụ thuộc engine/giọng đã được cài trên thiết bị; phải kiểm tra và cung cấp fallback text.  
\** App tiếp tục chạy offline; việc đồng bộ chỉ xảy ra khi online.

### 2.2. MỞ RỘNG NẾU CÒN THỜI GIAN (KHÔNG ĐƯỢC CHẶN MVP)

- [ ] **Text → ký hiệu minh họa** bằng clip/GIF/video **đúng từng mục từ đã có nguồn xác minh**, không hứa dịch mọi câu.
- [ ] **Voice → text → tra ký hiệu** (offline chỉ khi engine STT và bộ tiếng Việt offline được xác minh trên thiết bị).
- [ ] Chế độ luyện tập: xem mẫu → làm ký hiệu → AI đối chiếu → feedback.
- [ ] Hỗ trợ ký hiệu động với model temporal thực sự (LSTM/Transformer/TCN hoặc mô hình chuỗi đã cung cấp).
- [ ] Cloud LLM chỉnh câu qua API/Edge Function có thông báo rõ chỉ hoạt động online, có opt-in, không gửi video, không tự đổi ý nghĩa nhãn gốc.
- [ ] Đa ngôn ngữ giao diện; bổ sung iOS features đặc thù.

### 2.3. KHÔNG LÀM TRONG ĐỒ ÁN NÀY

- Huấn luyện mô hình quy mô lớn từ đầu hoặc thu thập lại toàn bộ dataset.
- Dịch ngôn ngữ ký hiệu tự do/hội thoại liên tục không giới hạn từ vựng.
- Sinh avatar 3D biểu đạt chuẩn ngôn ngữ ký hiệu từ câu tiếng Việt tự do.
- Tích hợp chat xã hội, livestream, video call hoặc nền tảng mạng xã hội.
- Thuê server riêng để upload và xử lý video trực tiếp.

---

## 3. 5 TIÊU CHUẨN BẮT BUỘC VÀ BẰNG CHỨNG NGHIỆM THU

| Tiêu chuẩn | Cách làm | Bằng chứng bàn giao |
|---|---|---|
| Clean Architecture | 3 lớp + dependency inversion + repository interface trong Domain | Cấu trúc source, review import, unit tests |
| AI thực sự | MediaPipe/TFLite xử lý camera, model được kiểm tra output với test vectors | Video demo máy thật, artifact model, accuracy/latency report |
| Offline-First | SQLite là nguồn hiển thị chính, outbox sync Supabase | Demo airplane mode, restart app, reconnect & reconcile |
| Mobile UX | Material 3, Dark Mode, typography dễ đọc, UI 60fps mục tiêu | Widget/golden tests khi phù hợp, DevTools profile logs |
| Fastlane CI/CD | Workflow test → build release → ký bằng secrets → lưu artifact | GitHub Actions logs và signed APK/AAB cài được |

**Điều kiện bắt buộc trước khi nói “đạt”:** phải có bằng chứng từ **máy thật** hoặc CI. Chưa đo thì ghi “chưa đo”, không điền chỉ số giả.

---

## 4. KIẾN TRÚC KỸ THUẬT

### 4.1. Luồng dependency (một chiều)

```text
┌─────────────────────────────────────────────────────┐
│ PRESENTATION                                        │
│ Flutter UI, Riverpod Notifier/Provider, Routing    │
└──────────────────────┬──────────────────────────────┘
                       │ gọi Use Cases
                       ▼
┌─────────────────────────────────────────────────────┐
│ DOMAIN (PURE DART)                                  │
│ Entities, Value Objects, Repo Interfaces, Use Cases│
│ Rules: prediction smoothing, threshold, validation │
└──────────────────────▲──────────────────────────────┘
                       │ implements interfaces
┌──────────────────────┴──────────────────────────────┐
│ DATA                                                │
│ Repository Impl, SQLite/Drift, Supabase, Camera/AI   │
│ adapter, TFLite interpreter, native platform bridge │
└─────────────────────────────────────────────────────┘
```

- **Domain:** không import `flutter`, `material.dart`, Riverpod, Drift, Supabase, MediaPipe, TFLite. Chỉ Dart thuần và kiểu dữ liệu nội tại; có thể dùng gói Dart thuần nếu được kiểm soát.
- **Data:** implement interface Domain; quản lý đọc/ghi SQLite, sync cloud, camera native adapter, model lifecycle, speech adapters.
- **Presentation:** widgets, theme, routing, permission dialog, states; không viết SQL, không khởi tạo model interpreter, không parse native camera frames trong widgets.
- **Composition root/DI:** nằm ở `lib/app/` hoặc vùng bootstrap; **không** đưa UI dependency vào Domain.
- **Dữ liệu UI lấy từ local repository**; không ràng buộc trực tiếp widget vào `supabase.from(...).select()`.

### 4.2. Cấu trúc thư mục đề xuất

```text
lingosign_ai/
├── AGENTS.md                      # Hướng dẫn thường trực cho Codex
├── PLAN.md                        # File kế hoạch này
├── README.md
├── docs/
│   ├── research/                   # RQ, methodology, experiments
│   ├── architecture/               # ADR, sơ đồ, contracts
│   ├── milestones/                 # Báo cáo/ảnh minh chứng M1..M4
│   ├── testing/                    # Kế hoạch test, device matrix
│   └── releases/                   # Release notes / checklist
├── assets/
│   ├── models/                     # .tflite/.task (nếu giấy phép cho phép)
│   ├── labels/                     # label_map.json
│   ├── seed/                       # Từ điển seed có nguồn hợp lệ
│   └── sign_media/                 # Ảnh/video ký hiệu đã xác minh
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   ├── theme/
│   │   └── di/                      # Riverpod provider wiring
│   ├── core/
│   │   ├── errors/
│   │   ├── logging/
│   │   ├── result/
│   │   └── utils/
│   └── features/
│       ├── recognition/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   └── usecases/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   ├── models/
│       │   │   ├── adapters/        # Landmark detector / model runner
│       │   │   └── repositories/
│       │   └── presentation/
│       │       ├── providers/
│       │       ├── pages/
│       │       └── widgets/
│       ├── dictionary/             # domain / data / presentation
│       ├── history/                # domain / data / presentation
│       ├── sync/                   # domain / data / presentation
│       ├── speech/                 # domain / data / presentation
│       └── settings/               # domain / data / presentation
├── test/
│   ├── domain/
│   ├── data/
│   ├── presentation/
│   └── fixtures/
├── integration_test/
├── android/
│   └── fastlane/
├── ios/
│   └── fastlane/                    # Chỉ hoàn tất khi có điều kiện ký iOS
├── supabase/
│   ├── migrations/
│   └── tests/
├── scripts/
└── .github/workflows/
    ├── ci.yml
    └── release_android.yml
```

**Quy tắc giảm độ phức tạp:** không bắt buộc tạo tất cả file rỗng ngay. Chỉ tạo khi có implementation hoặc testcase thật. Có thể dùng feature-first với 3 lớp bên trong mỗi feature như trên.

### 4.3. Các interface Domain nên có

```dart
// Chỉ là hợp đồng kiến trúc, Codex sẽ hoàn thiện theo model thật.
abstract interface class SignRecognitionRepository {
  Stream<RecognitionPrediction> recognize();
  Future<void> start();
  Future<void> stop();
}

abstract interface class SignDictionaryRepository {
  Future<List<SignEntry>> search(String query);
  Future<SignEntry?> findByCode(String code);
}

abstract interface class RecognitionHistoryRepository {
  Stream<List<RecognitionRecord>> watchHistory();
  Future<void> saveConfirmed(RecognitionRecord record);
  Future<void> delete(String id);
}

abstract interface class SyncRepository {
  Future<SyncResult> synchronize();
}
```

- `RecognitionPrediction`: `labelId`, `confidence`, `timestamp`, `isStable`; `unknown` là trạng thái hợp lệ.
- UI gọi `StartRecognition`, `StopRecognition`, `ConfirmRecognition`, `GetDictionaryEntries`, `SyncPendingChanges`.
- Camera frame / image bytes **không** nhất thiết đi xuyên qua toàn bộ Domain: expose typed predictions qua adapter. Nếu logic temporal smoothing cần raw frames/landmarks thì chỉ chuyển DTO thuần Dart đủ dùng.
- Cho phép mock mọi interface để chạy test không cần camera, TFLite, Supabase.

### 4.4. Quy trình nhận diện cốt lõi

```text
Camera Preview
     ↓
Frame capture (Android CameraX / iOS AVFoundation hoặc camera plugin)
     ↓
Giảm kích thước / kiểm soát frame backlog / xoay ảnh / mirror
     ↓
[Nhánh A] model nhận landmarks:
  MediaPipe Hand Landmarker → chuẩn hóa landmarks → TFLite classifier
[Nhánh B] model nhận RGB:
  preprocess ảnh theo metadata model → TFLite model trực tiếp
     ↓
Logits/probabilities + label mapping (đúng label order)
     ↓
Threshold + temporal smoothing + cooldown + Unknown
     ↓
Stable candidate → người dùng xác nhận (nếu cần)
     ↓
Subtitle + TTS + optional haptic + SQLite history
```

**Quan trọng:** Không mặc định dùng góc ngón tay để thay mô hình đã huấn luyện. Góc/khoảng cách chỉ là **feature engineering hoặc baseline** nếu phù hợp với dữ liệu. Mô hình ký hiệu động cần cửa sổ chuỗi frames. Chỉ nhận diện bàn tay có thể thiếu thông tin chuyển động, hướng, khuôn mặt hoặc vị trí cơ thể.

### 4.5. Mục tiêu hiệu năng và cách kiểm chứng

- **Mục tiêu UI:** 60fps trên máy mục tiêu; tối ưu jank bằng Flutter DevTools trong **profile/release mode**, không kết luận từ debug mode.
- **Inference FPS ≠ UI FPS**: có thể nhận 15–30 predictions/giây nhưng giao diện vẫn hiển thị 60fps. Không đòi suy luận đủ 60fps nếu máy không đáp ứng.
- **Mục tiêu tham khảo:** p95 end-to-end `< 300ms` cho bộ ký hiệu tĩnh, cần đo và điều chỉnh theo khả năng máy; `< 100ms` là mục tiêu tham vọng **không cam kết trước**.
- **Frame policy:** chỉ xử lý frame mới nhất, bỏ frame cũ khi AI bận (backpressure); không queue camera frames vô hạn.
- **Lifecycle:** start/stop/pause/resume, đổi camera, chuyển màn hình, background/foreground phải giải phóng đúng tài nguyên.
- **Không mặc định isolate giúp native nhanh hơn:** khảo sát phần native callback, thread, FFI và chi phí copy buffers; đo trước/sau tối ưu.

---

## 5. THIẾT KẾ SQLITE + DRIFT + SUPABASE (OFFLINE-FIRST)

### 5.1. Nguyên tắc vận hành

1. **SQLite là nguồn dữ liệu chính cho giao diện**; đọc từ local ngay khi mở app.
2. Mọi thao tác ghi trước hết là **SQLite transaction**; nếu là dữ liệu đồng bộ thì tạo `pending_sync_op` trong **cùng transaction**.
3. `SyncWorker` đẩy outbox khi online, xử lý retry theo backoff và pull thay đổi từ server vào SQLite.
4. Mất mạng / app bị tắt / server lỗi **không mất dữ liệu local**.
5. Không xóa outbox trước khi server xác nhận. Mỗi operation cần idempotency key, sync cursor và cơ chế chống ghi trùng.
6. **Catalog ký hiệu** ưu tiên server → local (read-only đối với người dùng); **lịch sử đã xác nhận** có thể local-only mặc định và chỉ sync khi người dùng đăng nhập + đồng ý.
7. Guest mode luôn dùng được; đăng nhập chỉ thêm khả năng sync liên thiết bị.

### 5.2. SQLite schema (đề xuất)

| Bảng | Trường chính | Mục đích |
|---|---|---|
| `sign_entries` | `id`, `code`, `label_vi`, `description`, `media_local_path`, `catalog_version`, `updated_at` | Từ điển đã seed |
| `recognition_history` | `id` (UUID), `user_id?`, `sign_code`, `confidence`, `recognized_at`, `confirmed`, `updated_at`, `deleted_at?` | Lịch sử được xác nhận |
| `learning_progress` | `id`, `sign_code`, `practice_count`, `last_practiced_at`, `updated_at` | Tiến độ học (nếu làm) |
| `settings` | `key`, `value_json`, `updated_at` | Cài đặt local |
| `pending_sync_ops` | `op_id` (UUID), `entity`, `entity_id`, `type`, `payload_json`, `created_at`, `retry_count`, `last_error?` | Outbox sync |
| `sync_state` | `collection`, `last_cursor`, `last_success_at` | Mốc pull incremental |

**Migrations:** Drift quản lý tăng `schemaVersion` và migration; phải kiểm thử nâng phiên bản DB mà không mất lịch sử. Định dạng timestamps UTC ISO-8601 hoặc milliseconds nhất quán.

### 5.3. Supabase schema & bảo mật

- `sign_catalog`: nội dung công khai được quản trị (read-only cho người dùng bình thường), có trường `catalog_version`.
- `user_history`: lưu theo `owner_id`, mỗi bản ghi có UUID, `updated_at`, `deleted_at` (tombstone) và metadata sync.
- `user_progress` (nếu có): đồng bộ theo user.
- **Bật Row Level Security (RLS)**; policy `auth.uid() = owner_id` cho dữ liệu riêng tư; catalog chỉ có quyền đọc công khai theo chính sách đã thống nhất.
- Chỉ dùng **publishable/anon key** ở app client; **không** nhúng Supabase `service_role` vào ứng dụng.
- Không upload raw camera/microphone, landmarks nhạy cảm, ảnh người dùng trừ khi có một tính năng khác được người dùng đồng ý rõ ràng.
- Cân nhắc xóa account, xóa cloud data và quyền rút đồng ý sync.

### 5.4. Quy tắc conflict và sync

- `sign_catalog`: dữ liệu version mới trên server ghi đè cache local; seed được giữ khi hoàn toàn offline.
- `recognition_history`: event/record có UUID bất biến; update khi xác nhận, xóa bằng `deleted_at`; server chỉ chấp nhận bản ghi của đúng `owner_id`. Có thể dùng LWW theo `updated_at` *nếu xử lý clock skew*, hoặc server-assigned revision. Chọn một chiến lược và ghi ADR.
- `learning_progress`: nếu là `practice_count`, **không dùng LWW đơn giản** gây mất lượt. Ưu tiên sync các sự kiện practice có UUID rồi tổng hợp, hoặc giải pháp merge đã định nghĩa rõ.
- Tự động retry khi mạng trở lại; có nút sync thủ công và trạng thái `local only` / `pending` / `synced` / `error`.

### 5.5. 6 kịch bản bắt buộc của Offline-First

- [ ] Tắt Wi-Fi/4G trước khi mở app: xem từ điển, camera AI, lịch sử bình thường.
- [ ] Nhận diện và xác nhận 3 ký hiệu khi offline, thoát app, mở lại vẫn còn lịch sử.
- [ ] Offline tạo 1 bản ghi, online lại: sync đúng 1 lần, không trùng.
- [ ] Cúp mạng giữa lúc push: retry, không mất/nhân đôi dữ liệu.
- [ ] Offline xóa lịch sử: sau reconnect cloud không hồi sinh bản ghi đã xóa.
- [ ] Đồng bộ catalog mới nhưng app offline lâu: vẫn đọc bản đã seed, online thì cập nhật phiên bản.

---

## 6. THIẾT KẾ TRẢI NGHIỆM & MÀN HÌNH

### 6.1. Navigation dự kiến

```text
App
├── Onboarding & Permissions
└── Main Shell (Bottom Navigation)
    ├── Nhận diện
    │   ├── Camera View
    │   ├── Prediction Overlay + Unknown / Confidence
    │   └── Xác nhận / Phát âm / Lưu
    ├── Từ điển
    │   ├── Tìm kiếm / lọc
    │   └── Chi tiết ký hiệu + media
    ├── Lịch sử
    │   └── Xem / phát lại / xóa / trạng thái sync
    └── Cài đặt
        ├── Theme / Accessibility / TTS
        ├── Tài khoản & Sync (không bắt buộc đăng nhập)
        └── Quyền riêng tư / Xóa dữ liệu
```

### 6.2. Checklist UX

- [ ] Material 3 + màu sắc qua `ColorScheme`, hỗ trợ Light/Dark theo hệ thống.
- [ ] Font/subtitle đủ lớn, độ tương phản tốt, hỗ trợ text scaling; không chỉ dùng màu để thể hiện kết quả.
- [ ] Permission camera/mic được hỏi **theo ngữ cảnh sử dụng**; từ chối permission vẫn vào được từ điển.
- [ ] Các trạng thái: `loading`, `camera denied`, `model unavailable`, `no hands`, `unknown`, `stable detected`, `offline`, `sync pending`, `sync error`.
- [ ] TTS không tự phát liên tục khi nhãn dao động; chỉ phát khi nhãn ổn định / người dùng bấm.
- [ ] Rung có thể bật/tắt; không rung liên tục khi camera quét.
- [ ] Camera UI tự xử lý orientation, mirror khi camera trước, overlay tỷ lệ đúng.
- [ ] Trang cài đặt có thông điệp minh bạch: đây là công cụ hỗ trợ, không phải phiên dịch viên ngôn ngữ ký hiệu toàn năng.

---

## 7. LỘ TRÌNH 13 TUẦN VÀ 4 MILESTONES

> Dùng checklist này như bảng tiến độ chính. **Không làm màn hình tiếp theo khi DoD của màn hình hiện tại chưa đạt.** Mỗi milestone phải có commit/tag, ảnh/demo và báo cáo minh chứng.

### GIAI ĐOẠN 1 — TUẦN 1–4: KHẢO SÁT, KIẾN TRÚC, PROTOTYPE (MILESTONE 1)

#### Tuần 1: Đặc tả nghiên cứu + kiểm tra đầu vào AI

- [ ] Viết `docs/research/problem_statement.md`: người dùng, pain points, giới hạn và RQ1–RQ5.
- [ ] Tạo bảng khảo sát **3–5 ứng dụng/giải pháp liên quan** với dẫn nguồn kiểm chứng: offline, kiểu nhận diện, ký hiệu hỗ trợ, giao diện, giới hạn; không tự suy đoán năng lực đối thủ.
- [ ] Kiểm kê dataset/model bằng `docs/research/model_contract.md`: format, input/output shapes, dtype, preprocessing, labels, model version, nguồn và licence.
- [ ] Chốt target Android SDK/iOS deployment, thiết bị demo, ràng buộc bản quyền video ký hiệu.
- [ ] Viết `docs/architecture/adr-001-stack.md` và sơ đồ hệ thống.
- [ ] Tạo repo + `.gitignore`, license phù hợp, issue board, bảo vệ nhánh `main` nếu có thể.

**DoD:** Có phạm vi 10–30 ký hiệu hoặc số lượng thực tế phù hợp model, có model contract đủ để Codex viết adapter, rõ AI inference input là ảnh hay landmarks.

#### Tuần 2: Flutter skeleton & Domain

- [ ] `flutter create` với app id/package name ổn định; cấu hình Android/iOS, lints, format.
- [ ] Tạo `app/`, theme Material 3, router, Riverpod DI, navigation cơ bản.
- [ ] Khởi tạo cấu trúc Clean Architecture và entities/interfaces/usecases Domain.
- [ ] Viết unit tests đầu tiên: threshold, stable predictions, unknown, save history use case.
- [ ] Tạo 4 màn hình skeleton **dùng dữ liệu giả minh bạch (mock)**; tách demo mock khỏi release.
- [ ] Pipeline CI cơ bản `flutter analyze`, `flutter test` chạy trên PR.

**DoD:** App mở được, navigation đúng, code clean, tests cơ bản xanh. UI chưa gọi cloud trực tiếp.

#### Tuần 3: SQLite & bộ từ điển offline

- [ ] Cài Drift/SQLite, schema v1, seed catalog từ asset hợp lệ.
- [ ] Repository từ điển + trang danh sách/tìm kiếm/chi tiết.
- [ ] Repository lịch sử + lưu/xem/xóa, giao diện local-only.
- [ ] DB migration test + DAO/repository tests bằng SQLite test DB.
- [ ] Kiểm tra hoàn toàn không mạng từ lần khởi chạy đầu tiên sau khi đã có assets.

**DoD:** Từ điển và lịch sử đọc/ghi SQLite thật, không mock; data sống qua restart.

#### Tuần 4: Camera/AI proof-of-concept + báo cáo M1

- [ ] Permission camera + preview máy Android thật.
- [ ] Load model ở chế độ thử nghiệm (test vector hoặc 1 sample thật), in shapes và expected output một cách kiểm soát.
- [ ] Nếu model landmark-based: đưa MediaPipe Hand Landmarker vào pipeline tối thiểu và mapping 21 landmarks đúng thứ tự.
- [ ] Nếu model image-based: preprocess đúng shape/color/normalize mà không lắp MediaPipe sai quy trình.
- [ ] Có **ít nhất một inference thật trên máy**, dù UI chưa đẹp.
- [ ] Soạn `docs/milestones/M1_week04.md`, ảnh, demo ngắn, tag `m1-week4`.

**DoD M1:** Có ứng dụng nền tảng Flutter + Domain/Data/Presentation + local DB + một đường infer AI thật hoặc biên bản blocker rõ ràng nếu artifact model chưa dùng được. Không gọi mock là AI.

### GIAI ĐOẠN 2 — TUẦN 5–8: AI REAL-TIME, UX, OFFLINE-FIRST (MILESTONE 2)

#### Tuần 5: Hoàn chỉnh AI adapter

- [ ] Viết `LandmarkDetectorAdapter` (nếu cần), `ModelInferenceAdapter` và `RecognitionRepositoryImpl`.
- [ ] Kiểm soát camera rotation/mirror, 1 tay/2 tay theo model, normalized coordinates.
- [ ] Xác thực label map bằng ít nhất 5 test samples đã biết đầu ra.
- [ ] Bọc errors model load, unsupported tensor, no hands, permission denied.
- [ ] Phân tách pipeline native/native callbacks và UI stream; không block main thread.

**DoD:** Dự đoán model thật liên tục (chưa yêu cầu perfect accuracy), UI không treo khi mở/đóng camera.

#### Tuần 6: Prediction stabilization + TTS + UI nhận diện

- [ ] Implement `ThresholdPrediction`, `TemporalSmoothing`, `PredictionCooldown` theo giả thuyết đã định.
- [ ] Có trạng thái unknown để tránh dự đoán tùy tiện và hiển thị confidence nếu hữu ích.
- [ ] Vẽ overlay landmark **chỉ khi có data** và đúng tỷ lệ camera; đảm bảo overlay không che nội dung chính.
- [ ] Tích hợp TTS, kiểm tra có giọng Việt on-device hay không; fallback không TTS.
- [ ] Nút xác nhận / lưu lịch sử / bật rung.
- [ ] Unit tests cho threshold, smoothing, duplicate suppression, stream lifecycle.

**DoD:** Camera → model → kết quả ổn định → chữ → phát âm thủ công → lưu lịch sử local.

#### Tuần 7: Supabase + sync outbox

- [ ] Thiết lập Supabase Auth tùy chọn + schema migration SQL.
- [ ] Bật RLS cho bảng user, kiểm tra user A không đọc/ghi dữ liệu user B.
- [ ] Viết local outbox, incremental pull, sync status, retry/backoff, delete tombstone.
- [ ] Áp dụng nguyên tắc guest-first: người không đăng nhập vẫn dùng AI + từ điển.
- [ ] Chạy toàn bộ 6 bài kiểm thử offline ở mục 5.5 và lưu evidence.

**DoD:** Có demo offline → lưu → reconnect → đồng bộ không nhân bản.

#### Tuần 8: UX polish + báo cáo M2

- [ ] Hoàn thiện Material 3 Dark Mode, responsive layout, text scaling, error states.
- [ ] Chạy Flutter profile mode trên máy thật; đo `UI frame time`, `inference time`, `end-to-end time`.
- [ ] Dọn warnings/crashes; thêm test happy path / denial / airplane mode.
- [ ] Viết M2: chức năng hoàn thành, demo và kết quả đo sơ bộ; tag `m2-week8`.

**DoD M2:** **End-to-end MVP** chạy trên Android thật, dữ liệu offline + sync thật, có log hiệu năng thật.

### GIAI ĐOẠN 3 — TUẦN 9–11: ĐÁNH GIÁ KHOA HỌC VÀ KIỂM THỬ (MILESTONE 3)

#### Tuần 9: Bộ test thực nghiệm AI

- [ ] Xây evaluation protocol từ dữ liệu được phép: tách người test không xuất hiện trong train nếu có thể, ánh sáng, nền, khoảng cách, tay thuận.
- [ ] Định nghĩa rõ `supported sign set` và `unknown/reject` cases.
- [ ] Đo per-class precision/recall/F1, macro-F1, confusion matrix; phân biệt model-level với end-to-end.
- [ ] So sánh **baseline không smoothing** với **có smoothing** trên cùng bộ thử.
- [ ] Ghi lại các tình huống sai, không tự sửa thủ công nhãn trong báo cáo.

**DoD:** Có `docs/research/experiments.md`, bảng kết quả và tập test/công cụ tái lập hoặc hướng dẫn tái lập (đảm bảo quyền riêng tư).

#### Tuần 10: Reliability, accessibility, performance

- [ ] Test vòng đời camera, đổi camera, khóa màn hình, xoay màn, cấp/thu hồi quyền.
- [ ] Test offline/online lặp lại, retry, idempotency, login/logout/switch user (nếu có).
- [ ] Profile CPU, memory, camera/model initialization, frame drops, nhiệt/pin theo phương pháp và thiết bị ghi rõ.
- [ ] Widget tests dark mode, oversized text, permission denied, empty/unknown states.
- [ ] Đánh giá sử dụng với nhóm nhỏ theo đồng thuận và mục tiêu học thuật; không thu thập thông tin cá nhân không cần thiết.
- [ ] Nếu có thiết bị iOS/macOS, hoàn thiện native adapter và test iOS. Nếu không, ghi rủi ro “chưa nghiệm thu iOS thực tế”.

**DoD:** Crash/blocker quan trọng được xử lý; có device matrix và số liệu trung thực.

#### Tuần 11: Khóa feature + báo cáo M3

- [ ] Đóng tính năng v1.0; chỉ nhận bugfix từ đây.
- [ ] Kiểm tra source imports, không có God Widget, không hardcode API secret, migration ổn.
- [ ] Unit + widget + integration CI xanh.
- [ ] Báo cáo M3: kiến trúc, kỹ thuật AI, test, RQ, giới hạn; tag `m3-week11`.

**DoD M3:** Release candidate đủ ổn định, phép đo nghiên cứu có thể bảo vệ, không còn tính năng cốt lõi chỉ là giả lập.

### GIAI ĐOẠN 4 — TUẦN 12–13: CI/CD, PHÁT HÀNH, BẢO VỆ (MILESTONE 4)

#### Tuần 12: Release engineering

- [ ] Cấu hình signing release Android, **keystore và mật khẩu chỉ qua local untracked hoặc GitHub Secrets**.
- [ ] `android/fastlane/Fastfile`: lane build/test/release artifact, không tự xuất bản store trừ khi được yêu cầu.
- [ ] `.github/workflows/release_android.yml` build signed APK/AAB qua secrets an toàn.
- [ ] Test cài signed APK trên máy thật, mở camera, AI, SQLite, offline, TTS; bản Release khác Debug.
- [ ] Ghi SHA/version/code, artifact và release notes.
- [ ] Với iOS: nếu có điều kiện hợp lệ, Fastlane signing IPA trên runner macOS có chứng chỉ/profiles; không khẳng định iOS release thành công nếu chưa build.

**DoD:** Có signed Android release artifact từ CI và bản cài trên thiết bị thật.

#### Tuần 13: Đóng gói và bảo vệ

- [ ] Chuẩn hóa README: mục tiêu, đối tượng, setup, lệnh chạy, kiến trúc, screenshots, giới hạn.
- [ ] Hoàn thiện báo cáo M4 và báo cáo tổng kết, kết quả 5 tiêu chuẩn.
- [ ] Soạn slide demo 5–7 phút, phân vai, dự phòng video demo khi môi trường camera bất lợi.
- [ ] Chạy demo cuối trên **máy thật với airplane mode**, rồi bật mạng sync lại.
- [ ] Demo GitHub Actions ký release, test logs, sơ đồ Clean Architecture, test report, nghiên cứu AI.
- [ ] Tag `v1.0.0`, backup source/reports, checklist nộp bài.

**DoD M4:** Đủ **4 báo cáo M1, M2, M3, M4**, mã nguồn, test, release, video/demo máy thật và số liệu đánh giá.

---

## 8. BACKLOG DÙNG ĐỂ GIAO CODEX THEO VERTICAL SLICES

> **Quy tắc:** Mỗi task chỉ giao một phạm vi nhỏ, có input/output, yêu cầu test và tiêu chí nghiệm thu. Không dùng câu lệnh “hãy viết toàn bộ ứng dụng”.

| Task ID | Công việc | Phụ thuộc | Mức | Kiểm chứng hoàn thành |
|---|---|---|---|---|
| TASK-001 | Scaffold Flutter, lint, router, DI, theme | Không | P0 | `flutter analyze`, `flutter test` xanh |
| TASK-002 | Domain entities, repository ports, usecases | 001 | P0 | Unit tests, không import Flutter |
| TASK-003 | SQLite/Drift schema, migrations, seed | 002 | P0 | CRUD + restart + migration tests |
| TASK-004 | Dictionary list/detail/search UI | 003 | P0 | Widget tests + offline |
| TASK-005 | History local CRUD + UI | 003 | P0 | Unit/widget tests |
| TASK-006 | Camera + permissions | 001 | P0 | Chạy máy thật, start/stop |
| TASK-007 | Inspect model metadata & add AI adapter | 002,006 | P0 | Test vectors từ model thật |
| TASK-008 | Continuous inference + lifecycle | 007 | P0 | Stream không treo, no frame backlog |
| TASK-009 | Smoothing + unknown + overlay | 008 | P0 | Domain tests + preview |
| TASK-010 | TTS + haptics + confirmation | 005,009 | P0 | Test fallback/duplicate |
| TASK-011 | Supabase RLS schema + Auth opt-in | 003 | P0 | SQL RLS tests |
| TASK-012 | Sync outbox & recovery | 005,011 | P0 | 6 offline tests |
| TASK-013 | Dark Mode + accessibility polish | 004,009 | P0 | Widget + manual audit |
| TASK-014 | Benchmarks, accuracy evaluation | 008–013 | P0 | CSV/JSON metrics + report |
| TASK-015 | CI, Fastlane, Android signing | 001 | P0 | Signed release built by CI |
| TASK-016 | Integration/regression test suite | 004–013 | P0 | Main flows tested |
| TASK-017 | Text→validated sign clip | 004 | P2 | Clip nguồn hợp lệ, offline |
| TASK-018 | Speech-to-text→sign lookup | 017 | P2 | Mic consent + engine check |
| TASK-019 | LLM cloud optional | 009 | P3 | Online-only, privacy, no raw video |
| TASK-020 | iOS native adapter & IPA release | 007,015 | P1* | Build/test trên macOS/máy iPhone |

\* Với yêu cầu bắt buộc phải chạy đủ **Android + iOS**, TASK-020 trở thành **P0**, phải chuẩn bị phần cứng/chứng chỉ trước Tuần 4.

### Trạng thái thực thi đã xác minh

- [x] TASK-001 — Flutter scaffold, lint, router, Riverpod DI và Material 3 light/dark. `flutter analyze` sạch; 2 widget tests pass ngày 17/10/2026. Build APK debug chưa xác minh do Android NDK chưa tải xong; xem `docs/agent/TEST_EVIDENCE.md`.
- [x] TASK-002 — Domain entities, repository ports và use cases thuần Dart. 6 unit tests mới pass; `flutter analyze` sạch; không có import framework/infra trong `domain/` ngày 17/10/2026.
- [ ] TASK-003 — SQLite/Drift schema, migrations, seed; nội dung seed chờ danh mục có nguồn xác minh.

---

## 9. KẾ HOẠCH KIỂM THỬ VÀ CHỈ SỐ NGHIÊN CỨU

### 9.1. Unit Test Domain (mục tiêu 100% các Use Cases quan trọng)

- [ ] `StartRecognition`: một lần start, start lại, lỗi permission, lỗi model.
- [ ] `StabilizePrediction`: threshold, tie, không có tay, nhãn dao động, cooldown.
- [ ] `ConfirmRecognition`: thêm lịch sử đúng một lần, timestamp, invalid sign code.
- [ ] `GetDictionaryEntries`: query rỗng, query không khớp, Unicode tiếng Việt.
- [ ] `SyncPendingChanges`: offline, duplicate retry, timeout, conflict, tombstone.
- [ ] Kiểm tra **coverage domain usecases mục tiêu 100%**, không dùng coverage để thay thế kiểm thử thực tế.

### 9.2. Widget & integration tests

- [ ] Dark/Light themes, text scaling lớn, fallback mic/camera permission.
- [ ] Từ điển tìm kiếm, vào chi tiết, empty state.
- [ ] Mở nhận diện với fake adapter → nhận subtitle stable/unknown.
- [ ] Lưu bản ghi → hiện History → xóa → refresh.
- [ ] Integration test: install → offline → camera → confirm → close/reopen → reconnect/sync (phần native camera chạy máy thật).

### 9.3. Chỉ số đo và mẫu log

| Nhóm | Metric | Cách ghi |
|---|---|---|
| Chất lượng AI | Accuracy, macro precision/recall/F1, confusion matrix | Tập test độc lập, nêu số mẫu, người thực hiện |
| Độ trễ | p50/p95 inference, preprocessing, end-to-end (ms) | `Stopwatch`/native timestamps đúng đoạn, đủ số lượt |
| UI | median/p95 frame build/raster times, % janky frames | Flutter DevTools profile mode |
| Tài nguyên | CPU, memory, nhiệt, battery drain | Mẫu thiết bị và khoảng thời gian nhất quán |
| Offline | % testcase thành công, sync duplicates, lost updates | Automated/manual test logs |
| UX | Tỉ lệ hoàn thành task, thời gian tác vụ, lỗi thao tác | Test script và đồng thuận người tham gia |

**Quy tắc báo cáo số liệu:** luôn ghi **model version, app version, device, OS, số mẫu, điều kiện đo**. Không ghi “AI chính xác 95%” từ một vài lần thử trực tiếp trước camera.

### 9.4. Điều kiện tối thiểu để demo

- App không crash qua 10 chu kỳ mở/đóng camera.
- Ứng dụng không cần mạng để load model, từ điển và lịch sử.
- Dự đoán đúng ít nhất một số ký hiệu đã công bố **trong tập hỗ trợ**, có thể thể hiện `unknown` ngoài tập.
- Signed release cài được, quyền camera/TTS vận hành trên máy demo.
- Supabase không nhìn thấy raw frames/video, Supabase policy được kiểm tra.

---

## 10. GIT WORKFLOW, QUALITY GATES VÀ RELEASE

### 10.1. Quy ước Git

- `main`: luôn build/test được.
- Nhánh tác vụ: `feat/TASK-007-model-adapter`, `fix/TASK-012-sync-retry`, `test/TASK-009-smoothing`.
- Commit nhỏ: `feat(recognition): add tflite adapter with tensor validation`.
- Mỗi PR/commit task cập nhật checklist PLAN.md và README khi có thay đổi chức năng.
- Gắn tag 4 milestones và release cuối; lưu changelog ngắn.

### 10.2. Các lệnh kiểm tra dự kiến

```bash
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --coverage
flutter build apk --release
flutter build appbundle --release
```

**Không chạy build release khi chưa cấu hình signing và `model assets` chính xác.** Một lệnh build thành công **không chứng minh** model chạy đúng trên máy thật.

### 10.3. GitHub Actions + Fastlane

- Workflow `ci.yml`: checkout → setup Flutter/Dart theo phiên bản **pin** → `pub get` → format/analyze/test → báo kết quả.
- Workflow `release_android.yml`: trigger từ manual `workflow_dispatch` hoặc tag version → chạy quality gates → giải mã keystore từ GitHub Secrets → Fastlane build signed APK/AAB → upload artifacts.
- Android release keys: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` (tên gợi ý, thống nhất với workflow).
- Secrets không in ra log; file `key.properties` và `.jks` không được commit.
- CI không có secrets trên PR từ fork; giữ signing workflow riêng để tránh lộ credential.
- Không cần tự publish Google Play để đạt yêu cầu ký release, trừ khi giảng viên yêu cầu phân phối qua store.
- iOS IPA signing cần **Mac/Xcode + Apple certificates/provisioning**, thường cần Apple Developer Program nếu phát hành ngoài thiết bị thử nghiệm.

---

## 11. RỦI RO, PHƯƠNG ÁN DỰ PHÒNG VÀ THỨ TỰ ƯU TIÊN

| Mã | Rủi ro | Mức | Hành động |
|---|---|---|---|
| R01 | Chỉ có dataset, chưa có TFLite model | Rất cao | Chốt tuần 1, tạo model contract; tách nhiệm vụ export/conversion ngoài phạm vi coding app |
| R02 | Model nhận chuỗi/video nhưng nhóm làm single-frame classifier | Rất cao | Nhánh pipeline theo tensor shape; không ép model động dùng một frame |
| R03 | MediaPipe 21 landmarks không đủ cho ký hiệu cần mặt/cơ thể | Cao | Thu hẹp phạm vi ký hiệu hoặc dùng model nhiều đầu vào đã tồn tại; nêu limitation |
| R04 | Flutter plugin MediaPipe không tương thích SDK | Cao | Dùng native Android/iOS integration + Method/Event Channel, version-pinning, spike tuần 4 |
| R05 | Không có Mac/iPhone để kiểm tra iOS | Cao | Chuẩn bị thiết bị từ đầu, báo phạm vi thực nghiệm trung thực |
| R06 | Model inference gây đơ UI/nhiệt cao | Cao | Profile, giảm camera resolution, frame skipping, backpressure, delegate nếu phù hợp |
| R07 | Supabase mất mạng, conflict dữ liệu | Cao | Transactional outbox, tombstone, retry/idempotency, integration test |
| R08 | STT/TTS offline không có voice pack | Trung bình | Fallback text và tải/cài language pack theo hướng dẫn, không tự quảng cáo 100% offline voice |
| R09 | Không có nguồn ký hiệu media đáng tin/có bản quyền | Cao | Chỉ dùng bộ có xác thực, bỏ animation tự chế |
| R10 | Quá sa đà tính năng thêm, trễ 4 milestone | Cao | Đóng P0 trước Tuần 8, P2/P3 chỉ làm khi P0 xanh |
| R11 | AI đo sai/không có test set độc lập | Cao | Thiết kế evaluation từ Tuần 1, ghi số liệu và hạn chế rõ |
| R12 | Secrets bị đẩy lên GitHub | Cao | `.gitignore`, secret scan, rotate leaked keys, release pipeline tách riêng |

**Quy tắc ưu tiên nếu trễ tiến độ:** `P0 Camera + AI thật → SQLite offline → Supabase Sync → Tests → signed APK/AAB → báo cáo` rồi mới `P2/P3`.

---

## 12. QUY TRÌNH VIBE CODING VỚI CODEX

### 12.1. Cách làm ở từng task

1. Đọc **`AGENTS.md`**, **`PLAN.md`**, files liên quan và tình trạng Git trước khi sửa.
2. Nhận đúng **01 Task ID** và nêu: file định sửa, dependencies, assumptions, test plan.
3. Đọc code hiện có, **không thay mới cấu trúc đang chạy** nếu không có lý do.
4. Viết implementation **end-to-end nhỏ nhất** (Domain → Data → Presentation nếu task cần).
5. Tạo tests cho logic quan trọng; không mock test để che lỗi thật.
6. Chạy `dart format`, `flutter analyze`, `flutter test` (và device test khi làm native/camera).
7. Báo lại: files changed, cách verify, kết quả tests, giới hạn/chướng ngại.
8. Chỉ đánh dấu `[x]` khi acceptance criteria đạt; commit với Task ID.

### 12.2. Prompt khởi động (copy vào Codex)

```text
Bạn là kỹ sư Flutter senior tham gia đồ án LingoSign AI.
Đọc toàn bộ PLAN.md và AGENTS.md trong repo trước khi làm việc.
Công nghệ bắt buộc: Flutter/Dart, Clean Architecture Domain/Data/Presentation,
Riverpod, SQLite qua Drift, Supabase offline-first, MediaPipe/TFLite khi phù hợp model.

Hãy kiểm tra repository hiện tại, liệt kê:
1) Những gì đã triển khai; 2) Task IDs đã xong/chưa xong trong PLAN.md;
3) blockers và dependencies; 4) nhiệm vụ P0 nhỏ nhất nên làm tiếp.
KHÔNG tự động code mọi feature. KHÔNG thay thế AI thật bằng output hardcode.
KHÔNG tự suy đoán model input/output nếu chưa có metadata.
Chỉ đưa ra kế hoạch triển khai task tiếp theo và nêu file dự kiến sửa.
```

### 12.3. Prompt triển khai mỗi task (copy và thay ID)

```text
Thực hiện TASK-XXX theo PLAN.md.

Quy trình bắt buộc:
- Đọc code hiện tại, model contract nếu liên quan AI.
- Chỉ sửa file cần thiết, tuân thủ Clean Architecture.
- Với Use Cases phải có unit tests; với UI có widget tests hợp lý.
- Không nhúng key bí mật, không thêm package không cần thiết.
- Không viết fake AI như thể là inference thật.
- Chạy format + analyze + tests có thể chạy trong môi trường hiện tại.
- Đưa tiêu chí nghiệm thu và hướng dẫn test máy thật nếu có native camera.
- Cập nhật TASK-XXX trong PLAN.md thành [x] CHỈ KHI thực sự hoàn tất.

Cuối cùng báo cáo: files changed, design decisions, test commands/results,
known issues, next smallest Task ID.
```

### 12.4. Prompt tích hợp AI (chỉ dùng khi có model)

```text
Triển khai TASK-007 + phần tối thiểu TASK-008.
Đọc docs/research/model_contract.md và assets/models trước.
Xác nhận input tensor (shape/dtype/range), output tensor, label order,
preprocessing, RGB/landmark/temporal mode. Nếu thiếu thông tin quan trọng:
viết kết quả kiểm kê và những trường còn thiếu, KHÔNG bịa metadata.

Thiết kế AI adapter nằm trong Data layer với interface thuần Dart ở Domain.
Tạo test vector có input-output expected từ chính model được cung cấp.
Chỉ thêm MediaPipe Hand Landmarker khi model thực sự dùng landmark features.
Xử lý lifecycle, errors và không block UI.
Không tuyên bố inference realtime cho đến khi chạy trên máy thật.
```

### 12.5. Prompt Offline-First

```text
Triển khai TASK-011/TASK-012 theo thiết kế mục 5 PLAN.md.
Giao diện luôn đọc từ SQLite/Drift. Ghi local trước bằng transaction cùng outbox.
Tạo Supabase RLS theo owner_id; không dùng service_role ở client.
Viết retry, idempotency, tombstone và sync status. Đảm bảo guest mode.
Bắt buộc có tests cho: offline create, app restart, network reconnect,
retry không tạo duplicate, offline delete không bị hồi sinh.
Không chuyển UI sang gọi cloud trực tiếp.
```

### 12.6. Prompt review nghiêm ngặt trước milestone

```text
Audit toàn bộ code so với PLAN.md tại Milestone M{1|2|3|4}.
Ưu tiên phát hiện bug và sai tiêu chuẩn thay vì khen ngợi.
Kiểm tra:
- Domain import Flutter/SDK ngoài ý muốn
- UI có business logic / SQL / interpreter init
- AI giả, sai preprocessing/label map/shape
- lỗi camera lifecycle, backpressure, stream memory leak
- offline queue, RLS, xung đột sync, quyền riêng tư
- test thật, signing secrets, build release máy thật
Trả về findings theo severity, file:line, reproduction, fix plan.
Không tự khẳng định đã chạy test chưa thực thi.
```

### 12.7. Prompt cập nhật tiến độ sau phiên làm việc

```text
Đối chiếu Git diff + test results với PLAN.md. Cập nhật checkbox của các task
THỰC SỰ hoàn thành, giữ nguyên các task chưa chứng minh được. Thêm log ngắn:
Ngày, task, commit/PR, tests, blockers, task tiếp theo. Không sửa phạm vi P0
hoặc xóa requirements chỉ để tăng số lượng checkbox đã hoàn thành.
```


### 12.8. Quy tắc checkpoint / handoff / tự khôi phục phiên (BẮT BUỘC)

**Mục tiêu:** Codex có thể tiếp tục **task đang làm dở** sau khi người dùng dừng, đổi model, mở phiên mới, hoặc sắp hết context/token mà không phải yêu cầu người dùng giải thích lại. `PLAN.md` chỉ mô tả **phải làm gì**; trạng thái phiên đang thực hiện phải được lưu tại **`docs/agent/PROGRESS.md`**.

1. **Khi bắt đầu phiên:** đọc `docs/agent/PROGRESS.md` trước khi quyết định task mới, rồi đối chiếu `git status --short`, `git diff`, file thật, `PLAN.md`, test logs. Nếu không có file, tạo từ mẫu §7.5 của `SKILLS_AGENT_RUNBOOK.md`; ghi `NOT_VERIFIED` cho những điều chưa kiểm tra. Nếu file cũ sai với repo, ghi rõ khác biệt, không xóa code để khớp log.
2. **Checkpoint định kỳ:** ghi khi bắt đầu task, khi xong một bước có ý nghĩa (ví dụ Domain / DAO / UI / test), trước và sau thay đổi khó đảo ngược, khi có lỗi/blocker, sau các lệnh kiểm chứng, và sau mỗi task. **Chủ động ghi trước khi gần hết context/token** và khi nhận lệnh dừng. Không chờ đến kết thúc toàn bộ task mới ghi.
3. **Snapshot phải đủ để tiếp tục**: thời điểm, TASK ID và tình trạng (`NOT_STARTED`, `IN_PROGRESS`, `NEEDS_VERIFY`, `BLOCKED`, `DONE`); mục tiêu/tiêu chí; công việc hoàn thành **đã kiểm chứng**; đoạn/file làm dở; git branch/commit và thay đổi chưa commit; test đã chạy/chưa chạy và kết quả; blockers/quyết định đang chờ; chính xác 1–3 bước tiếp theo với file/lệnh liên quan; skill và phụ thuộc cần đọc.
4. **Resume:** ưu tiên hoàn tất task `IN_PROGRESS`/`NEEDS_VERIFY`, kiểm tra những thay đổi dang dở, rồi chạy các test còn thiếu; **không khởi tạo lại project**, không chạy lại migration nguy hiểm, không mở task mới khi task cũ chưa được chốt hoặc ghi `BLOCKED` có lý do.
5. **Không bịa trạng thái:** nếu không chạy test thì `NOT_RUN`; nếu thiếu bằng chứng thì `NOT_VERIFIED`; nếu không biết vì sao có file đang sửa thì `UNKNOWN`. `[x]` trong checklist và `DONE` chỉ dành cho việc đã đạt DoD thực sự.
6. **Giới hạn thực tế:** khi một phiên bị kill/tắt đột ngột, agent không thể ghi log sau khi đã ngừng chạy. Vì vậy checkpoint sau mỗi bước quan trọng là biện pháp dự phòng, và phiên kế tiếp luôn phải xác minh lại bằng Git/code/tests.

**Lệnh tiếp tục mặc định:** `Đọc AGENTS.md và docs/agent/PROGRESS.md, đối chiếu Git, tiếp tục từ NEXT ACTION; không làm lại phần đã xác minh.` (Agent phải thực hiện ngay cả khi người dùng chỉ nói “tiếp tục”.)

---

## 13. BỘ CHECKLIST NGHIỆM THU CUỐI

### Sản phẩm

- [ ] Android app chạy thật từ release APK/AAB đã ký.
- [ ] Mô hình AI suy luận **thật**, labels và preprocessing được kiểm tra.
- [ ] Camera, subtitle, unknown/confirm, TTS/fallback, lịch sử hoạt động.
- [ ] Từ điển và lịch sử hoạt động khi bật airplane mode và sau restart.
- [ ] Supabase sync thật khi online, RLS đúng, không lộ dữ liệu người khác.
- [ ] Dark Mode, Material 3, xử lý quyền camera, UI responsive, profile 60fps hoặc có báo cáo nếu chưa đạt.
- [ ] Android/iOS build và test theo đúng phạm vi giảng viên chấp nhận; iOS có evidence riêng nếu bắt buộc.

### Chất lượng

- [ ] Domain không import Flutter và SDK framework/DB.
- [ ] Use cases và business rules có unit tests; UI có widget tests.
- [ ] Integration tests bao phủ đường demo chính.
- [ ] `flutter analyze` và `flutter test` pass.
- [ ] Kết quả accuracy/latency có bằng chứng và giới hạn rõ ràng.
- [ ] GitHub Actions tạo artifact release, signing secrets không ở repo.

### Hồ sơ học thuật

- [ ] M1 Tuần 4, M2 Tuần 8, M3 Tuần 11, M4 Tuần 13.
- [ ] README, architecture diagram, database schema, model contract, RQs.
- [ ] Baseline/ablation smoothing và experimental protocol.
- [ ] Bảng so sánh giải pháp liên quan có nguồn.
- [ ] Demo máy thật và kịch bản mất mạng/khôi phục mạng.
- [ ] Khai báo AI hỗ trợ coding, nguồn tài liệu, giấy phép dataset/media, đóng góp thực tế của nhóm.

---

## 14. NHẬT KÝ TIẾN ĐỘ (CẬP NHẬT SAU MỖI PHIÊN CODEX)

> Bảng này chỉ là lịch sử tóm tắt theo phiên. **Checkpoint mới nhất để khôi phục công việc nằm tại `docs/agent/PROGRESS.md`**; bắt buộc cập nhật theo §12.8 ngay cả khi TASK chưa xong.

| Ngày | Task ID | Thực hiện | Test/bằng chứng | Trạng thái | Bước tiếp theo |
|---|---|---|---|---|---|
| 17/10/2026 | PLAN | Khởi tạo kế hoạch, chưa triển khai mã nguồn | File `PLAN.md` | Kế hoạch | TASK-001 + kiểm kê model |

---

## 15. TÀI LIỆU CHÍNH THỨC ĐỂ CODEX THAM CHIẾU

> Dùng tài liệu dưới đây để kiểm tra API hiện hành; khi cài dependencies phải đọc tài liệu và pin version tương thích. Không sao chép code sample lỗi thời.

- Flutter Architecture: <https://docs.flutter.dev/app-architecture>
- Flutter SQLite: <https://docs.flutter.dev/cookbook/persistence/sqlite>
- Flutter Database Choice: <https://docs.flutter.dev/data-and-backend/persistence/choose-a-database>
- Drift: <https://drift.simonbinder.eu/>
- Drift Flutter: <https://pub.dev/packages/drift_flutter>
- MediaPipe Hand Landmarker (Android): <https://developers.google.com/edge/mediapipe/solutions/vision/hand_landmarker/android>
- MediaPipe Hand Landmarker overview: <https://ai.google.dev/edge/mediapipe/solutions/vision/hand_landmarker>
- TFLite Flutter: <https://pub.dev/packages/tflite_flutter>
- Supabase Flutter: <https://supabase.com/docs/guides/getting-started/quickstarts/flutter>
- Supabase RLS: <https://supabase.com/docs/guides/database/postgres/row-level-security>
- Flutter Testing: <https://docs.flutter.dev/testing/overview>
- Flutter Performance: <https://docs.flutter.dev/perf/ui-performance>
- Flutter Continuous Delivery: <https://docs.flutter.dev/deployment/cd>
- GitHub Actions Secrets: <https://docs.github.com/en/actions/reference/security/secrets>
- Fastlane Docs: <https://docs.fastlane.tools/>

---

### GHI CHÚ CUỐI

**Success = app thật + AI thật + offline thật + test thật + release thật + báo cáo có dữ liệu thật.**  
Codex là người hỗ trợ code; nhóm chịu trách nhiệm kỹ thuật, kiểm thử, bản quyền và trung thực học thuật.  
**Task đầu tiên:** kiểm kê model (`model_contract.md`), sau đó thực hiện `TASK-001`.
