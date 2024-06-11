import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'event_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT,
        location TEXT,
        time TEXT,
        date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE guests(
        id INTEGER PRIMARY KEY,
        event_id INTEGER,
        name VARCHAR(255),
        identity_card INTEGER,
        code INTEGER,
        status TEXT,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertEvent(Map<String, dynamic> event) async {
    Database db = await database;
    return await db.insert('events', event);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    Database db = await database;
    return await db.query('events');
  }

  Future<int> insertGuest(Map<String, dynamic> guest) async {
  Database db = await database;
  print('Inserting into guests table: $guest'); // Debug print
  return await db.insert('guests', guest);
}

Future<List<Map<String, dynamic>>> getGuests(int eventId) async {
  Database db = await database;
  print('Querying guests for event_id: $eventId'); // Debug print
  return await db.query('guests', where: 'event_id = ?', whereArgs: [eventId]);
}
}
