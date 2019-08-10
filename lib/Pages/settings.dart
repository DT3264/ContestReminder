import 'package:flutter/material.dart';
import 'package:contests_reminder/Utils/strings.dart';
import 'package:contests_reminder/Utils/scaledText.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';

class Settings extends StatefulWidget{
  @override
  _Settings createState ()=> _Settings();
}

class _Settings extends State<Settings>{
  SharedPreferencesHelper _prefsHelper = SharedPreferencesHelper();
  List<bool> subscriptionsList = [false, false, false];
  String reminderText = "1 hour";

  @override
  void initState(){
    super.initState();
    getPrefs();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("About"),
      ),
      body: getBody()
    );
  }

  Widget getBody(){
    return ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(5),
            child: getSubscribedPlatforms()
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Column(
              children: <Widget>[
                scaledText("Reminder time before contest", 18),
                PopupMenuButton(
                  child: Container(
                    decoration: ShapeDecoration(
                      color: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        side: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Padding(
                      child: scaledText(reminderText, 18),
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
                    _prefsHelper.setInt(Strings.reminderTime, value);
                    getPrefs();
                  },
                ),
              ],
            ),
          ),
        ],
      );
  }

  Widget getSubscribedPlatforms(){
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          scaledText("Subscribed platforms", 18),
          getPlatformRow(Strings.atcoderTopic, 0),
          getPlatformRow(Strings.codeforcesTopic, 1),
        ]
      );
  }

  Widget getPlatformRow(String platform, int index) {
    return Row(
      children: <Widget>[
        Checkbox(
          value: subscriptionsList[index],
          onChanged: (bool newState) => switchSubscription(newState, platform),
        ),
        scaledText(platform, 18)
      ]
    );
  }

  void switchSubscription(bool newState, String platform) async{
    await _prefsHelper.init();
    if(newState){
      await _prefsHelper.subscribeToTopic(platform);
    }
    else{
      await _prefsHelper.unsubscribeToTopic(platform);
    }
    await getPrefs();
  }

  Future<void> getPrefs() async{
    await _prefsHelper.checkInit();
    int reminderDelay = _prefsHelper.getInt(Strings.reminderTime, 60);
    if(reminderDelay == 60){
      reminderText = "1 hour";
    }
    else{
      reminderText = "$reminderDelay minute${reminderDelay > 1 ? "s" : ""}";
    }
    List<bool> tmpSubscriptionsList = List<bool>();
    tmpSubscriptionsList.add(_prefsHelper.getBool(Strings.atcoderTopic, false));
    tmpSubscriptionsList.add(_prefsHelper.getBool(Strings.codeforcesTopic, false));
    setState(() {
      subscriptionsList = tmpSubscriptionsList;
    });
  }
  
}