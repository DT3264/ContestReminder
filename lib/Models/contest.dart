import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contests_reminder/Helpers/local_contests_helper.dart';
class Contest{
  String contestName;
  DateTime contestStart;
  DateTime contestEnd;
  String contestPlatform;
  String contestUrl;
  int contestId;
  int hasAlert;
  int hidden;

  Contest({this.contestName, this.contestStart, this.contestEnd, this.contestUrl, this.contestPlatform, this.contestId=0, this.hidden=0, this.hasAlert=0});

  Contest.fromFirestore(Map<String, dynamic> contestData){
      contestName=contestData["contestName"];
      contestStart=DateTime.fromMillisecondsSinceEpoch(contestData["contestStart"]*1000, isUtc: true);
      contestEnd=DateTime.fromMillisecondsSinceEpoch(contestData["contestEnd"]*1000, isUtc: true);
      contestUrl=contestData["contestUrl"];
      contestPlatform=contestData["contestPlatform"];
      hidden=0;
      hasAlert=0;
  }

  String toSqlInsert(){
    return "(null, '$contestName', ${contestStart.millisecondsSinceEpoch~/1000}, ${contestEnd.millisecondsSinceEpoch~/1000}, '$contestUrl', '$contestPlatform', $hidden, $hasAlert)";
  }

  String toSqlUpdate(){
    return "contestName = '$contestName', contestStart = ${contestStart.millisecondsSinceEpoch~/1000}, contestEnd = ${contestEnd.millisecondsSinceEpoch~/1000}";
  }

  @override
  String toString() {
    return "$contestId - $contestName - $contestStart - $contestEnd - $contestPlatform - $contestUrl - $hidden - $hasAlert";
  }
  Future<List<Contest>> fetchContests({bool getHidden}) async{
	  LocalContestsHelper localContestsHelper = LocalContestsHelper();
    List<Contest> contestsList = List();
    if(getHidden){
      contestsList=await localContestsHelper.getHiddenContests();
      return contestsList;
    }
    await Firestore.instance
      .collection('contests').getDocuments()
      .then((QuerySnapshot ds){
        for(DocumentSnapshot contestSnapshot in ds.documents){
          contestsList.add(Contest.fromFirestore(contestSnapshot.data));
        }
      });
		await localContestsHelper.insertContests(contestsList);
    if(getHidden){
      return localContestsHelper.getHiddenContests();
    }
    else{
      return localContestsHelper.getContests();
    }
	}
}