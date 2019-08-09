import 'package:prefs/prefs.dart';
import 'package:flutter/material.dart';
import 'package:contests_reminder/Utils/strings.dart';
import 'package:contests_reminder/Utils/scaledText.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';

class Settings extends StatefulWidget{
  @override
  _Settings createState ()=> _Settings();
}

class _Settings extends State<Settings>{
  SharedPreferencesHelper _sharedPreferencesHelper = SharedPreferencesHelper();
  @override
  void initState(){
    super.initState();
    Prefs.init();
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
          Column(
            children: getSubscribedPlatforms()
          ),
          Column(
            children: <Widget>[
              scaledText("Ok", 18)
            ],
          ),
          Column(
            children: <Widget>[
              scaledText("Ok", 18)
            ],
          ),
        ],
      );
  }

  List<Widget> getSubscribedPlatforms(){
      return[
        scaledText("Subscribed platforms", 18),
        getPlatformRow(Strings.atcoderTopic),
        getPlatformRow(Strings.codeforcesTopic),
        getPlatformRow(Strings.debugTopic),
      ];
  }

  Widget getPlatformRow(String platform) {
    return Row(
      children: <Widget>[
        Checkbox(
          value: Prefs.getBool(platform),
          onChanged: (bool newState) => switchSubscription(newState, platform),
        ),
        scaledText(platform, 18)
      ]
    );
  }

  void switchSubscription(bool toSubscribe, String platform) async{
    if(toSubscribe){
      await _sharedPreferencesHelper.subscribeToTopic(platform);
    }
    else{
      await _sharedPreferencesHelper.unsubscribeToTopic(platform);
    }
    setState(() {});
  }

  
}