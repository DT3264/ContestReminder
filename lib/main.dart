import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:contest_reminder/contest.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
  int _fabState = 0;
  final String dataURL = "https://cf-at-api.herokuapp.com/get_contests";
  void _getContestList() async{
    setState(() {
     _fabState=1; 
    });
    dynamic contestResponse;
    http.Response response = await http.get(dataURL);
    setState(() {
      _fabState=0;
      contestResponse = json.decode(response.body);
      _contestList=_contestsResponseToList(contestResponse);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            widgetWPadding(Text("Next contests: ${_contestList.length}")),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) => _contestBuilder(context, index),
                itemCount: _contestList.length,
              ),
            ),
          ],
        )
      ),
      floatingActionButton: customFab(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget customFab() {
    var fab;
    if (_fabState == 0) {
      fab= FloatingActionButton(
        onPressed: () {
            setState(() {
              if (_fabState == 0) {
                _getContestList();
              }
            });
          },
        tooltip: 'Get data',
        child: Icon(Icons.file_download)
      );
    } 
    else if (_fabState == 1) {
      fab = FloatingActionButton(
        tooltip: 'Getting data',
        child: Icon(Icons.all_inclusive), 
        onPressed: () {},
      );
    }
    return fab;
  }

  List<Contest> _contestsResponseToList(dynamic _contestResponse){
    List<Contest> contestList=List<Contest>();
    for(var contestData in _contestResponse){
      String contestName=contestData[0];
      DateTime contestTime=DateTime.fromMillisecondsSinceEpoch(contestData[1]*1000, isUtc: true);
      String contestPlatform=contestData[2];
      Contest contest = Contest(contestName: contestName, contestTime:contestTime, contestPlatform: contestPlatform);
      contestList.add(contest);
    }
    return contestList;
  }

  Widget _contestBuilder(BuildContext context, int index){
    Contest contest = _contestList[index];
    return widgetWPadding(
      Column(
        children: <Widget>[
          Text(contest.contestPlatform),
          Text(contest.contestName),
          Text(contest.contestTime.toLocal().toString())
        ]
      )
    );
  }

  Widget widgetWPadding(Widget mainWidget){
    return Padding(
      child: mainWidget, 
      padding: EdgeInsets.only(bottom: 10),
    );
  }
}

