import 'package:levelup_money_life/domain/models/budget/allocation_item.dart';
import 'package:levelup_money_life/domain/models/gamification/quest.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';

/// Backup format versions this build can read.
const supportedBackupVersions = {1};

/// Why a backup import was rejected. The UI maps these to localized text.
enum BackupImportError {
  unsupportedVersion,
  invalidTransactions,
  invalidAllocations,
  invalidQuests,
  invalidGamification,
  invalidSettings,
  databaseError,
}

class BackupImportResult {
  final BackupImportError? error;

  /// Where validation failed, e.g. `transactions[3].date`. Not localized.
  final String? detail;

  const BackupImportResult.success() : error = null, detail = null;

  const BackupImportResult.failure(BackupImportError this.error, [this.detail]);

  bool get success => error == null;

  @override
  String toString() => success ? 'success' : '${error!.name}: $detail';
}

class BackupValidationException implements Exception {
  final BackupImportError error;
  final String detail;

  const BackupValidationException(this.error, this.detail);

  @override
  String toString() => 'BackupValidationException(${error.name}: $detail)';
}

class ParsedGamification {
  final int totalXp;
  final int streakDays;
  final String lastActiveDate;
  final List<String>? unlockedAchievementIds;

  const ParsedGamification({
    required this.totalXp,
    required this.streakDays,
    required this.lastActiveDate,
    this.unlockedAchievementIds,
  });
}

/// A fully validated backup. A null section means "not present in the
/// file": the import leaves that part of the database as it is.
class ParsedBackup {
  final List<TransactionItem>? transactions;
  final List<AllocationItem>? allocations;
  final List<QuestItem>? quests;
  final double? monthlyIncome;
  final ParsedGamification? gamification;
  final String? themeMode;
  final String? activeMonth;

  const ParsedBackup({
    this.transactions,
    this.allocations,
    this.quests,
    this.monthlyIncome,
    this.gamification,
    this.themeMode,
    this.activeMonth,
  });
}

final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _monthRe = RegExp(r'^\d{4}-\d{2}$');
const _maxAbsAmount = 1e12;

/// Validates and parses a backup map without touching the database.
///
/// Throws [BackupValidationException] on the first invalid field.
ParsedBackup parseBackup(Map<String, dynamic> json) {
  final version = json['version'];
  if (version != null &&
      (version is! int || !supportedBackupVersions.contains(version))) {
    throw BackupValidationException(
      BackupImportError.unsupportedVersion,
      'version=$version',
    );
  }

  return ParsedBackup(
    transactions: _optionalList(
      json,
      'transactions',
      BackupImportError.invalidTransactions,
      _parseTransactions,
    ),
    allocations: _optionalList(
      json,
      'allocations',
      BackupImportError.invalidAllocations,
      _parseAllocations,
    ),
    quests: _optionalList(
      json,
      'quests',
      BackupImportError.invalidQuests,
      _parseQuests,
    ),
    monthlyIncome: _parseMonthlyIncome(json['monthlyIncome']),
    gamification: _parseGamification(json['gamification']),
    themeMode: _parseThemeMode(json['themeMode']),
    activeMonth: _parseActiveMonth(json['activeMonth']),
  );
}

T? _optionalList<T>(
  Map<String, dynamic> json,
  String key,
  BackupImportError error,
  T Function(List<Object?>) parse,
) {
  final raw = json[key];
  if (raw == null) return null;
  if (raw is! List) {
    throw BackupValidationException(error, '$key is not a list');
  }
  return parse(raw);
}

Map<String, dynamic> _entry(Object? raw, String path, BackupImportError error) {
  if (raw is! Map) {
    throw BackupValidationException(error, '$path is not an object');
  }
  return Map<String, dynamic>.from(raw);
}

String _requireString(
  Map<String, dynamic> m,
  String key,
  String path,
  BackupImportError error, {
  String? alias,
}) {
  final value = m[key] ?? (alias == null ? null : m[alias]);
  if (value is! String || value.trim().isEmpty) {
    throw BackupValidationException(error, '$path.$key');
  }
  return value;
}

