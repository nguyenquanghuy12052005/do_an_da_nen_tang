# LingoSign AI — AGENT SKILLS RUNBOOK & AUTONOMOUS EXECUTION GUIDE

> **File điều phối dành cho OpenAI Codex (và coding agent tương thích Agent Skills).**  
> **Cập nhật:** 17/10/2026 · **Dự án:** LingoSign AI · **Ngôn ngữ điều phối:** Tiếng Việt · **Mức ưu tiên:** đọc sau `AGENTS.md` và `PLAN.md`.  
> **Trạng thái:** Playbook sẵn sàng sử dụng. **Chưa khẳng định bất kỳ skill nào đã được cài**, và chưa kiểm chứng dự án đã build.  
> **Phạm vi:** Agent Skills và quy trình triển khai ứng dụng. Đây **không** phải lệnh cài các package Dart/Flutter.

---

## 0. CHỈ THỊ CHO AGENT: ĐỌC VÀ TỰ TRIỂN KHAI

**Bạn là engineering agent phụ trách ứng dụng LingoSign AI. Đây là chỉ thị vận hành, không phải tài liệu chỉ để tham khảo.**

Ngay khi mở một phiên làm việc trong repository có file này:

1. Đọc `docs/agent/PROGRESS.md` **nếu có** để biết task dở và NEXT ACTION; sau đó đọc `AGENTS.md` (ràng buộc), `PLAN.md` (phạm vi, TASK-001 đến TASK-020, milestones) và runbook này. Nếu thiếu progress, tạo bản khởi đầu theo §7.5. Không tự thiết kế lại dự án.
2. Kiểm kê **project thực tế** bằng `pwd`, `git status --short`, cây thư mục, `flutter --version`, `dart --version`, `codex --version` nếu có. Kiểm tra SDK, thiết bị, model, nhãn, quyền truy cập, plugin và `.agents/skills/`. Không tuyên bố đã cài khi chưa kiểm tra.
3. Áp dụng bộ skill **P0** được định nghĩa ở phần 3. Cài theo phần 4 **khi môi trường cho phép và các lệnh đã được cấp quyền**. Kiểm tra nguồn, nội dung, tính tương thích trước khi cài; không chạy script lạ hoặc thực hiện cài đặt bị chặn bằng cách lách quyền. Nếu không thể cài, ghi rõ blocker và dùng hướng dẫn nguồn chính thức để tiếp tục phần không phụ thuộc.
4. Trước khi viết code, chọn **TASK P0 chưa hoàn thành đầu tiên có đủ dependency** trong `PLAN.md`. Có thể làm **kiểm kê hợp đồng mô hình** trước TASK-001; kết quả lưu `docs/research/model_contract.md`. Nếu không có model thì không giả lập tính năng đã hoàn thành.
5. Với mỗi task: đọc đúng skill liên quan theo ma trận ở phần 5 → ghi kế hoạch ngắn → code một vertical slice → thêm test → chạy lệnh kiểm tra → xem diff → chỉ đánh dấu `[x]` khi có bằng chứng → cập nhật nhật ký tiến độ. Tiếp tục task tiếp theo **theo thứ tự phụ thuộc** trong thời gian phiên còn chạy và được phép, nhưng luôn xử lý **một TASK tại một thời điểm**.
6. Tự động xử lý những việc không làm thay đổi bên ngoài: đọc tài liệu, tạo code và test, chạy kiểm tra hợp lệ, cập nhật tài liệu. **Dừng tại cổng cần người thật**: chấp thuận chi phí, tài khoản/dữ liệu riêng tư, ký số/keystore, cấu hình quyền cloud, deploy/đăng Play Store, xoá dữ liệu, cài chương trình thiếu quyền, bước phải có máy thật/iOS/Mac hoặc model thật chưa có. Nêu đúng thứ còn thiếu, không hỏi lại những thông tin đã có trong repo.
7. **Không thực hiện cả 20 task một cách mù quáng**: hết một task phải qua quality gate; có bug/blocker phải sửa hoặc báo cáo rồi dừng chuỗi phụ thuộc. Không tự tạo số liệu nghiên cứu, accuracy, F1, latency, FPS, hay kết quả device test.
8. **Checkpoint không chỉ sau task:** cập nhật `docs/agent/PROGRESS.md` ngay khi bắt đầu, sau mỗi bước code/test quan trọng, khi gặp blocker và **trước khi dừng/đổi phiên/gần hết context-token**. Trả lời theo mẫu `AGENTS.md`, ghi `Next smallest action` và trạng thái blocked/unblocked. Không cần người dùng viết lại prompt cho từng task.

**Thứ tự ưu tiên khi tài liệu mâu thuẫn:** yêu cầu đồ án và các ràng buộc an toàn → `AGENTS.md` → `PLAN.md` → file này → skill chính thức Flutter/Dart/Supabase → skill Addy/third-party → ví dụ của repository. Một skill hướng MVVM 2 lớp, React/JS, server-first hoặc cloud-only không được thay thế Clean Architecture 3 lớp đã chốt.

### Bản đồ công nghệ không được tự ý thay đổi

| Phần | Chọn cho LingoSign AI | Nguyên tắc |
|---|---|---|
| Ứng dụng | Flutter + Dart | UI Material 3, Android ưu tiên máy thật; iOS nếu đủ điều kiện |
| Kiến trúc | Domain / Data / Presentation | Domain pure Dart, không import Flutter, Drift, Supabase, MediaPipe/TFLite |
| State | Riverpod | Không pha thêm BLoC để làm hai nguồn chân lý |
| Local DB | SQLite qua Drift | Local là source of truth cho UI |
| Cloud | Supabase (Auth/Postgres/RLS) | Sync tuỳ chọn/online, guest dùng được offline |
| AI | MediaPipe Hand Landmarker + model thật tương thích | MediaPipe landmarks **không phải bộ dịch ký hiệu**; không giả định input model |
| Voice | TTS offline khi engine/voice có sẵn | STT và dịch ngược là mở rộng, không chặn MVP |
| CI/CD | GitHub Actions + Fastlane | Android APK/AAB ký tự động qua secrets; iOS cần macOS/chứng chỉ |
| Nghiên cứu | accuracy/F1, latency, offline test, 60fps UI | Phải đo và lưu raw evidence trên thiết bị thật |

---

## 1. TỔNG HỢP CÁC NGUỒN GITHUB ĐÃ LỌC

