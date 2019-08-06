import 'package:contests_reminder/Helpers/databaseHelper.dart';
import 'package:contests_reminder/Models/contest.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
	
class LocalContestsHelper{
  DatabaseHelper _dbHelper = DatabaseHelper();
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future insertContests(List<Contest> contestList) async{
    List<String> queries = List<String>();
    int nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String query;
    query = "select * from contests where contestEnd <= $nowInSeconds";
    List<Map<String, dynamic>> rows  = await _dbHelper.rawQuery(query);
    for(Map<String, dynamic> row in rows){
      int id = row["id"];
      _flutterLocalNotificationsPlugin.cancel(id);
    }
    if(contestList.length>0){
      query = "insert or ignore into contests values ";
      for(int i=0; i<contestList.length; i++){
        query += contestList[i].toSqlInsert();
        if(i<contestList.length-1){
          query += ", ";
        }
      }
      query += ";";
      queries.add(query);
    }
    query = "delete from contests where contestEnd <= $nowInSeconds";
    queries.add(query);
    await _dbHelper.rawTransaction(queries);
  }

  Future<List<Contest>> getContests() async{
    String query = "select * from contests where hidden = 0";
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
      print(actualContest);
      contestList.add(actualContest);
    }
    return contestList;
  }
  Future hideContest(Contest contest) async{
    String query = "update contests set hidden = 1 where id = ${contest.contestId}";
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
      //Remove alert
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
    await _flutterLocalNotificationsPlugin.schedule(
      contest.contestId,
      'Next contest',
      'The contest ${contest.contestName} would start in an hour',
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true
    );
  }

  Future<void> cancelContestNotification(Contest contest) async{
      // cancel the notification with id value of zero
      print("Notification for ${contest.contestId} canceled");
      await _flutterLocalNotificationsPlugin.cancel(contest.contestId);
  }
}