import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

/// Database Helper class implementing a SQLite singleton pattern for SpendWise.
///
/// This class handles all CRUD (Create, Read, Update, Delete) operations,
/// table creation, aggregations, and monthly budget persistence.
/// All queries are wrapped in try-catch blocks with descriptive error handling.
class DBHelper {
  /// Private constructor for the Singleton pattern.
  DBHelper._init();

  /// The single static instance of [DBHelper].
  static final DBHelper instance = DBHelper._init();

  /// Cached instance of the open SQLite database.
  static Database? _database;

  /// Database name and version configuration.
  static const String _databaseName = 'spendwise.db';
  static const int _databaseVersion = 1;

  /// Table and column name constants to prevent typos and ease maintenance.
  static const String tableExpenses = 'expenses';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colDate = 'date';
  static const String colNote = 'note';

  static const String tableBudgets = 'budgets';
  static const String colMonthKey = 'month_key'; // e.g. "2026-10"
  static const String colBudgetAmount = 'amount';

  /// Asynchronous getter for the database instance.
  /// If the DB is already open, returns it; otherwise opens/creates it.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  /// Opens or creates the SQLite database at the platform-appropriate location.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
    );
  }

  /// Creates necessary database tables on first launch.
  Future<void> _createDB(Database db, int version) async {
    // 1. Table for storing individual expenses
    await db.execute('''
      CREATE TABLE $tableExpenses (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        $colCategory TEXT NOT NULL,
        $colDate TEXT NOT NULL,
        $colNote TEXT
      )
    ''');

    // 2. Table for storing monthly budgets (month_key: "YYYY-MM")
    await db.execute('''
      CREATE TABLE $tableBudgets (
        $colMonthKey TEXT PRIMARY KEY,
        $colBudgetAmount REAL NOT NULL
      )
    ''');
  }

  // ==========================================
  // EXPENSE CRUD OPERATIONS
  // ==========================================

  /// Inserts a new [Expense] into the database.
  /// Returns the newly generated auto-incremented primary key [id].
  Future<int> insertExpense(Expense expense) async {
    try {
      final db = await instance.database;
      final id = await db.insert(
        tableExpenses,
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Failed to insert expense into database: $e');
    }
  }

  /// Retrieves all expenses from the database, sorted newest first.
  Future<List<Expense>> getAllExpenses() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        tableExpenses,
        orderBy: '$colDate DESC, $colId DESC',
      );
      return result.map((json) => Expense.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  /// Updates an existing [Expense] identified by its [id].
  /// Returns the number of database rows affected (should be 1).
  Future<int> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Cannot update an expense without a valid ID.');
    }
    try {
      final db = await instance.database;
      final count = await db.update(
        tableExpenses,
        expense.toMap(),
        where: '$colId = ?',
        whereArgs: [expense.id],
      );
      return count;
    } catch (e) {
      throw Exception('Failed to update expense #${expense.id}: $e');
    }
  }

  /// Deletes an expense from the database by its [id].
  /// Returns the number of rows deleted.
  Future<int> deleteExpense(int id) async {
    try {
      final db = await instance.database;
      final count = await db.delete(
        tableExpenses,
        where: '$colId = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      throw Exception('Failed to delete expense #$id: $e');
    }
  }

  /// Retrieves expenses filtered by a specific year and month.
  /// Format for month match: e.g. "2026-10" matches all ISO dates starting with "2026-10".
  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    try {
      final db = await instance.database;
      final monthStr = month.toString().padLeft(2, '0');
      final prefix = '$year-$monthStr';

      final result = await db.query(
        tableExpenses,
        where: "$colDate LIKE ?",
        whereArgs: ['$prefix%'],
        orderBy: '$colDate DESC, $colId DESC',
      );
      return result.map((json) => Expense.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses for $year-$month: $e');
    }
  }

  /// Computes category-wise spending totals for a given year and month.
  /// Returns a Map where key is category name and value is the sum of amounts.
  Future<Map<String, double>> getCategoryTotals(int year, int month) async {
    try {
      final db = await instance.database;
      final monthStr = month.toString().padLeft(2, '0');
      final prefix = '$year-$monthStr';

      final result = await db.rawQuery('''
        SELECT $colCategory, SUM($colAmount) as total
        FROM $tableExpenses
        WHERE $colDate LIKE ?
        GROUP BY $colCategory
        ORDER BY total DESC
      ''', ['$prefix%']);

      final totals = <String, double>{};
      for (final row in result) {
        final category = row[colCategory] as String;
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        totals[category] = total;
      }
      return totals;
    } catch (e) {
      throw Exception('Failed to compute category totals: $e');
    }
  }

  /// Computes the total spending amount for a given year and month.
  Future<double> getTotalSpentForMonth(int year, int month) async {
    try {
      final db = await instance.database;
      final monthStr = month.toString().padLeft(2, '0');
      final prefix = '$year-$monthStr';

      final result = await db.rawQuery('''
        SELECT SUM($colAmount) as total
        FROM $tableExpenses
        WHERE $colDate LIKE ?
      ''', ['$prefix%']);

      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to calculate total spent for $year-$month: $e');
    }
  }

  // ==========================================
  // MONTHLY BUDGET OPERATIONS
  // ==========================================

  /// Formats year and month into the database primary key format ("YYYY-MM").
  String _formatMonthKey(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  /// Retrieves the monthly budget for the given year and month.
  /// If no specific budget has been set yet, returns a sensible default of 15000.0.
  Future<double> getBudget(int year, int month) async {
    try {
      final db = await instance.database;
      final key = _formatMonthKey(year, month);
      final result = await db.query(
        tableBudgets,
        where: '$colMonthKey = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        return (result.first[colBudgetAmount] as num).toDouble();
      }
      // Default initial budget for college student demonstration
      return 15000.0;
    } catch (e) {
      throw Exception('Failed to fetch budget for $year-$month: $e');
    }
  }

  /// Inserts or updates the monthly budget for the given year and month.
  Future<void> setBudget(int year, int month, double amount) async {
    try {
      final db = await instance.database;
      final key = _formatMonthKey(year, month);
      await db.insert(
        tableBudgets,
        {
          colMonthKey: key,
          colBudgetAmount: amount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to set budget for $year-$month: $e');
    }
  }

  /// Closes the database connection (useful during testing or app teardown).
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
