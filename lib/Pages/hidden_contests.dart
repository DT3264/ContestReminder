import 'package:contests_reminder/Widgets/contests_list.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
//Local imports
import 'package:contests_reminder/Helpers/shared_preferences_helper.dart';

class HiddenContests extends StatefulWidget{
  @override
  _HiddenContests createState() => _HiddenContests();
}

class _HiddenContests extends State<HiddenContests>{
  final SharedPreferencesHelper prefsHelper = SharedPreferencesHelper();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Hidden contests"),
      ),
      body: ContestsList(context: context, showHidden: true,)
    );
  }
}