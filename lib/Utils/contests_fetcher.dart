import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contests_reminder/Models/contest.dart';
import 'package:contests_reminder/Helpers/localContestsHelper.dart';
class ContestsFetcher{

	Future<void> fetchContests() async{
	  LocalContestsHelper localContestsHelper = LocalContestsHelper();
    List<Contest> contestList = List();
    await Firestore.instance
      .collection('contests').getDocuments()
      .then((QuerySnapshot ds){
        for(DocumentSnapshot contestSnapshot in ds.documents){
          contestList.add(Contest.fromFirestore(contestSnapshot.data));
        }
      });
		await localContestsHelper.insertContests(contestList);
	}
}