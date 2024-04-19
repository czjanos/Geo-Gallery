import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ImageLocationDatabase {
  late Database _database;
  final String tableName = 'images';

  Future<void> initDatabase() async {
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'image_location_database.db');
    return openDatabase(
      databasePath,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $tableName(id INTEGER PRIMARY KEY, path TEXT, latitude REAL, longitude REAL, date TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertImage(
      String path, double latitude, double longitude, String date) async {
    await _checkDatabaseInitialized();
    await _database.insert(
      tableName,
      {
        'path': path,
        'latitude': latitude,
        'longitude': longitude,
        'date': date
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllImages() async {
    await _checkDatabaseInitialized();
    return await _database.query(
      tableName,
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteAllImages() async {
    await _checkDatabaseInitialized();
    await _database.delete(tableName);
  }

  Future<void> _checkDatabaseInitialized() async {
    if (!_database.isOpen) {
      await initDatabase();
    }
  }
}
