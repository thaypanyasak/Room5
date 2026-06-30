import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/member_avatar.dart';

class UtilitiesScreen extends ConsumerStatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  ConsumerState<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends ConsumerState<UtilitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Filter utility expenses
    final utilityExpenses = state.expenses
        .where((e) => e.category == ExpenseCategory.utilities)
        .toList();
    final double totalUtilities = utilityExpenses.fold<double>(0, (sum, e) => sum + e.totalAmount);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ຄ່າໄຟ - ຄ່ານ້ຳ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Utility Cost Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF831843), Color(0xFF4C0519)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ຄ່າໃຊ້ຈ່າຍຫ້ອງທັງໝົດ (ໄຟ, ນ້ຳ, ຫ້ອງ)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormat.format(totalUtilities),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '*ຄ່າໃຊ້ຈ່າຍເຫຼົ່ານີ້ຈະຖືກຫານໃຫ້ກັບຜູ້ທີ່ເລືອກໃນແຕ່ລະບິນ.',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ລາຍການບິນຄ່າຫ້ອງ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'ປັດເພື່ອລຶບ',
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Utility Expenses List
            Expanded(
              child: utilityExpenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.electric_bolt_rounded, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text(
                            'ຍັງບໍ່ມີລາຍການຄ່າໄຟ-ນ້ຳເທື່ອ',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: utilityExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = utilityExpenses[index];
                        
                        // Decide icon based on keywords in title
                        IconData iconData = Icons.home_outlined;
                        Color iconColor = const Color(0xFFEC4899);
                        final titleLower = expense.title.toLowerCase();
                        if (titleLower.contains('ໄຟ') || titleLower.contains('elect') || titleLower.contains('power')) {
                          iconData = Icons.electric_bolt_rounded;
                          iconColor = const Color(0xFFF59E0B);
                        } else if (titleLower.contains('ນ້ຳ') || titleLower.contains('water')) {
                          iconData = Icons.water_drop_rounded;
                          iconColor = const Color(0xFF3B82F6);
                        }

                        // Get primary payer name
                        final payerName = expense.payers.keys.map((k) {
                          return state.members.firstWhere(
                            (m) => m.id == k,
                            orElse: () => Member(id: k, name: 'ຄົນຈ່າຍ', avatarUrl: ''),
                          ).name;
                        }).join(', ');

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
                                    color: iconColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ຈ່າຍໂດຍ: $payerName • ${dateFormat.format(expense.date)}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ຫານກັນ ${expense.participantIds.length} ຄົນ',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(expense.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEC4899),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => const _AddUtilitySheet(),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ເພີ່ມຄ່າໄຟ-ນ້ຳ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AddUtilitySheet extends ConsumerStatefulWidget {
  const _AddUtilitySheet();

  @override
  ConsumerState<_AddUtilitySheet> createState() => _AddUtilitySheetState();
}

class _AddUtilitySheetState extends ConsumerState<_AddUtilitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  String? _payerId;
  List<String> _selectedParticipants = [];
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _initialize() {
    if (_initialized) return;
    final state = ref.read(financeProvider);
    if (state.members.isNotEmpty) {
      _payerId = state.members.first.id;
      _selectedParticipants = state.members.map((m) => m.id).toList();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    final state = ref.watch(financeProvider);

    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ເພີ່ມບິນຄ່າຫ້ອງ (ໄຟ / ນ້ຳ / ຫ້ອງ)',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                validator: (val) => val == null || val.trim().isEmpty ? 'ປ້ອນຫົວຂໍ້ບິນ' : null,
                decoration: InputDecoration(
                  labelText: 'ຊື່ລາຍການ (ຕົວຢ່າງ: ຄ່າໄຟເດືອນ 6, ຄ່ານ້ຳປະປາ...)',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEC4899)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: const TextStyle(color: Colors.white),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'ປ້ອນຈຳນວນເງິນ';
                  if (double.tryParse(val.replaceAll('.', '')) == null) return 'ປ້ອນຕົວເລກໃຫ້ຖືກຕ້ອງ';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'ຈຳນວນເງິນ (₭)',
                  labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEC4899)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payer Selector
              const Text('ໃຜເປັນຄົນຈ່າຍກ່ອນ?', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _payerId,
                    dropdownColor: const Color(0xFF0F172A),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    items: state.members.map((m) {
                      return DropdownMenuItem<String>(
                        value: m.id,
                        child: Text(m.name, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _payerId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Participant Multi-selector
              const Text('ຫານໃຫ້ໃຜແດ່? (ເລືອກຄົນທີ່ແບ່ງປັນຄ່າໃຊ້ຈ່າຍ)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: state.members.map((m) {
                    final isSelected = _selectedParticipants.contains(m.id);
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          MemberAvatar(
                            member: m,
                            radius: 16,
                          ),
                          const SizedBox(width: 12),
                          Text(m.name, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFFEC4899),
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (!isSelected) _selectedParticipants.add(m.id);
                          } else {
                            if (_selectedParticipants.length > 1) {
                              _selectedParticipants.remove(m.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ຕ້ອງມີຢ່າງໜ້ອຍ 1 ຄົນເພື່ອຫານເງິນ!')),
                              );
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _payerId != null && _selectedParticipants.isNotEmpty) {
                      final amount = double.parse(_costController.text.replaceAll('.', ''));
                      
                      final newExpense = Expense(
                        id: const Uuid().v4(),
                        title: _titleController.text.trim(),
                        category: ExpenseCategory.utilities,
                        totalAmount: amount,
                        date: DateTime.now(),
                        payers: {_payerId!: amount},
                        participantIds: _selectedParticipants,
                      );

                      ref.read(financeProvider.notifier).addExpense(newExpense);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'ບັນທຶກບິນຄ່າຫ້ອງ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
