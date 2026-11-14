import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levelup_money_life/shared/models/app_message.dart';
import 'package:levelup_money_life/domain/repositories/gamification_repository.dart';
import 'package:levelup_money_life/domain/repositories/user_repository.dart';
import 'package:levelup_money_life/feature/gamification/bloc/gamification_event.dart';
import 'package:levelup_money_life/feature/gamification/bloc/gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepositoryInterface gamificationRepository;
  final UserRepositoryInterface userRepository;

  GamificationBloc({
    required this.gamificationRepository,
    required this.userRepository,
  }) : super(const GamificationState()) {
    on<LoadGamificationDataEvent>(_onLoadData);
    on<ToggleQuestEvent>(_onToggleQuest);
    on<ClaimQuestEvent>(_onClaimQuest);
  }

  Future<void> _onLoadData(
    LoadGamificationDataEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(status: GamificationStatus.loading));
    try {
      await gamificationRepository.refreshDailyQuests();
      final evalResult = await gamificationRepository.evaluateAchievements();
      final user = await userRepository.getUserProfile();
      final quests = await gamificationRepository.getDailyQuests();

      emit(
        state.copyWith(
          status: GamificationStatus.success,
          userProfile: user,
          dailyQuests: quests,
          achievements: evalResult.allAchievements,
        ),
      );
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          status: GamificationStatus.failure,
          errorMessage: const AppMessage(AppMessageCode.loadFailed),
        ),
      );
    }
  }

  Future<void> _onToggleQuest(
    ToggleQuestEvent event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final updated = await gamificationRepository.toggleQuest(event.questId);
      final evalResult = await gamificationRepository.evaluateAchievements();
      final user = await userRepository.getUserProfile();
      final quests = await gamificationRepository.getDailyQuests();

      emit(
        state.copyWith(
          userProfile: user,
          dailyQuests: quests,
          achievements: evalResult.allAchievements,
          message: updated.done
              ? AppMessage(AppMessageCode.questCompleted, xp: updated.xp)
              : const AppMessage(AppMessageCode.questReverted),
        ),
      );
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          errorMessage: const AppMessage(AppMessageCode.genericError),
        ),
      );
    }
  }

  Future<void> _onClaimQuest(
    ClaimQuestEvent event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final claimed = await gamificationRepository.claimQuestReward(
        event.questId,
      );
      final evalResult = await gamificationRepository.evaluateAchievements();
      final user = await userRepository.getUserProfile();
      final quests = await gamificationRepository.getDailyQuests();

      emit(
        state.copyWith(
          userProfile: user,
          dailyQuests: quests,
          achievements: evalResult.allAchievements,
          message: AppMessage(
            AppMessageCode.questRewardClaimed,
            xp: claimed.xp,
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
