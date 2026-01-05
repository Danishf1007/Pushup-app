/// String manipulation helper functions.
///
/// Provides common string formatting and manipulation utilities.
abstract class StringHelper {
  /// Capitalize first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Convert to title case (first letter of significant words capitalized)
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    const minorWords = {
      'a',
      'an',
      'the',
      'and',
      'but',
      'or',
      'for',
      'nor',
      'on',
      'at',
      'to',
      'by',
      'of',
      'in',
    };
    final words = text.toLowerCase().split(' ');

    return words
        .asMap()
        .map((index, word) {
          if (index == 0 || !minorWords.contains(word)) {
            return MapEntry(index, capitalize(word));
          }
          return MapEntry(index, word);
        })
        .values
        .join(' ');
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Get initials from name (e.g., "John Doe" -> "JD")
  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';

    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .take(maxInitials)
        .map((word) => word[0].toUpperCase())
        .join();

    return initials;
  }

  /// Remove extra whitespace
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Check if string contains only letters
  static bool isAlpha(String text) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(text);
  }

  /// Check if string contains only numbers
  static bool isNumeric(String text) {
    return RegExp(r'^[0-9]+$').hasMatch(text);
  }

  /// Check if string is alphanumeric
  static bool isAlphanumeric(String text) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(text);
  }

  /// Format number with commas (e.g., 1000 -> "1,000")
  static String formatNumber(num number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  /// Convert camelCase to Sentence case
  static String camelToSentence(String text) {
    if (text.isEmpty) return text;

    final result = text
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match[0]}')
        .trim();

    return capitalize(result.toLowerCase());
  }

  /// Convert snake_case to Sentence case
  static String snakeToSentence(String text) {
    if (text.isEmpty) return text;
    return capitalize(text.replaceAll('_', ' '));
  }

  /// Check if string is a valid URL
  static bool isValidUrl(String text) {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(text);
  }

  /// Pluralize word based on count
  static String pluralize(String word, int count, {String? plural}) {
    if (count == 1) return word;
    return plural ?? '${word}s';
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
