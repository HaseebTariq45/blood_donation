import 'package:flutter/foundation.dart';

class Logger {
  final String tag;

  Logger({this.tag = 'BloodLine'});

  void d(String message) {
    if (kDebugMode) {
      print('[$tag] DEBUG: $message');
    }
  }

  void i(String message) {
    if (kDebugMode) {
      print('[$tag] INFO: $message');
    }
  }

  void w(String message) {
    if (kDebugMode) {
      print('[$tag] WARNING: $message');
    }
  }

  void e(String message) {
    if (kDebugMode) {
      print('[$tag] ERROR: $message');
    }
  }
}

// Global logger instance
final logger = Logger();
