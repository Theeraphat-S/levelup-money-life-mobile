import 'package:drift/drift.dart';
import 'package:levelup_money_life/domain/datasource/app_database.dart';
import 'package:levelup_money_life/domain/datasource/transaction_mapper.dart';
import 'package:levelup_money_life/domain/models/transaction/category_item.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';

abstract class TransactionRepositoryInterface {
  Future<List<TransactionItem>> getTransactions({String? monthFilter});
  Stream<List<TransactionItem>> watchTransactions({String? monthFilter});
  Future<List<CategoryItem>> getCategories();
  Future<TransactionItem> createTransaction(TransactionItem tx);
  Future<TransactionItem> updateTransaction(TransactionItem tx);

  /// Deletes the transaction and takes back the XP it awarded, atomically.
  /// Returns the deleted item, or null if no transaction had that id.
  Future<TransactionItem?> deleteTransaction(String id);
  Future<void> toggleCleared(String id);
  Future<void> bulkToggleCleared({required bool cleared, String? monthFilter});
  Future<Map<String, double>> getFinancialSummary({String? monthFilter});
}

class TransactionRepository implements TransactionRepositoryInterface {
  final AppDatabase db;

  TransactionRepository(this.db);

  SimpleSelectStatement<$TransactionsTable, TransactionData> _query(
    String? monthFilter,
  ) {
    final query = db.select(db.transactions)
      ..orderBy(newestTransactionsFirst());
    if (monthFilter != null && monthFilter.isNotEmpty) {
      query.where((t) => t.date.like('$monthFilter%'));
    }
    return query;
  }

  @override
  Stream<List<TransactionItem>> watchTransactions({String? monthFilter}) {
    return _query(
      monthFilter,
    ).watch().map((rows) => rows.map((r) => r.toItem()).toList());
  }

  @override
  Future<List<TransactionItem>> getTransactions({String? monthFilter}) async {
    final rows = await _query(monthFilter).get();
    return rows.map((r) => r.toItem()).toList();
  }

  @override
  Future<List<CategoryItem>> getCategories() async {
    return CategoryItem.defaultCategories;
  }

  @override
  Future<TransactionItem> createTransaction(TransactionItem tx) async {
    final stamped = tx.createdAt == null
        ? tx.copyWith(createdAt: DateTime.now())
        : tx;
    await db
        .into(db.transactions)
        .insert(stamped.toInsertCompanion(), mode: InsertMode.insertOrReplace);
    return stamped;
  }

  @override
  Future<TransactionItem> updateTransaction(TransactionItem tx) async {
    await (db.update(
      db.transactions,
    )..where((t) => t.id.equals(tx.id))).write(tx.toUpdateCompanion());
    return tx;
  }

  @override
  Future<TransactionItem?> deleteTransaction(String id) {
    return db.transaction(() async {
      final row = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return null;

      await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();

      if (row.expGained > 0) {
        // Clamp at 0 so deleting seed rows can never push XP negative.
        await db.customUpdate(
          'UPDATE user_profiles SET total_xp = MAX(total_xp - ?, 0) '
          "WHERE id = 'user_main'",
          variables: [Variable.withInt(row.expGained)],
          updates: {db.userProfiles},
        );
      }
      return row.toItem();
    });
  }

  @override
  Future<void> toggleCleared(String id) async {
    final tx = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (tx != null) {
      await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(cleared: Value(!tx.cleared)),
      );
    }
  }

  @override
  Future<void> bulkToggleCleared({
    required bool cleared,
    String? monthFilter,
  }) async {
    final updateQuery = db.update(db.transactions);
    if (monthFilter != null && monthFilter.isNotEmpty) {
      updateQuery.where((t) => t.date.like('$monthFilter%'));
    }
    await updateQuery.write(TransactionsCompanion(cleared: Value(cleared)));
  }

  @override
  Future<Map<String, double>> getFinancialSummary({String? monthFilter}) async {
    final txs = await getTransactions(monthFilter: monthFilter);
    return MoneySummary.of(txs).toMap();
  }
}
