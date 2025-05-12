import 'package:flutter/material.dart';

/// Model class representing mood data with colors, emoji, and UI styling
class MoodData {
  final String id;
  final String emoji;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle textStyle;
  final FloatingActionButtonThemeData fabTheme;
  final IconData fabIcon;
  final double fabElevation;
  final BorderRadius fabBorderRadius;

  const MoodData({
    required this.id,
    required this.emoji,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textStyle,
    required this.fabTheme,
    required this.fabIcon,
    required this.fabElevation,
    required this.fabBorderRadius,
  });
}

/// Map of available moods with their visual properties
final moodMap = {
  'jhappi': MoodData(
    id: 'jhappi',
    emoji: '😊',
    name: 'Happy',
    primaryColor: const Color(0xFFFFF176),
    secondaryColor: const Color.fromARGB(123, 155, 141, 8),
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.black87,
      letterSpacing: 0.5,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFFFEB3B),
      foregroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFF176), width: 2),
      ),
    ),
    fabIcon: Icons.sentiment_very_satisfied,
    fabElevation: 6,
    fabBorderRadius: BorderRadius.circular(16),
  ),

  'sad': MoodData(
    id: 'sad',
    emoji: '😢',
    name: 'Sad',
    primaryColor: const Color(0xFF90CAF9),
    secondaryColor: const Color(0xFF2196F3),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 15,
      color: Colors.white,
      letterSpacing: 0.25,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    fabIcon: Icons.healing,
    fabElevation: 4,
    fabBorderRadius: BorderRadius.circular(28),
  ),

  'angry': MoodData(
    id: 'angry',
    emoji: '😠',
    name: 'Angry',
    primaryColor: const Color(0xFFEF9A9A),
    secondaryColor: const Color(0xFFF44336),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      color: Colors.white,
      letterSpacing: 0.8,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFF44336),
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(24),
        ),
      ),
    ),
    fabIcon: Icons.flash_on,
    fabElevation: 8,
    fabBorderRadius: BorderRadius.circular(12),
  ),

  'relaxed': MoodData(
    id: 'relaxed',
    emoji: '😌',
    name: 'Relaxed',
    primaryColor: const Color(0xFFA5D6A7),
    secondaryColor: const Color(0xFF4CAF50),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: Colors.white,
      letterSpacing: 0.2,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
    fabIcon: Icons.spa,
    fabElevation: 2,
    fabBorderRadius: BorderRadius.circular(32),
  ),

  'excited': MoodData(
    id: 'excited',
    emoji: '🤩',
    name: 'Excited',
    primaryColor: const Color(0xFFFFAB91),
    secondaryColor: const Color(0xFFFF5722),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Colors.white,
      letterSpacing: 1.0,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFFF5722),
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    fabIcon: Icons.celebration,
    fabElevation: 10,
    fabBorderRadius: BorderRadius.circular(14),
  ),

  'cozy': MoodData(
    id: 'cozy',
    emoji: '☺️',
    name: 'Cozy',
    primaryColor: const Color(0xFFAEC6CF),
    secondaryColor: const Color(0xFF6A8CAF),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
      color: Colors.white,
      letterSpacing: 0.15,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF6A8CAF),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: const BorderSide(color: Color(0xFFAEC6CF), width: 1),
      ),
    ),
    fabIcon: Icons.nightlight_round,
    fabElevation: 4,
    fabBorderRadius: BorderRadius.circular(25),
  ),

  'loved': MoodData(
    id: 'loved',
    emoji: '🥰',
    name: 'Loved',
    primaryColor: const Color(0xFFAEC6CF),
    secondaryColor: const Color(0xFF6A8CAF),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: Colors.white,
      letterSpacing: 0.5,
    ),
    fabTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF6A8CAF),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.pink, width: 1.5),
      ),
    ),
    fabIcon: Icons.favorite,
    fabElevation: 6,
    fabBorderRadius: BorderRadius.circular(20),
  ),
};
