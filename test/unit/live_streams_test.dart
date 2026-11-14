import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:levelup_money_life/domain/datasource/app_database.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';
import 'package:levelup_money_life/domain/repositories/budget_repository.dart';
import 'package:levelup_money_life/domain/repositories/gamification_repository.dart';
import 'package:levelup_money_life/domain/repositories/transaction_repository.dart';
import 'package:levelup_money_life/domain/repositories/user_repository.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_bloc.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_event.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_state.dart';

/// Lets drift watch-queries and bloc handlers settle.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late AppDatabase db;
  late TransactionRepository transactionRepo;
  late GamificationRepository gamificationRepo;
  late UserRepository userRepo;
  late DashboardBloc bloc;

  const otherMonth = '2020-01';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.initDatabase();
    transactionRepo = TransactionRepository(db);
    gamificationRepo = GamificationRepository(db);
    userRepo = UserRepository(db);
    bloc = DashboardBloc(
      userRepository: userRepo,
      transactionRepository: transactionRepo,
      gamificationRepository: gamificationRepo,
      budgetRepository: BudgetRepository(db),
    );

    await transactionRepo.createTransaction(
      TransactionItem(
        id: 'other_month_income',
        name: 'Old bonus',
        amount: 1000,
        date: '$otherMonth-15',
        category: 'Income',
      ),
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  group('DashboardBloc live streams', () {
    test('reload without a month keeps the previous month scope', () async {
      bloc.add(const LoadDashboardData(monthFilter: otherMonth));
      await _settle();
      expect(bloc.state.summary['totalIncome'], 1000.0);

      // Same as what the add/edit sheets dispatch after saving.
      bloc.add(const LoadDashboardData());
      await _settle();
      expect(bloc.state.status, DashboardStatus.success);
      expect(
        bloc.state.summary['totalIncome'],
        1000.0,
        reason: 'must not widen to all months (seed data adds 48,000)',
      );
    });

    test('switching months replaces the old subscription', () async {
      bloc.add(const LoadDashboardData(monthFilter: otherMonth));
      await _settle();
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      bloc.add(LoadDashboardData(monthFilter: currentMonth));
      await _settle();
      final currentMonthIncome = bloc.state.summary['totalIncome'];

      // A write to the old month must not leak into the current view.
      await transactionRepo.createTransaction(
        TransactionItem(
          id: 'late_old_month_write',
          name: 'Refund',
          amount: 500,
          date: '$otherMonth-20',
          category: 'Income',
        ),
      );
      await _settle();

      expect(bloc.state.summary['totalIncome'], currentMonthIncome);
    });

    test('XP and quests update live without a reload', () async {
      bloc.add(const LoadDashboardData(monthFilter: otherMonth));
      await _settle();
      final xpBefore = bloc.state.userProfile!.totalXp;
      final quest = bloc.state.activeQuests.firstWhere((q) => !q.done);

      await gamificationRepo.toggleQuest(quest.id);
      await _settle();

      expect(bloc.state.userProfile!.totalXp, xpBefore + quest.xp);
      expect(
        bloc.state.activeQuests.firstWhere((q) => q.id == quest.id).done,
        isTrue,
      );
    });
  });

  group('Daily quest reset', () {
    test('no quest starts already completed', () async {
      final quests = await gamificationRepo.getDailyQuests();
      expect(quests.where((q) => q.done), isEmpty);
    });

    test('stale daily quests roll over to today and reopen', () async {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await db
          .update(db.quests)
          .write(
            const QuestsCompanion(date: Value('2020-01-01'), done: Value(true)),
          );

      await gamificationRepo.refreshDailyQuests();

      final quests = await gamificationRepo.getDailyQuests();
      expect(quests, isNotEmpty);
      for (final q in quests) {
        expect(q.date, today);
        expect(q.done, isFalse);
      }
    });

    test('quests completed today are kept', () async {
      final quest = (await gamificationRepo.getDailyQuests()).first;
      await gamificationRepo.toggleQuest(quest.id);

      await gamificationRepo.refreshDailyQuests();

      final after = (await gamificationRepo.getDailyQuests()).firstWhere(
        (q) => q.id == quest.id,
      );
      expect(after.done, isTrue);
    });
  });
}
