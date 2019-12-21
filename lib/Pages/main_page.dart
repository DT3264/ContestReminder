import 'dart:async';
import 'package:contests_reminder/Widgets/contests_list.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//Local imports
import 'package:contests_reminder/Utils/strings.dart';
import 'package:contests_reminder/Pages/settings.dart';
import 'package:contests_reminder/Widgets/scaled_text.dart';
import 'package:contests_reminder/Pages/hidden_contests.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  final FirebaseMessaging _fireCloudMessaging = FirebaseMessaging();
  SharedPreferencesHelper prefsHelper = SharedPreferencesHelper();
  FlutterLocalNotificationsPlugin _localNotifications;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await initFirebase();
    await checkFirstInit();
    initNotifications();
  }

  Future<void> initFirebase() async {
    _fireCloudMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
  }

  Future<void> checkFirstInit() async {
    await prefsHelper.init();
    if (prefsHelper.isFirstStart()) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("First time here, huh?"),
              content: Text(
                  "Click on any contest to see some options or refresh the available contests by pulling down the list."),
              actions: <Widget>[
                FlatButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    }
  }

  void initNotifications() {
    _localNotifications = new FlutterLocalNotificationsPlugin();
    //Initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    //Self note: AndroidSettings icon is from the drawable folder :d
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) async {});
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    _localNotifications.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Contests Reminder'), actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 2, child: Text("Hidden contests")),
                PopupMenuItem(value: 3, child: Text("Settings")),
                PopupMenuItem(value: 4, child: Text("About")),
              ];
            },
            onSelected: (int index) async{
              if (index == 2) {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HiddenContests()));
              } else if (index == 3) {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Settings()));
              } else if (index == 4) {
                showAboutDialog(
                  applicationVersion: "1.0.4",
                  applicationName: "Contests Reminder",
                  children: [
                    ScaledText(text: "With <3 by DT3264", fontSize: 18),
                    ScaledText(
                        text:
                            "Bugs or suggestions?, follow the link to the project.",
                        fontSize: 18),
                    GestureDetector(
                        child: Text(Strings.gitUrl,
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue)),
                        onTap: () {
                          launch(Strings.gitUrl);
                        })
                  ],
                  context: context,
                );
              }
            },
          )
        ]),
        body: Builder(
            builder: (context) => ContestsList(
                  context: context,
                  showHidden: false,
                )));
  }
}
