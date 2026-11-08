import hashlib
import re
import secrets
import sqlite3
from datetime import datetime
from typing import Optional
from fastapi import FastAPI, HTTPException, Header, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

app = FastAPI(
    title="SchedulAI Backend - SQLite Real Database",
    version="2.1.0"
)

# 1. Cấu hình CORS cho phép Flutter kết nối
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==============================================================================
# 2. KHỞI TẠO CƠ SỞ DỮ LIỆU THẬT SQLITE (LƯU TRONG FILE schedulai.db)
# ==============================================================================
DB_FILE = "schedulai.db"

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row  # Trả về kết quả dạng từ điển (dict-like)
    return conn

def init_database():
    conn = get_db_connection()
    cursor = conn.cursor()

    # Bảng 1: Lưu tài khoản người dùng
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT DEFAULT 'Student / Sinh viên',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Bảng 2: Lưu phiên đăng nhập (Access Tokens)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS user_tokens (
            token TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
    """)

    # Bảng 3: Lưu sự kiện lịch tuần (user_id = NULL là lịch ở Chế độ Khách)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NULL,
            title TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            category TEXT DEFAULT 'Công việc',
            description TEXT DEFAULT '',
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
    """)

    conn.commit()
    conn.close()

# Tự động tạo file schedulai.db và các bảng ngay khi chạy server
init_database()

# ==============================================================================
# 3. CÁC HÀM KIỂM TRA ĐỊNH DẠNG EMAIL & MẬT KHẨU (REGEX VALIDATORS)
# ==============================================================================
EMAIL_REGEX = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"

def validate_email_format(email: str) -> str:
    cleaned = email.strip().lower()
    if not re.match(EMAIL_REGEX, cleaned):
        raise ValueError("Email không đúng định dạng chuẩn (ví dụ: tenban@gmail.com)!")
    return cleaned

def validate_password_strength(password: str) -> str:
    if len(password) < 8:
        raise ValueError("Mật khẩu phải có ít nhất 8 ký tự!")
    if not re.search(r"[A-Za-z]", password):
        raise ValueError("Mật khẩu phải chứa ít nhất 1 chữ cái (a-z hoặc A-Z)!")
    if not re.search(r"\d", password):
        raise ValueError("Mật khẩu phải chứa ít nhất 1 chữ số (0-9)!")
    return password

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

# ==============================================================================
# 4. KHUÔN MẪU DỮ LIỆU (PYDANTIC SCHEMAS)
# ==============================================================================
class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2)
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def check_email(cls, v: str) -> str:
        return validate_email_format(v)

    @field_validator("password")
    @classmethod
    def check_password(cls, v: str) -> str:
        return validate_password_strength(v)

class LoginRequest(BaseModel):
    email: str
    password: str

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def check_new_password(cls, v: str) -> str:
        return validate_password_strength(v)

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    role: str

class AuthResponse(BaseModel):
    access_token: str
    user: UserResponse

class EventCreate(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime
    category: str = "Công việc"
    description: Optional[str] = ""

class EventUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    category: Optional[str] = None
    description: Optional[str] = None

class EventResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    title: str
    start_time: datetime
    end_time: datetime
    category: str
    description: str

# ==============================================================================
# 5. HÀM XÁC THỰC TOKEN TỪ DATABASE
# ==============================================================================
def get_current_user_id(authorization: Optional[str] = Header(default=None)) -> Optional[int]:
    if not authorization or not authorization.startswith("Bearer "):
        return None
    token = authorization.replace("Bearer ", "").strip()
    conn = get_db_connection()
    row = conn.execute("SELECT user_id FROM user_tokens WHERE token = ?", (token,)).fetchone()
    conn.close()
    return row["user_id"] if row else None

# ==============================================================================
# 6. CÁC ENDPOINTS QUẢN LÝ TÀI KHOẢN (LƯU VĨNH VIỄN VÀO SQLITE)
# ==============================================================================

@app.post("/api/auth/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register_account(req: RegisterRequest):
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Kiểm tra email trùng lặp trong bảng users
    existing = cursor.execute("SELECT id FROM users WHERE email = ?", (req.email,)).fetchone()
    if existing:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email này đã được đăng ký! Vui lòng dùng email khác hoặc đăng nhập."
        )

    # 2. Lưu tài khoản mới vào file schedulai.db
    pwd_hash = hash_password(req.password)
    cursor.execute(
        "INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, ?)",
        (req.full_name.strip(), req.email, pwd_hash, "Student / Sinh viên")
    )
    user_id = cursor.lastrowid

    # 3. Sinh Access Token và lưu vào bảng user_tokens
    token = secrets.token_hex(24)
    cursor.execute("INSERT INTO user_tokens (token, user_id) VALUES (?, ?)", (token, user_id))
    conn.commit()

    user_row = cursor.execute("SELECT id, full_name, email, role FROM users WHERE id = ?", (user_id,)).fetchone()
    conn.close()

    return {
        "access_token": token,
        "user": dict(user_row)
    }

@app.post("/api/auth/login", response_model=AuthResponse)
def login_account(req: LoginRequest):
    cleaned_email = req.email.strip().lower()
    pwd_hash = hash_password(req.password)

    conn = get_db_connection()
    cursor = conn.cursor()
    user_row = cursor.execute(
        "SELECT id, full_name, email, role FROM users WHERE email = ? AND password_hash = ?",
        (cleaned_email, pwd_hash)
    ).fetchone()

    if not user_row:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không chính xác!"
        )

    token = secrets.token_hex(24)
    cursor.execute("INSERT INTO user_tokens (token, user_id) VALUES (?, ?)", (token, user_row["id"]))
    conn.commit()
    conn.close()

    return {
        "access_token": token,
        "user": dict(user_row)
    }

