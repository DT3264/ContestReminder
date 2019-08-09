import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Helpers/databaseHelper.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
	
class LocalContestsHelper{
  DatabaseHelper _dbHelper = DatabaseHelper();
  SharedPreferencesHelper _sharedPreferencesHelper = SharedPreferencesHelper();
  FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future insertContests(List<Contest> contestList) async{
    int nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String query;
    query = "select * from contests where contestEnd <= $nowInSeconds";
    List<Map<String, dynamic>> rows  = await _dbHelper.rawQuery(query);
    for(Map<String, dynamic> row in rows){
      int id = row["id"];
      _localNotifications.cancel(id);
    }
    if(contestList.length>0){
      for(int i=0; i<contestList.length; i++){
        query = "update contests set ${contestList[i].toSqlUpdate()} where contestUrl = '${contestList[i].contestUrl}'";
        int res = await _dbHelper.rawUpdate(query);
        print(query);
        if(res==0){
          query = "insert into contests values ${contestList[i].toSqlInsert()};";
          await _dbHelper.rawInsert(query);
          print(query);
        }
      }
    }
  }

  Future<List<Contest>> getContests() async{
    String query;
    int nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    query = "delete from contests where contestEnd <= $nowInSeconds";
    _dbHelper.rawDelete(query);
    query = "select * from contests where hidden = 0";
    List<Map<String, dynamic>> rows = await _dbHelper.rawQuery(query);
    List<Contest> contestList = List<Contest>();
    Contest actualContest;
    List<String> contestsIgnored = _sharedPreferencesHelper.getUnsubscribedContests();
    for(Map<String, dynamic> row in rows){
      actualContest = Contest(
        contestId: row["id"],
        contestName: row["contestName"],
        contestStart: DateTime.fromMillisecondsSinceEpoch(row["contestStart"]*1000),
        contestEnd:  DateTime.fromMillisecondsSinceEpoch(row["contestEnd"]*1000),
        contestUrl: row["contestUrl"],
        contestPlatform: row["contestPlatform"],
        hidden: row["hidden"],
        hasAlert: row["hasAlertRegistred"]
      );
      //print(actualContest);
      if(!contestsIgnored.contains(actualContest.contestPlatform)){
        contestList.add(actualContest);
      }
    }
    return contestList;
  }
  
  Future<List<Contest>> getHiddenContests() async{
    String query;
    query = "select * from contests where hidden = 1";
    List<Map<String, dynamic>> rows = await _dbHelper.rawQuery(query);
    List<Contest> contestList = List<Contest>();
    Contest actualContest;
    for(Map<String, dynamic> row in rows){
      actualContest = Contest(
        contestId: row["id"],
        contestName: row["contestName"],
        contestStart: DateTime.fromMillisecondsSinceEpoch(row["contestStart"]*1000),
        contestEnd:  DateTime.fromMillisecondsSinceEpoch(row["contestEnd"]*1000),
        contestUrl: row["contestUrl"],
        contestPlatform: row["contestPlatform"],
        hidden: row["hidden"],
        hasAlert: row["hasAlertRegistred"]
      );
      //print(actualContest);
      contestList.add(actualContest);
    }
    return contestList;
  }
  Future switchContestHide(Contest contest) async{
    int newVal = contest.hidden == 0 ? 1 : 0;
    String query = "update contests set hidden = $newVal where id = ${contest.contestId}";
    await _dbHelper.rawQuery(query);
  }

  Future<void> switchAlertToContest(Contest contest) async{
    int newVal = contest.hasAlert == 0 ? 1 : 0;
    String query = "Update contests set hasAlertRegistred = $newVal where id = ${contest.contestId}";
    await _dbHelper.rawUpdate(query);
    if(newVal==1){
      //Set alert
      await scheduleContestNotification(contest);
    }
    else{
      await cancelContestNotification(contest);
    }
  }
  Future<void> scheduleContestNotification(Contest contest) async{
    var scheduledNotificationDateTime = contest.contestStart.subtract(Duration(hours: 1));
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'contest_reminder', 
      'contest_reminder', 
      'Chanel that notifies individual contests',
      style: AndroidNotificationStyle.BigText
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await _localNotifications.schedule(
      contest.contestId,
      'Next contest',
      'The contest ${contest.contestName} would start in an hour',
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true
    );
  }

  Future<void> cancelContestNotification(Contest contest) async{
      await _localNotifications.cancel(contest.contestId);
  }
}