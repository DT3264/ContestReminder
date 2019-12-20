
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

  Contest.fromFetch(Map<String, dynamic> contestData){
      contestName=contestData["name"];
      contestStart=DateTime.fromMillisecondsSinceEpoch(contestData["start"]*1000, isUtc: true);
      contestEnd=DateTime.fromMillisecondsSinceEpoch(contestData["end"]*1000, isUtc: true);
      contestUrl=contestData["url"];
      contestPlatform=contestData["platform"];
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

   
}