@app.put("/api/auth/change-password")
def change_password(
    req: ChangePasswordRequest,
    authorization: Optional[str] = Header(default=None)
):
    user_id = get_current_user_id(authorization)
    if not user_id:
        raise HTTPException(status_code=401, detail="Vui lòng đăng nhập để đổi mật khẩu!")

    conn = get_db_connection()
    cursor = conn.cursor()
    user_row = cursor.execute("SELECT password_hash FROM users WHERE id = ?", (user_id,)).fetchone()

    if not user_row or user_row["password_hash"] != hash_password(req.old_password):
        conn.close()
        raise HTTPException(status_code=400, detail="Mật khẩu hiện tại không đúng!")

    cursor.execute(
        "UPDATE users SET password_hash = ? WHERE id = ?",
        (hash_password(req.new_password), user_id)
    )
    conn.commit()
    conn.close()
    return {"status": "success", "message": "Đổi mật khẩu thành công!"}

# ==============================================================================
# 7. CÁC ENDPOINTS LỊCH TUẦN (LƯU VĨNH VIỄN VÀO SQLITE)
# ==============================================================================

def check_time_conflict_sqlite(
    conn: sqlite3.Connection,
    new_start: datetime,
    new_end: datetime,
    user_id: Optional[int],
    exclude_id: Optional[int] = None
):
    if new_start >= new_end:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Thời gian kết thúc phải lớn hơn thời gian bắt đầu!"
        )

    if user_id is None:
        rows = conn.execute("SELECT id, title, start_time, end_time FROM events WHERE user_id IS NULL").fetchall()
    else:
        rows = conn.execute("SELECT id, title, start_time, end_time FROM events WHERE user_id = ?", (user_id,)).fetchall()

    for r in rows:
        if exclude_id is not None and r["id"] == exclude_id:
            continue
        ev_start = datetime.fromisoformat(r["start_time"])
        ev_end = datetime.fromisoformat(r["end_time"])
        if new_start < ev_end and new_end > ev_start:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Trùng lịch với '{r['title']}' ({ev_start.strftime('%H:%M')} - {ev_end.strftime('%H:%M')})"
            )

@app.get("/api/events", response_model=list[EventResponse])
def get_events(authorization: Optional[str] = Header(default=None)):
    user_id = get_current_user_id(authorization)
    conn = get_db_connection()
    if user_id is None:
        rows = conn.execute("SELECT * FROM events WHERE user_id IS NULL ORDER BY start_time ASC").fetchall()
    else:
        rows = conn.execute("SELECT * FROM events WHERE user_id = ? ORDER BY start_time ASC", (user_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]

@app.post("/api/events", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def create_event(
    event_in: EventCreate,
    authorization: Optional[str] = Header(default=None)
):
    user_id = get_current_user_id(authorization)
    conn = get_db_connection()
    try:
        check_time_conflict_sqlite(conn, event_in.start_time, event_in.end_time, user_id)
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO events (user_id, title, start_time, end_time, category, description)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                event_in.title.strip(),
                event_in.start_time.isoformat(),
                event_in.end_time.isoformat(),
                event_in.category,
                event_in.description or ""
            )
        )
        conn.commit()
        new_id = cursor.lastrowid
        row = conn.execute("SELECT * FROM events WHERE id = ?", (new_id,)).fetchone()
        return dict(row)
    finally:
        conn.close()

@app.put("/api/events/{event_id}", response_model=EventResponse)
def update_event(
    event_id: int,
    event_update: EventUpdate,
    authorization: Optional[str] = Header(default=None)
):
    user_id = get_current_user_id(authorization)
    conn = get_db_connection()
    try:
        if user_id is None:
            target = conn.execute("SELECT * FROM events WHERE id = ? AND user_id IS NULL", (event_id,)).fetchone()
        else:
            target = conn.execute("SELECT * FROM events WHERE id = ? AND user_id = ?", (event_id, user_id)).fetchone()

        if not target:
            raise HTTPException(status_code=404, detail="Không tìm thấy sự kiện!")

        new_start = event_update.start_time or datetime.fromisoformat(target["start_time"])
        new_end = event_update.end_time or datetime.fromisoformat(target["end_time"])
        check_time_conflict_sqlite(conn, new_start, new_end, user_id, exclude_id=event_id)

        new_title = event_update.title if event_update.title is not None else target["title"]
        new_cat = event_update.category if event_update.category is not None else target["category"]
        new_desc = event_update.description if event_update.description is not None else target["description"]

        conn.execute(
            """
            UPDATE events
            SET title = ?, start_time = ?, end_time = ?, category = ?, description = ?
            WHERE id = ?
            """,
            (new_title, new_start.isoformat(), new_end.isoformat(), new_cat, new_desc, event_id)
        )
        conn.commit()
        updated = conn.execute("SELECT * FROM events WHERE id = ?", (event_id,)).fetchone()
        return dict(updated)
    finally:
        conn.close()

@app.delete("/api/events/{event_id}")
def delete_event(event_id: int, authorization: Optional[str] = Header(default=None)):
    user_id = get_current_user_id(authorization)
    conn = get_db_connection()
    cursor = conn.cursor()
    if user_id is None:
        cursor.execute("DELETE FROM events WHERE id = ? AND user_id IS NULL", (event_id,))
    else:
        cursor.execute("DELETE FROM events WHERE id = ? AND user_id = ?", (event_id, user_id))
    conn.commit()
    deleted_count = cursor.rowcount
    conn.close()

    if deleted_count == 0:
        raise HTTPException(status_code=404, detail="Không tìm thấy sự kiện để xóa!")
    return {"status": "success"}