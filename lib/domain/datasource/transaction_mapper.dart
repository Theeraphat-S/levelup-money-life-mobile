import 'package:drift/drift.dart';
import 'package:levelup_money_life/domain/datasource/app_database.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';

/// Single place that converts between Drift rows and [TransactionItem], so
/// the satang <-> baht conversion cannot drift apart between call sites.
extension TransactionDataMapper on TransactionData {
  TransactionItem toItem() => TransactionItem(
    id: id,
    name: name,
    amount: satangToBaht(amountSatang),
    date: date,
    category: category,
    cleared: cleared,
    notes: notes,
    expGained: expGained,
    createdAt: createdAt,
  );
}

extension TransactionItemCompanion on TransactionItem {
  /// Companion for inserts. Stamps [TransactionItem.createdAt] with now when
  /// the item does not carry one yet.
  TransactionsCompanion toInsertCompanion() => TransactionsCompanion.insert(
    id: id,
    name: name,
    amountSatang: amountSatang,
    date: date,
    category: category,
    cleared: Value(cleared),
    notes: Value(notes),
    expGained: Value(expGained),
    createdAt: Value(createdAt ?? DateTime.now()),
  );

  /// Companion for updates. Leaves `createdAt` untouched.
  TransactionsCompanion toUpdateCompanion() => TransactionsCompanion(
    name: Value(name),
    amountSatang: Value(amountSatang),
    date: Value(date),
    category: Value(category),
    cleared: Value(cleared),
    notes: Value(notes),
    expGained: Value(expGained),
  );
}

/// Newest first: by date, then creation time, then insertion order.
List<OrderingTerm Function($TransactionsTable)> newestTransactionsFirst() => [
  (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
  (t) => OrderingTerm(
    expression: t.createdAt,
    mode: OrderingMode.desc,
    nulls: NullsOrder.last,
  ),
  (t) => OrderingTerm(
    expression: const CustomExpression<int>('rowid'),
    mode: OrderingMode.desc,
  ),
];
