import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import 'package:levelup_money_life/config/config.dart';
import 'package:levelup_money_life/feature/budget/bloc/budget_bloc.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_bloc.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_event.dart';
import 'package:levelup_money_life/feature/gamification/bloc/gamification_bloc.dart';
import 'package:levelup_money_life/feature/gamification/bloc/gamification_event.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_bloc.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_event.dart';
import 'package:levelup_money_life/i18n/i18n.dart';
import 'package:levelup_money_life/locator.dart';
import 'package:levelup_money_life/router/router.dart';
import 'package:levelup_money_life/shared/bloc/app/app_bloc.dart';
import 'package:levelup_money_life/shared/bloc/language/language_bloc.dart';
import 'package:levelup_money_life/shared/bloc/language/language_event.dart';
import 'package:levelup_money_life/shared/bloc/language/language_state.dart';
import 'package:levelup_money_life/shared/tokens/p_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  await initLocator();

  // Must match AppGlobalBloc's initial activeMonth; if the persisted month
  // differs, the activeMonth listener in MyApp reloads every scoped bloc.
  final initialMonth = DateFormat('yyyy-MM').format(DateTime.now());

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AppGlobalBloc>(
          create: (context) =>
              locator<AppGlobalBloc>()..add(const InitializeAppEvent()),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) =>
              locator<DashboardBloc>()
                ..add(LoadDashboardData(monthFilter: initialMonth)),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) =>
              locator<TransactionBloc>()
                ..add(LoadTransactionsEvent(monthFilter: initialMonth)),
        ),
        BlocProvider<BudgetBloc>(
          create: (context) =>
              locator<BudgetBloc>()
                ..add(LoadBudgetDataEvent(monthFilter: initialMonth)),
        ),
        BlocProvider<GamificationBloc>(
          create: (context) =>
              locator<GamificationBloc>()
                ..add(const LoadGamificationDataEvent()),
        ),
        BlocProvider<LanguageBloc>(
          create: (context) =>
              locator<LanguageBloc>()..add(const InitializeLanguageEvent()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppGlobalBloc, AppGlobalState>(
      listenWhen: (prev, curr) => prev.activeMonth != curr.activeMonth,
      listener: (context, appState) {
        final month = appState.activeMonth;
        context.read<DashboardBloc>().add(
          LoadDashboardData(monthFilter: month),
        );
        context.read<TransactionBloc>().add(
          LoadTransactionsEvent(monthFilter: month),
        );
        context.read<BudgetBloc>().add(LoadBudgetDataEvent(monthFilter: month));
      },
      child: BlocBuilder<AppGlobalBloc, AppGlobalState>(
        builder: (context, appState) {
          return BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, languageState) {
              final lightTheme = ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: PColor.lightBase,
                primaryColor: PColor.primaryLight,
                colorScheme: const ColorScheme.light(
                  primary: PColor.primaryLight,
                  secondary: PColor.jadeLight,
                  surface: PColor.lightSurface,
                  onSurface: PColor.lightInk,
                  error: PColor.roseLight,
                ),
                dividerColor: PColor.lightLine,
                cardColor: PColor.lightSurface,
                appBarTheme: const AppBarTheme(
                  backgroundColor: PColor.lightSurface,
                  foregroundColor: PColor.lightInk,
                  elevation: 0,
                ),
              );

              final darkTheme = ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: PColor.darkBase,
                primaryColor: PColor.primaryDark,
                colorScheme: const ColorScheme.dark(
                  primary: PColor.primaryDark,
                  secondary: PColor.jadeDark,
                  surface: PColor.darkSurface,
                  onSurface: PColor.darkInk,
                  error: PColor.roseDark,
                ),
                dividerColor: PColor.darkLine,
                cardColor: PColor.darkSurface,
                appBarTheme: const AppBarTheme(
                  backgroundColor: PColor.darkSurface,
                  foregroundColor: PColor.darkInk,
                  elevation: 0,
                ),
              );

              return ToastificationWrapper(
                child: MaterialApp.router(
                  title: 'LevelUp Money Life',
                  debugShowCheckedModeBanner: false,
                  supportedLocales: I18n.all,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  locale: languageState.locale,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: appState.themeMode,
                  routerConfig: _appRouter.config(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