bool _isValidDate(String value) {
  if (!_dateRe.hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  // Reject values Dart would silently normalize, e.g. 2026-02-30.
  final roundTrip =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  return roundTrip == value;
}

List<TransactionItem> _parseTransactions(List<Object?> raw) {
  const error = BackupImportError.invalidTransactions;
  final seenIds = <String>{};
  final now = DateTime.now().millisecondsSinceEpoch;
  final result = <TransactionItem>[];

  for (var i = 0; i < raw.length; i++) {
    final path = 'transactions[$i]';
    final m = _entry(raw[i], path, error);

    final rawId = m['id'];
    if (rawId != null && (rawId is! String || rawId.isEmpty)) {
      throw BackupValidationException(error, '$path.id');
    }
    // Ids are optional for web exports; generate unique ones per row.
    final id = (rawId as String?) ?? 'import_${now}_$i';
    if (!seenIds.add(id)) {
      throw BackupValidationException(error, '$path.id duplicate "$id"');
    }

    final name = _requireString(m, 'name', path, error, alias: 'title');
    final category = _requireString(
      m,
      'category',
      path,
      error,
      alias: 'categoryName',
    );

    final amount = m['amount'];
    if (amount is! num || !amount.isFinite || amount.abs() > _maxAbsAmount) {
      throw BackupValidationException(error, '$path.amount');
    }

    final rawDate = m['date'];
    if (rawDate is! String ||
        rawDate.length < 10 ||
        !_isValidDate(rawDate.substring(0, 10))) {
      throw BackupValidationException(error, '$path.date');
    }

    final cleared = m['cleared'];
    if (cleared != null && cleared is! bool) {
      throw BackupValidationException(error, '$path.cleared');
    }
    final notes = m['notes'] ?? m['note'];
    if (notes != null && notes is! String) {
      throw BackupValidationException(error, '$path.notes');
    }
    final expGained = m['expGained'];
    if (expGained != null && (expGained is! int || expGained < 0)) {
      throw BackupValidationException(error, '$path.expGained');
    }
    final createdAt = m['createdAt'];
    if (createdAt != null &&
        (createdAt is! String || DateTime.tryParse(createdAt) == null)) {
      throw BackupValidationException(error, '$path.createdAt');
    }

    result.add(
      TransactionItem(
        id: id,
        name: name,
        amount: amount.toDouble(),
        date: rawDate.substring(0, 10),
        category: category,
        cleared: cleared as bool? ?? true,
        notes: notes as String?,
        expGained: expGained as int? ?? 15,
        createdAt: createdAt == null
            ? null
            : DateTime.parse(createdAt as String),
      ),
    );
  }
  return result;
}

List<AllocationItem> _parseAllocations(List<Object?> raw) {
  const error = BackupImportError.invalidAllocations;
  final seenIds = <String>{};
  final result = <AllocationItem>[];

  for (var i = 0; i < raw.length; i++) {
    final path = 'allocations[$i]';
    final m = _entry(raw[i], path, error);
    final id = _requireString(m, 'id', path, error);
    if (!seenIds.add(id)) {
      throw BackupValidationException(error, '$path.id duplicate "$id"');
    }
    final percent = m['percent'];
    if (percent is! num || percent < 0 || percent > 100) {
      throw BackupValidationException(error, '$path.percent');
    }
    result.add(
      AllocationItem(
        id: id,
        label: _requireString(m, 'label', path, error),
        percent: percent.round(),
        color: _requireString(m, 'color', path, error),
      ),
    );
  }
  return result;
}

List<QuestItem> _parseQuests(List<Object?> raw) {
  const error = BackupImportError.invalidQuests;
  final seenIds = <String>{};
  final result = <QuestItem>[];

  for (var i = 0; i < raw.length; i++) {
    final path = 'quests[$i]';
    final m = _entry(raw[i], path, error);
    final id = _requireString(m, 'id', path, error);
    if (!seenIds.add(id)) {
      throw BackupValidationException(error, '$path.id duplicate "$id"');
    }
    final date = _requireString(m, 'date', path, error);
    if (!_isValidDate(date)) {
      throw BackupValidationException(error, '$path.date');
    }
    final xp = m['xp'] ?? m['expReward'];
    if (xp is! int || xp < 0) {
      throw BackupValidationException(error, '$path.xp');
    }
    final done = m['done'] ?? m['isCompleted'];
    if (done != null && done is! bool) {
      throw BackupValidationException(error, '$path.done');
    }
    final category = m['category'];
    if (category != null && category is! String) {
      throw BackupValidationException(error, '$path.category');
    }
    result.add(
      QuestItem(
        id: id,
        title: _requireString(m, 'title', path, error),
        date: date,
        xp: xp,
        done: done as bool? ?? false,
        category: category as String? ?? 'daily',
      ),
    );
  }
  return result;
}

double? _parseMonthlyIncome(Object? raw) {
  if (raw == null) return null;
  if (raw is! num || !raw.isFinite || raw < 0 || raw > _maxAbsAmount) {
    throw const BackupValidationException(
      BackupImportError.invalidSettings,
      'monthlyIncome',
    );
  }
  return raw.toDouble();
}

ParsedGamification? _parseGamification(Object? raw) {
  if (raw == null) return null;
  const error = BackupImportError.invalidGamification;
  final m = _entry(raw, 'gamification', error);

  int nonNegativeInt(String key, int fallback) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is! int || v < 0) {
      throw BackupValidationException(error, 'gamification.$key');
    }
    return v;
  }

  final lastActive = m['lastActiveDate'];
  if (lastActive != null &&
      (lastActive is! String || !_isValidDate(lastActive))) {
    throw const BackupValidationException(error, 'gamification.lastActiveDate');
  }

  final rawIds = m['unlockedAchievementIds'];
  List<String>? ids;
  if (rawIds != null) {
    if (rawIds is! List || rawIds.any((e) => e is! String)) {
      throw const BackupValidationException(
        error,
        'gamification.unlockedAchievementIds',
      );
    }
    ids = rawIds.cast<String>().toSet().toList();
  }

  return ParsedGamification(
    totalXp: nonNegativeInt('totalXp', 180),
    streakDays: nonNegativeInt('streakDays', 1),
    lastActiveDate:
        lastActive as String? ??
        DateTime.now().toIso8601String().substring(0, 10),
    unlockedAchievementIds: ids,
  );
}

String? _parseThemeMode(Object? raw) {
  if (raw == null) return null;
  if (raw is! String || !const {'system', 'light', 'dark'}.contains(raw)) {
    throw const BackupValidationException(
      BackupImportError.invalidSettings,
      'themeMode',
    );
  }
  return raw;
}

String? _parseActiveMonth(Object? raw) {
  if (raw == null) return null;
  if (raw is! String || !_monthRe.hasMatch(raw) || !_isValidDate('$raw-01')) {
    throw const BackupValidationException(
      BackupImportError.invalidSettings,
      'activeMonth',
    );
  }
  return raw;
}
