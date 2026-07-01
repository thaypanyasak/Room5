import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/finance_provider.dart';
import '../widgets/member_avatar.dart';

class MemberDetailScreen extends ConsumerWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final freshMember = state.members.firstWhere((m) => m.id == member.id, orElse: () => member);
    final notifier = ref.read(financeProvider.notifier);
    final balances = notifier.calculateBalances();
    final balance = balances[freshMember.id] ?? 0.0;
    final isOwed = balance >= 0;

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'K',
      decimalDigits: 0,
    );

    // 1. Stock bought by member
    final stockItemsBought =
        state.preStockItems.where((item) => item.buyerId == freshMember.id).toList();
    final double totalStockSpent = stockItemsBought.fold(
      0.0,
      (sum, item) => sum + item.totalCost,
    );

    // 2. Expenses paid by member (non-kratom, e.g. utility, food)
    final expensesPaid =
        state.expenses.where((e) => e.payers.containsKey(freshMember.id)).toList();

    // 3. Expenses participated in (debited)
    final expensesParticipated =
        state.expenses
            .where((e) => e.participantIds.contains(freshMember.id))
            .toList();

    // Combined activities sorted by date desc
    final List<_ActivityItem> activities = [];

    // Add stock purchases (credited only for portions actually consumed in the period)
    for (var item in stockItemsBought) {
      final usedCount = state.expenses.where((e) =>
          (item.type == 'kratom' && e.kratomStockId == item.id) ||
          (item.type == 'syrup' && e.syrupStockId == item.id)
      ).length;
      final portionCost = item.totalCost / (item.portions > 0 ? item.portions : 1);
      final consumedValue = usedCount * portionCost;
      
      if (consumedValue > 0) {
        activities.add(
          _ActivityItem(
            date: item.date,
            title: 'ຊື້ສາງ: ${item.itemName} (ສ່ວນທີ່ໃຊ້)',
            subtitle: 'ໃຊ້ແລ້ວ $usedCount/${item.portions} ຄັ້ງ • ຊື້ເຂົ້າສາງ',
            amount: consumedValue,
            isPositive: true,
            icon: item.type == 'kratom' ? Icons.local_cafe : Icons.water_drop,
            iconColor:
                item.type == 'kratom'
                    ? const Color(0xFFD97706)
                    : const Color(0xFF8B5CF6),
          ),
        );
      }
    }

    // Add expenses where they paid (shows as positive / credit)
    for (var e in expensesPaid) {
      final amountPaid = e.payers[freshMember.id] ?? 0.0;
      final isIceMixer = e.category == ExpenseCategory.kratom;
      activities.add(
        _ActivityItem(
          date: e.date,
          title: isIceMixer ? 'ຈ່າຍ ຄ່ານ້ຳກ້ອນ - ນ້ຳປຸງ' : 'ຈ່າຍ: ${e.title}',
          subtitle:
              isIceMixer
                  ? e.title
                  : 'ຈ່າຍຄ່າໃຊ້ຈ່າຍກຸ່ມ • ${e.category == ExpenseCategory.utilities ? "ຄ່າໄຟ-ຄ່ານ້ຳ" : "ທົ່ວໄປ"}',
          amount: amountPaid,
          isPositive: true,
          icon:
              isIceMixer
                  ? Icons.ac_unit_rounded
                  : _getCategoryIconData(e.category),
          iconColor:
              isIceMixer
                  ? const Color(0xFF38BDF8)
                  : _getCategoryColor(e.category),
        ),
      );
    }

    // Add expenses they participated in (shows as debit / negative share)
    for (var e in expensesParticipated) {
      if (e.category == ExpenseCategory.kratom) {
        // Kratom session: they consumed portions of Kratom/Syrup
        final portionPriceKratom =
            e.kratomStockId != null
                ? _getPortionCost(state.preStockItems, e.kratomStockId!)
                : 0.0;
        final portionPriceSyrup =
            e.syrupStockId != null
                ? _getPortionCost(state.preStockItems, e.syrupStockId!)
                : 0.0;

        final kratomShare = portionPriceKratom / e.participantIds.length;
        final syrupShare = portionPriceSyrup / e.participantIds.length;
        final iceShare = e.totalAmount / e.participantIds.length;
        final totalSessionShare = kratomShare + syrupShare + iceShare;

        if (totalSessionShare > 0) {
          activities.add(
            _ActivityItem(
              date: e.date,
              title: 'ກິນທ້ອມ: ${e.title}',
              subtitle: e.totalAmount > 0 ? 'ຫານຄ່າທ້ອມ' : 'ຫານຄ່າທ້ອມ',
              amount: totalSessionShare,
              isPositive: false,
              icon: Icons.sports_bar_rounded,
              iconColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        // Regular expense share (utility, food, etc.)
        final share = e.totalAmount / e.participantIds.length;
        activities.add(
          _ActivityItem(
            date: e.date,
            title: 'ຫານ: ${e.title}',
            subtitle: 'ຫານຄ່າໃຊ້ຈ່າຍ',
            amount: share,
            isPositive: false,
            icon: Icons.receipt_long,
            iconColor: Colors.white38,
          ),
        );
      }
    }

    // Sort by date desc
    activities.sort((a, b) => b.date.compareTo(a.date));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(
            freshMember.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header profile card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 512,
                          maxHeight: 512,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          await ref.read(financeProvider.notifier).updateMemberAvatar(freshMember.id, image.path);
                        }
                      },
                      child: Stack(
                        children: [
                          MemberAvatar(member: freshMember, radius: 40),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      freshMember.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                isOwed ? 'ໄດ້ຮັບຄືນ' : 'ຕ້ອງຈ່າຍ',
                                style: TextStyle(
                                  color:
                                      isOwed
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currencyFormat.format(balance.abs()),
                                style: TextStyle(
                                  color:
                                      isOwed
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF87171),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'ຊື້ສາງສະສົມ',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currencyFormat.format(totalStockSpent),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'ທັງໝົດ'),
                  Tab(text: 'ອອກກ່ອນ'),
                  Tab(text: 'ຫານຄ່າໃຊ້ຈ່າຍ'),
                ],
              ),
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  _buildActivityList(activities, currencyFormat),
                  _buildActivityList(
                    activities.where((a) => a.isPositive).toList(),
                    currencyFormat,
                  ),
                  _buildActivityList(
                    activities.where((a) => !a.isPositive).toList(),
                    currencyFormat,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(
    List<_ActivityItem> filteredActivities,
    NumberFormat currencyFormat,
  ) {
    if (filteredActivities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Text(
            'ຍັງບໍ່ມີການເຄື່ອນໄຫວເທື່ອ',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    final Map<String, List<_ActivityItem>> grouped = {};
    for (var act in filteredActivities) {
      final dateStr = DateFormat('yyyy-MM-dd').format(act.date);
      grouped.putIfAbsent(dateStr, () => []).add(act);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final dayActivities = grouped[dateStr]!;
        final parsedDate = DateTime.parse(dateStr);
        final formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
              child: Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            ...dayActivities.map((act) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: act.iconColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(act.icon, color: act.iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            act.subtitle,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      (act.isPositive ? '+' : '-') +
                          currencyFormat.format(act.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            act.isPositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }

  double _getPortionCost(List<PreStockItem> stockItems, String stockId) {
    final preItem = stockItems.firstWhere(
      (i) => i.id == stockId,
      orElse:
          () => PreStockItem(
            id: '',
            itemName: '',
            totalCost: 0.0,
            buyerId: '',
            date: DateTime.now(),
            notes: '',
            portions: 1,
          ),
    );
    if (preItem.id.isEmpty) return 0.0;
    return preItem.totalCost / (preItem.portions > 0 ? preItem.portions : 1);
  }

  IconData _getCategoryIconData(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.kratom:
        return Icons.local_cafe;
      case ExpenseCategory.utilities:
        return Icons.electric_bolt;
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.other:
        return Icons.miscellaneous_services;
    }
  }

  Color _getCategoryColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.kratom:
        return const Color(0xFF10B981);
      case ExpenseCategory.utilities:
        return const Color(0xFFEC4899);
      case ExpenseCategory.food:
        return const Color(0xFFF59E0B);
      case ExpenseCategory.other:
        return const Color(0xFF8B5CF6);
    }
  }
}

class _ActivityItem {
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;

  _ActivityItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.icon,
    required this.iconColor,
  });
}
