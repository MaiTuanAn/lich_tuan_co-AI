-- =============================================================================
-- SchedulAI - Migration 2: Row Level Security + Grants
-- Quy tắc: mỗi user (kể cả khách ẩn danh) CHỈ thấy và sửa dữ liệu của chính mình.
-- Khách ẩn danh trong Supabase vẫn dùng role "authenticated" nên dùng chung policy.
-- =============================================================================

-- 1. Bật RLS cho mọi bảng (bảng nào chưa có policy sẽ bị chặn hoàn toàn)
alter table public.profiles       enable row level security;
alter table public.categories     enable row level security;
alter table public.events         enable row level security;
alter table public.user_settings  enable row level security;
alter table public.chat_messages  enable row level security;

-- 2. Cấp quyền truy cập Data API tường minh (chỉ role authenticated, không cấp cho anon)
grant usage on schema public to authenticated;

grant select, update                 on public.profiles      to authenticated;
grant select, insert, update, delete on public.categories    to authenticated;
grant select, insert, update, delete on public.events        to authenticated;
grant select, insert, update         on public.user_settings to authenticated;
grant select, insert, delete         on public.chat_messages to authenticated;

-- 3. Policy

-- profiles: xem và sửa hồ sơ của mình (hàng được tạo bởi trigger, không cho insert tay)
create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- categories
create policy "categories_select_own" on public.categories
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy "categories_insert_own" on public.categories
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "categories_update_own" on public.categories
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "categories_delete_own" on public.categories
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- events
create policy "events_select_own" on public.events
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy "events_insert_own" on public.events
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "events_update_own" on public.events
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "events_delete_own" on public.events
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- user_settings
create policy "settings_select_own" on public.user_settings
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy "settings_insert_own" on public.user_settings
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "settings_update_own" on public.user_settings
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- chat_messages
create policy "chat_select_own" on public.chat_messages
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy "chat_insert_own" on public.chat_messages
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "chat_delete_own" on public.chat_messages
  for delete to authenticated
  using (user_id = (select auth.uid()));
