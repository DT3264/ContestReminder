import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:contests_reminder/Helpers/local_contests_helper.dart';
import '../Models/contest.dart';

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

  Future<List<Contest>> fetchContests({bool getHidden}) async {
    LocalContestsHelper localContestsHelper = LocalContestsHelper();
    List<Contest> contestsList = List();
    http.Response response;
    if (getHidden) {
      return await localContestsHelper.getHiddenContests();
    }
    try {
      response = await _requestContests();
    } on Exception catch (e) {
      print("Excepiton on fetchContests");
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
}
