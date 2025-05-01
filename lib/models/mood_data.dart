import 'package:flutter/material.dart';

/// Model class representing mood data with colors and emoji
class MoodData {
  final String id;
  final String emoji;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;

  const MoodData({
    required this.id,
    required this.emoji,
    required this.name, 
    required this.primaryColor,
    required this.secondaryColor,
  });
}

/// Map of available moods with their visual properties
final moodMap = {
  'jhappi': const MoodData(
    id: 'jhappi',
    emoji: '😊',
    name: 'Happy',
    primaryColor: Color(0xFFFFF176),
    secondaryColor: Color(0xFFFFEB3B),
  ),
  'sad': const MoodData(
    id: 'sad',
    emoji: '😢',
    name: 'Sad',
    primaryColor: Color(0xFF90CAF9),
    secondaryColor: Color(0xFF2196F3),
  ),
  'angry': const MoodData(
    id: 'angry',
    emoji: '😠',
    name: 'Angry',
    primaryColor: Color(0xFFEF9A9A),
    secondaryColor: Color(0xFFF44336),
  ),
  'relaxed': const MoodData(
    id: 'relaxed',
    emoji: '😌',
    name: 'Relaxed',
    primaryColor: Color(0xFFA5D6A7),
    secondaryColor: Color(0xFF4CAF50),
  ),
  'excited': const MoodData(
    id: 'excited',
    emoji: '🤩',
    name: 'Excited',
    primaryColor: Color(0xFFFFAB91),
    secondaryColor: Color(0xFFFF5722),
  ),
}; 