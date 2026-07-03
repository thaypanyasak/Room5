import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/member_avatar.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _kratomCostController = TextEditingController();
  final _iceCostController = TextEditingController();
  final _generalCostController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _dateController;

  ExpenseCategory _selectedCategory = ExpenseCategory.kratom;
  String? _singlePayerId;
  final Map<String, double> _customPayers = {};
  List<String> _selectedParticipants = [];
  String? _selectedKratomStockId;
  String? _selectedSyrupStockId;
  int _kratomPortions = 1;
  int _syrupPortions = 1;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _kratomCostController.dispose();
    _iceCostController.dispose();
    _generalCostController.dispose();
    super.dispose();
  }

  void _initializeState() {
    if (_initialized) return;
    final state = ref.read(financeProvider);
    if (state.members.isNotEmpty) {
      _singlePayerId = state.members.first.id;
      _selectedParticipants = state.members.map((m) => m.id).toList();

      final activeKratom =
          state.preStockItems
              .where((i) => i.type == 'kratom' && !i.isOutOfStock)
              .toList();
      if (activeKratom.isNotEmpty) {
        _selectedKratomStockId = activeKratom.first.id;
      }
      final activeSyrup =
          state.preStockItems
              .where((i) => i.type == 'syrup' && !i.isOutOfStock)
              .toList();
      if (activeSyrup.isNotEmpty) {
        _selectedSyrupStockId = activeSyrup.first.id;
      }

      _titleController.text = 'ທ້ອມຊຸດທີ: ';
      _initialized = true;
    }
  }

  double _calculateTotalAmount() {
    if (_selectedCategory == ExpenseCategory.kratom) {
      final ice =
          double.tryParse(_iceCostController.text.replaceAll('.', '')) ?? 0.0;
      return ice;
    } else {
      return double.tryParse(_generalCostController.text.replaceAll('.', '')) ??
          0.0;
    }
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ກະລຸນາເລືອກຢ່າງໜ້ອຍ 1 ຄົນເພື່ອຫານເງິນ!')),
      );
      return;
    }

    final state = ref.read(financeProvider);
    final kratomStockItems =
        state.preStockItems.where((i) => i.type == 'kratom').toList();
    final syrupStockItems =
        state.preStockItems.where((i) => i.type == 'syrup').toList();

    if (_selectedCategory == ExpenseCategory.kratom) {
      if (_selectedKratomStockId == null && kratomStockItems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ກະລຸນາເລືອກ Kratom ໃນສາງ!')),
        );
        return;
      }
      if (_selectedSyrupStockId == null && syrupStockItems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ກະລຸນາເລືອກ ນ້ຳຢາ ໃນສາງ!')),
        );
        return;
      }
    }

    final total = _calculateTotalAmount();
    if (total < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ ຫຼື ເທົ່າກັບ 0!')),
      );
      return;
    }

    final Map<String, double> payersMap = {};
    if (total > 0) {
      if (_customPayers.isEmpty) {
        if (_singlePayerId != null) {
          payersMap[_singlePayerId!] = total;
        }
      } else {
        _customPayers.forEach((k, v) {
          if (v > 0) payersMap[k] = v;
        });
      }

      if (payersMap.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ກະລຸນາເລືອກຄົນຈ່າຍເງິນ!')),
        );
        return;
      }
    } else {
      if (_singlePayerId != null) {
        payersMap[_singlePayerId!] = 0.0;
      }
    }

    final now = DateTime.now();
    final expenseDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final newExpense = Expense(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _selectedCategory,
      totalAmount: total,
      date: expenseDate,
      kratomAmount: 0.0,
      iceAmount:
          _selectedCategory == ExpenseCategory.kratom
              ? double.tryParse(_iceCostController.text.replaceAll('.', ''))
              : null,
      kratomStockId:
          _selectedCategory == ExpenseCategory.kratom
              ? _selectedKratomStockId
              : null,
      syrupStockId:
          _selectedCategory == ExpenseCategory.kratom
              ? _selectedSyrupStockId
              : null,
      kratomPortions:
          _selectedCategory == ExpenseCategory.kratom && _selectedKratomStockId != null
              ? _kratomPortions
              : null,
      syrupPortions:
          _selectedCategory == ExpenseCategory.kratom && _selectedSyrupStockId != null
              ? _syrupPortions
              : null,
      payers: payersMap,
      participantIds: _selectedParticipants,
    );

    ref.read(financeProvider.notifier).addExpense(newExpense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _initializeState();
    final state = ref.watch(financeProvider);
    const primaryAccent = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'ເພີ່ມລາຍຈ່າຍໃໝ່',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Selector Card
                Row(
                  children: [
                    Icon(Icons.category_outlined, color: Colors.white.withValues(alpha: 0.6), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'ປະເພດລາຍຈ່າຍ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      ExpenseCategory.values
                          .where((cat) => cat != ExpenseCategory.utilities)
                          .map((cat) {
                            final isSelected = _selectedCategory == cat;
                            String label = '';
                            IconData icon = Icons.help_outline;

                            switch (cat) {
                              case ExpenseCategory.kratom:
                                label = 'ທ້ອມ';
                                icon = Icons.local_cafe_rounded;
                                break;
                              case ExpenseCategory.utilities:
                                label = 'ຄ່າໄຟ-ນ້ຳ';
                                icon = Icons.electric_bolt_rounded;
                                break;
                              case ExpenseCategory.food:
                                label = 'ຄ່າອາຫານ';
                                icon = Icons.restaurant_rounded;
                                break;
                              case ExpenseCategory.other:
                                label = 'ອື່ນໆ';
                                icon = Icons.miscellaneous_services_rounded;
                                break;
                            }

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                    if (cat == ExpenseCategory.kratom) {
                                      if (_titleController.text.isEmpty ||
                                          _titleController.text == 'ຊຸດທ້ອມ' ||
                                          !_titleController.text.startsWith(
                                            'ທ້ອມຊຸດທີ:',
                                          )) {
                                        _titleController.text = 'ທ້ອມຊຸດທີ: ';
                                      }
                                    } else {
                                      if (_titleController.text ==
                                              'ທ້ອມຊຸດທີ: ' ||
                                          _titleController.text.startsWith(
                                            'ທ້ອມຊຸດທີ:',
                                          )) {
                                        _titleController.text = '';
                                      }
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? primaryAccent.withValues(alpha: 0.15)
                                            : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? primaryAccent
                                              : Colors.white.withValues(alpha: 0.05),
                                      width: 1.5,
                                    ),
                                    boxShadow: isSelected 
                                      ? [
                                          BoxShadow(
                                            color: primaryAccent.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        icon,
                                        color:
                                            isSelected ? primaryAccent : Colors.white60,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.white60,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                ),
                const SizedBox(height: 20),

                // Title Input & Date Selector
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field with its own label
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                color: primaryAccent,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ຊື່ລາຍການ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _titleController,
                            hintText: 'ປ້ອນຊື່ລາຍການຈ່າຍ',
                            accentColor: primaryAccent,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'ກະລຸນາປ້ອນຊື່ລາຍການຈ່າຍ';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: primaryAccent,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ວັນທີ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2101),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: primaryAccent,
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF1E293B),
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor: const Color(0xFF0F172A),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                  _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                                });
                              }
                            },
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'dd/MM/yyyy',
                              hintStyle: const TextStyle(color: Colors.white24),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.white10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: primaryAccent, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount Inputs based on category
                if (_selectedCategory == ExpenseCategory.kratom) ...[
                  Builder(
                    builder: (context) {
                      final kratomStockItems =
                          state.preStockItems
                              .where((i) => i.type == 'kratom')
                              .toList();
                      final syrupStockItems =
                          state.preStockItems
                              .where((i) => i.type == 'syrup')
                              .toList();

                      final kratomDropdownItems =
                          kratomStockItems.map((item) {
                            final buyerName =
                                state.members
                                    .firstWhere(
                                      (m) => m.id == item.buyerId,
                                      orElse:
                                          () => Member(
                                            id: '',
                                            name: 'ບໍ່ຮູ້',
                                            avatarUrl: '',
                                          ),
                                    )
                                    .name;
                            final usedCount = state.expenses.fold<int>(0, (sum, e) =>
                              e.kratomStockId == item.id ? sum + (e.kratomPortions ?? 1) : sum);
                            final remaining = item.startingPortions - usedCount;
                            final isAvailable =
                                !item.isOutOfStock && remaining > 0;
                            final label =
                                '${item.itemName} (ຍັງ $remaining/${item.portions})';
                            return DropdownMenuItem<String>(
                              value: item.id,
                              enabled: isAvailable,
                              child: Text(
                                isAvailable ? label : '$label (ໝົດແລ້ວ)',
                                style: TextStyle(
                                  color:
                                      isAvailable
                                          ? Colors.white
                                          : Colors.white30,
                                  decoration:
                                      isAvailable
                                          ? null
                                          : TextDecoration.lineThrough,
                                ),
                              ),
                            );
                          }).toList();

                      final syrupDropdownItems =
                          syrupStockItems.map((item) {
                            final buyerName =
                                state.members
                                    .firstWhere(
                                      (m) => m.id == item.buyerId,
                                      orElse:
                                          () => Member(
                                            id: '',
                                            name: 'ບໍ່ຮູ້',
                                            avatarUrl: '',
                                          ),
                                    )
                                    .name;
                            final usedCount = state.expenses.fold<int>(0, (sum, e) =>
                              e.syrupStockId == item.id ? sum + (e.syrupPortions ?? 1) : sum);
                            final remaining = item.startingPortions - usedCount;
                            final isAvailable =
                                !item.isOutOfStock && remaining > 0;
                            final label =
                                '${item.itemName} (ຍັງ $remaining/${item.portions} )';
                            return DropdownMenuItem<String>(
                              value: item.id,
                              enabled: isAvailable,
                              child: Text(
                                isAvailable ? label : '$label (ໝົດແລ້ວ)',
                                style: TextStyle(
                                  color:
                                      isAvailable
                                          ? Colors.white
                                          : Colors.white30,
                                  decoration:
                                      isAvailable
                                          ? null
                                          : TextDecoration.lineThrough,
                                ),
                              ),
                            );
                          }).toList();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownWithCounter<String>(
                              labelText: 'ເລືອກ ທ້ອມ',
                              hintText:
                                  kratomStockItems.isEmpty
                                      ? 'ບໍ່ມີ ທ້ອມ ໃນສາງ'
                                      : 'ເລືອກ ທ້ອມ',
                              prefixIcon: Icons.local_cafe_outlined,
                              accentColor: primaryAccent,
                              value: _selectedKratomStockId,
                              items: kratomDropdownItems,
                              onChanged: (val) {
                                setState(() {
                                  _selectedKratomStockId = val;
                                  _kratomPortions = 1;
                                });
                              },
                              showCounter: _selectedKratomStockId != null,
                              counterValue: _kratomPortions,
                              onDecrement: () {
                                if (_kratomPortions > 1) {
                                  setState(() {
                                    _kratomPortions--;
                                  });
                                }
                              },
                              onIncrement: () {
                                final item = kratomStockItems.firstWhere((i) => i.id == _selectedKratomStockId);
                                final usedCount = state.expenses.fold<int>(0, (sum, e) => 
                                  e.kratomStockId == item.id ? sum + (e.kratomPortions ?? 1) : sum);
                                final remaining = item.startingPortions - usedCount;
                                if (_kratomPortions < remaining) {
                                  setState(() {
                                    _kratomPortions++;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ຈຳນວນທີ່ໃຊ້ເກີນປະລິມານຄົງເຫຼືອໃນສາງ!')),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownWithCounter<String>(
                              labelText: 'ເລືອກ ນ້ຳຢາ',
                              hintText:
                                  syrupStockItems.isEmpty
                                      ? 'ບໍ່ມີ ນ້ຳຢາ ໃນສາງ'
                                      : 'ເລືອກ ນ້ຳຢາ',
                              prefixIcon: Icons.water_drop_outlined,
                              accentColor: primaryAccent,
                              value: _selectedSyrupStockId,
                              items: syrupDropdownItems,
                              onChanged: (val) {
                                setState(() {
                                  _selectedSyrupStockId = val;
                                  _syrupPortions = 1;
                                });
                              },
                              showCounter: _selectedSyrupStockId != null,
                              counterValue: _syrupPortions,
                              onDecrement: () {
                                if (_syrupPortions > 1) {
                                  setState(() {
                                    _syrupPortions--;
                                  });
                                }
                              },
                              onIncrement: () {
                                final item = syrupStockItems.firstWhere((i) => i.id == _selectedSyrupStockId);
                                final usedCount = state.expenses.fold<int>(0, (sum, e) => 
                                  e.syrupStockId == item.id ? sum + (e.syrupPortions ?? 1) : sum);
                                final remaining = item.startingPortions - usedCount;
                                if (_syrupPortions < remaining) {
                                  setState(() {
                                    _syrupPortions++;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ຈຳນວນທີ່ໃຊ້ເກີນປະລິມານຄົງເຫຼືອໃນສາງ!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryAccent.withValues(alpha: 0.35), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.ac_unit, color: primaryAccent, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'ຄ່ານ້ຳກ້ອນ & ນ້ຳປຸງ (₭) *',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _iceCostController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'ປ້ອນຄ່ານ້ຳກ້ອນ & ນ້ຳປຸງ',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryAccent, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Total Display
                  Builder(
                    builder: (context) {
                      final ice =
                          double.tryParse(
                            _iceCostController.text.replaceAll('.', ''),
                          ) ??
                          0.0;
                      double kratomPortionCost = 0.0;
                      double syrupPortionCost = 0.0;

                      if (_selectedKratomStockId != null) {
                        final item = state.preStockItems.firstWhere(
                          (i) => i.id == _selectedKratomStockId,
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
                        if (item.id.isNotEmpty) {
                          kratomPortionCost =
                              item.totalCost /
                              (item.portions > 0 ? item.portions : 1);
                        }
                      }

                      if (_selectedSyrupStockId != null) {
                        final item = state.preStockItems.firstWhere(
                          (i) => i.id == _selectedSyrupStockId,
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
                        if (item.id.isNotEmpty) {
                          syrupPortionCost =
                              item.totalCost /
                              (item.portions > 0 ? item.portions : 1);
                        }
                      }

                      final totalSessionCost =
                          ice + (kratomPortionCost * _kratomPortions) + (syrupPortionCost * _syrupPortions);

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryAccent.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAccent.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'ລວມທັງໝົດຂອງຊຸດ:',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: 'K',
                                decimalDigits: 0,
                              ).format(totalSessionCost),
                              style: const TextStyle(
                                color: primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _generalCostController,
                    labelText: 'ຈຳນວນເງິນ (₭)',
                    hintText: 'ປ້ອນຈຳນວນເງິນ',
                    prefixIcon: Icons.payments,
                    accentColor: primaryAccent,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ກະລຸນາປ້ອນຈຳນວນເງິນ';
                      }
                      if (double.tryParse(value.replaceAll('.', '')) == null) {
                        return 'ກະລຸນາປ້ອນຕົວເລກໃຫ້ຖືກຕ້ອງ';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // Who Paid (Payers Selection Chips)
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.white.withValues(alpha: 0.6), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'ໃຜເປັນຄົນຈ່າຍ?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: state.members.map((m) {
                    final isSelected = _singlePayerId == m.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _singlePayerId = m.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryAccent.withValues(alpha: 0.15)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? primaryAccent : Colors.white.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MemberAvatar(member: m, radius: 11),
                            const SizedBox(width: 8),
                            Text(
                              m.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Who Participates (Participants Selection Chips)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: Colors.white.withValues(alpha: 0.6), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'ໃຜກິນ?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedParticipants.length ==
                              state.members.length) {
                            _selectedParticipants = [];
                          } else {
                            _selectedParticipants =
                                state.members.map((m) => m.id).toList();
                          }
                        });
                      },
                      child: Text(
                        _selectedParticipants.length == state.members.length
                            ? 'ຍົກເລີກທັງໝົດ'
                            : 'ເລືອກທັງໝົດ',
                        style: const TextStyle(
                          color: primaryAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: state.members.map((m) {
                    final isSelected = _selectedParticipants.contains(m.id);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedParticipants.remove(m.id);
                          } else {
                            _selectedParticipants.add(m.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryAccent.withValues(alpha: 0.15)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? primaryAccent : Colors.white.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MemberAvatar(member: m, radius: 11),
                            const SizedBox(width: 8),
                            Text(
                              m.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: primaryAccent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [primaryAccent, Color(0xFF059669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saveExpense,
                    child: const Text(
                      'ບັນທຶກ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? labelText,
    required String hintText,
    IconData? prefixIcon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: labelText != null
            ? TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13)
            : null,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: accentColor.withValues(alpha: 0.8), size: 20)
            : null,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownWithCounter<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData prefixIcon,
    required Color accentColor,
    String? hintText,
    required bool showCounter,
    required int counterValue,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(prefixIcon, color: accentColor.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 8),
                Text(
                  labelText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (showCounter)
              const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Text(
                  'ຈຳນວນຄັ້ງທີ່ໃຊ້',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                    hint: hintText != null
                        ? Text(
                            hintText,
                            style: const TextStyle(color: Colors.white30),
                          )
                        : null,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
            if (showCounter) ...[
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrement button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDecrement,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    // Value Display
                    Container(
                      constraints: const BoxConstraints(minWidth: 44),
                      alignment: Alignment.center,
                      child: Text(
                        '$counterValue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Increment button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onIncrement,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
