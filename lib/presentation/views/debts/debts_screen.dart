import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/debt_model.dart';
import '../../controllers/debt_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/bottom_nav_bar.dart';

class DebtsScreen extends GetView<DebtController> {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('debtsAndCredits'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'refresh'.tr,
              onPressed: controller.refresh,
            ),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'owedToYou'.tr),
              Tab(text: 'youOwe'.tr),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // --- Summary Banner ---
              Obx(() => Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: scheme.surfaceContainerHighest.withOpacity(0.4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'youAreOwed'.tr,
                        value: dashboardController.formatCurrency(controller.totalReceivables),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Container(width: 1, height: 40, color: scheme.outlineVariant),
                    Expanded(
                      child: _SummaryTile(
                        label: 'youOwe'.tr,
                        value: dashboardController.formatCurrency(controller.totalPayables),
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              )),

              // --- Search ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'searchByName'.tr,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: controller.search,
                ),
              ),
              const SizedBox(height: 8),

              // --- Tab Content ---
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }
                  return TabBarView(
                    children: [
                      _DebtList(
                        debts: controller.filteredDebtors(),
                        emptyText: 'noDebtorsEmpty'.tr,
                        formatCurrency: dashboardController.formatCurrency,
                      ),
                      _DebtList(
                        debts: controller.filteredCreditors(),
                        emptyText: 'noCreditorsEmpty'.tr,
                        formatCurrency: dashboardController.formatCurrency,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final String emptyText;
  final String Function(double) formatCurrency;

  const _DebtList({
    required this.debts,
    required this.emptyText,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText, textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: debts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final debt = debts[index];
        return _DebtTile(debt: debt, formatCurrency: formatCurrency);
      },
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final String Function(double) formatCurrency;

  const _DebtTile({required this.debt, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReceivable = debt.type == 'receivable';
    final accent = isReceivable ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withOpacity(0.12),
                child: Icon(
                  isReceivable ? Icons.person_rounded : Icons.local_shipping_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(debt.personName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (debt.personPhone.isNotEmpty)
                      Text(debt.personPhone,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: debt.status == 'partial'
                      ? Colors.orange.withOpacity(0.12)
                      : accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  debt.status == 'partial' ? 'partialStatus'.tr : 'unpaidStatus'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: debt.status == 'partial' ? Colors.orange : accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _amountColumn('totalLabel'.tr, formatCurrency(debt.totalAmount), scheme.onSurface)),
              Expanded(child: _amountColumn('paidLabel'.tr, formatCurrency(debt.amountPaid), scheme.onSurfaceVariant)),
              Expanded(child: _amountColumn('balanceLabel'.tr, formatCurrency(debt.balance), accent)),
            ],
          ),
          if (debt.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(debt.notes, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showPaymentDialog(context, debt),
              icon: const Icon(Icons.payments_rounded, size: 16),
              label: Text(
                isReceivable ? 'recordPaymentReceived'.tr : 'recordPaymentMade'.tr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context, Debt debt) {
    final amountCtrl = TextEditingController(text: debt.balance.toStringAsFixed(2));

    Get.dialog(
      AlertDialog(
        title: Text('${'paymentTitle'.tr} — ${debt.personName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'remainingBalance'.tr}: ${formatCurrency(debt.balance)}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'amountReceivedOrPaid'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              Get.back();
              DebtController.to.recordPayment(debt, amount);
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}