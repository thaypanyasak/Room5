import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'member_detail_screen.dart';

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

      // Debits: Participants split cost based on weights
      if (e.participantIds.isNotEmpty) {
        final weights = e.participantWeights ?? {};
        final totalWeight = e.participantIds.fold<double>(
            0.0, (sum, id) => sum + (weights[id] ?? 1.0));
        final totalWeightVal = totalWeight > 0 ? totalWeight : 1.0;

        for (var pId in e.participantIds) {
          final weight = weights[pId] ?? 1.0;
          final share = e.totalAmount * (weight / totalWeightVal);
          if (balances.containsKey(pId)) {
            balances[pId] = balances[pId]! - share;
          }
        }
      }
    }

    // 2. Process consumption of pre-stocked items from expenses (debit participants, credit buyer)
    for (var expense in period.expenses) {
      if (expense.category == ExpenseCategory.kratom && expense.participantIds.isNotEmpty) {
        final weights = expense.participantWeights ?? {};
        final totalWeight = expense.participantIds.fold<double>(0.0, (sum, partId) {
          return sum + (weights[partId] ?? 1.0);
        });
        final totalWeightVal = totalWeight > 0 ? totalWeight : 1.0;

        // Kratom Leaf consumption portion
        if (expense.kratomStockId != null) {
          final preItem = period.preStockItems.firstWhere(
            (i) => i.id == expense.kratomStockId,
            orElse: () => PreStockItem(id: '', itemName: '', totalCost: 0.0, buyerId: '', date: DateTime.now(), notes: '', portions: 1),
          );
          if (preItem.id.isNotEmpty && preItem.totalCost > 0) {
            final portionCost = preItem.totalCost / (preItem.portions > 0 ? preItem.portions : 1);
            final consumedCost = portionCost * (expense.kratomPortions ?? 1);
            
            for (var partId in expense.participantIds) {
              if (balances.containsKey(partId)) {
                final weight = weights[partId] ?? 1.0;
                final participantShare = consumedCost * (weight / totalWeightVal);
                balances[partId] = balances[partId]! - participantShare;
              }
            }

            final buyerId = preItem.buyerId;
            if (balances.containsKey(buyerId)) {
              balances[buyerId] = balances[buyerId]! + consumedCost;
            }
          }
        }

        // Syrup portion
        if (expense.syrupStockId != null) {
          final preItem = period.preStockItems.firstWhere(
            (i) => i.id == expense.syrupStockId,
            orElse: () => PreStockItem(id: '', itemName: '', totalCost: 0.0, buyerId: '', date: DateTime.now(), notes: '', portions: 1),
          );
          if (preItem.id.isNotEmpty && preItem.totalCost > 0) {
            final portionCost = preItem.totalCost / (preItem.portions > 0 ? preItem.portions : 1);
            final consumedCost = portionCost * (expense.syrupPortions ?? 1);
            
            for (var partId in expense.participantIds) {
              if (balances.containsKey(partId)) {
                final weight = weights[partId] ?? 1.0;
                final participantShare = consumedCost * (weight / totalWeightVal);
                balances[partId] = balances[partId]! - participantShare;
              }
            }

            final buyerId = preItem.buyerId;
            if (balances.containsKey(buyerId)) {
              balances[buyerId] = balances[buyerId]! + consumedCost;
            }
          }
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
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MemberDetailScreen(
                              member: m,
                              historicalExpenses: period.expenses,
                              historicalPreStockItems: period.preStockItems,
                              historicalBalance: balance,
                              periodName: period.name,
                              isReadOnly: true,
                            ),
                          ),
                        );
                      },
                      child: Padding(
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
                Builder(
                  builder: (context) {
                    final sortedExpenses = List<Expense>.from(period.expenses)
                      ..sort((a, b) => b.date.compareTo(a.date));

                    final Map<String, List<Expense>> groupedExpenses = {};
                    for (var expense in sortedExpenses) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(expense.date);
                      groupedExpenses.putIfAbsent(dateStr, () => []).add(expense);
                    }

                    final sortedDates = groupedExpenses.keys.toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedDates.map((dateStr) {
                        final dayExpenses = groupedExpenses[dateStr]!;
                        final parsedDate = DateTime.parse(dateStr);
                        final formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                        final kratomCount = dayExpenses.where((e) => e.category == ExpenseCategory.kratom).length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4, right: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (kratomCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withOpacity(0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'ໃຊ້ໄປ $kratomCount ຊຸດ',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ...dayExpenses.map((e) {
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

                              return GestureDetector(
                                onTap: () => _showHistoricalExpenseDetail(context, e, state.members),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.03)),
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
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    );
                  }
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

  void _showHistoricalExpenseDetail(BuildContext context, Expense expense, List<Member> members) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    PreStockItem? kratomStock;
    if (expense.kratomStockId != null) {
      try {
        kratomStock = period.preStockItems.firstWhere((i) => i.id == expense.kratomStockId);
      } catch (_) {}
    }

    PreStockItem? syrupStock;
    if (expense.syrupStockId != null) {
      try {
        syrupStock = period.preStockItems.firstWhere((i) => i.id == expense.syrupStockId);
      } catch (_) {}
    }

    final double kratomPortionCost = kratomStock != null
        ? (kratomStock.totalCost / (kratomStock.portions > 0 ? kratomStock.portions : 1))
        : 0.0;
    final double syrupPortionCost = syrupStock != null
        ? (syrupStock.totalCost / (syrupStock.portions > 0 ? syrupStock.portions : 1))
        : 0.0;

    final double currentKratomTotalCost = kratomPortionCost * (expense.kratomPortions ?? 1);
    final double currentSyrupTotalCost = syrupPortionCost * (expense.syrupPortions ?? 1);
    final double currentIceCost = expense.category == ExpenseCategory.kratom ? expense.totalAmount : 0.0;
    final double currentTotalSessionCost = currentKratomTotalCost + currentSyrupTotalCost + currentIceCost;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      expense.category == ExpenseCategory.kratom
                          ? Icons.local_cafe_rounded
                          : expense.category == ExpenseCategory.utilities
                              ? Icons.electric_bolt_rounded
                              : expense.category == ExpenseCategory.food
                                  ? Icons.restaurant_rounded
                                  : Icons.miscellaneous_services_rounded,
                      color: expense.category == ExpenseCategory.kratom
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEC4899),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expense.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ວັນທີ: ${dateFormat.format(expense.date)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Divider(color: Colors.white10, height: 32),
                const Text(
                  'ລາຍລະອຽດຄ່າໃຊ້ຈ່າຍ',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                if (expense.category == ExpenseCategory.kratom) ...[
                  _buildDetailRow(
                    label: 'ຄ່ານ້ຳກ້ອນ / ຄ່າບໍລິການ',
                    value: currencyFormat.format(currentIceCost),
                  ),
                  if (kratomStock != null)
                    _buildDetailRow(
                      label: 'ຄ່າໃບ Kratom (${expense.kratomPortions ?? 1} ຖ້ວຍ)',
                      value: currencyFormat.format(currentKratomTotalCost),
                      subText: '${kratomStock.itemName} • ${currencyFormat.format(kratomPortionCost)}/ຖ້ວຍ',
                    ),
                  if (syrupStock != null)
                    _buildDetailRow(
                      label: 'ຄ່ານ້ຳຢາສານ (${expense.syrupPortions ?? 1} ຝາ)',
                      value: currencyFormat.format(currentSyrupTotalCost),
                      subText: '${syrupStock.itemName} • ${currencyFormat.format(syrupPortionCost)}/ຝາ',
                    ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow(
                    label: 'ຍອດລວມທັງໝົດ',
                    value: currencyFormat.format(currentTotalSessionCost),
                    isBold: true,
                    valueColor: const Color(0xFF10B981),
                  ),
                ] else ...[
                  _buildDetailRow(
                    label: 'ຍອດລວມທັງໝົດ',
                    value: currencyFormat.format(expense.totalAmount),
                    isBold: true,
                    valueColor: const Color(0xFF10B981),
                  ),
                ],
                const Divider(color: Colors.white10, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ສະມາຊິກຮ່ວມ ແລະ ອັດຕາສ່ວນ',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${expense.participantIds.length} ຄົນ',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...expense.participantIds.map((pId) {
                  final member = members.firstWhere(
                    (m) => m.id == pId,
                    orElse: () => Member(id: pId, name: pId, avatarUrl: ''),
                  );
                  final weight = expense.participantWeights?[pId] ?? 1.0;
                  
                  final weights = expense.participantWeights ?? {};
                  final totalWeight = expense.participantIds.fold<double>(
                      0.0, (sum, id) => sum + (weights[id] ?? 1.0));
                  final totalWeightVal = totalWeight > 0 ? totalWeight : 1.0;
                  final totalCost = expense.category == ExpenseCategory.kratom ? currentTotalSessionCost : expense.totalAmount;
                  final share = totalCost * (weight / totalWeightVal);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: member.avatarUrl.isNotEmpty ? NetworkImage(member.avatarUrl) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          'ສ່ວນ: $weight',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          currencyFormat.format(share),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? subText,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: isBold ? 14 : 13,
                  ),
                ),
                if (subText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subText,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isBold ? Colors.white : Colors.white70),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
