import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'history_period_detail_screen.dart';

class HistoryPeriodsScreen extends ConsumerWidget {
  const HistoryPeriodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ປະຫວັດງວດທັງໝົດ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: state.periods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'ຍັງບໍ່ມີປະຫວັດງວດເທື່ອ',
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.periods.length,
              itemBuilder: (context, index) {
                // Reverse list to show newest periods first
                final period = state.periods[state.periods.length - 1 - index];
                
                final double totalExpenses = period.expenses.fold<double>(0, (sum, e) => sum + e.totalAmount);
                final double totalPreStock = period.preStockItems.fold<double>(0, (sum, i) => sum + i.totalCost);
                final double totalBudget = totalExpenses + totalPreStock;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryPeriodDetailScreen(period: period),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    period.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    _showDeletePeriodConfirm(context, ref, period);
                                  },
                                )
                              ],
                            ),
                            Text(
                              '${dateFormat.format(period.startDate)} - ${dateFormat.format(period.endDate)}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('ຍອດລວມງວດ:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(
                                      currencyFormat.format(totalBudget),
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDeletePeriodConfirm(BuildContext context, WidgetRef ref, Period period) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'ລຶບປະຫວັດງວດ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'ເຈົ້າຕ້ອງການລຶບປະຫວັດ "${period.name}" ແບບຖາວອນບໍ່?',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await ref.read(financeProvider.notifier).deletePeriod(period.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ລຶບ "${period.name}" ແລ້ວ!')),
                );
              },
              child: const Text('ຕົກລົງ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
