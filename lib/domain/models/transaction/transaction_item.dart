import 'package:intl/intl.dart';
import 'package:levelup_money_life/domain/models/transaction/category_item.dart';

enum TransactionType { expense, income }

/// Converts baht to integer satang (1 baht = 100 satang).
int bahtToSatang(double baht) => (baht * 100).round();

/// Converts integer satang back to baht for display.
double satangToBaht(int satang) => satang / 100;

class TransactionItem {
  final String id;
  final String name;

  /// Signed amount in baht, always rounded to whole satang: positive for
  /// income, negative for expense. Persisted as integer satang; aggregate
  /// with [amountSatang] to avoid floating-point drift in totals.
  final double amount;
  final String date; // "YYYY-MM-DD"
  final String category;
  final bool cleared;
  final String? notes;
  final int expGained;

  /// When the item was first saved; tie-breaker for same-day ordering.
  /// Null for rows created before schema v4.
  final DateTime? createdAt;

  TransactionItem({
    required this.id,
    required this.name,
    required double amount,
    required this.date,
    required this.category,
    this.cleared = true,
    this.notes,
    this.expGained = 15,
    this.createdAt,
  }) : amount = satangToBaht(bahtToSatang(amount));

  int get amountSatang => bahtToSatang(amount);
  int get absAmountSatang => amountSatang.abs();

  bool get isIncome => amount > 0 || category == 'Income';
  bool get isExpense => !isIncome;
  double get absAmount => amount.abs();
  String get title => name;
  String? get note => notes;

  TransactionType get type =>
      isIncome ? TransactionType.income : TransactionType.expense;

  CategoryItem get categoryItem => CategoryItem.fromCategoryId(category);

  DateTime get parsedDate {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return DateTime.now();
    }
  }

  String get formattedMonth {
    if (date.length >= 7) {
      return date.substring(0, 7);
    }
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  TransactionItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? date,
    String? category,
    bool? cleared,
    String? notes,
    int? expGained,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      cleared: cleared ?? this.cleared,
      notes: notes ?? this.notes,
      expGained: expGained ?? this.expGained,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final cat =
        json['category'] as String? ??
        json['categoryName'] as String? ??
        'Food';
    final name =
        json['name'] as String? ?? json['title'] as String? ?? 'รายการ';

    String dateStr =
        json['date'] as String? ??
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr.length > 10) {
      dateStr = dateStr.substring(0, 10);
    }

    return TransactionItem(
      id:
          json['id'] as String? ??
          'tx_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      amount: rawAmount,
      date: dateStr,
      category: cat,
      cleared: json['cleared'] as bool? ?? true,
      notes: json['notes'] as String? ?? json['note'] as String?,
      expGained: json['expGained'] as int? ?? 15,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date,
      'category': category,
      'cleared': cleared,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'expGained': expGained,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

/// Income / expense totals computed in integer satang, so sums are exact.
class MoneySummary {
  final int incomeSatang;
  final int expenseSatang;

  const MoneySummary({required this.incomeSatang, required this.expenseSatang});

  factory MoneySummary.of(Iterable<TransactionItem> transactions) {
    var income = 0;
    var expense = 0;
    for (final tx in transactions) {
      if (tx.isIncome) {
        income += tx.absAmountSatang;
      } else {
        expense += tx.absAmountSatang;
      }
    }
    return MoneySummary(incomeSatang: income, expenseSatang: expense);
  }

  double get totalIncome => satangToBaht(incomeSatang);
  double get totalExpense => satangToBaht(expenseSatang);
  double get netSavings => satangToBaht(incomeSatang - expenseSatang);

  /// Legacy map shape consumed by the dashboard UI.
  Map<String, double> toMap() => {
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'netSavings': netSavings,
    'totalBalance': netSavings,
  };
}
