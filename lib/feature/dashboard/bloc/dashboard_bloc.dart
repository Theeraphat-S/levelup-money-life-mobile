import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levelup_money_life/shared/models/app_message.dart';
import 'package:levelup_money_life/domain/models/gamification/quest.dart';
import 'package:levelup_money_life/domain/models/gamification/user_profile.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';
import 'package:levelup_money_life/domain/repositories/budget_repository.dart';
import 'package:levelup_money_life/domain/repositories/gamification_repository.dart';
import 'package:levelup_money_life/domain/repositories/transaction_repository.dart';
import 'package:levelup_money_life/domain/repositories/user_repository.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_event.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_state.dart';
import 'package:levelup_money_life/shared/utils/stream_utils.dart';

typedef _DashboardSnapshot = ({
  List<TransactionItem> transactions,
  UserProfile user,
  List<QuestItem> quests,
});

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final UserRepositoryInterface userRepository;
  final TransactionRepositoryInterface transactionRepository;
  final GamificationRepositoryInterface gamificationRepository;
  final BudgetRepositoryInterface budgetRepository;

  /// Last month the dashboard was scoped to. A [LoadDashboardData] without a
  /// month keeps this scope instead of silently widening to all months.
  String? _monthFilter;

  DashboardBloc({
    required this.userRepository,
    required this.transactionRepository,
    required this.gamificationRepository,
    required this.budgetRepository,
  }) : super(const DashboardState()) {
    on<LoadDashboardData>(_onLoadDashboardData, transformer: restartable());
    on<CheckInDailyEvent>(_onCheckInDaily);
    on<ClaimQuestRewardEvent>(_onClaimQuestReward);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    _monthFilter = event.monthFilter ?? _monthFilter;
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      await gamificationRepository.refreshDailyQuests();

      await emit.forEach<_DashboardSnapshot>(
        combineLatest3(
          transactionRepository.watchTransactions(monthFilter: _monthFilter),
          userRepository.watchUserProfile(),
          gamificationRepository.watchDailyQuests(),
          (transactions, user, quests) =>
              (transactions: transactions, user: user, quests: quests),
        ),
        onData: (snapshot) {
          final summary = MoneySummary.of(snapshot.transactions).toMap();

          return state.copyWith(
            status: DashboardStatus.success,
            userProfile: snapshot.user,
            summary: summary,
            recentTransactions: snapshot.transactions.take(5).toList(),
            activeQuests: snapshot.quests,
          );
        },
        onError: (e, stack) {
          addError(e, stack);
          return state.copyWith(
            status: DashboardStatus.failure,
            errorMessage: const AppMessage(AppMessageCode.loadFailed),
          );
        },
      );
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: const AppMessage(AppMessageCode.loadFailed),
        ),
      );
    }
  }

  Future<void> _onCheckInDaily(
    CheckInDailyEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final updatedUser = await userRepository.checkInDaily();
      emit(
        state.copyWith(
          userProfile: updatedUser,
          notificationMessage: const AppMessage(
            AppMessageCode.checkInSuccess,
            xp: 20,
          ),
        ),
      );
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          errorMessage: const AppMessage(AppMessageCode.checkInFailed),
        ),
      );
    }
  }

  Future<void> _onClaimQuestReward(
    ClaimQuestRewardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final claimedQuest = await gamificationRepository.claimQuestReward(
        event.questId,
      );
      final updatedUser = await userRepository.getUserProfile();
      final quests = await gamificationRepository.getDailyQuests();

      emit(
        state.copyWith(
          userProfile: updatedUser,
          activeQuests: quests,
          notificationMessage: AppMessage(
            AppMessageCode.questRewardClaimed,
            xp: claimedQuest.xp,
          ),
        ),
      );
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          errorMessage: const AppMessage(AppMessageCode.rewardClaimFailed),
        ),
      );
    }
  }
}
