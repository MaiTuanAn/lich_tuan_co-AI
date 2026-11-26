# SchedulAI

Ứng dụng quản lý lịch tuần tích hợp trợ lý AI. Frontend viết bằng Flutter (chạy được trên trình duyệt), backend dùng Supabase (Postgres, Auth, Row Level Security, Edge Functions). Người dùng có thể dùng lịch ở chế độ Khách (tài khoản ẩn danh) hoặc đăng ký để có lịch riêng; dữ liệu lưu trên cloud nên không phụ thuộc localhost.

## Tiến độ

| Hạng mục | Trạng thái |
|---|---|
| Đăng ký, đăng nhập, đổi mật khẩu (Supabase Auth) | Hoàn thành |
| Chế độ Khách bằng Anonymous Sign-in, khôi phục phiên khi F5 | Hoàn thành |
| CRUD sự kiện lưu trên Postgres, mỗi user một lịch riêng (RLS) | Hoàn thành |
| Chống trùng lịch ngay trong database (exclusion constraint) | Hoàn thành |
| Danh mục có màu, ẩn/hiện, lưu trên cloud | Hoàn thành |
| Trợ lý AI: Gemini hiểu yêu cầu, thuật toán tìm giờ trống | Đã deploy, đang kiểm thử |
| Cài đặt (ngôn ngữ, ngày đầu tuần, thời lượng mặc định...) | Chưa lưu và chưa áp dụng, chỉ theme và định dạng 24h có tác dụng |
| Kéo-thả và đổi kích thước sự kiện | Chưa làm |
| Nhắc lịch, sự kiện lặp lại | Chưa làm |
| Chuyển Khách thành tài khoản thật mà giữ nguyên lịch | Chưa làm |
| Deploy bản web (Vercel hoặc Firebase Hosting) | Chưa làm |
| Dọn thư mục `backend/` cũ (FastAPI + SQLite) | Chưa làm |

## Kiến trúc

```text
lich_tuan_co AI/
├── frontend/                          # Flutter (web, desktop, mobile)
│   ├── lib/
│   │   ├── main.dart                  # Khởi tạo Supabase, đăng ký CalendarProvider
│   │   ├── core/
│   │   │   ├── app_colors.dart        # Quy tắc màu giao diện và màu sự kiện
│   │   │   └── app_config.dart        # URL và publishable key của Supabase
│   │   ├── models/
│   │   │   ├── event_model.dart       # Sự kiện (id kiểu uuid, giờ đổi sang local)
│   │   │   ├── category_model.dart    # Danh mục, chuyển đổi màu Color <-> hex
│   │   │   └── ai_suggestion_model.dart # Gợi ý khung giờ do AI trả về
│   │   ├── services/
│   │   │   ├── auth_service.dart      # Đăng ký/đăng nhập/khách/đổi mật khẩu
│   │   │   ├── event_repository.dart  # CRUD sự kiện, dịch lỗi trùng lịch
│   │   │   ├── category_repository.dart # CRUD danh mục
│   │   │   └── ai_service.dart        # Gọi Edge Function ai-chat
│   │   ├── providers/
│   │   │   └── calendar_provider.dart # State trung tâm: auth, sự kiện, danh mục, chat, theme
│   │   ├── screens/
│   │   │   └── main_layout_screen.dart # Ghép taskbar, header, lịch và khung chat
│   │   └── widgets/
│   │       ├── weekly_grid_view.dart  # Lịch tuần Syncfusion và thẻ sự kiện
│   │       ├── vertical_taskbar.dart  # Tạo sự kiện, bộ lọc, AI, tài khoản, cài đặt
│   │       ├── top_header_bar.dart    # Điều hướng tuần, ngày hiện tại
│   │       ├── event_form_dialog.dart # Form tạo/sửa sự kiện
│   │       ├── auth_account_dialogs.dart # Đăng ký, đăng nhập, hồ sơ, đổi mật khẩu
│   │       ├── ai_chat_sidebar.dart   # Khung chat, thẻ gợi ý có nút Schedule/Cancel
│   │       └── settings_modal.dart    # Cài đặt giao diện và lịch
│   └── pubspec.yaml
│
├── supabase/                          # Toàn bộ phần backend
│   ├── config.jsonc
│   ├── migrations/
│   │   ├── 20261125100000_init_schema.sql   # Bảng, trigger, ràng buộc chống trùng lịch
│   │   └── 20261125100100_rls_policies.sql  # Bật RLS, policy, grant
│   └── functions/
│       ├── _shared/cors.ts            # Header CORS cho Edge Functions
│       └── ai-chat/
│           ├── index.ts               # Gọi Gemini, ghép gợi ý, xử lý lỗi, giới hạn lượt gọi
│           └── slots.ts               # Thuật toán tìm khung giờ trống (hàm thuần)
│
├── backend/                           # CŨ: FastAPI + SQLite, không còn dùng, sẽ xóa
├── README.md
└── .gitignore
```

### Luồng dữ liệu

