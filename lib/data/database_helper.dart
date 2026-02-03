import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wallet_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        name $textType,
        type $textType,
        colorValue $intType,
        initialBalance $doubleType,
        currentBalance $doubleType
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id $idType,
        accountId $textType,
        targetAccountId $textNullable,
        amount $doubleType,
        type $intType,
        category $textType,
        date $textType
      )
    ''');

    await db.execute('''
  CREATE TABLE weekly_calculator (
    id INTEGER PRIMARY KEY,
    sun_earn REAL DEFAULT 0, sun_spend REAL DEFAULT 0,
    mon_earn REAL DEFAULT 0, mon_spend REAL DEFAULT 0,
    tue_earn REAL DEFAULT 0, tue_spend REAL DEFAULT 0,
    wed_earn REAL DEFAULT 0, wed_spend REAL DEFAULT 0,
    thu_earn REAL DEFAULT 0, thu_spend REAL DEFAULT 0,
    fri_earn REAL DEFAULT 0, fri_spend REAL DEFAULT 0,
    sat_earn REAL DEFAULT 0, sat_spend REAL DEFAULT 0
  )
''');
  }
}
