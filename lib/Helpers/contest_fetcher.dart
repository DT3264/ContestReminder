import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:contests_reminder/Helpers/local_contests_helper.dart';
import '../Models/contest.dart';
import '../Widgets/scaled_text.dart';

class ContestsFetcher {
  Future<http.Response> _requestContests() async {
    String dataURL = "https://contests-api.herokuapp.com/api/all";
    try {
      http.Response response = await http.get(dataURL);
      return response;
    } on SocketException catch (e) {
      print("Socket exception from contests fetcher");
      print(e);
      throw e;
    }
  }

  Future<List<Contest>> _contestsResponseToList(
      dynamic _contestResponse) async {
    List<Contest> contestList = List<Contest>();
    Contest actualContest;
    for (var contestData in _contestResponse) {
      actualContest = Contest.fromFetch(contestData);
      contestList.add(actualContest);
    }
    return contestList;
  }

  Future<List<Contest>> fetchContests(
      {bool getHidden, BuildContext context}) async {
    LocalContestsHelper localContestsHelper = LocalContestsHelper();
    List<Contest> contestsList = List();
    http.Response response;
    if (getHidden) {
      return await localContestsHelper.getHiddenContests();
    }
    try {
      response = await _requestContests();
    } on SocketException catch (e) {
      showSnackBar('Internet not available', context);
      print(e);
    } on Exception catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).backgroundColor,
        content: ScaledText(
          text: e.toString(),
          fontSize: 16,
        ),
      ));
      throw (e);
    }
    List<Contest> contestList = [];
    if (response != null) {
      if (response.statusCode == 200) {
        dynamic contestResponse = json.decode(response.body);
        contestList = await _contestsResponseToList(contestResponse);
        await localContestsHelper.insertContests(contestList);
      } else {
        print("Response from fetchContests status was not 200");
        throw Exception(
            "Error fetching contests. Response code:${response.statusCode}.");
      }
    }

    await localContestsHelper.insertContests(contestsList);
    return await localContestsHelper.getContests();
  }

  void showSnackBar(String message, BuildContext context) {
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
}
