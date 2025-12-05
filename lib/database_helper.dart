import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

// User Role Enum
enum UserRole { admin, consumer }

// User Model
class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String contactNumber;
  final String address;
  final String barangay;
  final UserRole role;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.contactNumber,
    required this.address,
    required this.barangay,
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'contactNumber': contactNumber,
      'address': address,
      'barangay': barangay,
      'role': role.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      fullName: map['fullName'],
      contactNumber: map['contactNumber'],
      address: map['address'],
      barangay: map['barangay'],
      role: UserRole.values[map['role']],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Report Type Enum
enum ReportType { lowPressure, leakage }

// Report Status Enum
enum ReportStatus { pending, inProgress, resolved }

// Consumer Report Model
class ConsumerReport {
  final int? id;
  final int userId;
  final String consumerName;
  final String contactNumber;
  final String address;
  final String barangay;
  final ReportType type;
  final String description;
  final DateTime reportedAt;
  ReportStatus status;
  final double latitude;
  final double longitude;

  ConsumerReport({
    this.id,
    required this.userId,
    required this.consumerName,
    required this.contactNumber,
    required this.address,
    required this.barangay,
    required this.type,
    required this.description,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'consumerName': consumerName,
      'contactNumber': contactNumber,
      'address': address,
      'barangay': barangay,
      'type': type.index,
      'description': description,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status.index,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory ConsumerReport.fromMap(Map<String, dynamic> map) {
    return ConsumerReport(
      id: map['id'],
      userId: map['userId'],
      consumerName: map['consumerName'],
      contactNumber: map['contactNumber'],
      address: map['address'],
      barangay: map['barangay'],
      type: ReportType.values[map['type']],
      description: map['description'],
      reportedAt: DateTime.parse(map['reportedAt']),
      status: ReportStatus.values[map['status']],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}

// Water Interruption Model
class WaterInterruption {
  final int? id;
  final String title;
  final String description;
  final List<String> affectedBarangays;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final DateTime createdAt;

  WaterInterruption({
    this.id,
    required this.title,
    required this.description,
    required this.affectedBarangays,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'affectedBarangays': affectedBarangays.join(','),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WaterInterruption.fromMap(Map<String, dynamic> map) {
    return WaterInterruption(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      affectedBarangays: (map['affectedBarangays'] as String).split(','),
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Database Helper Singleton
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('valencia_water.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        contactNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        barangay TEXT NOT NULL,
        role INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        consumerName TEXT NOT NULL,
        contactNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        barangay TEXT NOT NULL,
        type INTEGER NOT NULL,
        description TEXT NOT NULL,
        reportedAt TEXT NOT NULL,
        status INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Water interruptions table
    await db.execute('''
      CREATE TABLE interruptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        affectedBarangays TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create default admin account
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'fullName': 'System Administrator',
      'contactNumber': '09000000000',
      'address': 'Valencia City Water District Office',
      'barangay': 'Poblacion',
      'role': UserRole.admin.index,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ============ USER METHODS ============

  Future<User?> createUser(User user) async {
    final db = await database;
    try {
      final id = await db.insert('users', user.toMap());
      return User(
        id: id,
        username: user.username,
        password: user.password,
        fullName: user.fullName,
        contactNumber: user.contactNumber,
        address: user.address,
        barangay: user.barangay,
        role: user.role,
        createdAt: user.createdAt,
      );
    } catch (e) {
      return null; // Username already exists
    }
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<bool> usernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  // ============ REPORT METHODS ============

  Future<ConsumerReport> createReport(ConsumerReport report) async {
    final db = await database;
    final id = await db.insert('reports', report.toMap());
    return ConsumerReport(
      id: id,
      userId: report.userId,
      consumerName: report.consumerName,
      contactNumber: report.contactNumber,
      address: report.address,
      barangay: report.barangay,
      type: report.type,
      description: report.description,
      reportedAt: report.reportedAt,
      status: report.status,
      latitude: report.latitude,
      longitude: report.longitude,
    );
  }

  Future<List<ConsumerReport>> getAllReports() async {
    final db = await database;
    final result = await db.query('reports', orderBy: 'reportedAt DESC');
    return result.map((map) => ConsumerReport.fromMap(map)).toList();
  }

  Future<List<ConsumerReport>> getReportsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'reports',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'reportedAt DESC',
    );
    return result.map((map) => ConsumerReport.fromMap(map)).toList();
  }

  Future<int> updateReportStatus(int id, ReportStatus status) async {
    final db = await database;
    return await db.update(
      'reports',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReport(int id) async {
    final db = await database;
    return await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  // ============ INTERRUPTION METHODS ============

  Future<WaterInterruption> createInterruption(WaterInterruption interruption) async {
    final db = await database;
    final id = await db.insert('interruptions', interruption.toMap());
    return WaterInterruption(
      id: id,
      title: interruption.title,
      description: interruption.description,
      affectedBarangays: interruption.affectedBarangays,
      startTime: interruption.startTime,
      endTime: interruption.endTime,
      isActive: interruption.isActive,
      createdAt: interruption.createdAt,
    );
  }

  Future<List<WaterInterruption>> getAllInterruptions() async {
    final db = await database;
    final result = await db.query('interruptions', orderBy: 'createdAt DESC');
    return result.map((map) => WaterInterruption.fromMap(map)).toList();
  }

  Future<List<WaterInterruption>> getActiveInterruptions() async {
    final db = await database;
    final result = await db.query(
      'interruptions',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'startTime DESC',
    );
    return result.map((map) => WaterInterruption.fromMap(map)).toList();
  }

  Future<int> updateInterruption(WaterInterruption interruption) async {
    final db = await database;
    return await db.update(
      'interruptions',
      interruption.toMap(),
      where: 'id = ?',
      whereArgs: [interruption.id],
    );
  }

  Future<int> deleteInterruption(int id) async {
    final db = await database;
    return await db.delete('interruptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> endInterruption(int id) async {
    final db = await database;
    return await db.update(
      'interruptions',
      {
        'isActive': 0,
        'endTime': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
