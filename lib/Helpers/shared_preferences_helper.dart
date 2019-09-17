import 'package:contests_reminder/Utils/strings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SharedPreferencesHelper{
  final FirebaseMessaging _fireCloudMessaging = FirebaseMessaging();
  SharedPreferences prefs;
  bool _isInit = false;

  Future<void> init() async{
    prefs = await SharedPreferences.getInstance();
    _isInit = true;
  }

  Future<void> checkInit() async{
    if(!_isInit){
      await init();
    }
  }

  bool getBool(String pref, bool defaultVal){
    if(!prefs.containsKey(pref)){
      prefs.setBool(pref, defaultVal);
      return defaultVal;
    }
    else{
      return prefs.getBool(pref);
    }
  }

  bool isFirstStart(){
    if(getBool(Strings.isFirstStart, true)){
      prefs.setBool(Strings.isFirstStart, false);
      prefs.setBool(Strings.atcoderTopic, true);
      prefs.setBool(Strings.codeforcesTopic, true);
      _fireCloudMessaging.subscribeToTopic(Strings.atcoderTopic);
      _fireCloudMessaging.subscribeToTopic(Strings.codeforcesTopic);
      return true;
    }
    else{
      return false;
    }
  }

  void setInt(String pref, int value){
    prefs.setInt(pref, value);
  }

  int getInt(String pref, int defaultVal){
    if(!prefs.containsKey(pref)){
      prefs.setInt(pref, defaultVal);
    }
    return prefs.getInt(pref);
  }

  void subscribeToAllContests(){
    subscribeToTopic(Strings.atcoderTopic);
    subscribeToTopic(Strings.codeforcesTopic);
    
    subscribeToTopic(Strings.debugTopic);
  }
  Future<void> unsubscribeToTopic(String topicToUnsubscribe) async{
    print("Unsibscribing from $topicToUnsubscribe");
    prefs.setBool(topicToUnsubscribe, false);
    await _fireCloudMessaging.unsubscribeFromTopic(topicToUnsubscribe);
  }
  Future<void> subscribeToTopic(String topicToSubscribe) async{
    print("Subscribing to $topicToSubscribe");
    prefs.setBool(topicToSubscribe, true);
    await _fireCloudMessaging.subscribeToTopic(topicToSubscribe);
  }
  Future<bool> isSubscibedToTopic(String topic) async{
    return getBool(topic, false);
  }
  Future<List<String>> getUnsubscribedContests() async{
      List<String> unsubscribedTopics = List<String>();
      if(! await isSubscibedToTopic(Strings.atcoderTopic)){
          unsubscribedTopics.add(Strings.atcoderTopic);
      }
      if(! await isSubscibedToTopic(Strings.codeforcesTopic)){
          unsubscribedTopics.add(Strings.codeforcesTopic);
      }
      return unsubscribedTopics;
  }
}