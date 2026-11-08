import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/calendar_provider.dart';

// ============================================================================
// BỘ KIỂM TRA ĐỊNH DẠNG EMAIL & MẬT KHẨU DÙNG CHUNG (REGEX VALIDATION)
// ============================================================================
class InputValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
  );
  static final RegExp _letterRegex = RegExp(r'[a-zA-Z]');
  static final RegExp _digitRegex = RegExp(r'\d');

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ Email!';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng (VD: tenban@gmail.com)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu!';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự!';
    }
    if (!_letterRegex.hasMatch(value) || !_digitRegex.hasMatch(value)) {
      return 'Mật khẩu phải bao gồm cả chữ cái và chữ số!';
    }
    return null;
  }
}

// ============================================================================
// 1. HỘP THOẠI ĐĂNG NHẬP & ĐĂNG KÝ (CÓ KIỂM TRA DỮ LIỆU CHẶT CHẼ)
// ============================================================================
class LoginRegisterDialog extends StatefulWidget {
  final bool initialIsLogin;
  const LoginRegisterDialog({super.key, this.initialIsLogin = true});

  @override
  State<LoginRegisterDialog> createState() => _LoginRegisterDialogState();
}

class _LoginRegisterDialogState extends State<LoginRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isLogin;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _rememberMe = false;
  bool _agreeTerms = true;
  bool _isLoading = false;
  String? _serverError;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  Future<void> _handleSubmit() async {
    setState(() => _serverError = null);

    // 1. Chạy toàn bộ các hàm validator của Form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogin && !_agreeTerms) {
      setState(() => _serverError = 'Vui lòng đồng ý với Điều khoản dịch vụ!');
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<CalendarProvider>();

    try {
      if (_isLogin) {
        await provider.loginAccount(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        await provider.registerAccount(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _serverError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

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
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Đăng nhập để mở khóa Trợ lý AI và đồng bộ lịch'
                      : 'Tạo tài khoản miễn phí để sử dụng Trợ lý Lịch AI',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: Colors.grey),
                ),
                const SizedBox(height: 18),

                // Hiển thị lỗi từ Server (VD: Email đã tồn tại hoặc sai mật khẩu)
                if (_serverError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Trường Họ và tên (Khi Đăng ký)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return 'Vui lòng nhập họ và tên (tối thiểu 2 ký tự)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Trường Email (Kiểm tra chuẩn định dạng Regex)
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'tenban@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: InputValidators.validateEmail,
                ),
                const SizedBox(height: 14),

                // Trường Mật khẩu (Kiểm tra >= 8 ký tự, gồm chữ và số)
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu *',
                    helperText: !_isLogin ? 'Ít nhất 8 ký tự, bao gồm cả chữ và số' : null,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: InputValidators.validatePassword,
                ),

                // Trường Xác nhận mật khẩu (Khi Đăng ký)
                if (!_isLogin) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu *',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Vui lòng nhập lại mật khẩu xác nhận!';
                      }
                      if (v != _passCtrl.text) {
                        return 'Mật khẩu xác nhận không khớp!';
                      }
                      return null;
                    },
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
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3E8A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isLogin ? 'Đăng nhập' : 'Đăng ký tài khoản',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? '),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _serverError = null;
                          _formKey.currentState?.reset();
                        });
                      },
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
      ),
    );
  }
}

// ============================================================================
// 2. HỘP THOẠI QUẢN LÝ TÀI KHOẢN & ĐỔI MẬT KHẨU (KHI BẤM VÀO AVATAR TRÒN)
// ============================================================================
class AccountProfileDialog extends StatefulWidget {
  const AccountProfileDialog({super.key});

  @override
  State<AccountProfileDialog> createState() => _AccountProfileDialogState();
}

class _AccountProfileDialogState extends State<AccountProfileDialog> {
  bool _showPasswordForm = false;
  final _passFormKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  String? _statusMessage;
  bool _isError = false;

  Future<void> _submitChangePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    try {
      await context.read<CalendarProvider>().changeUserPassword(
            oldPassword: _oldPassCtrl.text,
            newPassword: _newPassCtrl.text,
          );
      setState(() {
        _isError = false;
        _statusMessage = 'Đổi mật khẩu thành công!';
        _showPasswordForm = false;
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Quản lý Tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông tin User Profile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.indigo.shade600,
                  child: Text(
                    provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'U',
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
              const Divider(height: 24),

              if (_statusMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(color: _isError ? Colors.red.shade800 : Colors.green.shade800),
                  ),
                ),

              // Nút mở form Đổi mật khẩu
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: const Text('Đổi mật khẩu (Change Password)'),
                trailing: Icon(_showPasswordForm ? Icons.expand_less : Icons.expand_more),
                onTap: () => setState(() => _showPasswordForm = !_showPasswordForm),
              ),

              // Form Đổi mật khẩu (cũng kiểm tra >= 8 ký tự gồm chữ và số)
              if (_showPasswordForm)
                Form(
                  key: _passFormKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _oldPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu hiện tại',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu hiện tại' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _newPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu mới (ít nhất 8 ký tự chữ & số)',
                            border: OutlineInputBorder(),
                          ),
                          validator: InputValidators.validatePassword,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _submitChangePassword,
                            child: const Text('Cập nhật mật khẩu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_done_outlined, color: Colors.teal),
                title: const Text('Cloud Sync Status: Synced'),
                trailing: OutlinedButton(
                  onPressed: provider.loadEvents,
                  child: const Text('Sync Now'),
                ),
              ),
              const SizedBox(height: 18),

              // Nút Đăng xuất
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.logoutToGuestMode();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Log Out (Đăng xuất)',
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
      ),
    );
  }
}

// ============================================================================
// 3. HỘP THOẠI TẠO DANH MỤC MỚI TỐI GIẢN (CHỈ TÊN + BẢNG MÀU)
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
                final isSelected = _selectedColor == color;
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