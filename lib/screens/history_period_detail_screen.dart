import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';

class HistoryPeriodDetailScreen extends ConsumerWidget {
  final Period period;

  const HistoryPeriodDetailScreen({super.key, required this.period});

  Map<String, double> _calculateHistoricalBalances(List<Member> members) {
    final Map<String, double> balances = {};
    for (var m in members) {
      balances[m.id] = 0.0;
    }

    // 1. Process standard expenses
    for (var e in period.expenses) {
      // Credits: Payer gets credit
      e.payers.forEach((payerId, amountPaid) {
        if (balances.containsKey(payerId)) {
          balances[payerId] = balances[payerId]! + amountPaid;
        }
      });

      // Debits: Participants split cost equally
      if (e.participantIds.isNotEmpty) {
        final share = e.totalAmount / e.participantIds.length;
        for (var pId in e.participantIds) {
          if (balances.containsKey(pId)) {
            balances[pId] = balances[pId]! - share;
          }
        }
      }
    }

    // 2. Process pre-stock items (split equally among all members)
    for (var item in period.preStockItems) {
      if (balances.containsKey(item.buyerId)) {
        balances[item.buyerId] = balances[item.buyerId]! + item.totalCost;
      }
      if (members.isNotEmpty) {
        final share = item.totalCost / members.length;
        for (var m in members) {
          balances[m.id] = balances[m.id]! - share;
        }
      }
    }

    return balances;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final double totalExpenses = period.expenses.fold<double>(0, (sum, e) => sum + e.totalAmount);
    final double totalPreStock = period.preStockItems.fold<double>(0, (sum, i) => sum + i.totalCost);
    final double totalBudget = totalExpenses + totalPreStock;

    final historicalBalances = _calculateHistoricalBalances(state.members);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(period.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Meta & Total Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF064E3B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ລາຍຈ່າຍທັງໝົດໃນງວດ',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ງວດທີ່ປິດແລ້ວ',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(totalBudget),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(period.startDate)} - ${dateFormat.format(period.endDate)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _quickStatTile(
                            title: 'ສາງ ທ້ອມ',
                            value: currencyFormat.format(period.preStockItems
                                .where((i) => i.type == 'kratom')
                                .fold<double>(0, (sum, i) => sum + i.totalCost)),
                            icon: Icons.local_cafe_rounded,
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.white10),
                        Expanded(
                          child: _quickStatTile(
                            title: 'ສາງນ້ຳຢາ',
                            value: currencyFormat.format(period.preStockItems
                                .where((i) => i.type == 'syrup')
                                .fold<double>(0, (sum, i) => sum + i.totalCost)),
                            icon: Icons.water_drop_rounded,
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.white10),
                        Expanded(
                          child: _quickStatTile(
                            title: 'ຄ່າຫ້ອງ/ໄຟ/ນ້ຳ',
                            value: currencyFormat.format(period.expenses
                                .where((e) => e.category == ExpenseCategory.utilities)
                                .fold<double>(0, (sum, e) => sum + e.totalAmount)),
                            icon: Icons.home_outlined,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settled Transfers
              const Text(
                '💵 ປະຫວັດການໂອນເງິນທີ່ເຄຼຍແລ້ວ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              if (period.transfers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('ບໍ່ມີການໂອນເງິນເກີດຂຶ້ນໃນງວດນີ້', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                )
              else
                Column(
                  children: period.transfers.map((t) {
                    final fromMember = state.members.firstWhere((m) => m.id == t.fromId, orElse: () => Member(id: t.fromId, name: t.fromName, avatarUrl: ''));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: fromMember.avatarUrl.isNotEmpty ? NetworkImage(fromMember.avatarUrl) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: t.fromName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                  const TextSpan(
                                    text: ' ໂອນໃຫ້ ',
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  TextSpan(
                                    text: t.toName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            currencyFormat.format(t.amount),
                            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Historical Balances
              const Text(
                '👥 ຍອດເງິນສະມາຊິກໃນງວດ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: state.members.map((m) {
                    final balance = historicalBalances[m.id] ?? 0.0;
                    final isCreditor = balance >= 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isCreditor ? 'ໄດ້ຮັບຄືນ' : 'ຕ້ອງຈ່າຍ',
                                style: TextStyle(color: isCreditor ? const Color(0xFF10B981) : Colors.redAccent, fontSize: 10),
                              ),
                              Text(
                                currencyFormat.format(balance.abs()),
                                style: TextStyle(
                                  color: isCreditor ? const Color(0xFF10B981) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Activities / History Expenses list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🛍️ ລາຍການເຄື່ອນໄຫວ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${period.expenses.length} ລາຍການ',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (period.expenses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('ບໍ່ມີລາຍການໃຊ້ຈ່າຍ', style: TextStyle(color: Colors.white38)),
                  ),
                )
              else
                Column(
                  children: period.expenses.map((e) {
                    IconData catIcon = Icons.miscellaneous_services_rounded;
                    Color catColor = const Color(0xFF8B5CF6);

                    switch (e.category) {
                      case ExpenseCategory.kratom:
                        catIcon = Icons.local_cafe_rounded;
                        catColor = const Color(0xFF10B981);
                        break;
                      case ExpenseCategory.utilities:
                        catIcon = Icons.electric_bolt_rounded;
                        catColor = const Color(0xFFEC4899);
                        break;
                      case ExpenseCategory.food:
                        catIcon = Icons.restaurant_rounded;
                        catColor = const Color(0xFFF59E0B);
                        break;
                      case ExpenseCategory.other:
                        catIcon = Icons.miscellaneous_services_rounded;
                        catColor = const Color(0xFF8B5CF6);
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(catIcon, color: catColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${e.participantIds.length} ຄົນຮ່ວມ • ${dateFormat.format(e.date)}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormat.format(e.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickStatTile({required String title, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
