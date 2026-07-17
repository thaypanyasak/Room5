import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import 'add_expense_screen.dart';
import 'settle_up_screen.dart';
import 'history_periods_screen.dart';
import 'member_detail_screen.dart';
import '../widgets/member_avatar.dart';
import '../utils/currency_formatter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final notifier = ref.read(financeProvider.notifier);
    final balances = notifier.calculateBalances();
    
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'ROOM 5 SHARE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPeriodsScreen()),
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Overview Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'ລາຍຈ່າຍທັງໝົດຂອງກຸ່ມ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF10B981),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'ຍອດລວມທັງໝົດ / Total balance',
                              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormat.format(state.expenses.fold<double>(0, (sum, e) => sum + e.totalAmount) +
                                  state.preStockItems.fold<double>(0, (sum, i) => sum + i.totalCost)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              context,
                              label: 'ໄລ່ເງິນ & ສະຫຼຸບງວດນີ້',
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFF10B981),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettleUpScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ຍອດເງິນສະມາຊິກ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF10B981)),
                            onPressed: () => _showAddMemberDialog(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Members Grid/List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.members.length,
                        itemBuilder: (context, index) {
                          final member = state.members[index];
                          final balance = balances[member.id] ?? 0.0;
                          final isOwed = balance >= 0;

                          return Dismissible(
                            key: Key(member.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              final bool hasExpenses = state.expenses.any((e) =>
                                  e.payers.containsKey(member.id) || e.participantIds.contains(member.id));
                              final bool hasPreStock = state.preStockItems.any((i) => i.buyerId == member.id);
                              final bool isDeletable = !hasExpenses && !hasPreStock;

                              if (!isDeletable) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ບໍ່ສາມາດລົບສະມາຊິກໄດ້ ເພາະວ່າມີທຸລະກຳ ຫຼື ປະຫວັດການໃຊ້ຈ່າຍແລ້ວ!'),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                                return false;
                              }
                              return true;
                            },
                            onDismissed: (_) {
                              ref.read(financeProvider.notifier).deleteMember(member.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ລົບສະມາຊິກ "${member.name}" ສຳເລັດ!'),
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MemberDetailScreen(member: member),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    MemberAvatar(
                                      member: member,
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        member.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isOwed ? 'ໄດ້ຮັບຄືນ' : 'ຕ້ອງຈ່າຍ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOwed ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormat.format(balance.abs()),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isOwed ? const Color(0xFF10B981) : const Color(0xFFF87171),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Recent Activities Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ການເຄື່ອນໄຫວຫຼ້າສຸດ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (state.expenses.isNotEmpty)
                            const Text(
                              'ປັດເພື່ອລຶບ',
                              style: TextStyle(fontSize: 12, color: Colors.white38),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Activities List
                      if (state.expenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
                                const SizedBox(height: 12),
                                const Text(
                                  'ຍັງບໍ່ມີລາຍການຈ່າຍເທື່ອ',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final sortedExpenses = List<Expense>.from(state.expenses)
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
                                    ...dayExpenses.map((expense) {
                                      return Dismissible(
                                        key: Key(expense.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(Icons.delete, color: Colors.white),
                                        ),
                                        onDismissed: (_) {
                                          ref.read(financeProvider.notifier).deleteExpense(expense.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('ລຶບແລ້ວ: ${expense.title}')),
                                          );
                                        },
                                        child: GestureDetector(
                                          onTap: () => _showExpenseDetail(context, expense, state),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B).withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white.withOpacity(0.03)),
                                            ),
                                            child: Row(
                                              children: [
                                                _categoryIcon(expense.category),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        expense.title,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${expense.participantIds.length} ຄົນຫານ',
                                                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      currencyFormat.format(expense.totalAmount),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'ຄົນຈ່າຍ: ${expense.payers.keys.map((k) => state.members.firstWhere((m) => m.id == k, orElse: () => Member(id: k, name: k, avatarUrl: '')).name).join(", ")}',
                                                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 6),
                                  ],
                                );
                              }).toList(),
                            );
                          }
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'ເພີ່ມລາຍຈ່າຍ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }



  Widget _actionButton(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryIcon(ExpenseCategory category) {
    IconData iconData;
    Color color;

    switch (category) {
      case ExpenseCategory.kratom:
        iconData = Icons.local_cafe_rounded;
        color = const Color(0xFF10B981);
        break;
      case ExpenseCategory.utilities:
        iconData = Icons.electric_bolt_rounded;
        color = const Color(0xFFEC4899);
        break;
      case ExpenseCategory.food:
        iconData = Icons.restaurant_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case ExpenseCategory.other:
        iconData = Icons.miscellaneous_services_rounded;
        color = const Color(0xFF8B5CF6);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('ເພີ່ມສະມາຊິກໃໝ່', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'ປ້ອນຊື່ສະມາຊິກ',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF10B981))),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white30)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(financeProvider.notifier).addMember(name);
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(content: Text('ເພີ່ມສະມາຊິກ "$name" ສຳເລັດ!')),
                  );
                }
              },
              child: const Text('ເພີ່ມ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseDetail(BuildContext context, Expense expense, FinanceState state) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);

    PreStockItem? kratomStock;
    if (expense.kratomStockId != null) {
      try {
        kratomStock = state.preStockItems.firstWhere((i) => i.id == expense.kratomStockId);
      } catch (_) {}
    }

    PreStockItem? syrupStock;
    if (expense.syrupStockId != null) {
      try {
        syrupStock = state.preStockItems.firstWhere((i) => i.id == expense.syrupStockId);
      } catch (_) {}
    }

    final double kratomPortionCost = kratomStock != null
        ? (kratomStock.totalCost / (kratomStock.portions > 0 ? kratomStock.portions : 1))
        : 0.0;
    final double syrupPortionCost = syrupStock != null
        ? (syrupStock.totalCost / (syrupStock.portions > 0 ? syrupStock.portions : 1))
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentExpense = ref.watch(financeProvider).expenses.firstWhere((e) => e.id == expense.id, orElse: () => expense);
            final double currentKratomTotalCost = kratomPortionCost * (currentExpense.kratomPortions ?? 1);
            final double currentSyrupTotalCost = syrupPortionCost * (currentExpense.syrupPortions ?? 1);
            final double currentIceCost = currentExpense.category == ExpenseCategory.kratom ? currentExpense.totalAmount : 0.0;
            final double currentTotalSessionCost = currentKratomTotalCost + currentSyrupTotalCost + currentIceCost;
            final double currentSharePerPerson = currentExpense.participantIds.isNotEmpty
                ? (currentExpense.category == ExpenseCategory.kratom
                    ? (currentTotalSessionCost / currentExpense.participantIds.length)
                    : (currentExpense.totalAmount / currentExpense.participantIds.length))
                : 0.0;

            return _ExpenseDetailModalContent(
              expense: currentExpense,
              state: state,
              ref: ref,
              currencyFormat: currencyFormat,
              kratomStock: kratomStock,
              syrupStock: syrupStock,
              kratomPortionCost: kratomPortionCost,
              syrupPortionCost: syrupPortionCost,
              iceCost: currentIceCost,
              totalSessionCost: currentTotalSessionCost,
              sharePerPerson: currentSharePerPerson,
            );
          },
        );
      },
    );
  }
}

