extension StringExtensions on String {
  bool get isEmptyOrNull => this == null || isEmpty;

  bool get isNotEmptyOrNull => !isEmptyOrNull;

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeAll {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  String get toTitleCase {
    if (isEmpty) return this;
    final words = split(' ');
    return words.map((word) => word.capitalize).join(' ');
  }

  String get toSnakeCase {
    if (isEmpty) return this;
    return replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1_$2')
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .toLowerCase();
  }

  String get toCamelCase {
    if (isEmpty) return this;
    final parts = split('_');
    return parts.first + parts.skip(1).map((part) => part.capitalize).join('');
  }

  bool get isEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  bool get isPhone {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(this);
  }

  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  double get toDouble => double.tryParse(this) ?? 0.0;

  int get toInt => int.tryParse(this) ?? 0;

  DateTime? get toDateTime {
    try {
      return DateTime.parse(this);
    } catch (e) {
      return null;
    }
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  String removeHtmlTags() {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get sanitize {
    return replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
  }
}