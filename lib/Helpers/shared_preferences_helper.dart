import 'package:prefs/prefs.dart';
import 'package:contests_reminder/Utils/strings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
class SharedPreferencesHelper{
  final FirebaseMessaging _fireCloudMessaging = FirebaseMessaging();

  bool isFirstStart(){
    if(Prefs.getBool(Strings.isFirstStart, true)){
      return false;
    }
    else{
      Prefs.setBool(Strings.isFirstStart, false);
      return true;
    }
  }
  void subscribeToAllContests(){
    subscribeToTopic(Strings.atcoderTopic);
    subscribeToTopic(Strings.codeforcesTopic);
  }
  Future<void> unsubscribeToTopic(String topicToUnsubscribe) async{
    Prefs.setBool(topicToUnsubscribe, false);
    await _fireCloudMessaging.unsubscribeFromTopic(topicToUnsubscribe);
  }
  Future<void> subscribeToTopic(String topicToSubscribe) async{
    Prefs.setBool(topicToSubscribe, true);
    _fireCloudMessaging.subscribeToTopic(topicToSubscribe);
  }
  bool isSubscibedToTopic(String topic){
    return Prefs.getBool(topic, false);
  }
  List<String> getUnsubscribedContests(){
      List<String> unsubscribedTopics = List<String>();
      if(!isSubscibedToTopic(Strings.atcoderTopic)){
          unsubscribedTopics.add(Strings.atcoderTopic);
      }
      if(!isSubscibedToTopic(Strings.codeforcesTopic)){
          unsubscribedTopics.add(Strings.codeforcesTopic);
      }
      return unsubscribedTopics;
  }
}