import 'package:flutter/material.dart';

class NotificationService {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  void showError(String message) {
    _showSnackBar(message, Colors.red);
  }

  void showWarning(String message) {
    _showSnackBar(message, Colors.orange);
  }

  void showSuccess(String message) {
    _showSnackBar(message, Colors.green);
  }

  void showInfo(String message) {
    _showSnackBar(message, Colors.blue);
  }

  void _showSnackBar(String message, Color color) {
    scaffoldKey.currentState?.hideCurrentSnackBar();
    scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
