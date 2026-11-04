import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary.dart';

class DiaryDatabase {
  static final DiaryDatabase instance = DiaryDatabase._init();

  static Database? _database;

  DiaryDatabase._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // 日記をデータベースに保存する
  Future<int> insertDiary(Diary diary) async {
    final db = await database;

    return await db.insert('diaries', {
      'title': diary.title,
      'content': diary.content,
      'created_at': diary.createdAt.toIso8601String(),
      'updated_at': diary.updatedAt.toIso8601String(),
    });
  }

  // すべての日記を取得する
  Future<List<Diary>> getAllDiaries() async {
    final db = await database;

    final result = await db.query('diaries', orderBy: 'created_at DESC');

    return result.map((map) {
      return Diary(
        id: map['id'] as int,
        title: map['title'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    }).toList();
  }

  // 日記を更新する
  Future<int> updateDiary(Diary diary) async {
    final db = await database;

    if (diary.id == null) {
      throw ArgumentError('日記IDがありません');
    }

    return await db.update(
      'diaries',
      {
        'title': diary.title,
        'content': diary.content,
        'updated_at': diary.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }

  // 日記を削除する
  Future<int> deleteDiary(int id) async {
    final db = await database;

    return await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }
}
