import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelup_money_life/domain/datasource/app_database.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';
import 'package:levelup_money_life/domain/repositories/gamification_repository.dart';
import 'package:levelup_money_life/domain/repositories/transaction_repository.dart';
import 'package:levelup_money_life/domain/repositories/user_repository.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_bloc.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_event.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

/// Schema v3 as shipped before the satang migration (REAL `amount`).
const _v3Schema = [
  '''CREATE TABLE transactions (id TEXT NOT NULL, name TEXT NOT NULL,
     amount REAL NOT NULL, date TEXT NOT NULL, category TEXT NOT NULL,
     cleared INTEGER NOT NULL DEFAULT 1 CHECK (cleared IN (0, 1)),
     notes TEXT NULL, exp_gained INTEGER NOT NULL DEFAULT 15,
     created_at INTEGER NULL, PRIMARY KEY (id))''',
  '''CREATE TABLE allocations (id TEXT NOT NULL, label TEXT NOT NULL,
     percent INTEGER NOT NULL, color TEXT NOT NULL, PRIMARY KEY (id))''',
  '''CREATE TABLE quests (id TEXT NOT NULL, title TEXT NOT NULL,
     date TEXT NOT NULL, xp INTEGER NOT NULL,
     done INTEGER NOT NULL DEFAULT 0 CHECK (done IN (0, 1)),
     category TEXT NOT NULL, PRIMARY KEY (id))''',
  '''CREATE TABLE user_profiles (id TEXT NOT NULL DEFAULT 'user_main',
     name TEXT NOT NULL DEFAULT 'Finance Commander',
     total_xp INTEGER NOT NULL DEFAULT 180,
     streak_days INTEGER NOT NULL DEFAULT 1,
     last_active_date TEXT NOT NULL, PRIMARY KEY (id))''',
  '''CREATE TABLE unlocked_achievements (id TEXT NOT NULL,
     unlocked_at TEXT NOT NULL, PRIMARY KEY (id))''',
  '''CREATE TABLE app_settings (key TEXT NOT NULL, value TEXT NOT NULL,
     PRIMARY KEY (key))''',
];

