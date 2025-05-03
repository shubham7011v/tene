import 'package:shared_preferences/shared_preferences.dart';

class MoodStorageService {
  static const String _lastSelectedMoodKey = 'last_selected_mood';
  
  // Save the selected mood to SharedPreferences
  static Future<bool> saveLastSelectedMood(String moodId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_lastSelectedMoodKey, moodId);
    } catch (e) {
      // Handle errors silently but return false to indicate failure
      return false;
    }
  }
  
  // Retrieve the last selected mood from SharedPreferences
  static Future<String?> getLastSelectedMood() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastSelectedMoodKey);
    } catch (e) {
      // Handle errors silently but return null
      return null;
    }
  }
  
  // Clear the stored mood (if needed)
  static Future<bool> clearLastSelectedMood() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_lastSelectedMoodKey);
    } catch (e) {
      return false;
    }
  }
} 