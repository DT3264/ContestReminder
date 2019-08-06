import 'dart:async';
import 'dart:io';
import 'package:contests_reminder/contests_fetcher.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//Local imports
import 'package:contests_reminder/strings.dart';
import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Helpers/localContestsHelper.dart';

class ContestsList extends StatefulWidget{
  @override
  _ContestsList createState()=> _ContestsList();
}

class _ContestsList extends State<ContestsList> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	List<Contest> _contestList=[];
	bool isLoadingData=false;

  SharedPreferencesHelper _sharedPreferencesHelper = SharedPreferencesHelper();
  final ContestsFetcher _contestsFetcher = ContestsFetcher();
	final LocalContestsHelper _localContestsHelper = LocalContestsHelper();
	final FirebaseMessaging _fireCloudMessaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
	
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
	
	void init() async {
		initFirebase();
    bool isFirstStart = await _sharedPreferencesHelper.isFirstStart();
    if(isFirstStart){
      _sharedPreferencesHelper.subscribeToAll();
      await subscribeToAllOnFirecloud();
    }
    await _refreshContests();
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    //Initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    //Self note: AndroidSettings icon is from the drawable folder :d 
    var initializationSettingsAndroid = new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: (id, title, body, payload) async{});
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
	}

	void initFirebase() {
		_fireCloudMessaging.configure(
			onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        await _refreshContests();
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        await _refreshContests();
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        await _refreshContests();
      },
		);
	}

  Future<void> subscribeToAllOnFirecloud() async{
    await _fireCloudMessaging.subscribeToTopic(Strings.atcoderTopic);
    await _fireCloudMessaging.subscribeToTopic(Strings.codeforcesTopic);
    //Debug only, remove on production
    assert((){
      _fireCloudMessaging.subscribeToTopic(Strings.debugTopic); 
      return true;
    }());
  }

	Future loadLocalContests() async{
    if(!isLoadingData){
      setState((){
        isLoadingData=true;
      });
    }
		List<Contest> localContestList =  await _localContestsHelper.getContests();
		setState(() {
			_contestList = localContestList;
			isLoadingData=false;
		});
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

  Future<void> _refreshContests() async{
    setState(() {
      isLoadingData = true;
    });
    try{
      await _contestsFetcher.fetchContests();
    } on SocketException{
			showSnackBar("There's no internet connection. Try again later.");
    }
    _contestList = await _localContestsHelper.getContests();
    setState(() { 
      isLoadingData = false;
    });
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
			itemBuilder: (context)=>contestPopupItems(context, index),
      onSelected: (value) async{
				if(value==1){
				//See in browser
					await launch(contest.contestUrl);
				}
				if(value==2){
					//Hide contest
					await _localContestsHelper.hideContest(contest);
					await loadLocalContests();
				}
				if(value==3){
					//Remind me!
					await _localContestsHelper.switchAlertToContest(contest);
          setState(() {
            contest.hasAlert = contest.hasAlert == 0 ? 1 : 0; 
          });
				}
			},
		);
	}

	List<PopupMenuEntry<Object>> contestPopupItems(BuildContext context, int index){
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
					_contestList[index].hidden == 0 ? "Hide contest" : "Unhide contest",
					style: TextStyle(
						color: Colors.black, fontWeight: FontWeight.normal
					),
				),
			),
      //If contest is hidden don't let it to be reminded
      (_contestList[index].hidden == 0 ?
      PopupMenuDivider(
        height: 10,
      ) : []),
      (_contestList[index].hidden == 0 ?
        PopupMenuItem(
          value: 3,
          child: Text(
            _contestList[index].hasAlert == 0 ? "Remind me!" : "Disable alert",
            style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.normal
            ),
          ),
        ) : []),
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

	void showSnackBar(String text){
		final snackBar = SnackBar(
			//backgroundColor: Colors.black,
			content: Text(text)
		);
		// Find the Scaffold in the widget tree and use it to show a SnackBar.
		_scaffoldKey.currentState.showSnackBar(snackBar);
	}

	Color _getContestColor(int index){
		if(_contestList[index].contestPlatform==Strings.codeforcesTopic){
			return Colors.yellow;
		}
		else if(_contestList[index].contestPlatform==Strings.atcoderTopic){
			return Colors.black26;
		}
		return Colors.black;
	}
}

