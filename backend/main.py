from datetime import datetime
from typing import Optional
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(
    title="Hệ thống Quản lý Lịch tuần",
    description="API cung cấp đầy đủ các thao tác Thêm, Sửa, Xóa và Kiểm tra trùng lịch",
    version="1.0.0"
)

# 1. Cấu hình CORS để ứng dụng Flutter kết nối được
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. Định nghĩa cấu trúc dữ liệu với Pydantic
class EventBase(BaseModel):
    title: str = Field(..., example="Họp nhóm đồ án Lịch tuần")
    start_time: datetime = Field(..., example="2026-11-13T09:00:00")
    end_time: datetime = Field(..., example="2026-11-13T10:30:00")
    category: str = Field(default="Công việc", example="Học tập")
    description: Optional[str] = Field(default="", example="Báo cáo tiến độ 50% với hội đồng")

class EventCreate(EventBase):
    pass

class EventUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    category: Optional[str] = None
    description: Optional[str] = None

class EventResponse(EventBase):
    id: int

# 3. Dữ liệu mẫu ban đầu (Fake Database)
fake_database: list[dict] = [
    {
        "id": 1,
        "title": "Họp giao ban đầu tuần",
        "start_time": datetime.fromisoformat("2026-11-09T08:00:00"),
        "end_time": datetime.fromisoformat("2026-11-09T09:30:00"),
        "category": "Công việc",
        "description": "Lập kế hoạch tuần"
    },
    {
        "id": 2,
        "title": "Học chuyên đề Flutter",
        "start_time": datetime.fromisoformat("2026-11-10T13:30:00"),
        "end_time": datetime.fromisoformat("2026-11-10T15:30:00"),
        "category": "Học tập",
        "description": "Thực hành dựng giao diện Weekly View"
    }
]

# 4. Thuật toán kiểm tra xung đột thời gian (Trùng lịch)
def check_time_conflict(new_start: datetime, new_end: datetime, exclude_id: Optional[int] = None):
    """
    Hai khoảng thời gian [S1, E1) và [S2, E2) bị trùng nhau khi:
    S1 < E2 và E1 > S2
    """
    if new_start >= new_end:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Thời gian kết thúc phải diễn ra sau thời gian bắt đầu!"
        )

    for event in fake_database:
        # Bỏ qua chính nó khi đang thao tác Cập nhật (Sửa)
        if exclude_id is not None and event["id"] == exclude_id:
            continue

        # Kiểm tra điều kiện giao nhau
        if new_start < event["end_time"] and new_end > event["start_time"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Trùng lịch với: '{event['title']}' ({event['start_time'].strftime('%H:%M')} - {event['end_time'].strftime('%H:%M')})"
            )

# --- 5. CÁC ĐƯỜNG DẪN API (ENDPOINTS) ---

@app.get("/api/events", response_model=list[EventResponse])
def get_all_events():
    """Lấy danh sách tất cả các sự kiện (đã sắp xếp theo thời gian bắt đầu)"""
    return sorted(fake_database, key=lambda x: x["start_time"])

@app.get("/api/events/{event_id}", response_model=EventResponse)
def get_event_detail(event_id: int):
    """Xem chi tiết 1 sự kiện theo ID"""
    for event in fake_database:
        if event["id"] == event_id:
            return event
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy sự kiện!")

@app.post("/api/events", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def create_event(event_in: EventCreate):
    """Tạo sự kiện mới có kiểm tra trùng giờ"""
    # 1. Kiểm tra xem có bị trùng lịch với sự kiện nào không
    check_time_conflict(event_in.start_time, event_in.end_time)

    # 2. Tạo ID mới và lưu vào cơ sở dữ liệu
    new_id = max([e["id"] for e in fake_database], default=0) + 1
    new_event = {
        "id": new_id,
        "title": event_in.title,
        "start_time": event_in.start_time,
        "end_time": event_in.end_time,
        "category": event_in.category,
        "description": event_in.description
    }
    fake_database.append(new_event)
    return new_event

@app.put("/api/events/{event_id}", response_model=EventResponse)
def update_event(event_id: int, event_update: EventUpdate):
    """Sửa thông tin hoặc dời lịch sự kiện"""
    target_event = None
    for event in fake_database:
        if event["id"] == event_id:
            target_event = event
            break

    if not target_event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy sự kiện để sửa!")

    # Tính toán thời gian mới nếu có thay đổi
    new_start = event_update.start_time or target_event["start_time"]
    new_end = event_update.end_time or target_event["end_time"]

    # Kiểm tra trùng lịch (loại trừ chính sự kiện này)
    check_time_conflict(new_start, new_end, exclude_id=event_id)

    # Cập nhật thông tin
    if event_update.title is not None:
        target_event["title"] = event_update.title
    if event_update.category is not None:
        target_event["category"] = event_update.category
    if event_update.description is not None:
        target_event["description"] = event_update.description
    target_event["start_time"] = new_start
    target_event["end_time"] = new_end

    return target_event

@app.delete("/api/events/{event_id}", status_code=status.HTTP_200_OK)
def delete_event(event_id: int):
    """Xóa một sự kiện khỏi lịch"""
    global fake_database
    initial_length = len(fake_database)
    fake_database = [e for e in fake_database if e["id"] != event_id]

    if len(fake_database) == initial_length:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy sự kiện để xóa!")

    return {"status": "success", "message": f"Đã xóa thành công sự kiện #{event_id}"}