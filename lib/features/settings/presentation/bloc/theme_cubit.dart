import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// ThemeCubit manages app-wide ThemeMode and persists the choice to
/// SharedPreferences so the user's preference survives restarts.
@injectable
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(ThemeMode.system);

  /// Loads the persisted theme on startup.
  void loadTheme() {
    final stored = _prefs.getString(AppConstants.keyThemeMode);
    final mode = _fromString(stored);
    emit(mode);
  }

  void setLight() => _set(ThemeMode.light);
  void setDark() => _set(ThemeMode.dark);
  void setSystem() => _set(ThemeMode.system);

  void toggle() {
    if (state == ThemeMode.light) {
      _set(ThemeMode.dark);
    } else {
      _set(ThemeMode.light);
    }
  }

  void _set(ThemeMode mode) {
    _prefs.setString(AppConstants.keyThemeMode, _toString(mode));
    emit(mode);
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
