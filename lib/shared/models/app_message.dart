import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:levelup_money_life/i18n/i18n.dart';

/// What a bloc wants to tell the user. Blocs have no [BuildContext], so they
/// emit a code (plus data such as XP) and the UI localizes it.
enum AppMessageCode {
  loadFailed,
  saveFailed,
  updateFailed,
  deleteFailed,
  genericError,
  budgetSaveFailed,
  incomeSaveFailed,
  checkInFailed,
  rewardClaimFailed,
  checkInSuccess,
  questCompleted,
  questReverted,
  questRewardClaimed,
}

class AppMessage extends Equatable {
  final AppMessageCode code;

  /// XP gained, for messages that celebrate an XP award.
  final int? xp;

  const AppMessage(this.code, {this.xp});

  bool get isError => switch (code) {
    AppMessageCode.checkInSuccess ||
    AppMessageCode.questCompleted ||
    AppMessageCode.questReverted ||
    AppMessageCode.questRewardClaimed => false,
    _ => true,
  };

  String localize(BuildContext context) {
    final l = AppLocalizations(context).general;
    final xp = this.xp ?? 0;
    return switch (code) {
      AppMessageCode.loadFailed => l.msg_load_failed,
      AppMessageCode.saveFailed => l.msg_save_failed,
      AppMessageCode.updateFailed => l.msg_update_failed,
      AppMessageCode.deleteFailed => l.msg_delete_failed,
      AppMessageCode.genericError => l.msg_generic_error,
      AppMessageCode.budgetSaveFailed => l.msg_budget_save_failed,
      AppMessageCode.incomeSaveFailed => l.msg_income_save_failed,
      AppMessageCode.checkInFailed => l.msg_checkin_failed,
      AppMessageCode.rewardClaimFailed => l.msg_reward_claim_failed,
      AppMessageCode.checkInSuccess => l.msg_checkin_success(xp),
      AppMessageCode.questCompleted => l.msg_quest_completed(xp),
      AppMessageCode.questReverted => l.msg_quest_reverted,
      AppMessageCode.questRewardClaimed => l.msg_quest_reward_claimed(xp),
    };
  }

  @override
  List<Object?> get props => [code, xp];
}
