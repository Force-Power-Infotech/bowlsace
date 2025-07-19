import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../di/service_locator.dart';
import '../../../utils/local_storage.dart';
import '../../../api/api_error_handler.dart';
import '../../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _offlineMode = false;
  String _distanceUnit = 'meters'; // meters or feet
  bool _isLoading = false;

  final LocalStorage _localStorage = getIt<LocalStorage>();
  final ApiErrorHandler _errorHandler = getIt<ApiErrorHandler>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load settings from local storage
      final notificationsEnabled = await _localStorage.getItem(
        'notificationsEnabled',
      );
      final offlineMode = await _localStorage.getItem('offlineMode');
      final distanceUnit = await _localStorage.getItem('distanceUnit');

      setState(() {
        _notificationsEnabled = notificationsEnabled ?? true;
        _offlineMode = offlineMode ?? false;
        _distanceUnit = distanceUnit ?? 'meters';
      });
    } catch (e) {
      _errorHandler.handleError(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _localStorage.setItem(
        'notificationsEnabled',
        _notificationsEnabled,
      );
      await _localStorage.setItem('offlineMode', _offlineMode);
      await _localStorage.setItem('distanceUnit', _distanceUnit);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      _errorHandler.handleError(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save settings')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Appearance section
                const ListTile(
                  title: Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
                const Divider(),

                // Notifications section
                const ListTile(
                  title: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                    'Receive notifications for challenges and updates',
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(),

                // Data Usage section
                const ListTile(
                  title: Text(
                    'Data Usage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Offline Mode'),
                  subtitle: const Text(
                    'Save data by working offline when possible',
                  ),
                  value: _offlineMode,
                  onChanged: (value) {
                    setState(() {
                      _offlineMode = value;
                    });
                  },
                ),
                const Divider(),

                // Units section
                const ListTile(
                  title: Text(
                    'Measurement Units',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                RadioListTile<String>(
                  title: const Text('Meters'),
                  value: 'meters',
                  groupValue: _distanceUnit,
                  onChanged: (value) {
                    setState(() {
                      _distanceUnit = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Feet'),
                  value: 'feet',
                  groupValue: _distanceUnit,
                  onChanged: (value) {
                    setState(() {
                      _distanceUnit = value!;
                    });
                  },
                ),
                const Divider(),

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('SAVE SETTINGS'),
                  ),
                ),

                // App version
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'BowlsAce v1.0.0',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
