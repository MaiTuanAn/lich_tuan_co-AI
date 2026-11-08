import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/calendar_provider.dart';

// ============================================================================
// 1. HỘP THOẠI ĐĂNG NHẬP & ĐĂNG KÝ TÀI KHOẢN (CHUYỂN ĐỔI MƯỢT MÀ)
// ============================================================================
class LoginRegisterDialog extends StatefulWidget {
  final bool initialIsLogin;
  const LoginRegisterDialog({super.key, this.initialIsLogin = true});

  @override
  State<LoginRegisterDialog> createState() => _LoginRegisterDialogState();
}

class _LoginRegisterDialogState extends State<LoginRegisterDialog> {
  late bool _isLogin;
  bool _obscurePass = true;
  bool _rememberMe = false;
  bool _agreeTerms = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  void _handleSubmit() {
    final provider = context.read<CalendarProvider>();
    provider.login(
      _nameCtrl.text.trim().isEmpty ? 'Nguyễn Văn A' : _nameCtrl.text.trim(),
      _emailCtrl.text.trim().isEmpty ? 'nguyenvana@gmail.com' : _emailCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút đóng X góc phải
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Logo SchedulAI
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 32, color: Colors.indigo.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'SchedulAI',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Đăng nhập để mở khóa Trợ lý AI và đồng bộ lịch'
                    : 'Tạo tài khoản miễn phí để sử dụng Trợ lý Lịch AI',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: Colors.grey),
              ),
              const SizedBox(height: 22),

              if (!_isLogin) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: _isLogin ? 'Email / Tên đăng nhập' : 'Email',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),

              if (!_isLogin) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscurePass,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              if (_isLogin)
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v!),
                    ),
                    const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) => setState(() => _agreeTerms = v!),
                    ),
                    const Expanded(
                      child: Text(
                        'Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: _handleSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3E8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(
                    _isLogin ? 'Đăng nhập' : 'Đăng ký tài khoản',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (_isLogin) ...[
                const SizedBox(height: 16),
                const Text('Hoặc tiếp tục với', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                    label: const Text('Tiếp tục với Google'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? '),
                  InkWell(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                      style: const TextStyle(
                        color: Color(0xFF0F3E8A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. HỘP THOẠI QUẢN LÝ TÀI KHOẢN RIÊNG BIỆT (KHI BẤM VÀO AVATAR TRÒN)
// ============================================================================
class AccountProfileDialog extends StatelessWidget {
  const AccountProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Account Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.indigo.shade600,
                child: Text(
                  provider.userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(provider.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: Text(provider.userEmail),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Student / Sinh viên', style: TextStyle(fontSize: 11.5, color: Colors.indigo)),
              ),
            ),
            const Divider(height: 28),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Đổi mật khẩu (Change Password)'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined, color: Colors.teal),
              title: const Text('Cloud Sync Status: Synced'),
              trailing: OutlinedButton(
                onPressed: provider.loadEvents,
                child: const Text('Sync Now'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.logoutToGuestMode();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Log Out (Đăng xuất về Chế độ Khách)',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. HỘP THOẠI TẠO DANH MỤC MỚI TỐI GIẢN (CHỈ TÊN + BẢNG MÀU, BỎ ICON & PREVIEW)
// ============================================================================
class CreateCategoryDialog extends StatefulWidget {
  const CreateCategoryDialog({super.key});

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = AppColors.categoryPalette.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Create New Category',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Ví dụ: Tập Gym & Thể Thao',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColors.categoryPalette.map((color) {
                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              context.read<CalendarProvider>().addCategory(
                    _nameController.text.trim(),
                    _selectedColor,
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Tạo danh mục'),
        ),
      ],
    );
  }
}
