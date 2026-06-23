import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/interaction.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;
  static const int backupVersion = AppConstants.backupVersion;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'so_khach.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE customers ADD COLUMN phone TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE customers ADD COLUMN warranty_end_date INTEGER');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE customers ADD COLUMN source TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN product_id INTEGER');
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          cost_price REAL NOT NULL,
          default_sell_price REAL NOT NULL,
          default_commission REAL NOT NULL,
          note TEXT,
          active INTEGER NOT NULL DEFAULT 1,
          track_inventory INTEGER NOT NULL DEFAULT 0,
          stock_quantity INTEGER NOT NULL DEFAULT 0,
          low_stock_threshold INTEGER NOT NULL DEFAULT 5,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          product_id INTEGER,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_sell_price REAL NOT NULL,
          unit_cost REAL NOT NULL,
          unit_commission REAL NOT NULL,
          payment_status TEXT NOT NULL,
          paid_amount REAL NOT NULL,
          note TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        note TEXT,
        product TEXT,
        product_id INTEGER,
        source TEXT,
        status TEXT,
        created_at INTEGER,
        last_contact_at INTEGER,
        next_action_at INTEGER,
        warranty_end_date INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        content TEXT,
        created_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost_price REAL NOT NULL,
        default_sell_price REAL NOT NULL,
        default_commission REAL NOT NULL,
        note TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        track_inventory INTEGER NOT NULL DEFAULT 0,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 5,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_sell_price REAL NOT NULL,
        unit_cost REAL NOT NULL,
        unit_commission REAL NOT NULL,
        payment_status TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ── Customers ──────────────────────────────────────────────

  Future<int> insertCustomer(Customer c) async {
    final db = await database;
    return db.insert('customers', c.toMap());
  }

  Future<void> updateCustomer(Customer c) async {
    final db = await database;
    await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('orders', where: 'customer_id = ?', whereArgs: [id]);
      await txn.delete('interactions', where: 'customer_id = ?', whereArgs: [id]);
      await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Customer>> getNeedsAttention() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'customers',
      where: 'next_action_at <= ? AND status != ?',
      whereArgs: [now, 'closed'],
      orderBy: 'next_action_at ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getCustomersNeedingAttention() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.query(
      'customers',
      columns: ['id', 'status'],
      where: 'next_action_at <= ? AND status != ?',
      whereArgs: [now, 'closed'],
    );
  }

  Future<List<Customer>> getUpcoming() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'customers',
      where: 'next_action_at > ? AND status != ?',
      whereArgs: [now, 'closed'],
      orderBy: 'next_action_at ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'next_action_at ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> getOverdueCount() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 3))
        .millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM customers WHERE next_action_at <= ? AND status != 'closed'",
      [cutoff],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await database;
    final rows =
        await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  // ── Interactions ───────────────────────────────────────────

  Future<int> insertInteraction(Interaction i) async {
    final db = await database;
    return db.insert('interactions', i.toMap());
  }

  Future<List<Interaction>> getInteractions(int customerId) async {
    final db = await database;
    final rows = await db.query(
      'interactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Interaction.fromMap).toList();
  }

  // ── Products ───────────────────────────────────────────────

  Future<int> insertProduct(Product p) async {
    final db = await database;
    return db.insert('products', p.toMap(forDb: true));
  }

  Future<void> updateProduct(Product p) async {
    final db = await database;
    await db.update('products', p.toMap(forDb: true),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts({bool activeOnly = false}) async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    var list = rows.map(Product.fromMap).toList();
    if (activeOnly) list = list.where((p) => p.active).toList();
    return list;
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  // ── Orders ─────────────────────────────────────────────────

  Future<int> insertOrder(Order o) async {
    final db = await database;
    return db.insert('orders', o.toMap());
  }

  Future<void> deleteOrder(int id) async {
    final db = await database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'created_at DESC');
    return rows.map(Order.fromMap).toList();
  }

  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    final db = await database;
    final rows = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Order.fromMap).toList();
  }

  Future<List<Order>> getOrdersInRange(int start, int end) async {
    final db = await database;
    final rows = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start, end],
      orderBy: 'created_at DESC',
    );
    return rows.map(Order.fromMap).toList();
  }

  // ── Statistics ──────────────────────────────────────────────

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final contactRows = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM interactions WHERE created_at >= ? AND created_at < ?',
        [start, end]);
    final contactCount = Sqflite.firstIntValue(contactRows) ?? 0;

    final closedRows = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM interactions WHERE content LIKE 'Ghi đơn:%' AND created_at >= ? AND created_at < ?",
        [start, end]);
    final closedCount = Sqflite.firstIntValue(closedRows) ?? 0;

    final newRows = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM customers WHERE created_at >= ? AND created_at < ?',
        [start, end]);
    final newCount = Sqflite.firstIntValue(newRows) ?? 0;

    final productRows = await db.rawQuery(
        "SELECT product, COUNT(*) as cnt FROM customers WHERE product IS NOT NULL AND product != '' GROUP BY product ORDER BY cnt DESC LIMIT 5");

    return {
      'contacts': contactCount,
      'closed': closedCount,
      'new_customers': newCount,
      'top_products': productRows,
    };
  }

  Future<int> getCurrentStreak() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 365))
        .millisecondsSinceEpoch;

    final rows = await db.rawQuery(
      'SELECT DISTINCT CAST(created_at / 86400000 AS INTEGER) as day_bucket '
      'FROM interactions '
      'WHERE created_at >= ? AND created_at <= ? '
      'ORDER BY day_bucket DESC',
      [cutoff, todayStart + 86400000 - 1],
    );

    if (rows.isEmpty) return 0;

    final todayBucket = todayStart ~/ 86400000;
    int streak = 0;
    int expectedBucket = todayBucket;

    final firstBucket = rows.first['day_bucket'] as int;
    if (firstBucket == todayBucket - 1) {
      expectedBucket = todayBucket - 1;
    } else if (firstBucket != todayBucket) {
      return 0;
    }

    for (final row in rows) {
      final bucket = row['day_bucket'] as int;
      if (bucket == expectedBucket) {
        streak++;
        expectedBucket--;
      } else if (bucket < expectedBucket) {
        break;
      }
    }
    return streak;
  }

  // ── Settings ───────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Backup / Restore (Salenote JSON v2 — tương thích web) ──

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    final customers = await db.query('customers');
    final interactions = await db.query('interactions');
    final productRows = await db.query('products');
    final orderRows = await db.query('orders');

    return {
      'version': backupVersion,
      'customers': customers,
      'interactions': interactions,
      'products': productRows.map(_productRowForJson).toList(),
      'orders': orderRows,
    };
  }

  Map<String, dynamic> _productRowForJson(Map<String, dynamic> row) {
    final p = Product.fromMap(row);
    return p.toMap(forDb: false);
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    final customers =
        List<Map<String, dynamic>>.from(data['customers'] as List? ?? []);
    final interactions =
        List<Map<String, dynamic>>.from(data['interactions'] as List? ?? []);
    final products =
        List<Map<String, dynamic>>.from(data['products'] as List? ?? []);
    final orders =
        List<Map<String, dynamic>>.from(data['orders'] as List? ?? []);

    await db.transaction((txn) async {
      await txn.delete('orders');
      await txn.delete('products');
      await txn.delete('interactions');
      await txn.delete('customers');

      for (final c in customers) {
        await txn.insert('customers', Map<String, dynamic>.from(c));
      }
      for (final i in interactions) {
        await txn.insert('interactions', Map<String, dynamic>.from(i));
      }
      for (final raw in products) {
        final p = Product.fromMap(Map<String, dynamic>.from(raw));
        await txn.insert('products', p.toMap(forDb: true));
      }
      for (final o in orders) {
        await txn.insert('orders', Map<String, dynamic>.from(o));
      }
    });
  }
}
