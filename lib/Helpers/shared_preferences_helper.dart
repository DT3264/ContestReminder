import 'package:shared_preferences/shared_preferences.dart';
import 'package:contests_reminder/strings.dart';

class SharedPreferencesHelper{
  Future<bool> isFirstStart() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(Strings.isFirstStart);
  }

  Future<void> subscribeToAll() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(Strings.atcoderTopic, true);
    prefs.setBool(Strings.codeforcesTopic, true);
    prefs.setBool(Strings.isFirstStart, false);
  }

  Future<void> unsubscribeToTopic(String topicToUnsubscribe) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(topicToUnsubscribe, false);
  }
  Future<void> subscribeToTopic(String topicToSubscribe) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(topicToSubscribe, true);
  }
  Future<bool> isSubscibedToTopic(String topic) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(!prefs.containsKey(topic)){
        prefs.setBool(topic, false);
    }
    return prefs.getBool(topic);
  }
  Future<List<String>> getUnsubscribedContests() async{
      List<String> unsubscribedTopics = List<String>();
      if(!await isSubscibedToTopic(Strings.atcoderTopic)){
          unsubscribedTopics.add(Strings.atcoderTopic);
      }
      if(!await isSubscibedToTopic(Strings.codeforcesTopic)){
          unsubscribedTopics.add(Strings.codeforcesTopic);
      }
      return unsubscribedTopics;
  }
}