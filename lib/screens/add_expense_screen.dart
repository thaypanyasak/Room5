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

  ExpenseCategory _selectedCategory = ExpenseCategory.kratom;
  String? _singlePayerId;
  final Map<String, double> _customPayers = {};
  List<String> _selectedParticipants = [];
  String? _selectedKratomStockId;
  String? _selectedSyrupStockId;

  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
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

      final activeKratom = state.preStockItems.where((i) => i.type == 'kratom' && !i.isOutOfStock).toList();
      if (activeKratom.isNotEmpty) {
        _selectedKratomStockId = activeKratom.first.id;
      }
      final activeSyrup = state.preStockItems.where((i) => i.type == 'syrup' && !i.isOutOfStock).toList();
      if (activeSyrup.isNotEmpty) {
        _selectedSyrupStockId = activeSyrup.first.id;
      }

      _initialized = true;
    }
  }

  double _calculateTotalAmount() {
    if (_selectedCategory == ExpenseCategory.kratom) {
      final ice = double.tryParse(_iceCostController.text.replaceAll('.', '')) ?? 0.0;
      return ice;
    } else {
      return double.tryParse(_generalCostController.text.replaceAll('.', '')) ?? 0.0;
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
    final kratomStockItems = state.preStockItems.where((i) => i.type == 'kratom').toList();
    final syrupStockItems = state.preStockItems.where((i) => i.type == 'syrup').toList();

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

    final newExpense = Expense(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _selectedCategory,
      totalAmount: total,
      date: DateTime.now(),
      kratomAmount: 0.0,
      iceAmount: _selectedCategory == ExpenseCategory.kratom ? double.tryParse(_iceCostController.text.replaceAll('.', '')) : null,
      kratomStockId: _selectedCategory == ExpenseCategory.kratom ? _selectedKratomStockId : null,
      syrupStockId: _selectedCategory == ExpenseCategory.kratom ? _selectedSyrupStockId : null,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ເພີ່ມລາຍຈ່າຍໃໝ່', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                const Text('ປະເພດລາຍຈ່າຍ', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ExpenseCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    String label = '';
                    IconData icon = Icons.help_outline;
                    Color color = Colors.white;

                    switch (cat) {
                      case ExpenseCategory.kratom:
                        label = 'Kratom';
                        icon = Icons.local_cafe_rounded;
                        color = const Color(0xFF10B981);
                        break;
                      case ExpenseCategory.utilities:
                        label = 'ຄ່າໄຟ-ນ້ຳ';
                        icon = Icons.electric_bolt_rounded;
                        color = const Color(0xFFEC4899);
                        break;
                      case ExpenseCategory.food:
                        label = 'ຄ່າອາຫານ';
                        icon = Icons.restaurant_rounded;
                        color = const Color(0xFFF59E0B);
                        break;
                      case ExpenseCategory.other:
                        label = 'ອື່ນໆ';
                        icon = Icons.miscellaneous_services_rounded;
                        color = const Color(0xFF8B5CF6);
                        break;
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            if (cat == ExpenseCategory.kratom && _titleController.text.isEmpty) {
                              _titleController.text = 'ຊຸດ Kratom';
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.white.withOpacity(0.05),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon, color: isSelected ? color : Colors.white60, size: 22),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Title Input
                _buildTextField(
                  controller: _titleController,
                  labelText: 'ຊື່ລາຍການຈ່າຍ (ຕົວຢ່າງ: Kratom ຊຸດທີ 1, ຄ່າໄຟ...)',
                  hintText: 'ປ້ອນຊື່ລາຍການຈ່າຍ',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ກະລຸນາປ້ອນຊື່ລາຍການຈ່າຍ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Amount Inputs based on category
                if (_selectedCategory == ExpenseCategory.kratom) ...[
                  Builder(
                    builder: (context) {
                      final kratomStockItems = state.preStockItems.where((i) => i.type == 'kratom').toList();
                      final syrupStockItems = state.preStockItems.where((i) => i.type == 'syrup').toList();

                      final kratomDropdownItems = kratomStockItems.map((item) {
                        final buyerName = state.members.firstWhere((m) => m.id == item.buyerId, orElse: () => Member(id: '', name: 'ບໍ່ຮູ້', avatarUrl: '')).name;
                        final isAvailable = !item.isOutOfStock;
                        final label = '${item.itemName} ($buyerName - ${DateFormat('dd/MM').format(item.date)})';
                        return DropdownMenuItem<String>(
                          value: item.id,
                          enabled: isAvailable,
                          child: Text(
                            isAvailable ? label : '$label (ໝົດແລ້ວ)',
                            style: TextStyle(
                              color: isAvailable ? Colors.white : Colors.white30,
                              decoration: isAvailable ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      }).toList();

                      final syrupDropdownItems = syrupStockItems.map((item) {
                        final buyerName = state.members.firstWhere((m) => m.id == item.buyerId, orElse: () => Member(id: '', name: 'ບໍ່ຮູ້', avatarUrl: '')).name;
                        final isAvailable = !item.isOutOfStock;
                        final label = '${item.itemName} ($buyerName - ${DateFormat('dd/MM').format(item.date)})';
                        return DropdownMenuItem<String>(
                          value: item.id,
                          enabled: isAvailable,
                          child: Text(
                            isAvailable ? label : '$label (ໝົດແລ້ວ)',
                            style: TextStyle(
                              color: isAvailable ? Colors.white : Colors.white30,
                              decoration: isAvailable ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownField<String>(
                            labelText: 'ເລືອກ Kratom ໃນສາງ',
                            hintText: kratomStockItems.isEmpty ? 'ບໍ່ມີ Kratom ໃນສາງ' : 'ເລືອກ Kratom',
                            value: _selectedKratomStockId,
                            items: kratomDropdownItems,
                            onChanged: (val) {
                              setState(() {
                                _selectedKratomStockId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField<String>(
                            labelText: 'ເລືອກ ນ້ຳຢา ໃນສາງ',
                            hintText: syrupStockItems.isEmpty ? 'ບໍ່ມີ ນ້ຳຢາ ໃນສາງ' : 'ເລືອກ ນ້ຳຢາ',
                            value: _selectedSyrupStockId,
                            items: syrupDropdownItems,
                            onChanged: (val) {
                              setState(() {
                                _selectedSyrupStockId = val;
                              });
                            },
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _iceCostController,
                    labelText: 'ຄ່ານ້ຳກ້ອນ / ອື່ນໆ (₭)',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Total Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ລວມທັງໝົດຂອງຊຸດ (ຄ່ານ້ຳກ້ອນ/ອື່ນໆ):', style: TextStyle(color: Colors.white70)),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0).format(_calculateTotalAmount()),
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      ],
                    ),
                  )
                ] else ...[
                  _buildTextField(
                    controller: _generalCostController,
                    labelText: 'ຈຳນວນເງິນ (₭)',
                    hintText: 'ປ້ອນຈຳນວນເງິນ',
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

                // Who Paid (Payers Selection)
                const Text('ໃຜເປັນຄົນຈ່າຍ?', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: state.members.map((m) {
                      return RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: m.id,
                        groupValue: _singlePayerId,
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
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setState(() {
                            _singlePayerId = val;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Who Participates (Participants Selection)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ໃຜຮ່ວມຈ່າຍ/ໃຜດື່ມ?', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedParticipants.length == state.members.length) {
                            _selectedParticipants = [];
                          } else {
                            _selectedParticipants = state.members.map((m) => m.id).toList();
                          }
                        });
                      },
                      child: Text(
                        _selectedParticipants.length == state.members.length ? 'ຍົກເລີກທັງໝົດ' : 'ເລືອກທັງໝົດ',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: state.members.map((m) {
                      final isSelected = _selectedParticipants.contains(m.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isSelected,
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
                        activeColor: const Color(0xFF10B981),
                        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedParticipants.add(m.id);
                            } else {
                              _selectedParticipants.remove(m.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _saveExpense,
                    child: const Text(
                      'บันທຶກລາຍຈ່າຍ',
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
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
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: hintText != null ? Text(hintText, style: const TextStyle(color: Colors.white30)) : null,
              dropdownColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981)),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
