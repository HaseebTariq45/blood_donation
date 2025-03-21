import 'package:flutter/material.dart';

// Extension on BuildContext to easily access theme-aware colors
extension ThemeExtension on BuildContext {
  // Check if current theme is dark
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  // Get theme-aware background color
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  
  // Get theme-aware card color
  Color get cardColor => Theme.of(this).cardTheme.color ?? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);
  
  // Get theme-aware text color
  Color get textColor => isDarkMode ? Colors.white : Colors.black;
  
  // Get theme-aware secondary text color
  Color get secondaryTextColor => isDarkMode ? Colors.white70 : Colors.black54;
  
  // Get theme-aware divider color
  Color get dividerColor => Theme.of(this).dividerColor;
  
  // Get theme-aware app bar background color
  Color get appBarColor => Theme.of(this).appBarTheme.backgroundColor ?? 
    (isDarkMode ? const Color(0xFF121212) : Colors.white);
} 