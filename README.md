# SchedulAI - PHẦN MỀM QUẢN LÝ LỊCH TUẦN TÍCH HỢP CHATBOT AI

> **Hệ thống Quản lý Thời gian biểu Tuần thông minh hỗ trợ phát hiện xung đột thời gian và tương tác tự nhiên qua Chatbot AI.**  
> Dự án áp dụng kiến trúc tách biệt Client-Server: **Frontend Flutter (ngôn ngữ Dart)** đa nền tảng kết hợp **Backend Python (FastAPI)** và **LLM Function Calling**.

---

## 📌 MỤC LỤC
1. [Giới thiệu & Tính năng cốt lõi](#-giới-thiệu--tính-năng-cốt-lõi)
2. [Kiến trúc Hệ thống & Cấu trúc Thư mục](#-kiến-trúc-hệ-thống--cấu-trúc-thư-mục)
3. [Yêu cầu Môi trường (Prerequisites)](#-yêu-cầu-môi-trường-prerequisites)
4. [Hướng dẫn Cài đặt & Khởi chạy Chi tiết](#-hướng-dẫn-cài-đặt--khởi-chạy-chi-tiết)
   - [4.1. Khởi chạy Backend (Python FastAPI)](#41-khởi-chạy-backend-python-fastapi)
   - [4.2. Khởi chạy Frontend (Flutter SDK)](#42-khởi-chạy-frontend-flutter-sdk)
5. [Hướng dẫn Đọc & Mở rộng Mã nguồn (Developer Guide)](#-hướng-dẫn-đọc--mở-rộng-mã-nguồn-developer-guide)
6. [Lộ trình Phát triển (Project Roadmap)](#-lộ-trình-phát-triển-project-roadmap)

---

## 🚀 GIỚI THIỆU & TÍNH NĂNG CỐT LÕI

* **Giao diện Lịch tuần Trực quan (Weekly Grid View):** Bố cục 7 ngày (Thứ 2 đến Chủ nhật) chia khung giờ từ 07:00 đến 22:00, hỗ trợ vạch chỉ thời gian thực (`Current Time Indicator`).
* **Phân loại Sự kiện theo Danh mục & Mã màu:** Tự động hiển thị thẻ sự kiện theo màu Pastel hiện đại (Công việc - Xanh dương, Học tập - Xanh lá, Cá nhân - Vàng cam, Khẩn cấp - Đỏ).
* **Thuật toán Phát hiện Xung đột (Conflict Detection Engine):** Tự động phát hiện và cảnh báo tức thời khi có lịch trình bị đè hoặc trùng khung giờ.
* **Đồng bộ Dữ liệu Thời gian thực (Real-time State Synchronization):** Giao tiếp qua RESTful API, tự động vẽ lại sự kiện mới mà không cần tải lại trang.
* **Kiến trúc Sẵn sàng Tích hợp AI (AI-Ready Architecture):** Khung trợ lý `AI Scheduler` được thiết kế độc lập, sẵn sàng kết nối API Function Calling để bóc tách câu lệnh tiếng Việt tự nhiên thành lịch trình.

---

## 🏗 KIẾN TRÚC HỆ THỐNG & CẤU TRÚC THƯ MỤC

Dự án áp dụng mô hình **Clean Modular Architecture**, tách biệt hoàn toàn giữa ứng dụng Desktop/Mobile (`frontend/`) và máy chủ xử lý logic (`backend/`).

```text
lich_tuan_co_AI/
│
├── backend/                             # PHẦN BACKEND (PYTHON FASTAPI)
│   ├── venv/                            # Môi trường ảo Python (Virtual Environment)
│   ├── app/
│   │   ├── main.py                      # Điểm khởi chạy API, cấu hình CORS & Endpoints
│   │   ├── schemas.py                   # Khuôn mẫu dữ liệu JSON (Pydantic Models)
│   │   ├── ai_service.py                # Module phân tích NLP & Function Calling AI
│   │   └── database.py                  # Cấu hình kết nối CSDL (PostgreSQL / SQLite)
│   ├── requirements.txt                 # Danh sách thư viện Python cần cài đặt
│   └── README.md
│
├── frontend/                            # PHẦN FRONTEND (FLUTTER / DART)
│   ├── android/                         # Mã nguồn nền tảng Android (.apk)
│   ├── windows/                         # Mã nguồn nền tảng Windows Desktop (.exe)
│   ├── lib/                             # Thư mục mã nguồn chính (100% ngôn ngữ Dart)
│   │   ├── core/
│   │   │   └── app_colors.dart          # Quản lý bảng màu tập trung (Pastel & Primary)
│   │   ├── models/
│   │   │   └── event_model.dart         # Đối tượng Sự kiện (fromJson / toJson)
│   │   ├── services/
│   │   │   └── api_service.dart         # Lớp gọi HTTP REST API sang Backend
│   │   ├── providers/
│   │   │   └── calendar_provider.dart   # Quản lý State tập trung (Provider Pattern)
│   │   ├── widgets/
│   │   │   ├── top_header_bar.dart      # Thanh Header (Today, Chuyển tuần, View Day/Week)
│   │   │   ├── left_sidebar.dart        # Thanh Taskbar / Sidebar lọc danh mục
│   │   │   ├── weekly_grid_view.dart    # Lưới lịch tuần Syncfusion tùy biến thẻ Pastel
│   │   │   ├── ai_chat_sidebar.dart     # Khung Chatbot AI Scheduler độc lập
│   │   │   └── event_form_dialog.dart   # Popup Tạo / Sửa / Xóa & Báo lỗi trùng lịch
│   │   ├── screens/
│   │   │   └── main_layout_screen.dart  # Bố cục màn hình ghép nối các component
│   │   └── main.dart                    # Điểm khởi chạy ứng dụng Flutter
│   └── pubspec.yaml                     # Quản lý các package Flutter (Syncfusion, Http, Provider...)
│
└── README.md                            # Tài liệu tổng quan dự án
```

---

## 💻 YÊU CẦU MÔI TRƯỜNG (PREREQUISITES)

Để chạy và phát triển dự án trên máy tính, bạn cần cài đặt sẵn:

1. **Python:** Phiên bản `3.10` trở lên ([Tải tại python.org](https://www.python.org/downloads/)).
2. **Flutter SDK:** Phiên bản `3.22.x` trở lên ([Tải tại flutter.dev](https://docs.flutter.dev/get-started/install)).
3. **IDE đề xuất:** Visual Studio Code hoặc Android Studio / PyCharm.
   - *Extension khuyên dùng cho VS Code:* **Flutter**, **Dart**, **Python**.

---

## 🛠 HƯỚNG DẪN CÀI ĐẶT & KHỞI CHẠY CHI TIẾT

### 4.1. Khởi chạy Backend (Python FastAPI)

Mở **Terminal 1** trên máy tính:

```powershell
# 1. Đi vào thư mục backend
cd backend

# 2. Tạo môi trường ảo (chỉ cần làm 1 lần đầu)
python -m venv venv

# 3. Kích hoạt môi trường ảo:
# Trên Windows (PowerShell):
.\venv\Scripts\activate
# (Nếu PowerShell báo lỗi Script disabled, chạy lệnh: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned)

# Trên macOS / Linux:
source venv/bin/activate

# 4. Cài đặt các thư viện cần thiết
pip install fastapi "uvicorn[standard]" pydantic

# 5. Khởi động máy chủ phát triển (Development Server)
uvicorn main:app --reload
```

* Máy chủ Backend sẽ lắng nghe tại: **`http://127.0.0.1:8000`**
* Truy cập trang tài liệu API tự động (Swagger UI) để kiểm tra: **`http://127.0.0.1:8000/docs`**

---

### 4.2. Khởi chạy Frontend (Flutter SDK)

Mở **Terminal 2** (giữ nguyên Terminal 1 đang chạy server):

```powershell
# 1. Đi vào thư mục frontend
cd frontend

# 2. Cài đặt các thư viện liên quan được khai báo trong pubspec.yaml
flutter pub get

# 3. Kiểm tra các thiết bị có sẵn để chạy ứng dụng
flutter devices

# 4. Khởi chạy ứng dụng:
# Chạy bản Windows Desktop (Mượt mà nhất):
flutter run -d windows

# Hoặc chạy trên Trình duyệt Web:
flutter run -d chrome

# Hoặc chạy trên Điện thoại / Máy ảo Android:
flutter run -d android
```

---

## 📖 HƯỚNG DẪN ĐỌC & MỞ RỘNG MÃ NGUỒN (DEVELOPER GUIDE)

Nhờ kiến trúc module hóa, bạn có thể chỉnh sửa các phần riêng biệt mà không lo ảnh hưởng đến toàn bộ hệ thống:

| Nhu cầu chỉnh sửa | File cần can thiệp | Hướng dẫn thao tác |
| :--- | :--- | :--- |
| **Thay đổi bảng màu / Thêm danh mục** | `frontend/lib/core/app_colors.dart` | Thêm tên danh mục mới vào `categories` và định nghĩa màu tương ứng trong `getCategoryPastelColor()`. |
| **Thay đổi giao diện khối lịch tuần** | `frontend/lib/widgets/weekly_grid_view.dart` | Sửa widget trong hàm `appointmentBuilder` (ví dụ: bo góc, viền thẻ, thông tin hiển thị). |
| **Tùy biến hoặc gắn thêm icon Taskbar** | `frontend/lib/widgets/left_sidebar.dart` | Thêm các `IconButton` mới vào thanh Navigation Rail và định nghĩa sự kiện click. |
| **Sửa giao diện hoặc tích hợp logic Chatbot** | `frontend/lib/widgets/ai_chat_sidebar.dart` | Chỉnh sửa giao diện khung chat hoặc cập nhật hàm `sendUserChatMessage()` trong Provider. |
| **Thêm API hoặc nâng cấp thuật toán Backend** | `backend/main.py` | Bổ sung các hàm xử lý dữ liệu mới hoặc cập nhật logic hàm `check_time_conflict()`. |

---

## 📅 LỘ TRÌNH PHÁT TRIỂN (PROJECT ROADMAP)

* **Giai đoạn 1 (09/10 - 20/10):** Đặc tả yêu cầu phần mềm (SRS), phân tích Use Cases và thiết kế kiến trúc hệ thống. *(Hoàn thành)*
* **Giai đoạn 2 (21/10 - 28/10):** Thiết kế bản vẽ UI/UX và chuẩn hóa cấu trúc Cơ sở dữ liệu. *(Hoàn thành)*
* **Giai đoạn 3 (29/10 - 12/11 - Mốc 50% Báo cáo tiến độ):** Hoàn thiện 100% Core Lịch tuần Flutter, bộ API CRUD FastAPI và thuật toán kiểm tra xung đột thời gian. *(Hoàn thành)*
* **Giai đoạn 4 (14/11 - 25/11):** Nâng cấp Chatbot AI v2 (xử lý hội thoại đa lượt, tìm khung giờ trống thông minh).
* **Giai đoạn 5 (26/11 - 04/12):** Kiểm thử toàn diện (Unit Test, Integration Test) và tối ưu hiệu năng giao diện.
* **Giai đoạn 6 (05/12 - 10/12):** Đóng gói phần mềm, triển khai máy chủ và nghiệm thu sản phẩm cuối kỳ.

---

## 👥 THÀNH VIÊN THỰC HIỆN
* **Thành viên A:** Trưởng nhóm / Phụ trách Backend & AI Engine (`FastAPI`, `PostgreSQL`, `LLM Integration`).
* **Thành viên B:** Thành viên / Phụ trách Frontend & UI/UX Design (`Flutter`, `Dart`, `State Management`).
