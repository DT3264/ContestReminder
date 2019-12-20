//import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:contests_reminder/Pages/main_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Utils/strings.dart';
import 'Utils/themes.dart' as themes;

void main(){
  WidgetsFlutterBinding.ensureInitialized();
  //SharedPreferencesHelper prefs = SharedPreferencesHelper();
  //await prefs.init();
  //bool useDark=prefs.getBool(Strings.usingDark, false);
  SharedPreferences.getInstance().then((prefs) {
    var darkModeOn = prefs.getBool(Strings.usingDark) ?? true;
    runApp(
      ChangeNotifierProvider<themes.ThemeNotifier>(
        create: (_) => themes.ThemeNotifier(darkModeOn ? themes.darkTheme : themes.lightTheme),
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<themes.ThemeNotifier>(context);
    return MaterialApp(
      title: 'Contests Reminder',
      theme: themeNotifier.getTheme(),
      home: MainPage(),
    );
  }
}