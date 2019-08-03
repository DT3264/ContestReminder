import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  Database _database;
  bool alreadyInit=false;

  Future initDatabase() async{
    var databasesPath = await getDatabasesPath();
    String path = "${databasesPath}contests.db";
    // open the database
    _database = await openDatabase(
      path, 
      version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
          'create table contests(id integer primary key AUTOINCREMENT, contestName text unique, contestStart integer, contestEnd integer, contestUrl text, contestPlatform text, hidden bool);'
        );
      }
    );
    alreadyInit=true;
  }

  Future checkInit()async{
    if(!alreadyInit){
      await initDatabase();
    }
  }

  Future rawInsert(String sql) async{
    await checkInit();
    await _database.rawInsert(sql);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async{
    await checkInit();
    return await _database.rawQuery(sql);
  }

  Future rawTransaction(List<String> queries) async{
    await checkInit();
    await _database.transaction((trx)async {
      for(String query in queries){
        await trx.execute(query);
      }
    });
  }

}