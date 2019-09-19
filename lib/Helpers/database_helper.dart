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
        await createTable(db);
        // And put some example contests
        await fillWithExampleData(db);
      },
      onUpgrade: (Database db, int x, int y) async{
        await db.execute("drop table contests");
        await createTable(db);
      }
    );
    alreadyInit=true;
  }

  Future<void> createTable(Database db) async{
    await db.execute(
      'create table contests(id integer primary key AUTOINCREMENT, contestName text unique, contestStart integer, contestEnd integer, contestUrl text unique, contestPlatform text, hidden bool, hasAlertRegistred bool);'
    );
  }

  Future<void> fillWithExampleData(db) async{
    await db.execute("insert or ignore into contests values (null, 'Educational Codeforces Round 70 (Rated for Div. 2)', 1565188500.0, 1565195700.0, 'https://codeforces.com/contests/1202', 'Codeforces', 0, 0), (null, 'AtCoder Beginner Contest 137', 1565438400.0, 1565444400.0, 'https://atcoder.jp/contests/abc137', 'AtCoder', 0, 0), (null, 'Codeforces Round #TBA', 1565526900.0, 1565534100.0, 'https://codeforces.com/contests/1200', 'Codeforces', 0, 0);");
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

  Future<int> rawUpdate(String sql) async{
    await checkInit();
    return await _database.rawUpdate(sql);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async{
    await checkInit();
    return await _database.rawQuery(sql);
  }

  Future<int> rawDelete(String sql) async{
    await checkInit();
    return await _database.rawDelete(sql);
  }

  Future rawTransaction(List<String> queries) async{
    await checkInit();
    await _database.transaction((trx) async{
      for(String query in queries){
        await trx.rawQuery(query);
      }
    });
  }

}