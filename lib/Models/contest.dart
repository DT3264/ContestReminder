class Contest{
  String contestName;
  DateTime contestStart;
  DateTime contestEnd;
  String contestPlatform;
  String contestUrl;
  int contestId;

  Contest({this.contestName, this.contestStart, this.contestEnd, this.contestUrl, this.contestPlatform, this.contestId=0});

  Contest.fromArray(dynamic contestData){
      contestName=contestData[0];
      contestStart=DateTime.fromMillisecondsSinceEpoch(contestData[1]*1000, isUtc: true);
      contestEnd=DateTime.fromMillisecondsSinceEpoch(contestData[2]*1000, isUtc: true);
      contestUrl=contestData[3];
      contestPlatform=contestData[4];
  }
}