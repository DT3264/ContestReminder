import 'package:contests_reminder/Helpers/databaseHelper.dart';
import 'package:contests_reminder/Models/contest.dart';
	
class LocalContestsHelper{
  Future insertContests(List<Contest> contestList) async{
    DatabaseHelper dbHelper = DatabaseHelper();
    Contest actualContest;
    List<String> queries = List<String>();
    String query;
    if(contestList.length>0){
      query = "insert or ignore into contests values ";
      for(int i=0; i<contestList.length; i++){
        actualContest=contestList[i];
        query += "(null, '${actualContest.contestName}', ${actualContest.contestStart.millisecondsSinceEpoch/1000}, ${actualContest.contestEnd.millisecondsSinceEpoch/1000}, '${actualContest.contestUrl}', '${actualContest.contestPlatform}', 0)";
        if(i<contestList.length-1){
          query += ", ";
        }
      }
      query += ";";
      queries.add(query);
    }
    int nowInSeconds = DateTime.now().millisecondsSinceEpoch;
    query = "delete from contests where contestEnd <= $nowInSeconds";
    queries.add(query);
    await dbHelper.rawTransaction(queries);
  }

  Future<List<Contest>> getContests() async{
    DatabaseHelper dbHelper = DatabaseHelper();
    String query = "select * from contests where hidden = 0";
    List<Map<String, dynamic>> rows = await dbHelper.rawQuery(query);
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
      );
      contestList.add(actualContest);
    }
    return contestList;
  }
  Future hideContest(Contest contest) async{
    DatabaseHelper dbHelper = DatabaseHelper();
    String query = "update contests set hidden = 1 where id = ${contest.contestId}";
    await dbHelper.rawQuery(query);
  }
}