import 'dart:convert';

import '../helper/helper.dart';

class SettingDataProvider {
  final _settings = <String, String>{};
  bool _dirty = false;

  Future<void> loadSettings() async {
    final content = await readFile('settings.json');
    _settings.addAll(jsonDecode(content) as Map<String, String>);
    _dirty = false;
  }

  Future<void> saveSettings() async {
    if (!_dirty) {
      return;
    }

    await writeFile('settings.json', jsonEncode(_settings));
    _dirty = false;
  }

  void set(String key, String value) {
    _settings[key] = value;
    _dirty = true;
  }

  String? get(String key) {
    return _settings[key];
  }

  String getDefault(String key, String defaultValue) {
    return _settings[key] ?? defaultValue;
  }

  int getDefaultInt(String key, int defaultValue) {
    return int.tryParse(_settings[key] ?? '') ?? defaultValue;
  }

  bool getDefaultBool(String key, bool defaultValue) {
    return _settings[key] == 'true' ? true : defaultValue;
  }

  double getDefaultDouble(String key, double defaultValue) {
    return double.tryParse(_settings[key] ?? '') ?? defaultValue;
  }
}
