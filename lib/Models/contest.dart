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

  Contest.fromFetch(dynamic contestData){
      //print(contestData);
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
}