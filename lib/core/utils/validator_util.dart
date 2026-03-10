class ValidatorUtil {
  static String? phoneNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your mobile number.';
    }

    String cleanedValue = value.trim().replaceAll(" ", "");

    if (cleanedValue.length != 10) {
      return 'Phone number must be exactly 10 digits.';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(cleanedValue)) {
      return 'Phone number must contain only digits (0-9).';
    }

    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter the password";
    }

    String trimmedPassword = value.trim().replaceAll(" ", "");

    if (trimmedPassword.length < 6) {
      return "Password must be at least 6 characters long.";
    }

    if (!RegExp(r'[A-Z]').hasMatch(trimmedPassword)) {
      return 'Password must contain at least one uppercase letter.';
    }

    if (!RegExp(r'[a-z]').hasMatch(trimmedPassword)) {
      return 'Password must contain at least one lowercase letter.';
    }

    if (!RegExp(r'\d').hasMatch(trimmedPassword)) {
      return 'Password must contain at least one number.';
    }

    return null;
  }

  static String? fullnameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your full name";
    }

    String trimmedName = value.trim();
    if (trimmedName.length < 3) {
      return "Name must be at least 3 character long.";
    }

    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes.';
    }

    return null;
  }

  static String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your email";
    }

    final trimmedEmail = value.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return "Please enter a valid email address";
    }

    return null;
  }

  static String? confirmPasswordValidator({
    required String? value,
    required String? originalPassword,
  }) {
    if (value == null || value.trim().isEmpty) {
      return "Please retype the password";
    }
    if (value != originalPassword) {
      return "Passwords do not match!";
    }

    return null;
  }

  static String? validatePin(String value) {
    final cleaned = value.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(cleaned)) {
      return 'PIN must be exactly 4 digits.';
    }
    return null;
  }

  static String? validateAmount(double amount) {
    if (amount <= 0) {
      return 'Amount must be greater than 0.';
    }

    final scaled = amount * 100;
    if ((scaled - scaled.round()).abs() > 0.000001) {
      return 'Amount can have at most 2 decimal places.';
    }

    return null;
  }

  static String? validateRemark(String? remark) {
    final normalized = normalizeRemark(remark);
    if (normalized != null && normalized.length > 140) {
      return 'Request message must be at most 140 characters.';
    }
    return null;
  }

  static String? normalizeRemark(String? remark) {
    final trimmed = remark?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String normalizeAmountInput(String value) {
    var sanitized = value.replaceAll(RegExp(r'[^0-9.]'), '');

    if (sanitized.isEmpty) {
      return '';
    }

    final firstDot = sanitized.indexOf('.');
    if (firstDot >= 0) {
      final integerPart = sanitized.substring(0, firstDot);
      var decimalPart = sanitized.substring(firstDot + 1).replaceAll('.', '');
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      sanitized = decimalPart.isEmpty
          ? '$integerPart.'
          : '$integerPart.$decimalPart';
    }

    if (sanitized.startsWith('.')) {
      sanitized = '0$sanitized';
    }

    return sanitized;
  }

  static double normalizeAmount(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }

  static String? validateAccountNumber(String value) {
    final cleaned = value.trim();
    if (!RegExp(r'^\d{8,20}$').hasMatch(cleaned)) {
      return 'Account number must be 8 to 20 digits.';
    }
    return null;
  }

  static String? validateBankName(String value) {
    final cleaned = value.trim();
    if (cleaned.length < 2) {
      return 'Bank name must be at least 2 characters.';
    }
    return null;
  }
}
