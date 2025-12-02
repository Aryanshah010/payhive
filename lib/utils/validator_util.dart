class ValidatorUtil {
  
  static String? phoneNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number.';
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
      return "Please enter your password";
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
}
