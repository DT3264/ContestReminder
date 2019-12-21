import 'package:contests_reminder/Helpers/contest_fetcher.dart';
import 'package:flutter/Material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:contests_reminder/Helpers/local_contests_helper.dart';
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Widgets/scaled_text.dart';
import 'package:contests_reminder/Utils/strings.dart';

class ContestsList extends StatefulWidget {
  final bool showHidden;
  final BuildContext context;
  const ContestsList({this.context, this.showHidden});
  @override
  _ContestsList createState() => _ContestsList(showHidden: showHidden);
}

class _ContestsList extends State<ContestsList> {
  bool showHidden;
  //BuildContext context;
  List<Contest> _contestList = [];
  bool isLoadingData = false;
  bool firstLoad = true;
  LocalContestsHelper _localContestsHelper = LocalContestsHelper();
  SharedPreferencesHelper prefsHelper = SharedPreferencesHelper();

  _ContestsList({/*this.context,*/ this.showHidden});
  @override
  void initState() {
    super.initState();
    prefsHelper.init();
  }

  @override
  Widget build(BuildContext context) {
    if (firstLoad) {
      firstLoad = false;
      refreshContests(context: context);
      return getProgressDialog();
    }
    if (isLoadingData) {
      return getProgressDialog();
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: ScaledText(
                text:
                    "${showHidden ? "Hidden" : "Next"} contests: ${_contestList.length}",
                fontSize: 18),
            margin: EdgeInsets.only(top: 10),
          ),
          Expanded(
              child: new RefreshIndicator(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) =>
                  contestBuilder(context, index),
              itemCount: _contestList.length,
            ),
            onRefresh: () => refreshContests(context: context),
          )),
        ],
      );
    }
  }

  @widget
  Widget getProgressDialog() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ScaledText(text: "Fetching contests data", fontSize: 18)),
        CircularProgressIndicator()
      ],
    ));
  }

  Widget contestBuilder(BuildContext context, int index) {
    Contest contest = _contestList[index];
    return PopupMenuButton(
      child: contestCard(contest, index),
      offset: Offset(1, 10),
      itemBuilder: (context) => contestPopupItems(context, index),
      onSelected: (value) async {
        if (value == 1) {
          //See in browser
          await launch(contest.contestUrl);
        }
        if (value == 2) {
          //Hide contest
          await _localContestsHelper.switchContestHide(contest);
          await loadLocalContests();
        }
        if (value == 3) {
          //Remind me!
          await remindContest(contest);
        }
      },
    );
  }

  List<PopupMenuEntry<Object>> contestPopupItems(
      BuildContext context, int index) {
    return [
      PopupMenuItem(
        value: 1,
        child: Text(
          "Show in browser",
          style: TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      PopupMenuDivider(
        height: 10,
      ),
      PopupMenuItem(
        value: 2,
        child: Text(
          _contestList[index].hidden == 0 ? "Hide contest" : "Unhide contest",
          style: TextStyle(fontWeight: FontWeight.normal),
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
          style: TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
    ];
  }

  @widget
  Widget contestCard(Contest contest, int index) {
    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
        color: getContestColor(index),
        child: Padding(
          padding: EdgeInsets.only(top: 5, bottom: 10),
          child: Column(children: <Widget>[
            ScaledText(
                text: "${contest.contestPlatform} contest", fontSize: 18),
            ScaledText(text: contest.contestName, fontSize: 18),
            Row(
              children: <Widget>[
                dateTimeContestDesc(
                    date: contest.contestStart.toLocal(), isStart: true),
                dateTimeContestDesc(
                    date: contest.contestEnd.toLocal(), isStart: false),
              ],
            )
          ]),
        ));
  }

  @widget
  Widget dateTimeContestDesc({DateTime date, bool isStart}) {
    String hour =
        "${date.hour % 12 > 0 && date.hour % 12 < 10 ? "0" : ""}${(date.hour % 12 == 0 ? 12 : date.hour % 12)}";
    String minute = "${(date.minute <= 9 ? "0" : "")}${date.minute}";
    String hourPeriod = "${(date.hour <= 12 ? "a.m." : "p.m")}";
    String day = "${(date.day <= 9 ? "0" : "")}${date.day}";
    String month = "${(date.month <= 9 ? "0" : "")}${date.month}";
    return Expanded(
        child: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ScaledTextDate(text: isStart ? "Start" : "End"),
        ScaledTextDate(text: "$hour:$minute $hourPeriod"),
        ScaledTextDate(text: "$day/$month/${date.year}"),
      ],
    )));
  }

  Future<void> remindContest(Contest contest) async {
    int actualTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    int contestStart = contest.contestStart.millisecondsSinceEpoch ~/ 1000;
    int contestEnd = contest.contestEnd.millisecondsSinceEpoch ~/ 1000;
    if (actualTime >= contestEnd) {
      showSnackBar("The contest has already ended");
      await refreshContests(context: context);
    } else if (actualTime >= contestStart) {
      showSnackBar("The contests is in progress");
    } else if (contestStart - actualTime <= 60) {
      showSnackBar("The contest would start in <1 minute");
    }
    await _localContestsHelper.switchAlertToContest(contest);
    String message;
    int timeDelay = prefsHelper.getInt(Strings.reminderTime, 60);
    if (contest.hasAlert == 0) {
      message =
          "The contest would be notified ${timeDelay % 60 > 0 ? timeDelay : 1} ${timeDelay % 60 > 0 ? "minute" : "hour"}${timeDelay % 60 > 1 ? "s" : ""} before the contest";
    } else {
      message = "The contest notification has been canceled";
    }
    showSnackBar(message);
    setState(() {
      contest.hasAlert = contest.hasAlert == 0 ? 1 : 0;
    });
  }

  void showSnackBar(String message) {
    final snackbar = SnackBar(
        backgroundColor: Theme.of(context).backgroundColor,
        duration: Duration(seconds: 4),
        content: Text(
          message,
          style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white),
        ));
    // Find the Scaffold in the widget tree and use it to show a SnackBar.
    Scaffold.of(context).showSnackBar(snackbar);
  }

  Color getContestColor(int index) {
    if (_contestList[index].contestPlatform == Strings.codeforcesTopic) {
      return Colors.blue;
    } else if (_contestList[index].contestPlatform == Strings.atcoderTopic) {
      return Colors.grey;
    }
    return Colors.black;
  }

  Future<void> refreshContests({BuildContext context}) async {
    setState(() {
      isLoadingData = true;
    });
    if (showHidden) {
      _contestList = await ContestsFetcher()
          .fetchContests(getHidden: true, context: context);
    } else {
      _contestList = await ContestsFetcher()
          .fetchContests(getHidden: false, context: context);
    }
    setState(() {
      isLoadingData = false;
    });
  }

  Future loadLocalContests() async {
    if (!isLoadingData) {
      setState(() {
        isLoadingData = true;
      });
    }
    List<Contest> localContestList;
    if (showHidden) {
      localContestList = await _localContestsHelper.getHiddenContests();
    } else {
      localContestList = await _localContestsHelper.getContests();
    }
    setState(() {
      _contestList = localContestList;
      isLoadingData = false;
    });
  }
}