void main() {
  group('Schema v3 -> v4 migration', () {
    test('converts REAL baht amounts to exact integer satang', () async {
      final db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (raw) {
            for (final ddl in _v3Schema) {
              raw.execute(ddl);
            }
            raw.execute(
              'INSERT INTO transactions (id, name, amount, date, category, exp_gained) '
              "VALUES ('a', 'Coffee', -65.5, '2026-01-02', 'Food', 20), "
              "('b', 'Salary', 48000.0, '2026-01-01', 'Income', 30), "
              "('c', 'Odd', 0.29, '2026-01-03', 'Income', 15)",
            );
            raw.execute(
              'INSERT INTO user_profiles (id, total_xp, last_active_date) '
              "VALUES ('user_main', 500, '2026-01-03')",
            );
            raw.execute(
              "INSERT INTO allocations VALUES ('needs','Needs',50,'#000')",
            );
            raw.execute('PRAGMA user_version = 3');
          },
        ),
      );
      addTearDown(db.close);

      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final types = {
        for (final c in cols) c.read<String>('name'): c.read<String>('type'),
      };
      expect(types['amount_satang'], 'INTEGER');
      expect(types.containsKey('amount'), isFalse);

      final repo = TransactionRepository(db);
      final txs = {for (final t in await repo.getTransactions()) t.id: t};
      expect(txs['a']!.amountSatang, -6550);
      expect(txs['b']!.amountSatang, 4800000);
      expect(
        txs['c']!.amountSatang,
        29,
        reason: '0.29 * 100 must round, not truncate',
      );
      expect(txs['a']!.expGained, 20);
      expect((await UserRepository(db).getUserProfile()).totalXp, 500);
    });
  });

  group('Money precision', () {
    late AppDatabase db;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });
    tearDown(() => db.close());

    test('totals are exact to the satang', () async {
      final repo = TransactionRepository(db);
      for (var i = 0; i < 10; i++) {
        await repo.createTransaction(
          TransactionItem(
            id: 'dime_$i',
            name: 'Dime',
            amount: 0.1,
            date: '2030-05-0${i % 9 + 1}',
            category: 'Income',
          ),
        );
      }
      final summary = await repo.getFinancialSummary(monthFilter: '2030-05');
      // Summing ten 0.1 doubles gives 0.9999999999999999.
      expect(summary['totalIncome'], 1.0);
    });

    test('amounts are rounded to whole satang on creation', () {
      final tx = TransactionItem(
        id: 'x',
        name: 'x',
        amount: 10.005,
        date: '2030-01-01',
        category: 'Food',
      );
      expect(tx.amountSatang, 1001);
    });
  });

  group('Ordering', () {
    test('same-day transactions are newest first', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = TransactionRepository(db);
      final base = DateTime(2030, 1, 1, 9);
      for (final (id, minutes) in [('early', 0), ('late', 120), ('mid', 60)]) {
        await repo.createTransaction(
          TransactionItem(
            id: id,
            name: id,
            amount: -1,
            date: '2030-01-01',
            category: 'Food',
            createdAt: base.add(Duration(minutes: minutes)),
          ),
        );
      }
      final ids = (await repo.getTransactions(
        monthFilter: '2030-01',
      )).map((t) => t.id).toList();
      expect(ids, ['late', 'mid', 'early']);
    });
  });

  group('XP integrity', () {
    late AppDatabase db;
    late UserRepository userRepo;
    late TransactionRepository txRepo;
    late TransactionBloc bloc;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.initDatabase();
      userRepo = UserRepository(db);
      txRepo = TransactionRepository(db);
      bloc = TransactionBloc(
        transactionRepository: txRepo,
        userRepository: userRepo,
        gamificationRepository: GamificationRepository(db),
      );
    });
    tearDown(() async {
      await bloc.close();
      await db.close();
    });

    test('add then delete returns XP to where it started', () async {
      // Earn every achievement the add could unlock first, so the bonus
      // XP they award does not muddy the round trip.
      await GamificationRepository(db).evaluateAchievements();
      final before = (await userRepo.getUserProfile()).totalXp;

      bloc.add(
        AddTransactionItemEvent(
          TransactionItem(
            id: 'farm',
            name: 'Farm',
            amount: -1,
            date: '2030-01-01',
            category: 'Food',
            notes: 'note',
            expGained: 999,
          ),
        ),
      );
      await _settle();

      final stored = (await txRepo.getTransactions()).firstWhere(
        (t) => t.id == 'farm',
      );
      expect(
        stored.expGained,
        20,
        reason: 'stores XP actually awarded, not the input',
      );
      expect((await userRepo.getUserProfile()).totalXp, before + 20);

      bloc.add(const DeleteTransactionItemEvent('farm'));
      await _settle();
      expect((await userRepo.getUserProfile()).totalXp, before);
    });

    test('deleting never drives XP below zero', () async {
      await db.customStatement(
        "UPDATE user_profiles SET total_xp = 5 WHERE id = 'user_main'",
      );
      final deleted = await txRepo.deleteTransaction('t1');
      expect(deleted, isNotNull);
      expect((await userRepo.getUserProfile()).totalXp, 0);
    });

    test('deleting an unknown id is a no-op', () async {
      final before = (await userRepo.getUserProfile()).totalXp;
      expect(await txRepo.deleteTransaction('missing'), isNull);
      expect((await userRepo.getUserProfile()).totalXp, before);
    });
  });

  group('Backup import validation', () {
    late AppDatabase db;
    late TransactionRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.initDatabase();
      repo = TransactionRepository(db);
    });
    tearDown(() => db.close());

    Map<String, dynamic> tx(Map<String, dynamic> overrides) => {
      'id': 'i1',
      'name': 'Lunch',
      'amount': -80,
      'date': '2030-02-01',
      'category': 'Food',
      ...overrides,
    };

    Future<void> expectRejected(
      Map<String, dynamic> backup,
      BackupImportError error,
      String detailContains,
    ) async {
      final before = await repo.getTransactions();
      final result = await db.importBackupJson(backup);
      expect(result.success, isFalse);
      expect(result.error, error);
      expect(result.detail, contains(detailContains));
      expect(
        (await repo.getTransactions()).length,
        before.length,
        reason: 'a rejected import must leave existing data untouched',
      );
    }

    test('rejects an invalid date and keeps existing data', () async {
      await expectRejected(
        {
          'transactions': [
            tx({}),
            tx({'id': 'i2', 'date': '2030-02-30'}),
          ],
        },
        BackupImportError.invalidTransactions,
        'transactions[1].date',
      );
    });

    test('rejects a non-numeric amount', () async {
      await expectRejected(
        {
          'transactions': [
            tx({'amount': 'lots'}),
          ],
        },
        BackupImportError.invalidTransactions,
        'transactions[0].amount',
      );
    });

    test('rejects duplicate ids instead of silently dropping rows', () async {
      await expectRejected(
        {
          'transactions': [tx({}), tx({})],
        },
        BackupImportError.invalidTransactions,
        'duplicate',
      );
    });

    test('rejects an unsupported version', () async {
      await expectRejected(
        {
          'version': 99,
          'transactions': [tx({})],
        },
        BackupImportError.unsupportedVersion,
        'version=99',
      );
    });

    test(
      'rejects an invalid setting even when transactions are fine',
      () async {
        await expectRejected(
          {
            'transactions': [tx({})],
            'themeMode': 'neon',
          },
          BackupImportError.invalidSettings,
          'themeMode',
        );
      },
    );

    test('accepts web-format aliases and generates unique ids', () async {
      final result = await db.importBackupJson({
        'transactions': [
          {
            'title': 'A',
            'amount': -1.25,
            'date': '2030-03-01T10:00:00Z',
            'categoryName': 'Food',
            'note': 'n',
          },
          {
            'title': 'B',
            'amount': 2,
            'date': '2030-03-02',
            'categoryName': 'Income',
          },
        ],
      });
      expect(result.success, isTrue, reason: result.toString());

      final txs = await repo.getTransactions();
      expect(txs, hasLength(2));
      expect(txs.map((t) => t.id).toSet(), hasLength(2));
      final a = txs.firstWhere((t) => t.name == 'A');
      expect(a.amountSatang, -125);
      expect(a.date, '2030-03-01');
      expect(a.notes, 'n');
    });

    test('export then import round-trips amounts and createdAt', () async {
      final created = DateTime.utc(2030, 4, 1, 12, 30);
      await repo.createTransaction(
        TransactionItem(
          id: 'rt',
          name: 'RT',
          amount: -123.45,
          date: '2030-04-01',
          category: 'Food',
          createdAt: created,
        ),
      );
      final backup = await db.exportBackupJson();

      await db.resetAllData();
      final result = await db.importBackupJson(backup);
      expect(result.success, isTrue, reason: result.toString());

      final rt = (await repo.getTransactions()).firstWhere((t) => t.id == 'rt');
      expect(rt.amountSatang, -12345);
      expect(rt.createdAt!.isAtSameMomentAs(created), isTrue);
    });
  });
}
