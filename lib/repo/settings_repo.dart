import 'dart:async';

import 'package:BrainTalk/repo/settings_data.dart';

class SettingRepository {
  final SettingDataProvider _dataProvider;

  SettingRepository(this._dataProvider) {
    _dataProvider.loadSettings();

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _dataProvider.saveSettings();
    });
  }

  void set(String key, String value) {
    _dataProvider.set(key, value);
  }

  String? get(String key) {
    return _dataProvider.get(key);
  }

  String stringDefault(String key, String defaultValue) {
    return _dataProvider.getDefault(key, defaultValue);
  }

  int intDefault(String key, int defaultValue) {
    return _dataProvider.getDefaultInt(key, defaultValue);
  }

  bool boolDefault(String key, bool defaultValue) {
    return _dataProvider.getDefaultBool(key, defaultValue);
  }

  double doubleDefault(String key, double defaultValue) {
    return _dataProvider.getDefaultDouble(key, defaultValue);
  }
}
