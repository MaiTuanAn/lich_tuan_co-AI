import 'package:supabase_flutter/supabase_flutter.dart';

/// Bao Supabase Auth: đăng ký, đăng nhập, khách ẩn danh, đổi mật khẩu.
/// Mọi lỗi được đổi thành Exception(message tiếng Việt) để UI hiển thị trực tiếp.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  /// Phiên đăng nhập được supabase_flutter tự lưu trong trình duyệt (F5 không mất).
  /// Nếu chưa có phiên nào -> tạo khách ẩn danh để có chỗ lưu lịch.
  Future<void> ensureSession() async {
    if (_client.auth.currentSession == null) {
      await _guard(() => _client.auth.signInAnonymously());
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await _guard(
      () => _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'full_name': fullName.trim()},
      ),
    );
    // Nếu dashboard đang bật "Confirm email" thì chưa có phiên cho tới khi xác nhận
    if (res.session == null) {
      throw Exception(
        'Đăng ký thành công! Hãy kiểm tra email để xác nhận rồi đăng nhập.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _guard(
      () => _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      ),
    );
  }

  /// Đăng xuất rồi tạo khách ẩn danh mới (lịch khách mới, trống).
  Future<void> signOutToGuest() async {
    await _guard(() => _client.auth.signOut());
    await ensureSession();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('Vui lòng đăng nhập để đổi mật khẩu!');
    }

    // Xác minh mật khẩu cũ bằng cách đăng nhập lại
    try {
      await _client.auth.signInWithPassword(email: email, password: oldPassword);
    } on AuthException {
      throw Exception('Mật khẩu hiện tại không đúng!');
    }

    await _guard(
      () => _client.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }

  /// Lấy họ tên từ bảng profiles (do trigger tạo khi đăng ký)
  Future<String?> fetchFullName() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', uid)
        .maybeSingle();
    return row?['full_name'] as String?;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw Exception(_translate(e));
    }
  }

  String _translate(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return 'Email hoặc mật khẩu không chính xác!';
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        msg.contains('already registered')) {
      return 'Email này đã được đăng ký! Vui lòng dùng email khác hoặc đăng nhập.';
    }
    if (code == 'weak_password') {
      return 'Mật khẩu quá yếu, hãy chọn mật khẩu mạnh hơn!';
    }
    if (code == 'email_not_confirmed') {
      return 'Email chưa được xác nhận. Hãy kiểm tra hộp thư của bạn.';
    }
    if (code.contains('rate_limit')) {
      return 'Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút.';
    }
    if (code == 'same_password') {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại!';
    }
    return e.message;
  }
}
