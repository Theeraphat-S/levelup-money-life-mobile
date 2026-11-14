// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'general_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GeneralLocalizationsEn extends GeneralLocalizations {
  GeneralLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get status => 'Status';

  @override
  String get language => 'Language';

  @override
  String get thai => 'Thai';

  @override
  String get english => 'English';

  @override
  String get theme_light => 'Light Mode';

  @override
  String get theme_dark => 'Dark Mode';

  @override
  String get theme_system => 'System Theme';

  @override
  String get data_manager => 'Data Manager';

  @override
  String get backup_data => 'Backup Data (JSON)';

  @override
  String get restore_data => 'Restore Data (JSON)';

  @override
  String get reset_data => 'Reset All Data';

  @override
  String get reset_confirm => 'Are you sure you want to reset all data to default?';

  @override
  String get data_restored_success => 'Data restored successfully!';

  @override
  String get data_restore_failed => 'Failed to restore data. Invalid JSON.';

  @override
  String get copied_to_clipboard => 'Copied to clipboard';

  @override
  String get backup_error_unsupported_version => 'This backup was made by a newer app version and can\'t be restored.';

  @override
  String backup_error_invalid_transactions(String detail) {
    return 'Backup has an invalid transaction ($detail). Nothing was changed.';
  }

  @override
  String backup_error_invalid_allocations(String detail) {
    return 'Backup has an invalid budget allocation ($detail). Nothing was changed.';
  }

  @override
  String backup_error_invalid_quests(String detail) {
    return 'Backup has an invalid quest ($detail). Nothing was changed.';
  }

  @override
  String backup_error_invalid_gamification(String detail) {
    return 'Backup has invalid XP / streak data ($detail). Nothing was changed.';
  }

  @override
  String backup_error_invalid_settings(String detail) {
    return 'Backup has an invalid setting ($detail). Nothing was changed.';
  }

  @override
  String get backup_error_database => 'Couldn\'t write the backup to the database. Your existing data was not changed.';

  @override
  String get msg_load_failed => 'Couldn\'t load data. Please try again.';

  @override
  String get msg_save_failed => 'Couldn\'t save the transaction.';

  @override
  String get msg_update_failed => 'Couldn\'t update the transaction.';

  @override
  String get msg_delete_failed => 'Couldn\'t delete the transaction.';

  @override
  String get msg_generic_error => 'Something went wrong. Please try again.';

  @override
  String get msg_budget_save_failed => 'Couldn\'t save the budget allocation.';

  @override
  String get msg_income_save_failed => 'Couldn\'t save your monthly income.';

  @override
  String get msg_checkin_failed => 'Daily check-in failed.';

  @override
  String get msg_reward_claim_failed => 'Couldn\'t claim the reward.';

  @override
  String msg_checkin_success(int xp) {
    return 'Checked in! +$xp XP';
  }

  @override
  String msg_quest_completed(int xp) {
    return 'Quest complete! +$xp XP';
  }

  @override
  String get msg_quest_reverted => 'Quest marked as not done.';

  @override
  String msg_quest_reward_claimed(int xp) {
    return 'Reward claimed! +$xp XP';
  }

  @override
  String get settings_title => 'Settings & Profile';

  @override
  String xp_and_streak(int xp, int days) {
    return '$xp XP · $days Day Streak';
  }

  @override
  String get general_preferences => 'General Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get backup_and_data => 'Backup & Data Management';

  @override
  String get backup_and_data_subtitle => 'Export / Import JSON Data';

  @override
  String get manage => 'Manage';

  @override
  String get saved_success => 'Saved!';

  @override
  String get tab_export => 'Export';

  @override
  String get tab_import => 'Import';

  @override
  String get tab_reset => 'Reset';

  @override
  String get export_hint => 'JSON backup (also works with the web app):';

  @override
  String get copy_json_backup => 'Copy JSON Backup';

  @override
  String get import_hint => 'Paste JSON exported from the web or mobile app:';

  @override
  String get import_and_restore => 'Import & Restore';

  @override
  String get reset_description => 'Transactions, stats and quests will be reset to the default sample data.';

  @override
  String get reset_confirm_button => 'Confirm Reset All';
}