class _ExpenseDetailModalContent extends StatefulWidget {
  final Expense expense;
  final FinanceState state;
  final WidgetRef ref;
  final NumberFormat currencyFormat;
  final PreStockItem? kratomStock;
  final PreStockItem? syrupStock;
  final double kratomPortionCost;
  final double syrupPortionCost;
  final double iceCost;
  final double totalSessionCost;
  final double sharePerPerson;

  const _ExpenseDetailModalContent({
    required this.expense,
    required this.state,
    required this.ref,
    required this.currencyFormat,
    this.kratomStock,
    this.syrupStock,
    required this.kratomPortionCost,
    required this.syrupPortionCost,
    required this.iceCost,
    required this.totalSessionCost,
    required this.sharePerPerson,
  });

  @override
  State<_ExpenseDetailModalContent> createState() => _ExpenseDetailModalContentState();
}

class _ExpenseDetailModalContentState extends State<_ExpenseDetailModalContent> {
  bool _isEditing = false;
  late List<String> _editedParticipants;
  late Map<String, double> _editedParticipantWeights;
  late String? _editedPayerId;
  late TextEditingController _titleController;
  late TextEditingController _iceController;

  @override
  void initState() {
    super.initState();
    _editedParticipants = List.from(widget.expense.participantIds);
    _editedParticipantWeights = widget.expense.participantWeights != null
        ? Map<String, double>.from(widget.expense.participantWeights!)
        : {for (var id in _editedParticipants) id: 1.0};
    _editedPayerId = widget.expense.payers.isNotEmpty ? widget.expense.payers.keys.first : null;
    _titleController = TextEditingController(text: widget.expense.title);
    
    final displayFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    final initialCost = widget.expense.category == ExpenseCategory.kratom
        ? (widget.expense.iceAmount ?? widget.expense.totalAmount)
        : widget.expense.totalAmount;
    _iceController = TextEditingController(text: displayFormat.format(initialCost).trim());
  }

