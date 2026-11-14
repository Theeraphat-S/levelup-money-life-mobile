import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levelup_money_life/domain/models/gamification/quest.dart';
import 'package:levelup_money_life/i18n/i18n.dart';
import 'package:levelup_money_life/shared/models/app_message.dart';

Future<BuildContext> _contextFor(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: I18n.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  final q1 = QuestItem(id: 'q1', title: 'stored', date: '2030-01-01', xp: 15);
  final custom = QuestItem(
    id: 'custom',
    title: 'My own quest',
    date: '2030-01-01',
    xp: 5,
  );
  const reward = AppMessage(AppMessageCode.questRewardClaimed, xp: 25);

  testWidgets('messages and quest titles follow English locale', (
    tester,
  ) async {
    final context = await _contextFor(tester, const Locale('en'));
    expect(reward.localize(context), 'Reward claimed! +25 XP');
    expect(
      q1.getLocalizedTitle(context),
      'Record all daily expenses for today',
    );
    expect(custom.getLocalizedTitle(context), 'My own quest');
  });

  testWidgets('messages and quest titles follow Thai locale', (tester) async {
    final context = await _contextFor(tester, const Locale('th'));
    expect(reward.localize(context), 'ปลดล็อกสำเร็จ! ได้รับ +25 XP');
    expect(
      q1.getLocalizedTitle(context),
      'บันทึกรายจ่ายประจำวันทุกรายการวันนี้',
    );
  });

  test('success codes are not errors', () {
    expect(reward.isError, isFalse);
    expect(const AppMessage(AppMessageCode.saveFailed).isError, isTrue);
  });
}
