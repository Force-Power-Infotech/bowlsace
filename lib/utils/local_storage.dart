import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  Future<void> setItem(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(value);
    await prefs.setString(key, jsonString);
  }

  Future<dynamic> getItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    return json.decode(jsonString);
  }

  Future<void> removeItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