```text
Widget / Screen
      ↓ đọc state và gọi hành động
CalendarProvider (ChangeNotifier)
      ↓
AuthService / EventRepository / CategoryRepository / AiService
      ↓ supabase_flutter (HTTPS)
Supabase: Auth + Postgres (RLS) + Edge Function ai-chat
                                        ↓
                                  Gemini API
```

`CalendarProvider` giữ trạng thái đăng nhập, theme, danh mục, bộ lọc, sự kiện và hội thoại AI. `notifyListeners()` làm các widget liên quan vẽ lại. Các lớp `Repository` và `Service` là nơi duy nhất giao tiếp với Supabase.

### Cơ sở dữ liệu

| Bảng | Nội dung |
|---|---|
| `profiles` | Họ tên và vai trò, tạo tự động khi có user mới (kể cả khách) |
| `categories` | Danh mục của từng user: tên, màu `#RRGGBB`, trạng thái ẩn/hiện |
| `events` | Sự kiện: tiêu đề, mô tả, `start_time`/`end_time` kiểu `timestamptz`, `category_id` |
| `user_settings` | Cài đặt dạng JSON (bảng đã có, app chưa dùng) |
| `chat_messages` | Lịch sử chat AI (bảng đã có, app chưa dùng) |

Các điểm đáng chú ý:

- **Row Level Security** bật trên mọi bảng. Mỗi user (kể cả khách ẩn danh) chỉ đọc và sửa dữ liệu của chính mình. Role `anon` không được cấp quyền gì.
- **Chống trùng lịch do database đảm nhiệm:** ràng buộc `events_no_overlap` từ chối hai sự kiện chồng giờ của cùng một user. Hai sự kiện nối tiếp nhau (kết thúc đúng lúc cái sau bắt đầu) vẫn hợp lệ.
- **Mỗi user mới** tự có 4 danh mục mặc định: Công việc, Học tập, Cá nhân, Khẩn cấp.
- **Giờ lưu theo UTC** (`timestamptz`), app đổi sang giờ máy khi hiển thị.

### Trợ lý AI

```text
Người dùng gõ câu yêu cầu
      ↓ gửi kèm giờ hiện tại, các khoảng giờ bận, danh mục
Edge Function ai-chat
      ↓ Gemini chỉ phân tích ý định thành JSON (việc gì, bao lâu, khoảng ngày, buổi nào)
slots.ts tìm tối đa 3 khung giờ trống, không trùng lịch, không nằm trong quá khứ
      ↓
Thẻ gợi ý trong khung chat → bấm Schedule để tạo sự kiện thật
```

- Gemini không quyết định giờ nào trống; việc đó do code tính trên lịch thật, nên gợi ý không chồng sự kiện. Database vẫn kiểm tra trùng lịch lần cuối khi tạo.
- Khóa `GEMINI_API_KEY` chỉ nằm trong secret của Supabase, không có trong app.
- Mặc định dùng model `gemini-3.5-flash-lite`. Khi gặp 503/500/504, function thử lại tối đa 3 lần rồi chuyển sang model dự phòng `gemini-2.5-flash-lite`. Khi gặp 404 hoặc 429 ở model chính cũng chuyển sang model dự phòng. Có thể đổi model bằng secret `GEMINI_MODEL` và `GEMINI_FALLBACK_MODEL` mà không cần sửa code.
- Khung chat chỉ hiện khi đã đăng nhập bằng tài khoản thật.
- Giờ gửi và nhận là giờ địa phương dạng `yyyy-MM-ddTHH:mm`. Khung gợi ý nằm trên mốc :00 và :30.

## Yêu cầu môi trường

- Flutter SDK tương thích Dart SDK `^3.13.7`
- Supabase CLI (trên Windows cài bằng Scoop)
- Tài khoản Supabase (gói Free đủ dùng) và một API key Gemini (lấy miễn phí tại Google AI Studio)
- Windows: bật **Developer Mode** (`start ms-settings:developers`) để Flutter tạo được symlink cho plugin

## Cài đặt và chạy

