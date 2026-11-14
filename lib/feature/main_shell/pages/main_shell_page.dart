import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levelup_money_life/feature/budget/bloc/budget_bloc.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_bloc.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_state.dart';
import 'package:levelup_money_life/router/router.dart';
import 'package:levelup_money_life/shared/components/appbar/bottombar_custom.dart';
import 'package:levelup_money_life/shared/components/header_command_deck.dart';
import 'package:levelup_money_life/shared/components/toasts/toast_helper.dart';
import 'package:levelup_money_life/shared/models/app_message.dart';

@RoutePage()
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  void _showError(BuildContext context, AppMessage message) {
    showErrorToast(context: context, description: message.localize(context));
  }

  @override
  Widget build(BuildContext context) {
    // Transaction and budget errors are not tied to one screen, so surface
    // them here once instead of in every page.
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listenWhen: (prev, curr) =>
              curr.errorMessage != null &&
              curr.errorMessage != prev.errorMessage,
          listener: (context, state) =>
              _showError(context, state.errorMessage!),
        ),
        BlocListener<BudgetBloc, BudgetState>(
          listenWhen: (prev, curr) =>
              curr.errorMessage != null &&
              curr.errorMessage != prev.errorMessage,
          listener: (context, state) =>
              _showError(context, state.errorMessage!),
        ),
      ],
      child: AutoTabsScaffold(
        routes: const [
          DashboardRoute(),
          TransactionRoute(),
          BudgetRoute(),
          AnalyticsRoute(),
          QuestRoute(),
        ],
        appBarBuilder: (context, tabsRouter) =>
            HeaderCommandDeck(onOpenQuests: () => tabsRouter.setActiveIndex(4)),
        bottomNavigationBuilder: (context, tabsRouter) => BottomBarCustom(
          activeIndex: tabsRouter.activeIndex,
          onItemTapped: tabsRouter.setActiveIndex,
        ),
      ),
    );
  }
}
