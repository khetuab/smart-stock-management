import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Size
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Navigation
  void push(Widget widget) => Navigator.push(
    this,
    MaterialPageRoute(builder: (_) => widget),
  );

  void pushReplacement(Widget widget) => Navigator.pushReplacement(
    this,
    MaterialPageRoute(builder: (_) => widget),
  );

  void pushAndRemoveUntil(Widget widget) => Navigator.pushAndRemoveUntil(
    this,
    MaterialPageRoute(builder: (_) => widget),
        (route) => false,
  );

  void pop<T extends Object?>([T? result]) => Navigator.pop(this, result);

  // Snackbar
  void showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccess(String message) {
    showSnackBar(message, color: Colors.green);
  }

  void showError(String message) {
    showSnackBar(message, color: Colors.red);
  }

  void showWarning(String message) {
    showSnackBar(message, color: Colors.orange);
  }

  // Dialog
  Future<T?> showCustomDialog<T>(Widget dialog) {
    return showDialog<T>(
      context: this,
      builder: (_) => dialog,
    );
  }

  // Loading
  void showLoading() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void hideLoading() {
    Navigator.pop(this);
  }
}