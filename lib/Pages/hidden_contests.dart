import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
//Local imports
import 'package:contests_reminder/Utils/strings.dart';
import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Helpers/localContestsHelper.dart';
import 'package:contests_reminder/Utils/scaledText.dart';

class HiddenContests extends StatefulWidget{
  @override
  _HiddenContests createState() => _HiddenContests();
}

class _HiddenContests extends State<HiddenContests>{
  final _scaffoldKey = GlobalKey<ScaffoldState>();
	List<Contest> _contestList=[];
	bool isLoadingData=false;

	final LocalContestsHelper _localContestsHelper = LocalContestsHelper();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Hidden contests"),
      ),
      body: getListView()
    );
  }

  @override
	void initState() {
		super.initState();
		loadLocalContests(); 
	}

  Future loadLocalContests() async{
    if(!isLoadingData){
      setState((){
        isLoadingData=true;
      });
    }
		List<Contest> localContestList =  await _localContestsHelper.getHiddenContests();
		setState(() {
			_contestList = localContestList;
			isLoadingData=false;
		});
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
					await _localContestsHelper.switchContestHide(contest);
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
      //If contest is hidden don't let it to be reminded
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

	Color _getContestColor(int index){
		if(_contestList[index].contestPlatform==Strings.codeforcesTopic){
			return Colors.yellow;
		}
		else if(_contestList[index].contestPlatform==Strings.atcoderTopic){
			return Colors.grey;
		}
		return Colors.black;
	}
}