### 1. Cài Supabase CLI (Windows)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
iwr -useb get.scoop.sh | iex
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
supabase --version
```

### 2. Tạo project Supabase và liên kết

1. Vào supabase.com, tạo Organization và Project (region gần nhất, ví dụ Singapore). Nên tick **Enable RLS on new tables automatically**.
2. Trong **Authentication → Sign In / Providers**: bật **Allow anonymous sign-ins**. Khi phát triển có thể tắt **Confirm email** của Email provider để thử đăng ký nhanh; trước khi công khai nên bật lại.
3. Ở thư mục gốc repo:

```powershell
supabase login
supabase link --project-ref <project-ref>
```

### 3. Đẩy schema lên cloud

CLI bản mới mặc định nhắm vào database local (cần Docker), nên thêm cờ `--remote`:

```powershell
supabase migration list --remote
supabase db push --remote
```

Sau đó mở **Table Editor** trên dashboard, phải thấy 5 bảng `profiles`, `categories`, `events`, `user_settings`, `chat_messages`.

### 4. Cấu hình và deploy trợ lý AI

```powershell
supabase secrets set GEMINI_API_KEY=<key-của-bạn>
supabase functions deploy ai-chat
```

Nếu CLI báo cần Docker, thêm `--use-api`. Xem log tại **Dashboard → Edge Functions → ai-chat → Logs**.

### 5. Chạy frontend

Điền thông tin kết nối vào `frontend/lib/core/app_config.dart` (URL dự án và **publishable key**; không dùng `secret` hay `service_role`) hoặc truyền qua `--dart-define`:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Có thể thay `chrome` bằng `windows` hoặc thiết bị khác.

### Build bản web

```powershell
cd frontend
flutter build web --release
```

Đưa thư mục `frontend/build/web` lên một dịch vụ host tĩnh (Vercel, Firebase Hosting, Netlify, Cloudflare Pages...). Khi deploy thật, đổi `Access-Control-Allow-Origin` trong `supabase/functions/_shared/cors.ts` từ `*` thành đúng domain của bạn.

## Kiểm tra nhanh sau khi cài

1. Mở app, tạo sự kiện: dòng mới xuất hiện trong bảng `events`.
2. Tạo sự kiện thứ hai chồng giờ: app báo trùng lịch.
3. Nhấn F5: lịch vẫn còn (phiên được khôi phục).
4. Đăng ký tài khoản, đăng xuất, đăng nhập lại: mỗi tài khoản có lịch riêng.
5. Đăng nhập tài khoản thật và nhắn trợ lý, ví dụ "Họp nhóm 2 tiếng chiều thứ Năm tuần sau": phải có thẻ gợi ý, bấm Schedule thì sự kiện được tạo.

## Hạn chế hiện tại

- **Chuyển từ Khách sang tài khoản thật không giữ lịch cũ.** Đăng ký tạo user mới.
- **Đăng xuất tạo khách ẩn danh mới**, nên bảng Users trên dashboard tích lũy dần các user ẩn danh và cần dọn định kỳ.
- **Giới hạn lượt gọi AI mới ở mức sơ sài:** 20 lượt mỗi 10 phút mỗi user, đếm trong bộ nhớ của function, và ai cũng có thể tạo khách ẩn danh. Nếu công khai thật cần bộ đếm lưu trong database.
- **Gói Free của Gemini có thể dùng nội dung gửi lên để cải thiện sản phẩm của Google.** Không nên nhập thông tin nhạy cảm vào khung chat.
- **Model Gemini có thể quá tải tạm thời (503).** Function đã tự thử lại và chuyển model dự phòng, nhưng vẫn có lúc phải thử lại sau ít phút.
- **Font `Segoe UI` chỉ có trên Windows.** Bản web nên bundle một font (Inter, Roboto) trong `pubspec.yaml`.
- **Lỗi khi xóa sự kiện từ thẻ trên lịch** chưa có thông báo cho người dùng, hiện chỉ in ra console.
- **Chưa có test tự động ở phía Flutter.** Thuật toán `slots.ts` đã được kiểm thử riêng khi viết.

## Hướng dẫn mở rộng

| Nhu cầu | File nên sửa |
|---|---|
| Thêm/sửa màu danh mục mặc định | `supabase/migrations` (hàm `handle_new_user`), `frontend/lib/core/app_colors.dart` |
| Thêm bảng hoặc cột | Tạo migration mới bằng `supabase migration new <tên>`, viết SQL kèm policy RLS rồi `db push --remote` |
| Thay đổi state hoặc nghiệp vụ lịch | `frontend/lib/providers/calendar_provider.dart` |
| Sửa cách đọc/ghi dữ liệu | `event_repository.dart`, `category_repository.dart`, `auth_service.dart` |
| Sửa giao diện lịch tuần | `frontend/lib/widgets/weekly_grid_view.dart` |
| Sửa khung chat AI | `ai_chat_sidebar.dart`, `ai_service.dart` |
| Đổi cách AI hiểu yêu cầu | `buildPrompt` và `INTENT_SCHEMA` trong `supabase/functions/ai-chat/index.ts` |
| Đổi thuật toán tìm giờ trống | `supabase/functions/ai-chat/slots.ts` |
| Đổi nhà cung cấp AI | Hàm `askGemini` trong `ai-chat/index.ts` (phần còn lại không phụ thuộc nhà cung cấp) |
| Lưu Settings lên cloud | Dùng bảng `user_settings` (có sẵn), thêm `settings_repository.dart` và đọc/ghi trong provider |

## Lưu ý bảo mật

- Publishable key được phép nằm trong app. **Tuyệt đối không** đưa `secret`, `service_role` hay `GEMINI_API_KEY` vào code Flutter hoặc commit lên Git.
- Quyền truy cập dữ liệu dựa hoàn toàn vào policy RLS ở `20261125100100_rls_policies.sql`. Khi thêm bảng mới phải bật RLS và viết policy, nếu không bảng sẽ bị chặn (hoặc lộ, nếu cấp grant mà quên RLS).
- Nhớ đưa `.env`, khóa API và thư mục `supabase/.temp` vào `.gitignore`.