  @override
  void didUpdateWidget(covariant _ExpenseDetailModalContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expense != oldWidget.expense) {
      _editedParticipants = List.from(widget.expense.participantIds);
      _editedParticipantWeights = widget.expense.participantWeights != null
          ? Map<String, double>.from(widget.expense.participantWeights!)
          : {for (var id in _editedParticipants) id: 1.0};
      _editedPayerId = widget.expense.payers.isNotEmpty ? widget.expense.payers.keys.first : null;
      _titleController.text = widget.expense.title;
      
      final displayFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
      final cost = widget.expense.category == ExpenseCategory.kratom
          ? (widget.expense.iceAmount ?? widget.expense.totalAmount)
          : widget.expense.totalAmount;
      _iceController.text = displayFormat.format(cost).trim();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _iceController.dispose();
    super.dispose();
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
                  Text(
                    subText,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white70,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double inputIce = double.tryParse(_iceController.text.replaceAll('.', '')) ?? 0.0;
    final double previewTotalSession = widget.kratomPortionCost + widget.syrupPortionCost + inputIce;
    final double previewShare = _editedParticipants.isNotEmpty
        ? (widget.expense.category == ExpenseCategory.kratom
            ? (previewTotalSession / _editedParticipants.length)
            : (inputIce / _editedParticipants.length))
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isEditing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ແກ້ໄຂຂໍ້ມູນກິດຈະກຳ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _editedParticipants = List.from(widget.expense.participantIds);
                      _editedParticipantWeights = widget.expense.participantWeights != null
                          ? Map<String, double>.from(widget.expense.participantWeights!)
                          : {for (var id in _editedParticipants) id: 1.0};
                      _editedPayerId = widget.expense.payers.isNotEmpty ? widget.expense.payers.keys.first : null;
                      _titleController.text = widget.expense.title;
                      final displayFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
                      final initialCost = widget.expense.category == ExpenseCategory.kratom
                          ? (widget.expense.iceAmount ?? widget.expense.totalAmount)
                          : widget.expense.totalAmount;
                      _iceController.text = displayFormat.format(initialCost).trim();
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ຊື່ກິດຈະກຳ',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _iceController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.expense.category == ExpenseCategory.kratom ? 'ຄ່ານ້ຳກ້ອນ - ນ້ຳປຸງ (₭)' : 'ຈຳນວນເງິນ (₭)',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ໃຜເປັນຄົນຈ່າຍ?',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _editedPayerId,
                  dropdownColor: const Color(0xFF0F172A),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF10B981), size: 20),
                  items: widget.state.members.map((m) {
                    return DropdownMenuItem<String>(
                      value: m.id,
                      child: Row(
                        children: [
                          MemberAvatar(member: m, radius: 12),
                          const SizedBox(width: 8),
                          Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _editedPayerId = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ຜູ້ເຂົ້າຮ່ວມຫານ (${_editedParticipants.length} ຄົນ)',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.state.members.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final member = widget.state.members[index];
                    final isSelected = _editedParticipants.contains(member.id);
                    final weight = _editedParticipantWeights[member.id] ?? 1.0;

                    // Preview share amount for this participant
                    final totalWeight = _editedParticipants.fold<double>(
                        0.0, (sum, id) => sum + (_editedParticipantWeights[id] ?? 1.0));
                    final totalWeightVal = totalWeight > 0 ? totalWeight : 1.0;
                    
                    final double previewTotalCost = widget.expense.category == ExpenseCategory.kratom
                        ? (widget.kratomPortionCost * (widget.expense.kratomPortions ?? 1) +
                           widget.syrupPortionCost * (widget.expense.syrupPortions ?? 1) +
                           inputIce)
                        : inputIce;
                    final shareAmount = isSelected ? (previewTotalCost * (weight / totalWeightVal)) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _editedParticipants.remove(member.id);
                                  _editedParticipantWeights.remove(member.id);
                                } else {
                                  _editedParticipants.add(member.id);
                                  _editedParticipantWeights[member.id] = 1.0;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : Colors.white30,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          MemberAvatar(member: member, radius: 14),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white38,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isSelected && previewTotalCost > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.currencyFormat.format(shareAmount),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    icon: const Icon(Icons.remove, color: Colors.white70, size: 12),
                                    onPressed: () {
                                      if (weight > 0.5) {
                                        setState(() {
                                          _editedParticipantWeights[member.id] = weight - 0.5;
                                        });
                                      }
                                    },
                                  ),
                                  Text(
                                    '${weight.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    icon: const Icon(Icons.add, color: Colors.white70, size: 12),
                                    onPressed: () {
                                      if (weight < 5.0) {
                                        setState(() {
                                          _editedParticipantWeights[member.id] = weight + 0.5;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: widget.expense.category == ExpenseCategory.kratom ? 'ຄ່ານ້ຳກ້ອນ - ນ້ຳປຸງໃໝ່' : 'ຈຳນວນເງິນໃໝ່',
                    value: widget.currencyFormat.format(inputIce),
                  ),
                  if (widget.expense.category == ExpenseCategory.kratom)
                    _buildDetailRow(
                      label: 'ລາຄາລວມ 1 ຊຸດໃໝ່',
                      value: widget.currencyFormat.format(previewTotalSession),
                      isBold: true,
                      valueColor: const Color(0xFF10B981),
                    ),
                  const Divider(color: Colors.white12),
                  _buildDetailRow(
                    label: 'ສ່ວນຫານຕໍ່ຄົນ (ຄາດຄະເນ)',
                    value: widget.currencyFormat.format(previewShare),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _editedParticipants = List.from(widget.expense.participantIds);
                      _editedParticipantWeights = widget.expense.participantWeights != null
                          ? Map<String, double>.from(widget.expense.participantWeights!)
                          : {for (var id in _editedParticipants) id: 1.0};
                      _editedPayerId = widget.expense.payers.isNotEmpty ? widget.expense.payers.keys.first : null;
                      _titleController.text = widget.expense.title;
                      final displayFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
                      final initialCost = widget.expense.category == ExpenseCategory.kratom
                          ? (widget.expense.iceAmount ?? widget.expense.totalAmount)
                          : widget.expense.totalAmount;
                      _iceController.text = displayFormat.format(initialCost).trim();
                    });
                  },
                  child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_editedParticipants.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ກະລຸນາເລືອກຢ່າງໜ້ອຍ 1 ຄົນເພື່ອຫານເງິນ!')),
                      );
                      return;
                    }
                    if (_editedPayerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ກະລຸນາເລືອກຄົນຈ່າຍ!')),
                      );
                      return;
                    }

                    final newAmount = double.tryParse(_iceController.text.replaceAll('.', '')) ?? 0.0;

                    final Map<String, double> updatedPayers = {
                      _editedPayerId!: newAmount,
                    };

                    final updatedExpense = widget.expense.copyWith(
                      title: _titleController.text.trim(),
                      totalAmount: newAmount,
                      iceAmount: widget.expense.category == ExpenseCategory.kratom ? newAmount : null,
                      payers: updatedPayers,
                      participantIds: _editedParticipants,
                      participantWeights: _editedParticipantWeights,
                    );

                    final messenger = ScaffoldMessenger.of(context);
                    await widget.ref.read(financeProvider.notifier).updateExpense(updatedExpense);
                    
                    setState(() {
                      _isEditing = false;
                    });
                    
                    messenger.showSnackBar(
                      const SnackBar(content: Text('ອັບເດດຂໍ້ມູນສຳເລັດ!')),
                    );
                  },
                  child: const Text('ບັນທຶກ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.expense.title.isEmpty ? 'ລາຍລະອຽດກິດຈະກຳ' : widget.expense.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ວັນທີ: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.expense.date)}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF10B981)),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExpenseScreen(expenseToEdit: widget.expense),
                      ),
                    );
                  },
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'ລາຍລະອຽດຄ່າໃຊ້ຈ່າຍ',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  if (widget.expense.category == ExpenseCategory.kratom) ...[
                    if (widget.kratomStock != null)
                      _buildDetailRow(
                        label: 'ໃບ Kratom (x${widget.expense.kratomPortions ?? 1}) (${widget.kratomStock!.itemName})',
                        value: widget.currencyFormat.format(widget.kratomPortionCost * (widget.expense.kratomPortions ?? 1)),
                        subText: 'ຊື້ໂດຍ: ${widget.state.members.firstWhere((m) => m.id == widget.kratomStock!.buyerId, orElse: () => Member(id: '', name: 'ບໍ່ຮູ້ຊື່', avatarUrl: '')).name}',
                      ),
                    if (widget.syrupStock != null)
                      _buildDetailRow(
                        label: 'ນ້ຳຢາ (x${widget.expense.syrupPortions ?? 1}) (${widget.syrupStock!.itemName})',
                        value: widget.currencyFormat.format(widget.syrupPortionCost * (widget.expense.syrupPortions ?? 1)),
                        subText: 'ຊື້ໂດຍ: ${widget.state.members.firstWhere((m) => m.id == widget.syrupStock!.buyerId, orElse: () => Member(id: '', name: 'ບໍ່ຮູ້ຊື່', avatarUrl: '')).name}',
                      ),
                    if (widget.iceCost > 0)
                      _buildDetailRow(
                        label: 'ຄ່ານ້ຳກ້ອນ - ນ້ຳປຸງ',
                        value: widget.currencyFormat.format(widget.iceCost),
                        subText: 'ຈ່າຍໂດຍ: ${widget.expense.payers.keys.map((k) => widget.state.members.firstWhere((m) => m.id == k, orElse: () => Member(id: k, name: k, avatarUrl: '')).name).join(", ")}',
                      ),
                    const Divider(color: Colors.white12, height: 20),
                    _buildDetailRow(
                      label: 'ລາຄາລວມ',
                      value: widget.currencyFormat.format(widget.totalSessionCost),
                      isBold: true,
                      valueColor: const Color(0xFF10B981),
                    ),
                  ] else ...[
                    _buildDetailRow(
                      label: widget.expense.category == ExpenseCategory.utilities ? 'ຄ່າໄຟ-ນ້ຳ' : 'ຄ່າອາຫານ-ທົ່ວໄປ',
                      value: widget.currencyFormat.format(widget.expense.totalAmount),
                      subText: 'ຈ່າຍໂດຍ: ${widget.expense.payers.keys.map((k) => widget.state.members.firstWhere((m) => m.id == k, orElse: () => Member(id: k, name: k, avatarUrl: '')).name).join(", ")}',
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    _buildDetailRow(
                      label: 'ລວມທັງໝົດ',
                      value: widget.currencyFormat.format(widget.expense.totalAmount),
                      isBold: true,
                      valueColor: const Color(0xFF10B981),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ຜູ້ເຂົ້າຮ່ວມຫານ (${widget.expense.participantIds.length} ຄົນ)',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
              child: ListView(
                shrinkWrap: true,
                children: widget.expense.participantIds.map((partId) {
                  final member = widget.state.members.firstWhere((m) => m.id == partId, orElse: () => Member(id: partId, name: partId, avatarUrl: ''));
                  
                  // Calculate weighted share for this participant
                  final weights = widget.expense.participantWeights ?? {};
                  final totalWeight = widget.expense.participantIds.fold<double>(
                      0.0, (sum, id) => sum + (weights[id] ?? 1.0));
                  final weight = weights[partId] ?? 1.0;
                  final totalWeightVal = totalWeight > 0 ? totalWeight : 1.0;
                  
                  final double individualShare;
                  if (widget.expense.category == ExpenseCategory.kratom) {
                    individualShare = widget.totalSessionCost * (weight / totalWeightVal);
                  } else {
                    individualShare = widget.expense.totalAmount * (weight / totalWeightVal);
                  }

                  final paidAmount = widget.expense.payers[partId] ?? 0.0;
                  final netShare = paidAmount - individualShare;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        MemberAvatar(member: member, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (widget.expense.participantWeights != null && widget.expense.participantWeights!.values.any((w) => w != 1.0)) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${weight.toStringAsFixed(1)} ສ່ວນ)',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                              if (paidAmount > 0)
                                Text(
                                  'ຈ່າຍກ່ອນ: ${widget.currencyFormat.format(paidAmount)}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${netShare >= 0 ? "+" : ""}${widget.currencyFormat.format(netShare)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: netShare >= 0 ? const Color(0xFF10B981) : const Color(0xFFF87171),
                              ),
                            ),
                            Text(
                              'Boss: -${widget.currencyFormat.format(individualShare)}',
                              style: const TextStyle(color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

