import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//Local imports
import 'package:contests_reminder/Utils/strings.dart';
import 'package:contests_reminder/Pages/settings.dart';
import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Utils/scaledText.dart';
import 'package:contests_reminder/Pages/hidden_contests.dart';
import 'package:contests_reminder/Utils/contests_fetcher.dart';
import 'package:contests_reminder/Helpers/localContestsHelper.dart';

class ContestsList extends StatefulWidget{
  @override
  _ContestsList createState()=> _ContestsList();
}

class _ContestsList extends State<ContestsList> {
	final _scaffoldKey = GlobalKey<ScaffoldState>();
	List<Contest> _contestList=[];
	bool isLoadingData=false;

  final ContestsFetcher _contestsFetcher = ContestsFetcher();
	final LocalContestsHelper _localContestsHelper = LocalContestsHelper();
	final FirebaseMessaging _fireCloudMessaging = FirebaseMessaging();
  SharedPreferencesHelper prefsHelper = SharedPreferencesHelper();
  FlutterLocalNotificationsPlugin _localNotifications;

  @override
	void initState() {
		super.initState();
		init();
	}

  void init() async {
		initFirebase();
    checkFirstInit();
    refreshContests();
	}

  void checkFirstInit() async{
    await prefsHelper.init();
    if(prefsHelper.isFirstStart()){
      print("first init");
      showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text("First time here, huh?"),
            content: Text("Click on any contest to see some options or refresh the available contests by pulling down the list."),
            actions: <Widget>[
              FlatButton(
                child: Text("OK"),
                onPressed: (){
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
      );
    }
  }

  void initNotifications(){
    _localNotifications = new FlutterLocalNotificationsPlugin();
    //Initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    //Self note: AndroidSettings icon is from the drawable folder :d 
    var initializationSettingsAndroid = new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: (id, title, body, payload) async{});
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    _localNotifications.initialize(initializationSettings);
  }

	@override
	Widget build(BuildContext context) {
		return Scaffold(
		key: _scaffoldKey,
		appBar: AppBar(
			title: Text("Contest Reminder"),
      actions: [getAppBarActions()]
		),
		body: Builder (
			builder: (context) => getBody(context)
		)
		);
	}

  Widget getAppBarActions(){
    return PopupMenuButton(
      itemBuilder: (BuildContext context){
        return [
          PopupMenuItem(value: 1, child: Text("Refresh contests")),
          PopupMenuItem(value: 2, child: Text("Hidden contests")),
          PopupMenuItem(value: 3, child: Text("Settings")),
          PopupMenuItem(value: 4, child: Text("About")),
        ];
      },
      onSelected: (int index) async{
        if(index==1){
          refreshContests();
        }
        else if(index==2){
          await Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => HiddenContests()
            )
          );
          refreshContests();
        }
        else if(index==3){
          await Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => Settings()
            )
          );
          refreshContests();
        }
        else if(index==4){
          showAboutDialog(
            applicationVersion: "1.0",
            applicationName: "Contests Reminder",
            children: [
              scaledText("With <3 by DT3264", 18),
              scaledText("Bugs or suggestions?, follow the link to the project.", 18),
              GestureDetector(
                child: Text(
                  Strings.gitUrl, 
                  style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                onTap: () {
                  launch(Strings.gitUrl);
                }
              )
            ],
            context: context,
          );
        }
      },
    );
  }

	void initFirebase() {
		_fireCloudMessaging.configure(
			onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        refreshContests();
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        refreshContests();
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        refreshContests();
      },
		);
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
						child: scaledText("Fetching contests data", 18)
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
						child: scaledText("Next contests: ${_contestList.length}", 18),
						margin: EdgeInsets.only(top: 10),
					),
					Expanded(
						child: new RefreshIndicator(
							child: getContestList(),
							onRefresh: refreshContests,
						)
					),
				],
			);
	}

  Future<void> refreshContests() async{
    setState(() {
      isLoadingData = true;
    });
    try{
      await _contestsFetcher.fetchContests();
    } on SocketException{
			showSnackBar("There's no internet connection. Try again later.");
    }
    on Exception catch(e){
      print(e);
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
			itemBuilder: (BuildContext context, int index) => contestBuilder(context, index),
			itemCount: _contestList.length,
		);
	}

	Widget contestBuilder(BuildContext context, int index){
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
					await _localContestsHelper.switchContestHide(contest);
					await loadLocalContests();
				}
				if(value==3){
					//Remind me!
					await _localContestsHelper.switchAlertToContest(contest);
          String message;
          int timeDelay = prefsHelper.getInt(Strings.reminderTime, 60);
          if(contest.hasAlert == 0){ 
            message = "The contest would be notified ${timeDelay%60 > 0 ? timeDelay : 1} ${timeDelay%60 > 0 ? "minute" : "hour"}${timeDelay%60 > 1 ? "s" : ""} before the contest" ;
          }
          else{
            message = "The contest notification has been canceled";
          }
          showSnackBar(message);
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
      PopupMenuDivider(
        height: 10,
      ),
      PopupMenuItem(
        value: 3,
        child: Text(
          _contestList[index].hasAlert == 0 ? "Remind me!" : "Disable alert",
          style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.normal
          ),
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
			color: getContestColor(index),
			child: Padding(
			padding: EdgeInsets.only(top: 5, bottom: 10),
			child: Column(
				children: <Widget>[
					scaledText("${contest.contestPlatform} contest", 18),
					scaledText(contest.contestName, 18),
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

	void showSnackBar(String text){
		final snackBar = SnackBar(
			//backgroundColor: Colors.black,
			content: scaledText(text, 16)
		);
		// Find the Scaffold in the widget tree and use it to show a SnackBar.
		_scaffoldKey.currentState.showSnackBar(snackBar);
	}

	Color getContestColor(int index){
		if(_contestList[index].contestPlatform==Strings.codeforcesTopic){
			return Colors.yellow;
		}
		else if(_contestList[index].contestPlatform==Strings.atcoderTopic){
			return Colors.grey;
		}
		return Colors.black;
	}
}
