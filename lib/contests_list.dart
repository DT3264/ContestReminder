import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
//Local imports
import 'package:contest_reminder/Models/contest.dart';
import 'package:contest_reminder/Helpers/databaseHelper.dart';
import 'package:contest_reminder/Helpers/localContestsHelper.dart';

class ContestsList extends StatefulWidget{
  @override
  _ContestsList createState()=> _ContestsList();
}

class _ContestsList extends State<ContestsList> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Contest> _contestList=[];
  bool isLoadingData=false;
  DatabaseHelper _databaseHelper = DatabaseHelper();
  LocalContestsHelper _localContestsHelper = LocalContestsHelper();
  @override
  void initState() {
    super.initState();
    init();   
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Contest Reminder"),
      ),
      body: Builder (
        builder: (context)=> getBody(context)
      )
    );
  }
  
  void init(){
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

  Widget getBody(BuildContext context) {
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
                onRefresh: _refreshContests,
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

  Widget _contestBuilder(BuildContext context, int index){
    Contest contest = _contestList[index];
    return PopupMenuButton(
      child: contestCard(contest, index),
      offset: Offset(1, 10),
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

  List<PopupMenuEntry<Object>> contestPopupItems(BuildContext context){
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
      PopupMenuDivider(
        height: 10,
      ),
      PopupMenuItem(
        value: 2,
        child: Text(
          "Hide contest",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.normal),
        ),
      ),
      PopupMenuDivider(
        height: 10,
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
          mainAxisAlignment: MainAxisAlignment.center,
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
      child: AutoSizeText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18
        )
      )
    );
  }

  Widget scaledTextDate(String text){
    return AutoSizeText(
      text,
      softWrap: true,
      style: TextStyle(
        fontSize: 18,
        height: 0.8
      )
    );
  }

  Future<http.Response> _fetchContests() async{
    String dataURL = "https://cf-at-api.herokuapp.com/get_contests";
    try{
      http.Response response = await http.get(dataURL);
      return response;
    } on SocketException catch (e){
      print(e);
      showSnackBar("There's no internet connection. Try again later.");
      return null;
    }
  }

  Future<void> _refreshContests() async{
    setState(() {
      isLoadingData=true; 
    });
    http.Response response = await _fetchContests();
    if(response!=null){
      if(response.statusCode==200){
        dynamic contestResponse = json.decode(response.body);
        _contestList= _contestsResponseToList(contestResponse);
        _localContestsHelper.insertContests(_contestList, _databaseHelper);
      }
      else{
        showSnackBar("Error fetching contests. Response code:${response.statusCode}.");
      }
    }
    setState((){
      isLoadingData=false;
    });
  }

  void showSnackBar(String text){
    final snackBar = SnackBar(
      //backgroundColor: Colors.black,
      content: Text(text)
    );
    // Find the Scaffold in the widget tree and use it to show a SnackBar.
    _scaffoldKey.currentState.showSnackBar(snackBar);
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

