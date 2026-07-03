import 'dart:io';
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
      final usedCount = state.expenses.fold<int>(0, (sum, e) {
        if (item.type == 'kratom' && e.kratomStockId == item.id) {
          return sum + (e.kratomPortions ?? 1);
        }
        if (item.type == 'syrup' && e.syrupStockId == item.id) {
          return sum + (e.syrupPortions ?? 1);
        }
        return sum;
      });
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

        final kratomShare = (portionPriceKratom * (e.kratomPortions ?? 1)) / e.participantIds.length;
        final syrupShare = (portionPriceSyrup * (e.syrupPortions ?? 1)) / e.participantIds.length;
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
      length: 4,
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

            // TabBar — per-tab coloured
            const _ColoredTabBar(),

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
                  _buildQRTabContent(context, freshMember, ref),
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

  Widget _buildQRTabContent(BuildContext context, Member member, WidgetRef ref) {
    final qrPath = member.qrPath;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          if (qrPath == null || qrPath.isEmpty) ...[
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFF10B981),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ບໍ່ມີ QR Code ເທື່ອ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ອັບໂຫຼດ QR Code ສ່ວນຕົວເພື່ອໃຊ້ຮັບເງິນ',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  maxHeight: 1024,
                  imageQuality: 85,
                );
                if (image != null) {
                  await ref.read(financeProvider.notifier).updateMemberQR(member.id, image.path);
                }
              },
              icon: const Icon(Icons.photo_library_rounded, size: 20),
              label: const Text(
                'ເລືອກຮູບພາບ QR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(qrPath),
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 220,
                      height: 220,
                      color: const Color(0xFF334155),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white38,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await ref.read(financeProvider.notifier).updateMemberQR(member.id, image.path);
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('ປ່ຽນຮູບໃໝ່'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: BorderSide(color: const Color(0xFFF87171).withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('ຢືນຢັນການລຶບ', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'ທ່ານຕ້ອງການລຶບ QR Code ນີ້ແທ້ຫຼືບໍ່?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white38)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ລຶບເລີຍ', style: TextStyle(color: Color(0xFFF87171))),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(financeProvider.notifier).updateMemberQR(member.id, null);
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('ລຶບຮູບ'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Self-contained per-tab coloured TabBar
// ---------------------------------------------------------------------------

/// Colour spec for a single tab.
class _TabSpec {
  final String label;
  /// Active indicator background (semi-transparent tint)
  final Color activeBg;
  /// Active label / indicator border colour
  final Color activeLabel;
  /// Inactive label colour
  final Color inactiveLabel;
  const _TabSpec({
    required this.label,
    required this.activeBg,
    required this.activeLabel,
    required this.inactiveLabel,
  });
}

const _kTabSpecs = [
  // ທັງໝົດ — vivid emerald, same treatment as others
  _TabSpec(
    label: 'ທັງໝົດ',
    activeBg:      Color(0x40064E3B),   // emerald-900 @25%
    activeLabel:   Color(0xFF10B981),   // emerald-500 — vivid
    inactiveLabel: Color(0xFF10B981),   // same as active
  ),
  // ອອກກ່ອນ — vivid emerald-300 label; dark bg tint so text pops
  _TabSpec(
    label: 'ອອກກ່ອນ',
    activeBg:      Color(0x40064E3B),   // emerald-900 @25%
    activeLabel:   Color(0xFF34D399),   // emerald-300 — bright
    inactiveLabel: Color(0xFF34D399),   // same as active
  ),
  // ຫານເງິນ — vivid rose label; dark bg tint so text pops
  _TabSpec(
    label: 'ຫານເງິນ',
    activeBg:      Color(0x404C0519),   // rose-950 @25%
    activeLabel:   Color(0xFFFB7185),   // rose-400 — bright
    inactiveLabel: Color(0xFFFB7185),   // same as active
  ),
  // QR — vivid emerald, same treatment as ທັງໝົດ
  _TabSpec(
    label: 'QR',
    activeBg:      Color(0x40064E3B),   // emerald-900 @25%
    activeLabel:   Color(0xFF10B981),   // emerald-500 — vivid
    inactiveLabel: Color(0xFF10B981),   // same as active
  ),
];

class _ColoredTabBar extends StatefulWidget {
  const _ColoredTabBar();
  @override
  State<_ColoredTabBar> createState() => _ColoredTabBarState();
}

class _ColoredTabBarState extends State<_ColoredTabBar> {
  int _active = 0;
  TabController? _ctrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = DefaultTabController.of(context);
    if (ctrl != _ctrl) {
      _ctrl?.removeListener(_onTabChange);
      _ctrl = ctrl;
      _ctrl!.addListener(_onTabChange);
      _active = _ctrl!.index;
    }
  }

  void _onTabChange() {
    if (_ctrl != null && _ctrl!.index != _active) {
      setState(() => _active = _ctrl!.index);
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _kTabSpecs[_active];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: spec.activeBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: spec.activeLabel.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: spec.activeLabel,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: List.generate(_kTabSpecs.length, (i) {
          final s = _kTabSpecs[i];
          final isActive = _active == i;
          return Tab(
            child: Text(
              s.label,
              style: TextStyle(
                color: isActive ? s.activeLabel : s.inactiveLabel,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }),
      ),
    );
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
