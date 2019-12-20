import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
);

class ThemeNotifier with ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  getTheme() => _themeData;

  setTheme(ThemeData themeData) async {
    _themeData = themeData;
    notifyListeners();
  }
}