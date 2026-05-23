class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || !value.contains('@')) {
      return 'Nhập email hợp lệ.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        !RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'Mật khẩu phải chứa chữ hoa, thường, số và ký tự đặc biệt.';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự.';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Nhập họ tên (tối thiểu 2 ký tự).';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Nhập lại mật khẩu để xác nhận.';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp.';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().length != 6) {
      return 'Nhập đủ 6 số OTP.';
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'Bắt buộc'}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName;
    }
    return null;
  }
}
