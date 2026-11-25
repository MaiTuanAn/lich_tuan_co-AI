-- =============================================================================
-- SchedulAI - Migration 1: Schema
-- Thay thế hoàn toàn backend/main.py + schedulai.db (SQLite)
-- =============================================================================

-- Extension cho ràng buộc chống trùng lịch (exclusion constraint)
create extension if not exists btree_gist with schema extensions;

-- -----------------------------------------------------------------------------
-- Hàm tiện ích: tự cập nhật cột updated_at
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 1. profiles: thông tin hiển thị của user (mật khẩu/email nằm ở auth.users)
-- -----------------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default 'Khách',
  role        text not null default 'Student / Sinh viên',
  created_at  timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 2. categories: danh mục (có màu) của từng user
-- -----------------------------------------------------------------------------
create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  name        text not null check (char_length(btrim(name)) > 0),
  color       text not null default '#9333EA'
              check (color ~ '^#[0-9A-Fa-f]{6}$'),
  is_visible  boolean not null default true,
  created_at  timestamptz not null default now()
);

-- Mỗi user không có 2 danh mục trùng tên (không phân biệt hoa/thường)
create unique index categories_user_name_uq
  on public.categories (user_id, lower(btrim(name)));

-- -----------------------------------------------------------------------------
-- 3. events: sự kiện lịch tuần
--    - timestamptz: lưu theo UTC, hết lỗi lệch múi giờ của bản SQLite cũ
--    - exclusion constraint: DB tự từ chối sự kiện trùng giờ của cùng 1 user
--      (thay cho hàm check_time_conflict_sqlite trong main.py)
-- -----------------------------------------------------------------------------
create table public.events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid()
               references auth.users (id) on delete cascade,
  category_id  uuid references public.categories (id) on delete set null,
  title        text not null check (char_length(btrim(title)) > 0),
  description  text not null default '',
  start_time   timestamptz not null,
  end_time     timestamptz not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  constraint events_time_order check (end_time > start_time),
  constraint events_no_overlap exclude using gist (
    user_id with =,
    tstzrange(start_time, end_time) with &&
  )
);

create index events_user_start_idx on public.events (user_id, start_time);

create trigger events_set_updated_at
  before update on public.events
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 4. user_settings: cài đặt người dùng (lưu dạng JSON cho linh hoạt)
-- -----------------------------------------------------------------------------
create table public.user_settings (
  user_id     uuid primary key default auth.uid()
              references auth.users (id) on delete cascade,
  settings    jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

create trigger user_settings_set_updated_at
  before update on public.user_settings
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 5. chat_messages: lịch sử chat với trợ lý AI
-- -----------------------------------------------------------------------------
create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  is_user     boolean not null,
  text        text not null,
  suggestion  jsonb,
  created_at  timestamptz not null default now()
);

create index chat_messages_user_created_idx
  on public.chat_messages (user_id, created_at);

-- -----------------------------------------------------------------------------
-- 6. Trigger: khi có user mới (kể cả khách ẩn danh) -> tự tạo
--    profile + 4 danh mục mặc định + dòng settings
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''), 'Khách')
  );

  insert into public.categories (user_id, name, color) values
    (new.id, 'Công việc', '#2563EB'),
    (new.id, 'Học tập',   '#16A34A'),
    (new.id, 'Cá nhân',   '#EA580C'),
    (new.id, 'Khẩn cấp',  '#DC2626');

  insert into public.user_settings (user_id) values (new.id);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
