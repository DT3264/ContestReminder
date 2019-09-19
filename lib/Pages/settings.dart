import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

import 'package:contests_reminder/Utils/strings.dart';
import 'package:contests_reminder/Widgets/scaled_text.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';

class Settings extends StatefulWidget{
  @override
  _Settings createState ()=> _Settings();
}

class _Settings extends State<Settings>{
  SharedPreferencesHelper _prefsHelper = SharedPreferencesHelper();
  bool _usingDark=false;
  List<bool> _subscriptionsList = [false, false, false];
  int _reminderMinutes=60;

  @override
  void initState(){
    super.initState();
    getPrefs();
  }

  Future<void> getPrefs() async{
    await _prefsHelper.init();
    bool isDark=_prefsHelper.getBool(Strings.usingDark, false);
    int reminderMinutes=_prefsHelper.getInt(Strings.reminderTime, 60);
    List<bool> tmpSubscriptionsList = List<bool>();
    tmpSubscriptionsList.add(_prefsHelper.getBool(Strings.atcoderTopic, false));
    tmpSubscriptionsList.add(_prefsHelper.getBool(Strings.codeforcesTopic, false));
    tmpSubscriptionsList.add(_prefsHelper.getBool(Strings.debugTopic, false));
    setState(() {
      _subscriptionsList = tmpSubscriptionsList;
      this._reminderMinutes=reminderMinutes;
      _usingDark=isDark;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Builder(
        builder: (context){
          return ListView(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    ScaledText(text: "Subscribed platforms", fontSize: 18),
                    getPlatformRow(Strings.atcoderTopic, 0),
                    getPlatformRow(Strings.codeforcesTopic, 1),
                  ]
                )
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  children: <Widget>[
                    ScaledText(text: "Reminder time before contest", fontSize: 18),
                    PopupMenuButton(
                      child: Container(
                        decoration: ShapeDecoration(
                          color: Theme.of(context).backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            side: BorderSide(color: Theme.of(context).buttonColor, width: 2),
                          ),
                        ),
                        child: Padding(
                          child: ScaledText(text: getReminderText(_reminderMinutes), fontSize: 18),
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                        )
                      ),
                      itemBuilder: (context){
                        return [
                          PopupMenuItem(value: 1, child: Text("1 min.")),
                          PopupMenuItem(value: 5, child: Text("5 min.")),
                          PopupMenuItem(value: 15, child: Text("15 min.")),
                          PopupMenuItem(value: 30, child: Text("30 min.")),
                          PopupMenuItem(value: 60, child: Text("1 hour")),
                        ];
                      },
                      onSelected: (value){
                        setState(() {
                        _reminderMinutes=value; 
                        });
                        _prefsHelper.setInt(Strings.reminderTime, value);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: <Widget>[
                    Checkbox(
                      checkColor: Theme.of(context).accentColor,
                      activeColor: Theme.of(context).backgroundColor,
                      value: _usingDark,
                      onChanged: (bool toDark) {
                        setState(() {
                          _usingDark=toDark;
                        });
                        _prefsHelper.setBool(Strings.usingDark, toDark);
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            duration: Duration(seconds: 4),
                            content: ScaledText(text: "Restart the app to see the changes", fontSize: 16),
                          )
                        );
                      }
                    ),
                    ScaledText(text: "Enable dark theme", fontSize:18)
                  ]
                )
              ),
            ],
          );
        },
      )
    );
  }

  @widget
  Widget getPlatformRow(String platform, int index) {
    return Row(
      children: <Widget>[
        Checkbox(
          checkColor: Theme.of(context).accentColor,
          activeColor: Theme.of(context).backgroundColor,
          value: _subscriptionsList[index],
          onChanged: (bool isSubscribed) {
            setState(() {
            _subscriptionsList[index]=isSubscribed;
            });
            switchSubscription(isSubscribed, platform);
          }
        ),
        ScaledText(text: platform, fontSize:18)
      ]
    );
  }

  void switchSubscription(bool suscribed, String platform){
    if(suscribed){
      _prefsHelper.subscribeToTopic(platform);
    }
    else{
      _prefsHelper.unsubscribeToTopic(platform);
    }
  }

  String getReminderText(int minutes){
    if(minutes == 60){
      return "1 hour";
    }
    else{
      return "$minutes minute${minutes > 1 ? "s" : ""}";
    }
  }
}