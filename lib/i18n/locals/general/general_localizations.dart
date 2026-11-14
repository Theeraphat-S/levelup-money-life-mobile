import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'general_localizations_en.dart';
import 'general_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GeneralLocalizations
/// returned by `GeneralLocalizations.of(context)`.
///
/// Applications need to include `GeneralLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'general/general_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GeneralLocalizations.localizationsDelegates,
///   supportedLocales: GeneralLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GeneralLocalizations.supportedLocales
/// property.
abstract class GeneralLocalizations {
  GeneralLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GeneralLocalizations? of(BuildContext context) {
    return Localizations.of<GeneralLocalizations>(context, GeneralLocalizations);
  }

  static const LocalizationsDelegate<GeneralLocalizations> delegate = _GeneralLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Thai
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get thai;

  /// English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Light Mode
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get theme_light;

  /// Dark Mode
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get theme_dark;

  /// System Theme
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get theme_system;

  /// Data Manager
  ///
  /// In en, this message translates to:
  /// **'Data Manager'**
  String get data_manager;

  /// Backup Data
  ///
  /// In en, this message translates to:
  /// **'Backup Data (JSON)'**
  String get backup_data;

  /// Restore Data
  ///
  /// In en, this message translates to:
  /// **'Restore Data (JSON)'**
  String get restore_data;

  /// Reset All Data
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get reset_data;

  /// Reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all data to default?'**
  String get reset_confirm;

  /// Data restored successfully
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully!'**
  String get data_restored_success;

  /// Failed to restore data
  ///
  /// In en, this message translates to:
  /// **'Failed to restore data. Invalid JSON.'**
  String get data_restore_failed;

  /// Copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied_to_clipboard;

  /// Backup version is not supported
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer app version and can\'t be restored.'**
  String get backup_error_unsupported_version;

  /// Invalid transaction in backup
  ///
  /// In en, this message translates to:
  /// **'Backup has an invalid transaction ({detail}). Nothing was changed.'**
  String backup_error_invalid_transactions(String detail);

  /// Invalid allocation in backup
  ///
  /// In en, this message translates to:
  /// **'Backup has an invalid budget allocation ({detail}). Nothing was changed.'**
  String backup_error_invalid_allocations(String detail);

  /// Invalid quest in backup
  ///
  /// In en, this message translates to:
  /// **'Backup has an invalid quest ({detail}). Nothing was changed.'**
  String backup_error_invalid_quests(String detail);

  /// Invalid gamification data in backup
  ///
  /// In en, this message translates to:
  /// **'Backup has invalid XP / streak data ({detail}). Nothing was changed.'**
  String backup_error_invalid_gamification(String detail);

  /// Invalid setting in backup
  ///
  /// In en, this message translates to:
  /// **'Backup has an invalid setting ({detail}). Nothing was changed.'**
  String backup_error_invalid_settings(String detail);

  /// Database error while restoring
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t write the backup to the database. Your existing data was not changed.'**
  String get backup_error_database;

  /// Generic load failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data. Please try again.'**
  String get msg_load_failed;

  /// Transaction save failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the transaction.'**
  String get msg_save_failed;

  /// Transaction update failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the transaction.'**
  String get msg_update_failed;

  /// Transaction delete failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the transaction.'**
  String get msg_delete_failed;

  /// Generic error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get msg_generic_error;

  /// Budget allocation save failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the budget allocation.'**
  String get msg_budget_save_failed;

  /// Monthly income save failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your monthly income.'**
  String get msg_income_save_failed;

  /// Check-in failure
  ///
  /// In en, this message translates to:
  /// **'Daily check-in failed.'**
  String get msg_checkin_failed;

  /// Reward claim failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t claim the reward.'**
  String get msg_reward_claim_failed;

  /// Daily check-in success
  ///
  /// In en, this message translates to:
  /// **'Checked in! +{xp} XP'**
  String msg_checkin_success(int xp);

  /// Quest completed
  ///
  /// In en, this message translates to:
  /// **'Quest complete! +{xp} XP'**
  String msg_quest_completed(int xp);

  /// Quest un-completed
  ///
  /// In en, this message translates to:
  /// **'Quest marked as not done.'**
  String get msg_quest_reverted;

  /// Quest reward claimed
  ///
  /// In en, this message translates to:
  /// **'Reward claimed! +{xp} XP'**
  String msg_quest_reward_claimed(int xp);

  /// Settings & Profile
  ///
  /// In en, this message translates to:
  /// **'Settings & Profile'**
  String get settings_title;

  /// {xp} XP · {days} Day Streak
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · {days} Day Streak'**
  String xp_and_streak(int xp, int days);

  /// General Preferences
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get general_preferences;

  /// Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Backup & Data Management
  ///
  /// In en, this message translates to:
  /// **'Backup & Data Management'**
  String get backup_and_data;

  /// Export / Import JSON Data
  ///
  /// In en, this message translates to:
  /// **'Export / Import JSON Data'**
  String get backup_and_data_subtitle;

  /// Manage
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Saved!
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved_success;

  /// Export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get tab_export;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get tab_import;

  /// Reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tab_reset;

  /// JSON backup (also works with the web app):
  ///
  /// In en, this message translates to:
  /// **'JSON backup (also works with the web app):'**
  String get export_hint;

  /// Copy JSON Backup
  ///
  /// In en, this message translates to:
  /// **'Copy JSON Backup'**
  String get copy_json_backup;

  /// Paste JSON exported from the web or mobile app:
  ///
  /// In en, this message translates to:
  /// **'Paste JSON exported from the web or mobile app:'**
  String get import_hint;

  /// Import & Restore
  ///
  /// In en, this message translates to:
  /// **'Import & Restore'**
  String get import_and_restore;

  /// Transactions, stats and quests will be reset to the default sample data.
  ///
  /// In en, this message translates to:
  /// **'Transactions, stats and quests will be reset to the default sample data.'**
  String get reset_description;

  /// Confirm Reset All
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset All'**
  String get reset_confirm_button;
}

class _GeneralLocalizationsDelegate extends LocalizationsDelegate<GeneralLocalizations> {
  const _GeneralLocalizationsDelegate();

  @override
  Future<GeneralLocalizations> load(Locale locale) {
    return SynchronousFuture<GeneralLocalizations>(lookupGeneralLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_GeneralLocalizationsDelegate old) => false;
}

GeneralLocalizations lookupGeneralLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return GeneralLocalizationsEn();
    case 'th': return GeneralLocalizationsTh();
  }

  throw FlutterError(
    'GeneralLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
