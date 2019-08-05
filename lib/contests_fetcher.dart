import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Helpers/localContestsHelper.dart';
class ContestsFetcher{
  Future<http.Response> _requestContests() async{
		String dataURL = "https://cf-at-api.herokuapp.com/get_contests";
		try{
			http.Response response = await http.get(dataURL);
			return response;
		} on SocketException catch (e){
			print("Socket exception from contests fetcher");
      print(e);
			throw e;
		}
	}

	Future<List<Contest>> fetchContests() async{
	  LocalContestsHelper localContestsHelper = LocalContestsHelper();
    http.Response response;
    try{
		  response = await _requestContests();
    } on Exception catch(e){
      print("Excepiton on fetchContests");
      throw(e);
    }
    List<Contest> contestList = [];
		if(response!=null){
			if(response.statusCode==200){
				dynamic contestResponse = json.decode(response.body);
				contestList = await _contestsResponseToList(contestResponse);
				await localContestsHelper.insertContests(contestList);
			}
			else{
        print("Response from fetchContests status was not 200");
				throw Exception("Error fetching contests. Response code:${response.statusCode}.");
			}
		}
    return contestList;
	}

  Future<List<Contest>> _contestsResponseToList(dynamic _contestResponse) async{
		List<Contest> contestList = List<Contest>();
    List<String> contestsIgnored = await SharedPreferencesHelper().getUnsubscribedContests();
    for(var i=0; i<contestsIgnored.length; i++){
      print(contestsIgnored[i]);
    }
		Contest actualContest;
		for(var contestData in _contestResponse){
			//print("Parsing: ");
			//print(contestData);
			actualContest = Contest.fromArray(contestData);
      if(!contestsIgnored.contains(actualContest.contestPlatform)){
			  contestList.add(actualContest);
      }
		}
		return contestList;
	}
}