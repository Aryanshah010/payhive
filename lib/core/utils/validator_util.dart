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
}
