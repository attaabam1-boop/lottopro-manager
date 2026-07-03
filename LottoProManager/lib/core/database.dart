import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';
import '../models/dashboard_summary.dart';
import '../models/payment.dart';
import '../models/report_summary.dart';
import '../models/ticket.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'lotto_pro_manager.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _create,
      onUpgrade: _upgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        whatsapp TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        numbers TEXT NOT NULL,
        play_type TEXT NOT NULL,
        stake REAL NOT NULL,
        draw_date TEXT NOT NULL,
        status TEXT NOT NULL,
        winnings REAL NOT NULL DEFAULT 0,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(tickets)');
      final hasWinnings = columns.any((column) => column['name'] == 'winnings');
      if (!hasWinnings) {
        await db.execute(
          'ALTER TABLE tickets ADD COLUMN winnings REAL NOT NULL DEFAULT 0',
        );
      }
    }
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap()..remove('id'));
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return db.update(
      'customers',
      customer.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getCustomers({String query = ''}) async {
    final db = await database;
    final rows = query.trim().isEmpty
        ? await db.query('customers', orderBy: 'name COLLATE NOCASE')
        : await db.query(
            'customers',
            where: 'name LIKE ? OR phone LIKE ? OR whatsapp LIKE ?',
            whereArgs: ['%$query%', '%$query%', '%$query%'],
            orderBy: 'name COLLATE NOCASE',
          );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> insertTicket(Ticket ticket) async {
    final db = await database;
    return db.insert('tickets', ticket.toMap()..remove('id'));
  }

  Future<int> updateTicket(Ticket ticket) async {
    final db = await database;
    return db.update(
      'tickets',
      ticket.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [ticket.id],
    );
  }

  Future<int> deleteTicket(int id) async {
    final db = await database;
    return db.delete('tickets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Ticket>> getTickets({String query = ''}) async {
    final db = await database;
    final trimmed = query.trim();
    final rows = trimmed.isEmpty
        ? await db.query('tickets', orderBy: 'draw_date DESC, id DESC')
        : await db.query(
            'tickets',
            where: 'CAST(id AS TEXT) LIKE ? OR numbers LIKE ?',
            whereArgs: ['%$trimmed%', '%$trimmed%'],
            orderBy: 'draw_date DESC, id DESC',
          );
    return rows.map(Ticket.fromMap).toList();
  }

  Future<List<Ticket>> getTicketsByCustomer(int customerId) async {
    final db = await database;
    final rows = await db.query(
      'tickets',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'draw_date DESC, id DESC',
    );
    return rows.map(Ticket.fromMap).toList();
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return db.insert('payments', payment.toMap()..remove('id'));
  }

  Future<List<Payment>> getPayments({int? customerId}) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: customerId == null ? null : 'customer_id = ?',
      whereArgs: customerId == null ? null : [customerId],
      orderBy: 'date DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final db = await database;
    final customers = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;
    final tickets = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM tickets'),
        ) ??
        0;
    final stake = await _sum('tickets', 'stake');
    final winnings = await _sum('tickets', 'winnings');
    final paid = await _sum('payments', 'amount');
    return DashboardSummary(
      totalCustomers: customers,
      totalTickets: tickets,
      totalStake: stake,
      totalWinnings: winnings,
      totalPaid: paid,
    );
  }

  Future<ReportSummary> getReportSummary(DateTime start, DateTime end) async {
    final db = await database;
    final tickets = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(stake), 0) AS stake,
             COALESCE(SUM(winnings), 0) AS winnings
      FROM tickets
      WHERE draw_date >= ? AND draw_date < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final payments = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS paid
      FROM payments
      WHERE date >= ? AND date < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return ReportSummary(
      totalStake: ((tickets.first['stake'] as num?) ?? 0).toDouble(),
      totalWinnings: ((tickets.first['winnings'] as num?) ?? 0).toDouble(),
      totalPaid: ((payments.first['paid'] as num?) ?? 0).toDouble(),
    );
  }

  Future<double> _sum(String table, String column) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM($column), 0) AS total FROM $table',
    );
    return ((rows.first['total'] as num?) ?? 0).toDouble();
  }
}
