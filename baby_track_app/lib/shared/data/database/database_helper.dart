import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Sistema de migraciones siguiendo AGENTS.md
class DatabaseHelper {
  static const String _databaseName = 'baby_track.db';
  static const int _databaseVersion = 2; // Incrementado para migración

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creación inicial con estructura v2
  Future<void> _onCreate(Database db, int version) async {
    await _createBabiesTableV2(db);
    await _createIndices(db);
  }

  /// Sistema de migraciones
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Migrating database from version $oldVersion to $newVersion');

    // Migración de v1 a v2: agregar campo gender
    if (oldVersion < 2) {
      await _upgradeToV2(db);
    }

    // Futuras migraciones
    // if (oldVersion < 3) {
    //   await _upgradeToV3(db);
    // }
  }

  /// Crear índices para rendimiento
  Future<void> _createIndices(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_babies_name ON babies(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_babies_birth_date ON babies(birth_date)');
  }

  /// Tabla v2 (con gender)
  Future<void> _createBabiesTableV2(Database db) async {
    await db.execute('''
      CREATE TABLE babies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        gender TEXT NOT NULL DEFAULT 'M',
        photo_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
  }

  /// Migración segura v1 → v2
  Future<void> _upgradeToV2(Database db) async {
    try {
      // Verificar si la columna gender ya existe
      final tableInfo = await db.rawQuery('PRAGMA table_info(babies)');
      final hasGender = tableInfo.any((col) => col['name'] == 'gender');

      if (!hasGender) {
        // Agregar columna gender con valor por defecto
        await db.execute('ALTER TABLE babies ADD COLUMN gender TEXT NOT NULL DEFAULT "M"');
        print('Successfully added gender column to babies table');
      }
    } catch (e) {
      print('Error during v1 to v2 migration: $e');
      // En caso de error, registrar pero continuar
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'baby_track.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