Ngày đối chiếu GitHub: **17/10/2026**. Stars là **xấp xỉ của cả repo**, biến động theo thời gian; sao nhiều không tự chứng minh một skill phù hợp.

| Nguồn | Stars gần đúng | Phân loại | Quyết định |
|---|---:|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | 301k | Bộ điều phối tổng quát, TDD, debugging | **Phương án thay thế** Addy, không chạy song song 2 workflow manager |
| [anthropics/skills](https://github.com/anthropics/skills) | 182k | Kho ví dụ & `skill-creator` | **Tham khảo**, dùng khi cần tạo skill riêng |
| **[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)** | **107.5k** | 25 workflow skills, từ spec đến ship | **Chọn làm bộ quản lý quy trình chính** |
| [flutter/agent-plugins](https://github.com/flutter/agent-plugins) | 3.1k | Flutter Team chính thức | **Bắt buộc ưu tiên** |
| [supabase/agent-skills](https://github.com/supabase/agent-skills) | 2.9k | Supabase chính thức | **Bắt buộc khi bắt đầu TASK-011** |
| [dart-lang/skills](https://github.com/dart-lang/skills) | 523 | Dart Team chính thức | **Bắt buộc ưu tiên** |
| [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills) | 57 | Flutter/Riverpod/Drift chuyên sâu | **Chọn một số skill phù hợp**, kiểm duyệt trước khi cài |

Nguồn cài đặt: [Addy Codex guide](https://github.com/addyosmani/agent-skills/blob/main/docs/codex-setup.md), [Flutter hướng dẫn Codex](https://docs.flutter.dev/ai/get-started), [Dart Skills README](https://github.com/dart-lang/skills), [Supabase Skills README](https://github.com/supabase/agent-skills), [Flutter-Skills catalog](https://github.com/zakariaf/Flutter-Skills).

**Quan trọng:** Chỉ cài một bộ điều phối quy trình chính. `addyosmani/agent-skills` và `obra/superpowers` trùng nhiều phần lập kế hoạch/TDD/review; bộ Addy được chọn vì người dùng yêu cầu nghiên cứu repo này. **Không cài thêm Superpowers trong cấu hình mặc định**. Nếu Superpowers đã có, không cài Addy ồ ạt: giữ một bộ làm chính và chỉ nhập các skill bổ khuyết sau khi rà soát trùng tên.

---

## 2. CHỌN SKILL TỪ `addyosmani/agent-skills` (CÓ LỌC)

Danh mục thực tế của repo: [README / All 25 Skills](https://github.com/addyosmani/agent-skills#all-25-skills). Những skill dưới đây thuộc **repository Addy**, không phải kỹ năng Flutter chuyên biệt.

### 2.1. Nên sử dụng: 12 skill

| Tên chính xác `skills/<name>/SKILL.md` | Mức | Khi nào kích hoạt trong LingoSign AI | Phạm vi |
|---|---|---|---|
| [`context-engineering`](https://github.com/addyosmani/agent-skills/blob/main/skills/context-engineering/SKILL.md) | P0 | Khởi động/đổi task, không để quên ràng buộc | Tải đúng context, không đổ mọi skill vào cùng prompt |
| [`source-driven-development`](https://github.com/addyosmani/agent-skills/blob/main/skills/source-driven-development/SKILL.md) | P0 | Chọn package/API SDK Flutter, camera, TFLite, Supabase | Tra official docs, kiểm tra version, không bịa API |
| [`api-and-interface-design`](https://github.com/addyosmani/agent-skills/blob/main/skills/api-and-interface-design/SKILL.md) | P0 | Thiết kế Domain repository port, AI gateway, sync contract | Contract-first, typed errors, validation ở boundary |
| [`incremental-implementation`](https://github.com/addyosmani/agent-skills/blob/main/skills/incremental-implementation/SKILL.md) | P0 | **Mọi TASK code** | Vertical slice nhỏ, test, verify, rollback được |
| [`test-driven-development`](https://github.com/addyosmani/agent-skills/blob/main/skills/test-driven-development/SKILL.md) | P0 | Use Case, thuật toán smoothing, mapping, outbox | Red → green → refactor; test độc lập hạ tầng |
| [`debugging-and-error-recovery`](https://github.com/addyosmani/agent-skills/blob/main/skills/debugging-and-error-recovery/SKILL.md) | P0 | Build lỗi, test fail, camera crash, DB lỗi | Reproduce → isolate → fix → regression test |
| [`code-review-and-quality`](https://github.com/addyosmani/agent-skills/blob/main/skills/code-review-and-quality/SKILL.md) | P0 | Trước khi tick task và trước milestone | Review dependency, robustness, readability, tests |
| [`security-and-hardening`](https://github.com/addyosmani/agent-skills/blob/main/skills/security-and-hardening/SKILL.md) | P0 | Quyền camera/mic, Auth, RLS, secrets, storage | Privacy, least privilege, RLS, không đẩy camera lên cloud |
| [`git-workflow-and-versioning`](https://github.com/addyosmani/agent-skills/blob/main/skills/git-workflow-and-versioning/SKILL.md) | P0 | Mỗi thay đổi | Commit nhỏ và có thể truy vết (chỉ commit nếu được phép) |
| [`ci-cd-and-automation`](https://github.com/addyosmani/agent-skills/blob/main/skills/ci-cd-and-automation/SKILL.md) | P1 | TASK-015, milestone release | Quality gates, reproducible builds |
| [`documentation-and-adrs`](https://github.com/addyosmani/agent-skills/blob/main/skills/documentation-and-adrs/SKILL.md) | P1 | Thay đổi kiến trúc, model contract, release | Ghi **vì sao** chọn kỹ thuật, ADR và evidence |
| [`shipping-and-launch`](https://github.com/addyosmani/agent-skills/blob/main/skills/shipping-and-launch/SKILL.md) | P1 | Tuần 12–13, phát hành Android | Checklist release, rollback, permission & store readiness |

**Phần đã đủ trong PLAN.md nên không tự ý lặp:** `spec-driven-development`, `planning-and-task-breakdown`, `constraint-driven-development` (chỉ gọi khi task lớn cần chia thêm hoặc ràng buộc thay đổi). `performance-optimization` của Addy nghiêng về web metrics, **dùng `flutter-performance` chuyên biệt thay thế**. `frontend-ui-engineering` và `browser-testing-with-devtools` dành nhiều cho web; **không cài làm skill trọng tâm của mobile**. `interview-me`, `idea-refine`, `deprecation-and-migration`, `observability-and-instrumentation`, `doubt-driven-development`, `code-simplification` chỉ dùng khi có tình huống phù hợp, không tự kích hoạt tất cả.

**Lưu ý khi cài lẻ Addy:** README cảnh báo một số skill tham chiếu `references/` cấp root, và cài từng skill bằng `npx` có thể thiếu những file đó. **Ưu tiên cài qua plugin Codex đầy đủ**, nhưng khi triển khai chỉ kích hoạt 12 skill trong bảng, không preload cả 25 bộ hướng dẫn. Nếu Codex CLI cũ, xem phần 4.4.

---

## 3. CÁC SKILL KHÁC NÊN CÀI / NÊN HỌC

> **P0 = cần cho lõi ứng dụng; P1 = cần ở task/milestone tương ứng; P2 = tuỳ điều kiện.** Không nhầm Agent Skill với `flutter pub add` hoặc model ML.

### 3.1. Flutter chính thức (được cung cấp bởi plugin `dart-flutter`)

| Skill thật | Ưu tiên | Vì sao cần |
|---|---|---|
| `flutter-apply-architecture-best-practices` | P0 | Đặt luồng dependency, DI, tách widget khỏi logic. **Override** hướng kiến trúc mặc định bằng Domain/Data/Presentation trong `AGENTS.md` |
| `flutter-add-widget-test` | P0 | Kiểm tra giao diện camera state, từ điển, lịch sử, lỗi, offline |
| `flutter-add-integration-test` | P1 | Kiểm tra các luồng chính end-to-end |
| `flutter-build-responsive-layout` | P1 | Điều chỉnh màn hình, xoay, text scale |
| `flutter-fix-layout-issues` | P1 | Sửa overflow/layout constraints |
| `flutter-setup-declarative-routing` | P1 | Router theo `PLAN.md`, nếu `go_router` được dùng |

Nguồn: [flutter/agent-plugins](https://github.com/flutter/agent-plugins).

### 3.2. Dart chính thức (được cung cấp bởi plugin `dart-flutter`)

| Skill thật | Ưu tiên | Vì sao cần |
|---|---|---|
| `dart-add-unit-test` | P0 | Unit Test cho Domain / use cases |
| `dart-run-static-analysis` | P0 | Static analyzer và lint chất lượng code |
| `dart-generate-test-mocks` | P1 | Mock boundary khi fake thủ công không đủ |
| `dart-resolve-package-conflicts` | P1 | Giải quyết conflict Flutter SDK/package |
| `dart-collect-coverage` | P1 | Chạy báo cáo coverage, không bịa 100% |
| `dart-use-ffigen` | P2 | Chỉ khi integration thực sự dùng Dart FFI |

Nguồn: [dart-lang/skills](https://github.com/dart-lang/skills). Đừng dùng `dart-build-cli-app` vì LingoSign là ứng dụng mobile.

### 3.3. Flutter chuyên sâu bên thứ ba (cài có chọn lọc)

Nguồn: [zakariaf/Flutter-Skills](https://github.com/zakariaf/Flutter-Skills). Đây là bộ 40 skill, ít stars hơn nhưng **khớp trực tiếp** Riverpod/Drift. Agent phải đọc `SKILL.md`/scripts trước khi dùng, so với tài liệu chính thức và tuân thủ Clean Architecture ba lớp.

| Skill thật | Ưu tiên | TASK điển hình |
|---|---|---|
| `state-management-riverpod` | P0 | 001,004,005,008,009,010 |
| `persistence-drift` | P0 | 003,005,012 |
| `service-boundary-and-native` | P0 | 006,007,008,010,020 |
| `async-safety` | P0 | 006,008,012 (dispose, cancel, lifecycle, Future) |
| `codegen-and-toolchain` | P0 | 001,003 (Drift build_runner, lockfile) |
| `flutter-performance` | P0 | 008,009,014 (profile mode, UI thread) |
| `accessibility-as-code` | P0 | 004,009,013 |
| `ui-states-and-feedback` | P1 | 004,005,009,013 |
| `custom-canvas-and-gestures` | P1 | 009 (landmarks overlay bằng CustomPainter) |
| `widget-golden-and-a11y-testing` | P1 | 013,016 |
| `ci-pipeline-and-gates` | P1 | 015 |
| `release-and-store-shipping` | P1 | 015, milestone 13 |
| `run-migration` | P1 (manual-only) | Khi thay đổi Drift schema đã phát hành; **KHÔNG tự chạy destructive migration** |
| `dependency-hygiene` | P1 | 001,015, kiểm tra third-party ML plugin |

Có thể tham khảo thêm `navigation-and-routing`, `i18n-rtl-l10n`, `motion-and-haptics` khi task tương ứng xuất hiện. **Không chọn `flutter-architecture` làm luật thay thế**, vì skill này mô tả feature-first MVVM còn đồ án quy định Domain/Data/Presentation nghiêm ngặt.

### 3.4. Supabase chính thức

| Skill thật | Ưu tiên | TASK | Phạm vi |
|---|---|---|---|
| `supabase` | P1 | 011,012 | Auth, schema, client, migrations, lỗi kết nối |
| `supabase-postgres-best-practices` | P1 | 011,012 | SQL, indexes, RLS, performance; kiểm thử user isolation |

Nguồn: [supabase/agent-skills](https://github.com/supabase/agent-skills). **Không dùng service-role key trên thiết bị**, chỉ anon/publishable key đi cùng RLS; dữ liệu người dùng không sync khi chưa opt-in.

### 3.5. Skill chỉ làm nguồn tham khảo, không cài mặc định

- `obra/superpowers`: ~301k stars. Có TDD, debugging và review rất tốt, nhưng trùng bộ điều phối Addy. **Chỉ dùng thay thế** khi muốn chuyển workflow manager. [Repo](https://github.com/obra/superpowers).
- `anthropics/skills` → `skill-creator`: tham khảo khi thiết kế **skill mới riêng của dự án**, không cần cài cả bộ skills thiên về tài liệu/nội dung. [Skill](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md).
- [Google MediaPipe](https://github.com/google-ai-edge/mediapipe), [TensorFlow Lite Flutter](https://github.com/tensorflow/flutter-tflite): **tài liệu/mã nguồn kỹ thuật, không phải Agent Skills**; phải tra thêm tài liệu và license của SDK/model đang dùng.

---

## 4. QUY TRÌNH BOOTSTRAP: TỰ KIỂM TRA, TỰ CÀI, TỰ XÁC MINH

**Môi trường ví dụ:** Windows PowerShell, chạy trong **thư mục gốc ứng dụng Flutter**. Các lệnh dưới đây dành cho **Codex CLI hỗ trợ plugin**. Agent hãy kiểm tra `codex --version` và `codex plugin --help` trước. **Không giả định** người dùng đã cài Flutter, Codex CLI, Node hay NPM.

### 4.1. Preflight (luôn chạy trước; không sửa dự án)

```powershell
Get-Location
git status --short
flutter --version
dart --version
codex --version
codex plugin --help
node --version
npx --version
Test-Path .\PLAN.md
Test-Path .\AGENTS.md
Test-Path .\SKILLS_AGENT_RUNBOOK.md
```

Nếu công cụ nào không tồn tại thì chỉ ghi `NOT_INSTALLED` hoặc `UNAVAILABLE`; đừng báo sai rằng preflight xanh. Không tự thay thế `PLAN.md`/`AGENTS.md`.

### 4.2. Cài 2 plugin cốt lõi vào Codex CLI **khi đã được cấp quyền cài**

```powershell
# Flutter + Dart chính thức: skill + Dart/Flutter MCP (nếu plugin hỗ trợ cấu hình)
codex plugin marketplace add flutter/agent-plugins
codex plugin add dart-flutter@dart-flutter

# Quy trình kỹ thuật chính của Addy; cài đầy đủ để giữ shared references
codex plugin marketplace add addyosmani/agent-skills
codex plugin add agent-skills@agent-skills

# Xác minh plugin thực tế
codex plugin list
```

Nguồn chính thức: [Flutter Codex](https://docs.flutter.dev/ai/get-started), [Addy Codex](https://github.com/addyosmani/agent-skills/blob/main/docs/codex-setup.md). **Plugin Addy yêu cầu Codex CLI v0.122+ theo tài liệu repo**; nếu thấp hơn hoặc lệnh đổi, xem `codex plugin --help`, cập nhật hợp lệ hoặc chuyển qua hướng dẫn 4.4. Cần **mở lại phiên Codex sau cài** để nạp skills. Các slash command `/spec`/`/build` của Addy chủ yếu thuộc Claude; trong Codex sử dụng skill name (ví dụ `@incremental-implementation`) khi thực sự cần.

### 4.3. Cài skill chuyên biệt dự án tại `.agents/skills/`

Có thể dùng `npx skills add` để **cài lẻ** và chỉ có skill cần thiết (repo chọn lọc từ nguồn bên thứ ba):

```powershell
# Flutter/Riverpod/Drift chuyên sâu
npx skills add zakariaf/Flutter-Skills --skill state-management-riverpod --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill persistence-drift --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill service-boundary-and-native --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill async-safety --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill codegen-and-toolchain --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill flutter-performance --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill accessibility-as-code --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill ui-states-and-feedback --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill custom-canvas-and-gestures --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill widget-golden-and-a11y-testing --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill ci-pipeline-and-gates --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill release-and-store-shipping --agent universal --yes
npx skills add zakariaf/Flutter-Skills --skill dependency-hygiene --agent universal --yes

# Supabase chính thức, có thể trì hoãn đến TASK-011
npx skills add supabase/agent-skills --skill supabase --agent universal --yes
npx skills add supabase/agent-skills --skill supabase-postgres-best-practices --agent universal --yes
```

`run-migration` là **manual-only**: có thể cài nếu cần, nhưng chỉ chạy khi có snapshot/backup, test migration và sự cho phép thích hợp:

```powershell
npx skills add zakariaf/Flutter-Skills --skill run-migration --agent universal --yes
```

**Lưu ý bảo mật và độ tin cậy:** `--yes` chỉ bỏ qua các câu hỏi tương tác của installer; không có nghĩa đã kiểm toán nội dung. Trước khi chạy, agent xem nguồn, repo, các shell scripts và quyền cần cấp. Nếu tổ chức yêu cầu approval, dừng đúng điểm đó. Tránh chạy cùng tên skill từ nhiều repo: chọn bản theo bảng trên.

### 4.4. Nếu Codex plugin không khả dụng: fallback chính thức

```powershell
# Hai repo official có tài liệu xác nhận flag universal
npx skills add flutter/agent-plugins --skill '*' --agent universal --yes
npx skills add dart-lang/skills --skill '*' --agent universal --yes

# Addy fallback chọn lọc (cần xem lưu ý references ở mục 2)
npx skills add addyosmani/agent-skills --skill source-driven-development --agent universal --yes
npx skills add addyosmani/agent-skills --skill incremental-implementation --agent universal --yes
npx skills add addyosmani/agent-skills --skill test-driven-development --agent universal --yes
npx skills add addyosmani/agent-skills --skill code-review-and-quality --agent universal --yes
npx skills add addyosmani/agent-skills --skill debugging-and-error-recovery --agent universal --yes
npx skills add addyosmani/agent-skills --skill security-and-hardening --agent universal --yes
```

Khi dùng fallback, kiểm tra từng skill có `SKILL.md` hợp lệ và đủ `references/`; không khẳng định full workflow của plugin vẫn hoạt động nếu thiếu nguồn chung. **Không cài lặp official skills** nếu đã có từ plugin Codex.

### 4.5. Agent phải lập inventory thực tế

Tạo/cập nhật `docs/agent/SKILL_INVENTORY.md`, bảng các cột:

`Source | Skill | Intended use | Version/commit or date | Installed? | Path or plugin | SKILL.md readable? | Warnings | Next action`.

Quét `.agents/skills/*/SKILL.md`, plugin list và các skill thực sự khám phá được. Nếu package manager có `npx skills list`, sử dụng sau khi kiểm tra `npx skills --help`; không đoán hành vi option. Kiểm tra **file `SKILL.md`, frontmatter `name`/`description`, files tham chiếu và script**, không chỉ nhìn thư mục. Sau khi cài skill, khởi tạo phiên Codex mới nếu cần; agent trong phiên hiện tại có thể ghi `restart required` chứ không khẳng định plugin đã được nạp.

**Hoàn thành BOOTSTRAP khi:** có inventory thật + skill P0 khả dụng (hoặc blocker có chứng cứ) + `PLAN.md`/`AGENTS.md` chưa bị ghi đè + đã chọn TASK hợp lệ tiếp theo.

---

## 5. MA TRẬN TASK → SKILL PHẢI ĐỌC → EVIDENCE

Dùng tên chính xác. **Skill Addy** đặt trước `@` ở chat Codex nếu cần gọi tường minh; skill Flutter/Dart/Supabase/third-party thường agent tự khám phá theo mô tả, và có thể đọc trực tiếp file `SKILL.md` nếu loader không hỗ trợ. Với task nhỏ, chỉ nạp **1–3 skill chuyên môn** + workflow `incremental-implementation`/testing khi cần; không tải cả thư viện vào một context.

| PLAN Task | Skill chuyên ngành ưu tiên | Skill workflow Addy | Bằng chứng tối thiểu |
|---|---|---|---|
| Pre-TASK: model contract | `service-boundary-and-native` + official ML docs | `source-driven-development`, `documentation-and-adrs` | `docs/research/model_contract.md`: artifact, shape, labels, preprocessing, blocker |
| **001** Scaffold, DI, lint, router, theme | `flutter-apply-architecture-best-practices`, `state-management-riverpod`, `codegen-and-toolchain` | `incremental-implementation`, `source-driven-development` | Flutter app build; analyze/test; Domain độc lập |
| **002** Domain entities, ports, use cases | `dart-add-unit-test`, `dart-run-static-analysis` | `api-and-interface-design`, `test-driven-development` | Unit tests + kiểm tra import Domain |
| **003** SQLite/Drift schema, seed | `persistence-drift`, `codegen-and-toolchain` | `test-driven-development`, `source-driven-development` | CRUD, migration/restart test |
| **004** Dictionary UI | `state-management-riverpod`, `flutter-add-widget-test`, `accessibility-as-code` | `incremental-implementation` | Search/list/detail widget tests, offline |
| **005** History local | `persistence-drift`, `dart-add-unit-test`, `flutter-add-widget-test` | `test-driven-development` | Insert/delete/history persistence |
| **006** Camera, permission | `service-boundary-and-native`, `async-safety` | `security-and-hardening`, `debugging-and-error-recovery` | Permission, lifecycle, close/reopen; máy thật nếu có |
| **007** Model/MediaPipe adapter | `service-boundary-and-native`, `dart-add-unit-test` | `source-driven-development`, `api-and-interface-design` | Real test vectors, preprocessing exact contract; không mock-as-real |
| **008** Stream inference | `async-safety`, `flutter-performance` | `incremental-implementation`, `debugging-and-error-recovery` | No unbounded frame queue, dispose; đo trên máy thật |
| **009** Smoothing, unknown, overlay | `custom-canvas-and-gestures`, `state-management-riverpod`, `dart-add-unit-test` | `test-driven-development` | So sánh raw/smoothed, unknown tests, overlay đúng tọa độ |
| **010** TTS/haptics | `service-boundary-and-native`, `async-safety` | `incremental-implementation` | Tránh phát lặp; fallback voice; device check |
| **011** Supabase Auth, RLS | `supabase`, `supabase-postgres-best-practices` | `security-and-hardening`, `source-driven-development` | RLS user A không truy cập được dữ liệu user B |
| **012** Offline sync | `persistence-drift`, `supabase`, `async-safety` | `test-driven-development`, `debugging-and-error-recovery` | 6 offline scenarios trong PLAN.md; retry/idempotency |
| **013** Dark Mode & a11y | `accessibility-as-code`, `widget-golden-and-a11y-testing`, `flutter-build-responsive-layout` | `code-review-and-quality` | Light/dark, large font, TalkBack, tap targets |
| **014** Research benchmark | `flutter-performance`, `dart-collect-coverage` | `source-driven-development`, `documentation-and-adrs` | Raw CSV/JSON + phân tích F1/latency/FPS, device info |
| **015** CI/CD, Fastlane, signing | `ci-pipeline-and-gates`, `release-and-store-shipping` | `ci-cd-and-automation`, `security-and-hardening` | Build signed APK/AAB bằng CI, secrets ngoài repo |
| **016** Integration/regression | `flutter-add-integration-test`, `flutter-add-widget-test`, `dart-collect-coverage` | `test-driven-development`, `code-review-and-quality` | Main user journeys chạy, log không bị bịa |
| **017** Text → validated sign clip | `persistence-drift`, `flutter-add-widget-test` | `source-driven-development` | Clip đúng nguồn, license, offline (P2) |
| **018** STT → sign lookup | `service-boundary-and-native`, `async-safety` | `security-and-hardening` | Mic consent, model offline verified or label online-only (P2) |
| **019** Cloud LLM optional | `supabase` (nếu dùng edge) | `api-and-interface-design`, `security-and-hardening` | Redaction/privacy, internet required, no video to LLM (P3) |
| **020** iOS native & IPA | `service-boundary-and-native`, `release-and-store-shipping` | `ci-cd-and-automation`, `shipping-and-launch` | Build/test macOS/iPhone, signing (P1 hoặc P0 nếu bắt buộc cả 2 OS) |

### Task order và dependencies

- Chọn dựa trên **bảng dependency trong `PLAN.md` mục 8**, **không dựa đơn thuần vào thứ tự số**. Ưu tiên MVP P0 trước task P2/P3.
- TASK-007 **không thể hoàn thành** chỉ bằng một interface giả nếu chưa có model/artifact và test vectors thật. Có thể hoàn thành phần adapter skeleton, đánh dấu blocker, chuyển qua nhánh không phụ thuộc (ví dụ dictionary).
- TASK-015 có thể khởi động sớm để CI chạy test, nhưng **ký release thực tế** cần keystore và CI secrets. Tách bước có thể tự động và bước phụ thuộc người dùng.
- Nếu môn học yêu cầu **Android và iOS** đều chạy được, nâng TASK-020 lên P0 và lên kế hoạch Mac/device từ tuần đầu.
- Giữ báo cáo Milestone 4/8/11/13 tương ứng với kế hoạch; không tự thay deadline.

---

## 6. 3 CUSTOM SKILLS PHẢI TẠO TỪ DỰ ÁN THẬT

**Không tìm được skill GitHub phổ biến nào thay thế hoàn toàn logic chuyên biệt của LingoSign.** Agent tự tạo dưới `.agents/skills/` bằng template Agent Skills (`SKILL.md` có YAML `name` và `description`) **sau khi có đủ thông tin kỹ thuật**. Có thể tham khảo [Anthropic skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md). Không sao chép model/nhãn chưa được cung cấp; không ghi chú giả rằng đã huấn luyện.

### 6.1. `.agents/skills/lingosign-model-integration/SKILL.md`

**Tạo khi bắt đầu kiểm kê model / TASK-007.** Nội dung phải ép Agent: 

- Xác minh model `.tflite` / `.task` / format thực tế, SHA256, nguồn/giấy phép, tensor inputs/outputs, quantization, labels order, pre/postprocessing, normalization, threshold.
- Phân biệt ảnh raw, crop RGB, single-hand landmarks, both-hands landmarks, temporal sequences. Không tự assume `21*3` input khi model chưa rõ.
- Trình bày pipeline: CameraX/AVFoundation → frame transform → detector → preprocessing → classifier → temporal smoothing → UI → TTS. Tách Platform Adapter khỏi Domain Use Case.
- Test golden vectors từ dữ liệu có thật; kiểm tra rotation, mirror selfie camera, mất tay/2 tay/ánh sáng, class unknown, debounce, dispose, thermal/performance.
- Khi artifact thiếu: ghi blocker `MISSING_MODEL_ARTIFACT`, chỉ làm adapter/mock test, **không claim AI feature đã xong**.

### 6.2. `.agents/skills/lingosign-offline-sync/SKILL.md`

**Tạo trước TASK-011/012.** Nội dung phải ép Agent:

- SQLite/Drift local source of truth; local writes+outbox **cùng một transaction**; sync opt-in; RLS đầy đủ trên Supabase.
- Retry exponential backoff, idempotency keys, tombstone/safe delete, conflict policy, resume sau crash, migration/versioning; tuyệt đối không sync video camera hoặc biometric landmarks mặc định.
- Dựa trên 6 kịch bản offline trong `PLAN.md` để tạo test thực chứng; không báo thành công nếu chỉ test online.

### 6.3. `.agents/skills/lingosign-research-benchmark/SKILL.md`

**Tạo trước TASK-014.** Nội dung phải ép Agent:

- Dataset/test set độc lập, class definition, split tránh rò rỉ theo signer nếu có metadata, số mẫu, điều kiện môi trường, device/hardware/OS.
- Xuất `precision`, `recall`, `macro-F1`, confusion matrix; latency p50/p95 của preprocessing/inference/end-to-end; UI frame times, dropped frames, peak memory, battery/thermal khi có thể.
- Đo **profile/release trên máy thật**; phân biệt 60fps UI với 60fps inference và không tự hứa latency <100ms nếu chưa đo.
- Lưu JSON/CSV measurement + timestamp + version model + device info; ghi limitation và confidence interval nếu đủ dữ liệu, **không tự tạo số liệu**.

**Definition of done của custom skill:** có `SKILL.md` rõ trigger/process/checklist, không import/xử lý ngoài phạm vi, có ít nhất 1 lần agent áp dụng và kiểm tra kết quả; ghi vào inventory. Không viết skill quá dài gây tràn context; đưa ví dụ vào `references/` khi cần.

---

## 7. QUY TRÌNH VẬN HÀNH TỰ ĐỘNG (MỖI PHIÊN / MỖI TASK)

```text
START SESSION / CONTEXT RESET
   |
   v
Read docs/agent/PROGRESS.md if present + validate Git/worktree
   |
   v
Read AGENTS.md + PLAN.md + SKILLS_AGENT_RUNBOOK.md
   |
   v
Preflight: repo, SDK, model, device, installed skills
   |
   +-- Missing critical access/model? --> write blocker/evidence
   |                                 \--> choose independent task or STOP safely
   v
Load only relevant SKILL.md (1–3 technical + workflow)
   |
   v
Choose next unblocked TASK from PLAN dependency table
   |
   v
Understand acceptance criteria -> small code change -> tests
   |
   v
format / analyze / test / platform build when possible
   |
   +-- FAIL --> reproduce, debug, regression test -> retry, else BLOCKED
   |
   v
Architecture & security review + diff review
   |
   v
Checkpoint docs/agent/PROGRESS.md + evidence; PLAN checklist if DoD
   |
   v
Report current task + next task; repeat if permitted and unblocked
```

### 7.1. Checklist quality gate (không được skip)

- [ ] Code đúng feature scope và dependency direction 3 lớp; Domain không import Flutter/framework/infra.
- [ ] Không có widget gọi thẳng Supabase/Drift/TFLite; có repository abstraction/DI.
- [ ] `dart format` chạy hoặc có lý do chưa chạy được.
- [ ] `flutter analyze` chạy hoặc có lý do chưa chạy được.
- [ ] `flutter test` chạy hoặc có lý do chưa chạy được.
- [ ] Với DAO/sync: DB persistence/migration/offline error tests.
- [ ] Với model: test vectors thật + device checks, không lấy mock làm output thật.
- [ ] Với UI: loading/empty/error/unknown, text scale, dark mode, a11y.
- [ ] Với camera/native: permissions, start/stop, background/foreground, dispose/thermal guard.
- [ ] Secrets, signing credentials không commit. Supabase RLS kiểm thử bằng hai user độc lập.
- [ ] Chỉ đánh dấu hoàn thành PLAN.md khi có bằng chứng; ghi rõ **NOT RUN** thay vì “PASS” giả.

### 7.2. Lệnh kiểm thử chuẩn (chỉ chạy nếu có Flutter SDK và project hợp lệ)

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Release pipeline **chỉ khi** có đầy đủ ký số và platform setup; Fastlane CI job tạo APK/AAB ký từ secrets, không yêu cầu upload Google Play nếu người dùng chưa yêu cầu. Đo FPS bằng **Flutter profile mode trên thiết bị thật**, không suy từ `flutter test`.

### 7.3. File agent được phép tự tạo để ghi bằng chứng

```text
docs/
  agent/
    SKILL_INVENTORY.md       # hiện có những skill nào, nguồn, version, warnings
    PROGRESS.md              # Snapshot bền vững, code đang dở, evidence, next action và lịch sử
    TEST_EVIDENCE.md         # lệnh, timestamp, kết quả, môi trường
  research/
    model_contract.md        # metadata model thật; chưa có thì ghi MISSING
    experiment_protocol.md   # phương pháp/metric/trình tự đo
  adr/
    ADR-001-*.md             # quyết định kiến trúc quan trọng khi phát sinh
```

### 7.4. Mẫu bản ghi chuẩn sau một task

```markdown
### TASK-00X | YYYY-MM-DD | PASS / PARTIAL / BLOCKED
- Mục tiêu và tiêu chí nghiệm thu:
- Skills đã đọc (tên, đường dẫn):
- Files đã thay đổi:
- Lý do quyết định kiến trúc:
- Lệnh thực chạy + kết quả (PASS/FAIL/NOT RUN):
- Device checks thực tế và còn thiếu:
- Model/DB/sync blockers:
- Security / privacy considerations:
- Evidence/artifact (path trong repo):
- PLAN.md checklist đã cập nhật? Vì sao?
- NEXT TASK đủ dependency:
```


### 7.5. Mandatory persistent checkpoint, handoff và resume (đọc cả khi đổi model)

**Nguồn sự thật trạng thái phiên: `docs/agent/PROGRESS.md`.** Đây là file trong repository, tồn tại qua các phiên chat. Không dùng lịch sử hội thoại hoặc trí nhớ agent làm nguồn duy nhất. `AGENTS.md` quy định bắt buộc; `PLAN.md` quy định DoD; Git và kết quả test mới là bằng chứng thực.

**BOOT/RESUME:**
1. Mở `docs/agent/PROGRESS.md` nếu có. Nếu không có, tạo theo mẫu `docs/agent/PROGRESS.md` trong bundle; nếu cũng không có mẫu, dùng schema bên dưới với `NOT_INSPECTED`/`NOT_VERIFIED` và kiểm kê repo trước khi cập nhật.
2. Chạy/đọc `git status --short`, `git branch --show-current`, `git rev-parse --short HEAD`, `git diff --stat` (nếu là Git repo), đọc những file được liệt kê là đang dở, so sánh checklist `PLAN.md` và TEST_EVIDENCE. Không reset, revert hay xóa file lạ do người dùng hoặc agent cũ đang sửa.
3. Nếu `CURRENT_TASK=IN_PROGRESS` hoặc `NEEDS_VERIFY`, ưu tiên tiếp tục chính task đó theo `NEXT_ACTIONS`; sửa sai lệch giữa checkpoint và trạng thái thực trước khi code. Nếu `BLOCKED`, chỉ chọn task độc lập khi dependencies cho phép. Nếu `DONE`/`NOT_STARTED`, chọn task đủ điều kiện tiếp theo.

**WRITE CHECKPOINT ngay khi:** bắt đầu task; hoàn tất một phần cụ thể; thay đổi schema/native/model; vừa chạy test; gặp blocker; user yêu cầu dừng; chuẩn bị handoff sang agent/model khác; **khi dự đoán context/token gần giới hạn**; trước khi kết thúc phiên. Tạo checkpoint sớm vì dừng đột ngột có thể khiến checkpoint cuối không kịp lưu. Không hứa ghi log sau khi quá trình đã bị ngắt.

**Định dạng snapshot tối thiểu trong `docs/agent/PROGRESS.md`:**

```markdown
# LingoSign AI - Persistent Agent Progress
> LAST_UPDATED: YYYY-MM-DD HH:MM TZ | STATUS: NOT_STARTED / IN_PROGRESS / NEEDS_VERIFY / BLOCKED / DONE

## CURRENT TASK
- ID / objective / acceptance criteria:
- Verified completed (evidence links/paths):
- Partial/unverified work and exact location (file, class, function):
- Files edited, including uncommitted modifications:
- Git branch / HEAD / dirty status:
- Skills and project docs to consult:

## VALIDATION
- Executed commands and exact result (PASS / FAIL / NOT_RUN):
- Device/manual checks (PASS / FAIL / NOT_RUN):
- Known errors/blockers and missing prerequisites:

## NEXT ACTIONS (1–3 executable steps)
1. [exact file/command, expected output]
2. [exact next action]
3. [exact verification]

## DECISIONS / RISKS
- Decisions, assumptions and unanswered questions:

## CHECKPOINT HISTORY
- [timestamp] TASK-... | result | next step | evidence (append concise entries)
```

- Snapshot ở đầu file được **cập nhật**, history ở cuối file được **append** (tránh phình to không cần thiết). Với token/context thấp ưu tiên ghi trạng thái file + NEXT ACTIONS, rồi mới tóm tắt dài.
- `DONE` và tick `[x]` **chỉ khi** acceptance evidence đã có; thay đổi chưa kiểm chứng ghi `NEEDS_VERIFY`, không biến thành `DONE`. Mọi test chưa thực thi ghi `NOT_RUN`, không ghi PASS bằng suy đoán.
- Nếu task có code chưa commit, giữ nguyên và mô tả rành mạch. Handoff **không đồng nghĩa** commit/push, và không tự dùng `git reset --hard`, `git clean -fd`, `git checkout --` để ép repo khớp ghi chú.
- Không bao giờ ghi API key, mật khẩu, signing key, secret, thông tin người dùng hoặc camera frames vào nhật ký.

**KHI NHẬN LỆNH STOP HOẶC SẮP HẾT CONTEXT:** (a) ngừng mở việc mới, (b) ghi checkpoint vào file thật, (c) đọc lại để xác nhận tồn tại và thông tin mới nhất, (d) trả lời ngắn TASK/status/next action. Nếu không thể ghi file, thông báo rõ và cung cấp handoff text để người dùng lưu thủ công.

**PROMPT KHÔI PHỤC NỘI BỘ:**

```text
Read AGENTS.md, docs/agent/PROGRESS.md (if present), PLAN.md and
SKILLS_AGENT_RUNBOOK.md. Compare progress with git status, diff and actual files.
Resume the saved unfinished TASK at the first unverified NEXT_ACTION, without
recreating verified code. Run the missing tests, update the checkpoint frequently,
and only mark DONE when acceptance evidence exists. If the checkpoint is absent,
reconstruct from Git and tests without guessing. Do not ask for prior chat history.
```

---

## 8. PROMPT ĐIỀU PHỐI NỘI BỘ CHO CODEX (TỰ THỰC THI, KHÔNG CẦN COPY HẰNG NGÀY)

> **Nội dung bên dưới là chỉ thị điều phối có sẵn trong file**. Agent đọc và tuân theo mà không đòi người dùng dán prompt ở mỗi phiên. Người dùng chỉ cần mở đúng repository có `AGENTS.md` tham chiếu runbook này.

```text
ROLE: Lead Flutter engineer + offline-first architect + on-device AI integrator +
      test/release engineer for LingoSign AI.
GOAL: Build the real capstone app described by PLAN.md under AGENTS.md constraints.
SOURCE_OF_TRUTH: AGENTS.md > PLAN.md > SKILLS_AGENT_RUNBOOK.md > selected SKILL.md.

ON START:
  1) Read docs/agent/PROGRESS.md if it exists, then inspect git status/diff, SDK, model and skills. Reconcile claims with actual code; resume unfinished TASK first.
  2) Read exact applicable SKILL.md files; log missing skills honestly.
  3) Bootstrap missing permitted skills from verified sources; never bypass approvals.
  4) If no valid unfinished TASK exists, read PLAN.md dependencies; pick one unblocked P0 TASK and its acceptance checks. Create/update PROGRESS.md immediately.

FOR EACH TASK:
  SPEC -> CONTRACT -> MINIMAL IMPLEMENTATION -> TEST -> VERIFY -> REVIEW -> LOG.
  Keep Domain pure Dart. Use Riverpod, Drift/SQLite, Supabase offline-first,
  native/on-device model inference through adapters. Never substitute placeholders
  for actual AI, device benchmarks, or release signing.
  Always run available checks and report exactly what ran and the exit status.
  Checkpoint docs/agent/PROGRESS.md at task start, after meaningful substeps/tests,
  and at stop/context-limit warnings. Mark complete only with acceptance evidence.

STOP CONDITIONS:
  - Missing model artifact or necessary metadata for real inference.
  - Credentials / secrets / signing / store submission / external paid services.
  - Security risk, destructive operation or schema change without safe migration.
  - Required real-device/macOS platform not available for requested verification.
  - Tests failing without safe isolated fix, or user permission required.
  When possible choose an independent unblocked task; otherwise STOP with blocker.
  Save and verify docs/agent/PROGRESS.md before an intentional stop or handoff.
  If abruptly terminated, next agent must reconstruct from Git and tests.

OUTPUT FORMAT:
  TASK ID | Summary | Skills used | Files changed | Design decisions |
  Tests actually executed and results | Manual checks still needed |
  Risks and blockers | PLAN.md update | Checkpoint path/status | Next exact action.

Do not ask the user to rewrite prompts; use this file and PLAN.md to decide the
next action. Never claim work happened without proof.
```

---

## 9. NHỮNG VIỆC KHÔNG LÀM

1. Không cài toàn bộ danh sách Awesome-Copilot, 25 Addy + Superpowers + 40 Flutter-Skills vào một prompt/session. Chỉ đọc skill kích hoạt theo từng task.
2. Không biến dự án Flutter thành React/Next.js hoặc backend Node chỉ vì các skill web hướng dẫn như vậy.
3. Không tách bỏ Domain hay import UI/Drift vào Domain vì repository skill nào đó hướng MVVM.
4. Không ghi nhận diện ký hiệu là “100% chính xác”, “60fps inference”, “<100ms” hoặc “hoạt động offline với mọi STT” khi chưa đo.
5. Không gửi video, landmark, dữ liệu sinh trắc học/nhạy cảm lên Cloud theo mặc định.
6. Không commit service-role key, keystore, signing password, model có license không cho phép.
7. Không tự nhảy sang tính năng hai chiều, LLM hay STT nếu MVP còn lỗi hoặc thiếu model.
8. Không đổi database sang Isar/Firebase vì skill gợi ý; SQLite+Drift+Supabase đã chốt.
9. Không tự tạo task mới vượt scope, tự tick checklist, tự khai device test hoặc tự báo build ký thành công khi chưa có bằng chứng.

---

## 10. KIỂM TRA THÀNH CÔNG KHI BÀN GIAO

- [ ] `PLAN.md`, `AGENTS.md`, `SKILLS_AGENT_RUNBOOK.md` đặt cùng thư mục gốc.
- [ ] `AGENTS.md` trỏ tới file này để Codex có thể đọc ngay khi mở project.
- [ ] Có `docs/agent/SKILL_INVENTORY.md` dựa trên những skill thực sự cài/được discover.
- [ ] Có ghi nhận status TASK-001/Pre-TASK, model contract và các blocker.
- [ ] Bộ Addy được chọn làm quy trình chính, không có workflow manager trùng lặp gây xung đột.
- [ ] Flutter/Dart official skills sẵn sàng; third-party skills chuyên ngành được rà soát.
- [ ] Test/report chưa chạy được sẽ ghi rõ trạng thái, không bị mô tả thành hoàn thành.
- [ ] Agent chọn đúng task kế tiếp theo dependency, ưu tiên MVP.

**Kết quả mong muốn:** sau khi file được đặt đúng trong project và môi trường Codex được cấp các quyền cần thiết, agent có đủ ngữ cảnh để tự kiểm kê skill, lựa chọn tài liệu, thực hiện lần lượt các task hợp lệ, kiểm tra và báo cáo; người dùng chỉ cần can thiệp cho blocker thực sự hoặc hành động nhạy cảm.

---

## 11. NGUỒN KIỂM CHỨNG VÀ TÀI LIỆU NÊN ĐỌC

- Addy repo/25 skill: https://github.com/addyosmani/agent-skills
- Addy Codex install/limitations: https://github.com/addyosmani/agent-skills/blob/main/docs/codex-setup.md
- Flutter Official Agent Plugins: https://github.com/flutter/agent-plugins
- Flutter official Codex plugin setup: https://docs.flutter.dev/ai/get-started
- Dart Official Skills: https://github.com/dart-lang/skills
- Supabase Official Skills: https://github.com/supabase/agent-skills
- Flutter specialized skills: https://github.com/zakariaf/Flutter-Skills
- Superpowers (alternative only): https://github.com/obra/superpowers
- Anthropic skill creator (reference only): https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
- Google MediaPipe: https://github.com/google-ai-edge/mediapipe
- TFLite Flutter project: https://github.com/tensorflow/flutter-tflite
- Flutter testing: https://docs.flutter.dev/testing/overview
- Flutter performance profiling: https://docs.flutter.dev/perf/ui-performance

**Ghi chú thời điểm:** các tên skill, số sao, plugin commands được rà từ tài liệu công khai ngày 17/10/2026. Nếu CLI/README thay đổi, hãy kiểm tra phiên bản và tài liệu repo **trước khi chạy lệnh**; không tự suy đoán rằng lệnh cũ vẫn hoạt động.
