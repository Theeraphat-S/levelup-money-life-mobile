import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levelup_money_life/shared/models/app_message.dart';
import 'package:levelup_money_life/domain/models/budget/allocation_item.dart';
import 'package:levelup_money_life/domain/models/transaction/category_item.dart';
import 'package:levelup_money_life/domain/models/transaction/transaction_item.dart';
import 'package:levelup_money_life/domain/repositories/budget_repository.dart';
import 'package:levelup_money_life/domain/repositories/gamification_repository.dart';
import 'package:levelup_money_life/domain/repositories/transaction_repository.dart';
import 'package:levelup_money_life/shared/utils/stream_utils.dart';

// State
enum BudgetStatus { initial, loading, success, failure }

class BudgetState extends Equatable {
  final BudgetStatus status;
  final double monthlyIncome;
  final List<AllocationItem> allocations;
  final List<BucketSpendingSummary> summaries;
  final AppMessage? errorMessage;

  const BudgetState({
    this.status = BudgetStatus.initial,
    this.monthlyIncome = 48000.0,
    this.allocations = const [],
    this.summaries = const [],
    this.errorMessage,
  });

  int get totalAllocatedPercent =>
      allocations.fold<int>(0, (sum, a) => sum + a.percent);

  bool get isBalanced => totalAllocatedPercent == 100;

  BudgetState copyWith({
    BudgetStatus? status,
    double? monthlyIncome,
    List<AllocationItem>? allocations,
    List<BucketSpendingSummary>? summaries,
    AppMessage? errorMessage,
  }) {
    return BudgetState(
      status: status ?? this.status,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      allocations: allocations ?? this.allocations,
      summaries: summaries ?? this.summaries,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    monthlyIncome,
    allocations,
    summaries,
    errorMessage,
  ];
}

// Events
abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetDataEvent extends BudgetEvent {
  final String? monthFilter;
  const LoadBudgetDataEvent({this.monthFilter});
  @override
  List<Object?> get props => [monthFilter];
}

class UpdateAllocationsEvent extends BudgetEvent {
  final List<AllocationItem> allocations;
  const UpdateAllocationsEvent(this.allocations);
  @override
  List<Object?> get props => [allocations];
}

class UpdateMonthlyIncomeEvent extends BudgetEvent {
  final double income;
  const UpdateMonthlyIncomeEvent(this.income);
  @override
  List<Object?> get props => [income];
}

// Bloc
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepositoryInterface budgetRepository;
  final TransactionRepositoryInterface transactionRepository;
  final GamificationRepositoryInterface gamificationRepository;

  /// Last month the budget view was scoped to; reloads without a month keep it.
  String? _monthFilter;

  BudgetBloc({
    required this.budgetRepository,
    required this.transactionRepository,
    required this.gamificationRepository,
  }) : super(const BudgetState()) {
    on<LoadBudgetDataEvent>(_onLoadBudgetData, transformer: restartable());
    on<UpdateAllocationsEvent>(_onUpdateAllocations);
    on<UpdateMonthlyIncomeEvent>(_onUpdateMonthlyIncome);
  }

  Future<void> _onLoadBudgetData(
    LoadBudgetDataEvent event,
    Emitter<BudgetState> emit,
  ) async {
    _monthFilter = event.monthFilter ?? _monthFilter;
    emit(state.copyWith(status: BudgetStatus.loading));
    try {
      final income = await budgetRepository.getMonthlyIncome();
      final allocations = await budgetRepository.getAllocations();

      await emit.forEach<List<TransactionItem>>(
        transactionRepository.watchTransactions(monthFilter: _monthFilter),
        onData: (transactions) {
          var needsSatang = 0;
          var wantsSatang = 0;
          var savingsSatang = 0;

          for (final tx in transactions) {
            if (tx.isIncome) continue;
            final cat = tx.categoryItem;
            final absAmt = tx.absAmountSatang;

            if (cat.bucket == BudgetBucket.needs) {
              needsSatang += absAmt;
            } else if (cat.bucket == BudgetBucket.wants) {
              wantsSatang += absAmt;
            } else if (cat.bucket == BudgetBucket.savings) {
              savingsSatang += absAmt;
            } else {
              needsSatang += absAmt;
            }
          }

          final summaries = allocations.map((alloc) {
            final budgetAmount = (income * alloc.percent) / 100.0;
            double spent = 0.0;
            if (alloc.id == 'needs') {
              spent = satangToBaht(needsSatang);
            } else if (alloc.id == 'wants') {
              spent = satangToBaht(wantsSatang);
            } else if (alloc.id == 'savings') {
              spent = satangToBaht(savingsSatang);
            }

            final remaining = budgetAmount - spent;
            final progress = budgetAmount > 0
                ? ((spent / budgetAmount) * 100.0).clamp(0.0, 100.0)
                : 0.0;

            return BucketSpendingSummary(
              id: alloc.id,
              label: alloc.label,
              percent: alloc.percent,
              budgetAmount: budgetAmount,
              spentAmount: spent,
              remainingAmount: remaining,
              progressPercent: progress,
              color: alloc.color,
            );
          }).toList();

          return state.copyWith(
            status: BudgetStatus.success,
            monthlyIncome: income,
            allocations: allocations,
            summaries: summaries,
          );
        },
        onError: (e, stack) {
          addError(e, stack);
          return state.copyWith(
            status: BudgetStatus.failure,
            errorMessage: const AppMessage(AppMessageCode.loadFailed),
          );
        },
      );
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          status: BudgetStatus.failure,
          errorMessage: const AppMessage(AppMessageCode.loadFailed),
        ),
      );
    }
  }

  Future<void> _onUpdateAllocations(
    UpdateAllocationsEvent event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await budgetRepository.saveAllocations(event.allocations);
      await gamificationRepository.evaluateAchievements();
      add(const LoadBudgetDataEvent());
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          errorMessage: const AppMessage(AppMessageCode.budgetSaveFailed),
        ),
      );
    }
  }

  Future<void> _onUpdateMonthlyIncome(
    UpdateMonthlyIncomeEvent event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await budgetRepository.saveMonthlyIncome(event.income);
      add(const LoadBudgetDataEvent());
    } catch (e, st) {
      addError(e, st);
      emit(
        state.copyWith(
          errorMessage: const AppMessage(AppMessageCode.incomeSaveFailed),
        ),
      );
    }
  }
}
