import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levelup_money_life/domain/datasource/app_database.dart';
import 'package:levelup_money_life/feature/budget/bloc/budget_bloc.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_bloc.dart';
import 'package:levelup_money_life/feature/dashboard/bloc/dashboard_event.dart';
import 'package:levelup_money_life/feature/gamification/bloc/gamification_bloc.dart';
import 'package:levelup_money_life/feature/gamification/bloc/gamification_event.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_bloc.dart';
import 'package:levelup_money_life/feature/transaction/bloc/transaction_event.dart';
import 'package:levelup_money_life/i18n/i18n.dart';
import 'package:levelup_money_life/locator.dart';
import 'package:levelup_money_life/shared/bloc/app/app_bloc.dart';
import 'package:levelup_money_life/shared/tokens/p_colors.dart';

class DataManagerDialog extends StatefulWidget {
  const DataManagerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const DataManagerDialog(),
    );
  }

  @override
  State<DataManagerDialog> createState() => _DataManagerDialogState();
}

class _DataManagerDialogState extends State<DataManagerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();
  String _exportedJson = '';
  bool _isLoadingExport = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExportData();
  }

  Future<void> _loadExportData() async {
    final db = locator<AppDatabase>();
    final jsonMap = await db.exportBackupJson();
    if (mounted) {
      setState(() {
        _exportedJson = const JsonEncoder.withIndent('  ').convert(jsonMap);
        _isLoadingExport = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  void _copyExportedJson() {
    if (_isLoadingExport) return;
    Clipboard.setData(ClipboardData(text: _exportedJson));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(AppLocalizations(context).general.copied_to_clipboard)),
    );
  }

  void _importJson() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations(context).general.data_restore_failed)),
      );
      return;
    }

    try {
      final map = jsonDecode(text);
      if (map is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON map structure');
      }

      final db = locator<AppDatabase>();
      final result = await db.importBackupJson(map);
      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_importErrorText(result))),
        );
        return;
      }

      context.read<AppGlobalBloc>().add(const InitializeAppEvent());
      context.read<DashboardBloc>().add(const LoadDashboardData());
      context.read<TransactionBloc>().add(const LoadTransactionsEvent());
      context.read<BudgetBloc>().add(const LoadBudgetDataEvent());
      context.read<GamificationBloc>().add(const LoadGamificationDataEvent());

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations(context).general.data_restored_success)),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations(context).general.data_restore_failed)),
        );
      }
    }
  }

  String _importErrorText(BackupImportResult result) {
    final l = AppLocalizations(context).general;
    final detail = result.detail ?? '';
    return switch (result.error!) {
      BackupImportError.unsupportedVersion => l.backup_error_unsupported_version,
      BackupImportError.invalidTransactions =>
        l.backup_error_invalid_transactions(detail),
      BackupImportError.invalidAllocations =>
        l.backup_error_invalid_allocations(detail),
      BackupImportError.invalidQuests => l.backup_error_invalid_quests(detail),
      BackupImportError.invalidGamification =>
        l.backup_error_invalid_gamification(detail),
      BackupImportError.invalidSettings =>
        l.backup_error_invalid_settings(detail),
      BackupImportError.databaseError => l.backup_error_database,
    };
  }

  void _resetData() async {
    final db = locator<AppDatabase>();
    await db.resetAllData();

    if (mounted) {
      context.read<AppGlobalBloc>().add(const InitializeAppEvent());
      context.read<DashboardBloc>().add(const LoadDashboardData());
      context.read<TransactionBloc>().add(const LoadTransactionsEvent());
      context.read<BudgetBloc>().add(const LoadBudgetDataEvent());
      context.read<GamificationBloc>().add(const LoadGamificationDataEvent());

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations(context).general.data_restored_success)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = PColor.surface(context);
    final borderColor = PColor.line(context);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PColor.primarySoft(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.storage_outlined,
                      color: PColor.primary(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations(context).general.data_manager,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PColor.ink(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: PColor.primary(context),
              labelColor: PColor.primary(context),
              unselectedLabelColor: PColor.inkSoft(context),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: AppLocalizations(context).general.tab_export),
                Tab(text: AppLocalizations(context).general.tab_import),
                Tab(text: AppLocalizations(context).general.tab_reset),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Export
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations(context).general.export_hint,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PColor.ink(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PColor.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: _isLoadingExport
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : SingleChildScrollView(
                                    child: Text(
                                      _exportedJson,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingExport ? null : _copyExportedJson,
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: Text(AppLocalizations(context).general.copy_json_backup),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PColor.primary(context),
                              foregroundColor:
                                  isDark ? PColor.darkBase : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Import
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations(context).general.import_hint,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PColor.ink(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TextField(
                            controller: _importController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  '{\n  "version": 1,\n  "transactions": [...]\n}',
                              filled: true,
                              fillColor: PColor.surfaceSubtle(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _importJson,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(AppLocalizations(context).general.import_and_restore),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PColor.primary(context),
                              foregroundColor:
                                  isDark ? PColor.darkBase : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Reset
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: PColor.rose(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations(context).general.reset_confirm,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PColor.ink(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations(context).general.reset_description,
                          style: TextStyle(
                            fontSize: 12,
                            color: PColor.inkSoft(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _resetData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PColor.rose(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(AppLocalizations(context).general.reset_confirm_button),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
