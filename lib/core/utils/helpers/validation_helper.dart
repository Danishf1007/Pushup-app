/// Form validation helper functions.
///
/// Provides reusable validation logic for form fields.
abstract class ValidationHelper {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate name (letters and spaces only)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove common formatting characters
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanedValue.length < 10) {
      return 'Please enter a valid phone number';
    }
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleanedValue)) {
      return 'Phone number can only contain digits';
    }
    return null;
  }

  /// Validate positive integer
  static String? validatePositiveInt(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    if (intValue <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validate range
  static String? validateRange(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid number';
    }
    if (intValue < min || intValue > max) {
      return '$fieldName must be between $min and $max';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value, {
    required int minLength,
    String fieldName = 'Field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value, {
    required int maxLength,
    String fieldName = 'Field',
  }) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }
}
