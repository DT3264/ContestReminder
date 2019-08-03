import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//Local imports
import 'package:contest_reminder/Models/contest.dart';
import 'package:contest_reminder/Helpers/databaseHelper.dart';
import 'package:contest_reminder/Helpers/localContestsHelper.dart';

void main() => runApp(MainPage());

class MainPage extends StatefulWidget{
  @override
  _MainPage createState()=> _MainPage();
}

class _MainPage extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contest Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Contest Reminder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Contest> _contestList=[];
  bool isLoadingData=false;
  DatabaseHelper _databaseHelper = DatabaseHelper();
  LocalContestsHelper _localContestsHelper = LocalContestsHelper();
  @override void initState() {
    super.initState();
    _databaseHelper.initDatabase();
    setState(() {
     isLoadingData=true; 
    });
    loadLocalContests();
  }

  Future loadLocalContests() async{
    List<Contest> localContestList =  await _localContestsHelper.getContests(_databaseHelper);
    setState(() {
      _contestList = localContestList;
      isLoadingData=false;
    });
  }

  Future hideContest(Contest contestToHide) async{
    await _localContestsHelper.hideContest(contestToHide, _databaseHelper);
  }

  @override
  Widget build(BuildContext context) {
    
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    ScreenUtil.instance = ScreenUtil(width: width, height: height)..init(context);
    //ScreenUtil.getInstance()..setHeight(height);
    //ScreenUtil.getInstance()..setWidth(width);
    print(width);
    print(height);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: getBody()
      ),
      //floatingActionButton: getFab(),
    );
  }

  Widget getProgressDialog(){
    return Center(child: 
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: scaledText("Fetching contests data")
          ),
          CircularProgressIndicator()
        ],
      )
    );
  }

  Widget getBody() {
    if (isLoadingData) {
      return getProgressDialog();
    } else {
      return getListView();
    }
  }

  Widget getListView(){
    return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: scaledText("Next contests: ${_contestList.length}"),
              margin: EdgeInsets.only(top: 10),
            ),
            Expanded(
              child: new RefreshIndicator(
                child: getContestList(),
                onRefresh: _getContestList,
              )
            ),
          ],
        );
  }

  Widget getContestList(){
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) => _contestBuilder(context, index),
      itemCount: _contestList.length,
    );
  }

  Widget getFab() {
    var fab;
    if (!isLoadingData) {
      fab = FloatingActionButton(
        onPressed: () {
            if (!isLoadingData) {
                _getContestList();
            }
          },
        tooltip: 'Get data',
        child: Icon(Icons.file_download)
      );
    }
    return fab;
  }

  Widget _contestBuilder(BuildContext context, int index){
    Contest contest = _contestList[index];
    return PopupMenuButton(
      child: contestCard(contest, index),
      offset: Offset(0, 110),
      itemBuilder: contestPopupItems,
      onSelected: (value) async{
        if(value==1){
          //See in browser
          await launch(contest.contestUrl);
        }
        if(value==2){
          //Hide contest
          await hideContest(contest);
          await loadLocalContests();
        }
        if(value==3){
          //Remind me!
          //TO-DO
        }
      },
    );
  }

  Widget contestCard(Contest contest, int index){
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)
        ),
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        color: _getContestColor(index),
        child: Padding(
          padding: EdgeInsets.only(top: 5, bottom: 10),
          child: Column(
            children: <Widget>[
              scaledText("${contest.contestPlatform} contest"),
              scaledText(contest.contestName),
              Row(
                children: <Widget>[
                  dateTimeContestDesc(
                    date: contest.contestStart.toLocal(),
                    isStart: true
                  ),
                  dateTimeContestDesc(
                    date: contest.contestEnd.toLocal(),
                    isStart: false
                  ),
                ],
              )
            ]
          ),
        )
      );
  }

  Widget dateTimeContestDesc({DateTime date, bool isStart}){
    String hour = "${date.hour%12 > 0 && date.hour%12 < 10 ? "0" : ""}${(date.hour%12==0 ? 12 : date.hour%12)}";
    String minute = "${(date.minute <= 9 ? "0" : "")}${date.minute}";
    String hourPeriod = "${(date.hour<=12 ? "a.m." : "p.m")}";
    String day = "${(date.day <= 9 ? "0" : "")}${date.day}";
    String month = "${(date.month <= 9 ? "0" : "")}${date.month}";
    return Expanded(
      child: Center(
        child: Column(
          children: <Widget>[
            scaledTextDate(isStart ? "Start" : "End"),
            scaledTextDate("$hour:$minute $hourPeriod"),
            scaledTextDate("$day/$month/${date.year}"),
          ],
          )
      )
    );
  }

  Widget scaledText(String text){
    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ScreenUtil.getInstance().setSp(16),
        )
      )
    );
  }

  Widget scaledTextDate(String text){
    return Text(
      text,
      style: TextStyle(
        fontSize: ScreenUtil.getInstance().setSp(16),
        height: 0.8
      )
    );
  }

  List<PopupMenuItem<int>> contestPopupItems(BuildContext context){
    return [
      PopupMenuItem(
        value: 1,
        child: Text(
          "Show in browser",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.normal
          ),
        ),
      ),
      PopupMenuItem(
        value: 2,
        child: Text(
          "Hide contest",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.normal),
        ),
      ),
      PopupMenuItem(
        value: 3,
        child: Text(
          "Remind me!",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.normal),
        ),
      ),
    ];
  }

  Future<void> _getContestList() async{
    setState(() {
      isLoadingData=true; 
    });
    dynamic contestResponse;
    String _dataURL = "https://cf-at-api.herokuapp.com/get_contests";
    http.Response response = await http.get(_dataURL);
    //print("Status code: ${response.statusCode}");
    //print("Repsonse: ${response.body}");  
    if(response.statusCode==200){
      contestResponse = json.decode(response.body);
      _contestList=_contestsResponseToList(contestResponse);
      await _localContestsHelper.insertContests(_contestList, _databaseHelper);
    }
    else{
      final snackBar = SnackBar(content: Text('Error fetching contests. Code:${response.statusCode}'));
      // Find the Scaffold in the widget tree and use it to show a SnackBar.
      Scaffold.of(context).showSnackBar(snackBar);
    }
    setState(() {
      isLoadingData=false;
    });
  }

  List<Contest> _contestsResponseToList(dynamic _contestResponse){
    List<Contest> contestList=List<Contest>();
    Contest actualContest;
    for(var contestData in _contestResponse){
      //print("Parsing: ");
      //print(contestData);
      actualContest = Contest.fromArray(contestData);
      contestList.add(actualContest);
    }
    return contestList;
  }

  Color _getContestColor(int index){
    if(_contestList[index].contestPlatform=="Codeforces"){
      return Colors.yellow;
    }
    else if(_contestList[index].contestPlatform=="ATCoder"){
      return Colors.black26;
    }
    return Colors.black;
  }
}
