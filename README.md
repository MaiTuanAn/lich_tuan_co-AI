# SchedulAI

Ứng dụng quản lý lịch tuần với giao diện Flutter đa nền tảng và backend FastAPI. Dữ liệu được lưu trong SQLite; người dùng có thể sử dụng lịch ở Guest Mode hoặc đăng nhập để có lịch riêng.

## Kiến trúc hệ thống

Repo được tổ chức theo mô hình client–server:

```text
lich_tuan_co AI/
├── backend/
│   ├── main.py             # FastAPI app, schema, auth, event API và business logic
│   └── schedulai.db        # SQLite database được tạo/cập nhật khi backend chạy
├── frontend/
│   ├── lib/
│   │   ├── main.dart       # Điểm khởi chạy Flutter và đăng ký CalendarProvider
│   │   ├── core/
│   │   │   └── app_colors.dart        # Quy tắc màu giao diện và màu sự kiện
│   │   ├── models/
│   │   │   ├── event_model.dart       # Mô hình sự kiện, ánh xạ JSON
│   │   │   └── category_model.dart    # Mô hình danh mục và trạng thái hiển thị
│   │   ├── services/
│   │   │   └── api_service.dart       # HTTP client, token và các lệnh gọi REST
│   │   ├── providers/
│   │   │   └── calendar_provider.dart # State trung tâm, auth, CRUD, filter, theme
│   │   ├── screens/
│   │   │   └── main_layout_screen.dart # Ghép taskbar, header, calendar và chat
│   │   └── widgets/
│   │       ├── weekly_grid_view.dart  # Lịch tuần Syncfusion và event card
│   │       ├── vertical_taskbar.dart  # Tạo sự kiện, filter, AI, tài khoản, settings
│   │       ├── top_header_bar.dart    # Điều hướng tuần, ngày hiện tại, chế độ xem
│   │       ├── event_form_dialog.dart # Form tạo/sửa sự kiện
│   │       ├── auth_account_dialogs.dart # Đăng ký, đăng nhập, hồ sơ, đổi mật khẩu
│   │       ├── ai_chat_sidebar.dart   # Giao diện trợ lý AI hiện tại
│   │       └── settings_modal.dart    # Cài đặt giao diện và lịch
│   ├── pubspec.yaml
│   └── test/
├── README.md
└── .gitignore
```

### Luồng dữ liệu

```text
Widget / Screen
      ↓ đọc và gọi hành động
CalendarProvider (ChangeNotifier)
      ↓ gọi REST, gắn Bearer token
ApiService
      ↓ HTTP / JSON
FastAPI (backend/main.py)
      ↓ SQL queries
SQLite (backend/schedulai.db)
```

Frontend dùng `Provider` để quản lý state. `CalendarProvider` giữ trạng thái đăng nhập, theme, danh mục, bộ lọc và danh sách sự kiện; `notifyListeners()` làm các widget liên quan render lại. `ApiService` là lớp duy nhất chịu trách nhiệm giao tiếp với backend.

Backend hiện là một module FastAPI duy nhất, trong đó có:

- Auth: đăng ký, đăng nhập, đổi mật khẩu và access token.
- Event CRUD: lấy, tạo, sửa, xóa sự kiện.
- SQLite: các bảng `users`, `user_tokens` và `events` được khởi tạo tự động.
- Validation: Pydantic kiểm tra dữ liệu đầu vào; `check_time_conflict_sqlite()` chặn lịch bị trùng.
- Guest Mode: sự kiện không có token được lưu với `user_id IS NULL`; sự kiện đã đăng nhập được lọc theo `user_id`.

> Lưu ý: `ai_chat_sidebar.dart` và `CalendarProvider.sendUserChatMessage()` hiện là luồng chat mô phỏng ở frontend, chưa gọi API AI riêng. Không nên mô tả `ai_service.py` hoặc Function Calling là các module đã tồn tại trong repo.

## API chính

Base URL mặc định của frontend: `http://127.0.0.1:8000/api`

| Nhóm | Method | Endpoint |
|---|---:|---|
| Auth | POST | `/auth/register` |
| Auth | POST | `/auth/login` |
| Auth | PUT | `/auth/change-password` |
| Events | GET | `/events` |
| Events | POST | `/events` |
| Events | PUT | `/events/{event_id}` |
| Events | DELETE | `/events/{event_id}` |

## Yêu cầu môi trường

- Python 3.10 trở lên
- Flutter SDK tương thích Dart SDK `^3.13.7`
- Thiết bị Flutter hoặc Windows/Web/Android toolchain tương ứng

## Cài đặt và chạy

### Backend

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install fastapi "uvicorn[standard]" pydantic
uvicorn main:app --reload
```

Backend chạy tại `http://127.0.0.1:8000`; tài liệu Swagger ở `http://127.0.0.1:8000/docs`.

### Frontend

Mở terminal khác:

```powershell
cd frontend
flutter pub get
flutter run -d windows
```

Có thể thay `windows` bằng `chrome` hoặc thiết bị Android đang kết nối.

## Hướng dẫn mở rộng

| Nhu cầu | File nên sửa |
|---|---|
| Thêm/sửa màu danh mục | `frontend/lib/core/app_colors.dart`, `calendar_provider.dart` |
| Thay đổi state hoặc nghiệp vụ lịch | `frontend/lib/providers/calendar_provider.dart` |
| Thêm endpoint hoặc sửa database | `backend/main.py` |
| Thay đổi format request/response | `frontend/lib/services/api_service.dart` và các model |
| Sửa giao diện lịch tuần | `frontend/lib/widgets/weekly_grid_view.dart` |
| Sửa auth/account | `frontend/lib/widgets/auth_account_dialogs.dart` và `api_service.dart` |
| Phát triển AI thật | Tạo API AI ở backend, sau đó bổ sung method tương ứng trong `ApiService` và action trong `CalendarProvider` |

## Trạng thái kiến trúc

Kiến trúc hiện tại phù hợp cho MVP: frontend đã tách theo model–service–provider–widget, nhưng backend chưa tách thành các package `schemas`, `services`, `repositories`. Khi nghiệp vụ lớn hơn, có thể tách `backend/main.py` thành router, schema, service và database layer mà không thay đổi contract REST hiện tại.
