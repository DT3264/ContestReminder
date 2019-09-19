import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:contests_reminder/Pages/main_page.dart';

import 'Utils/strings.dart';

void main() async{
  SharedPreferencesHelper prefs = SharedPreferencesHelper();
  await prefs.init();
  bool useDark=prefs.getBool(Strings.usingDark, false);
  return runApp(
    MaterialApp(
      home: MainPage(),
      theme: ThemeData(
        brightness: useDark ? Brightness.dark : Brightness.light
      ),
    )
  );
}