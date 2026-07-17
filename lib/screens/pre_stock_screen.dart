import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../providers/finance_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/member_avatar.dart';

class PreStockScreen extends ConsumerStatefulWidget {
  final String type; // 'kratom' or 'syrup'

  const PreStockScreen({super.key, this.type = 'kratom'});

  @override
  ConsumerState<PreStockScreen> createState() => _PreStockScreenState();
}

class _PreStockScreenState extends ConsumerState<PreStockScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'K',
      decimalDigits: 0,
    );

    // Filter items based on selected tab type
    final items =
        state.preStockItems.where((item) => item.type == widget.type).toList();
    final double totalStockCost = items.fold<double>(
      0,
      (sum, item) {
        final usedCount = state.expenses.fold<int>(0, (sum2, e) {
          if (item.type == 'kratom' && e.kratomStockId == item.id) {
            return sum2 + (e.kratomPortions ?? 1);
          }
          if (item.type == 'syrup' && e.syrupStockId == item.id) {
            return sum2 + (e.syrupPortions ?? 1);
          }
          return sum2;
        });
        final remaining = item.startingPortions - usedCount;
        final portionCost = item.totalCost / (item.portions > 0 ? item.portions : 1);
        return sum + (portionCost * remaining);
      },
    );

    final isKratom = widget.type == 'kratom';
    final accentColor =
        isKratom ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final gradientColors =
        isKratom
            ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
            : [const Color(0xFF881337), const Color(0xFF4C0519)];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          isKratom ? 'ທ້ອມ ໃນສາງ' : 'ນ້ຳຢາ ໃນສາງ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            isKratom ? const Color(0xFF064E3B) : const Color(0xFF881337),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Stock Cost Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: gradientColors),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ມູນຄ່າສາງທັງໝົດ',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormat.format(totalStockCost),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isKratom
                        ? '*ທຸກໆລາຍການ ທ້ອມ ໃນສາງຈະຫານສະເໝີກັນໃຫ້ທຸກຄົນໃນກຸ່ມ.'
                        : '*ທຸກໆລາຍການ ນ້ຳຢາ ໃນສາງຈະຫານສະເໝີກັນໃຫ້ທຸກຄົນໃນກຸ່ມ.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ລາຍການນຳເຂົ້າສາງ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ປັດເພື່ອລຶບ',
                  style: TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items List
            Expanded(
              child:
                  items.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isKratom
                                  ? 'ຍັງບໍ່ມີເຄື່ອງໃນສາງ ທ້ອມ ເທື່ອ'
                                  : 'ຍັງບໍ່ມີນ້ຳຢາໃນສາງເທື່ອ',
                              style: const TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final buyer = state.members.firstWhere(
                            (m) => m.id == item.buyerId,
                            orElse:
                                () => Member(
                                  id: item.buyerId,
                                  name: 'ຄົນຊື້',
                                  avatarUrl: '',
                                ),
                          );

                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              ref
                                  .read(financeProvider.notifier)
                                  .deletePreStockItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ລຶບແລ້ວ: ${item.itemName}'),
                                ),
                              );
                            },
                            child: Opacity(
                              opacity: item.isOutOfStock ? 0.55 : 1.0,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        item.isOutOfStock
                                            ? Colors.redAccent.withValues(
                                              alpha: 0.15,
                                            )
                                            : accentColor.withValues(
                                              alpha: 0.25,
                                            ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap:
                                        () => _showEditPreStockSheet(
                                          context,
                                          item,
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title & Price Badge
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.itemName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    letterSpacing: 0.3,
                                                    decoration:
                                                        item.isOutOfStock
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      item.isOutOfStock
                                                          ? Colors.redAccent
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                          : accentColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  currencyFormat.format(
                                                    item.totalCost,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        item.isOutOfStock
                                                            ? const Color(
                                                              0xFFEF4444,
                                                            )
                                                            : accentColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),

                                          // Portions Progress Bar
                                          Builder(
                                            builder: (context) {
                                              final usedCount = state.expenses
                                                  .fold<int>(0, (sum, e) {
                                                    if (item.type == 'kratom' &&
                                                        e.kratomStockId ==
                                                            item.id) {
                                                      return sum +
                                                          (e.kratomPortions ??
                                                              1);
                                                    }
                                                    if (item.type == 'syrup' &&
                                                        e.syrupStockId ==
                                                            item.id) {
                                                      return sum +
                                                          (e.syrupPortions ??
                                                              1);
                                                    }
                                                    return sum;
                                                  });
                                              final remaining =
                                                  item.startingPortions -
                                                  usedCount;
                                              final progress =
                                                  item.portions > 0
                                                      ? (remaining /
                                                              item.portions)
                                                          .clamp(0.0, 1.0)
                                                      : 0.0;

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'ປະລິມານຄົງເຫຼືອ:',
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        'ຍັງເຫຼືອ $remaining/${item.portions} ຄັ້ງ',
                                                        style: TextStyle(
                                                          color:
                                                              item.isOutOfStock ||
                                                                      remaining ==
                                                                          0
                                                                  ? const Color(
                                                                    0xFFEF4444,
                                                                  )
                                                                  : accentColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: LinearProgressIndicator(
                                                      value: progress,
                                                      minHeight: 7,
                                                      backgroundColor: Colors
                                                          .white
                                                          .withValues(
                                                            alpha: 0.06,
                                                          ),
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            item.isOutOfStock ||
                                                                    remaining ==
                                                                        0
                                                                ? const Color(
                                                                  0xFFEF4444,
                                                                )
                                                                : accentColor,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Buyer & Date Footer
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  MemberAvatar(
                                                    member: buyer,
                                                    radius: 12,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    buyer.name,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 11,
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(item.date),
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Switch for availability
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        item.isOutOfStock
                                                            ? 'ໝົດ'
                                                            : 'ຍັງ',
                                                        style: TextStyle(
                                                          color:
                                                              item.isOutOfStock
                                                                  ? const Color(
                                                                    0xFFEF4444,
                                                                  )
                                                                  : accentColor,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      SizedBox(
                                                        width: 32,
                                                        height: 20,
                                                        child: FittedBox(
                                                          fit: BoxFit.fill,
                                                          child: Switch(
                                                            value:
                                                                !item
                                                                    .isOutOfStock,
                                                            activeColor:
                                                                accentColor,
                                                            activeTrackColor:
                                                                accentColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    ),
                                                            inactiveThumbColor:
                                                                Colors.white30,
                                                            inactiveTrackColor:
                                                                Colors.white10,
                                                            onChanged: (val) {
                                                              ref
                                                                  .read(
                                                                    financeProvider
                                                                        .notifier,
                                                                  )
                                                                  .updatePreStockItem(
                                                                    item.copyWith(
                                                                      isOutOfStock:
                                                                          !val,
                                                                    ),
                                                                  );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (item.notes.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.03,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'ໝາຍເຫດ: ${item.notes}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
        backgroundColor: accentColor,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _AddPreStockSheet(type: widget.type),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isKratom ? 'ນຳເຂົ້າສາງ ທ້ອມ' : 'ນຳເຂົ້າສາງນ້ຳຢາ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showEditPreStockSheet(BuildContext context, PreStockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditPreStockSheet(item: item),
    );
  }
}

class _AddPreStockSheet extends ConsumerStatefulWidget {
  final String type;

  const _AddPreStockSheet({required this.type});

  @override
  ConsumerState<_AddPreStockSheet> createState() => _AddPreStockSheetState();
}

class _AddPreStockSheetState extends ConsumerState<_AddPreStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  late final TextEditingController _portionsController;
  late final TextEditingController _remainingPortionsController;
  String? _buyerId;
  bool _manuallyEditedRemaining = false;

  @override
  void initState() {
    super.initState();
    final defaultPortions = widget.type == 'syrup' ? 50 : 10;
    _portionsController = TextEditingController(
      text: defaultPortions.toString(),
    );
    _remainingPortionsController = TextEditingController(
      text: defaultPortions.toString(),
    );

    _portionsController.addListener(() {
      if (!_manuallyEditedRemaining) {
        _remainingPortionsController.text = _portionsController.text;
      }
    });

    _remainingPortionsController.addListener(() {
      if (_remainingPortionsController.text != _portionsController.text) {
        _manuallyEditedRemaining = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _portionsController.dispose();
    _remainingPortionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    if (_buyerId == null && state.members.isNotEmpty) {
      _buyerId = state.members.first.id;
    }

    final isKratom = widget.type == 'kratom';
    final accentColor =
        isKratom ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header title with close icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isKratom ? Icons.local_cafe : Icons.water_drop,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKratom
                                      ? 'ເພີ່ມ ທ້ອມ ເຂົ້າສາງ'
                                      : 'ເພີ່ມນ້ຳຢາ ເຂົ້າສາງ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isKratom
                                      ? 'ເພີ່ມ ແລະ ບັນທຶກຂໍ້ມູນ ທ້ອມ ເຂົ້າໃນສາງ'
                                      : 'ເພີ່ມ ແລະ ບັນທຶກຂໍ້ມູນນ້ຳຢາ ເຂົ້າໃນສາງ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white30,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 20),

                // Item Name
                _buildTextFormField(
                  controller: _nameController,
                  label:
                      isKratom
                          ? 'ຊື່ ທ້ອມ (ຕົວຢ່າງ: ທ້ອມ 1 ຍົກ, ຜົງ ທ້ອມ 3kg...)'
                          : 'ຊື່ນ້ຳຢາ (ຕົວຢ່າງ: ນ້ຳຢາລົດສະຕໍເບີຣີ, Syrup ຫວານ...)',
                  hintText: isKratom ? 'ປ້ອນຊື່ ທ້ອມ...' : 'ປ້ອນຊື່ນ້ຳຢາ...',
                  prefixIcon:
                      isKratom
                          ? Icons.shopping_bag_outlined
                          : Icons.water_drop_outlined,
                  accentColor: accentColor,
                  validator:
                      (val) =>
                          val == null || val.trim().isEmpty
                              ? 'ປ້ອນຊື່ສິນຄ້າ'
                              : null,
                ),
                const SizedBox(height: 16),

                // Cost
                _buildTextFormField(
                  controller: _costController,
                  label: 'ລາຄາຊື້ (₭)',
                  hintText: 'ປ້ອນລາຄາຊື້...',
                  prefixIcon: Icons.payments_outlined,
                  accentColor: accentColor,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'ປ້ອນລາຄາຊື້';
                    }
                    if (double.tryParse(val.replaceAll('.', '')) == null) {
                      return 'ປ້ອນຕົວເລກໃຫ້ຖືກຕ້ອງ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Portions & Remaining Portions Field in a Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _portionsController,
                        label:
                            isKratom
                                ? 'ຄາດຄະເນໃຊ້ງານ (ຄັ້ງ/KG)'
                                : 'ຄາດຄະເນໃຊ້ງານ (ຄັ້ງ/ຖັງ)',
                        hintText: 'ປ້ອນຈຳນວນຄັ້ງ...',
                        prefixIcon: Icons.calculate_outlined,
                        accentColor: accentColor,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'ປ້ອນຈຳນວນຄັ້ງ';
                          }
                          final parsed = int.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return 'ປ້ອນຕົວເລກ (> 0)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _remainingPortionsController,
                        label: 'ຈຳນວນຄັ້ງທີ່ຍັງເຫຼືອ',
                        hintText: 'ປ້ອນຈຳນວນຄັ້ງທີ່ຍັງເຫຼືອ...',
                        prefixIcon: Icons.hourglass_empty,
                        accentColor: accentColor,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'ປ້ອນຈຳນວນຄັ້ງທີ່ຍັງເຫຼືອ';
                          }
                          final remaining = int.tryParse(val);
                          if (remaining == null || remaining < 0) {
                            return 'ປ້ອນຕົວເລກ (>= 0)';
                          }
                          final total = int.tryParse(_portionsController.text);
                          if (total != null && remaining > total) {
                            return 'ບໍ່ຄວນຫຼາຍກວ່າທັງໝົດ';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buyer Selector
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white30,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ໃຜເປັນຄົນຊື້?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _buyerId,
                      hint: Text(
                        'ເລືອກຜູ້ຊື້',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.24),
                          fontSize: 14,
                        ),
                      ),
                      dropdownColor: const Color(0xFF0F172A),
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: accentColor,
                        size: 20,
                      ),
                      items:
                          state.members.map((m) {
                            return DropdownMenuItem<String>(
                              value: m.id,
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _buyerId = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                _buildTextFormField(
                  controller: _notesController,
                  label: 'ໝາຍເຫດ (ທາງເລືອກ)',
                  hintText: 'ປ້ອນໝາຍເຫດ...',
                  prefixIcon: Icons.description_outlined,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 24),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors:
                          isKratom
                              ? [
                                const Color(0xFF059669),
                                const Color(0xFF10B981),
                              ]
                              : [
                                const Color(0xFFE11D48),
                                const Color(0xFFF43F5E),
                              ],
                    ),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          _buyerId != null) {
                        final item = PreStockItem(
                          id: const Uuid().v4(),
                          itemName: _nameController.text.trim(),
                          totalCost: double.parse(
                            _costController.text.replaceAll('.', ''),
                          ),
                          buyerId: _buyerId!,
                          date: DateTime.now(),
                          notes: _notesController.text.trim(),
                          type: widget.type,
                          portions: int.parse(_portionsController.text.trim()),
                          initialRemainingPortions: int.parse(
                            _remainingPortionsController.text.trim(),
                          ),
                        );
                        ref
                            .read(financeProvider.notifier)
                            .addPreStockItem(item);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      isKratom ? 'ບັນທຶກເຂົ້າສາງ ທ້ອມ' : 'ບັນທຶກເຂົ້າສາງນ້ຳຢາ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required Color accentColor,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(prefixIcon, color: accentColor, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.24),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditPreStockSheet extends ConsumerStatefulWidget {
  final PreStockItem item;

  const _EditPreStockSheet({required this.item});

  @override
  ConsumerState<_EditPreStockSheet> createState() => _EditPreStockSheetState();
}

class _EditPreStockSheetState extends ConsumerState<_EditPreStockSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late final TextEditingController _portionsController;
  late final TextEditingController _remainingPortionsController;
  String? _buyerId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    final costStr = NumberFormat(
      '#,###',
    ).format(widget.item.totalCost).replaceAll(',', '.');
    _costController = TextEditingController(text: costStr);
    _notesController = TextEditingController(text: widget.item.notes);
    _portionsController = TextEditingController(
      text: widget.item.portions.toString(),
    );
    _buyerId = widget.item.buyerId;

    final state = ref.read(financeProvider);
    final usedCount = state.expenses.fold<int>(0, (sum, e) {
      if (widget.item.type == 'kratom' && e.kratomStockId == widget.item.id) {
        return sum + (e.kratomPortions ?? 1);
      }
      if (widget.item.type == 'syrup' && e.syrupStockId == widget.item.id) {
        return sum + (e.syrupPortions ?? 1);
      }
      return sum;
    });
    final currentRemaining = widget.item.startingPortions - usedCount;
    _remainingPortionsController = TextEditingController(
      text: currentRemaining.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _portionsController.dispose();
    _remainingPortionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final isKratom = widget.item.type == 'kratom';
    final accentColor =
        isKratom ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header title with close icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              isKratom ? Icons.local_cafe : Icons.water_drop,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKratom
                                      ? 'ແກ້ໄຂຂໍ້ມູນ ທ້ອມ'
                                      : 'ແກ້ໄຂຂໍ້ມູນນ້ຳຢາ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isKratom
                                      ? 'ແກ້ໄຂຂໍ້ມູນ ທ້ອມ ທີ່ເລືອກໃນສາງ'
                                      : 'ແກ້ໄຂຂໍ້ມູນນ້ຳຢາ ທີ່ເລືອກໃນສາງ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white30,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 20),

                // Item Name
                _buildTextFormField(
                  controller: _nameController,
                  label: 'ຊື່ສິນຄ້າ',
                  hintText: isKratom ? 'ປ້ອນຊື່ ທ້ອມ...' : 'ປ້ອນຊື່ນ້ຳຢາ...',
                  prefixIcon:
                      isKratom
                          ? Icons.shopping_bag_outlined
                          : Icons.water_drop_outlined,
                  accentColor: accentColor,
                  validator:
                      (val) =>
                          val == null || val.trim().isEmpty
                              ? 'ປ້ອນຊື່ສິນຄ້າ'
                              : null,
                ),
                const SizedBox(height: 16),

                // Cost
                _buildTextFormField(
                  controller: _costController,
                  label: 'ລາຄາຊື້ (₭)',
                  hintText: 'ປ້ອນລາຄາຊື້...',
                  prefixIcon: Icons.payments_outlined,
                  accentColor: accentColor,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'ປ້ອນລາຄາຊື້';
                    if (double.tryParse(val.replaceAll('.', '')) == null) {
                      return 'ປ້ອນຕົວເລກໃຫ້ຖືກຕ້ອງ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Portions & Remaining Portions Field in a Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _portionsController,
                        label: 'ຄາດຄະເນໃຊ້ງານ (ຄັ້ງ)',
                        hintText: 'ປ້ອນຈຳນວນຄັ້ງ...',
                        prefixIcon: Icons.calculate_outlined,
                        accentColor: accentColor,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'ປ້ອນຈຳນວນຄັ້ງ';
                          }
                          final parsed = int.tryParse(val);
                          if (parsed == null || parsed <= 0) {
                            return 'ປ້ອນຕົວເລກ (> 0)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _remainingPortionsController,
                        label: 'ຈຳນວນຄັ້ງທີ່ຍັງເຫຼືອ',
                        hintText: 'ປ້ອນຈຳນວນຄັ້ງທີ່ຍັງເຫຼືອ...',
                        prefixIcon: Icons.hourglass_empty,
                        accentColor: accentColor,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'ປ້ອນຈຳນວນຄັ້ງທີ່ຍັງເຫຼືອ';
                          }
                          final remaining = int.tryParse(val);
                          if (remaining == null || remaining < 0) {
                            return 'ປ້ອນຕົວເລກ (>= 0)';
                          }
                          final total = int.tryParse(_portionsController.text);
                          if (total != null && remaining > total) {
                            return 'ບໍ່ຄວນຫຼາຍກວ່າທັງໝົດ ($total)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buyer Selector
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white30,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ໃຜເປັນຄົນຊື້?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _buyerId,
                      hint: Text(
                        'ເລືອກຜູ້ຊື້',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.24),
                          fontSize: 14,
                        ),
                      ),
                      dropdownColor: const Color(0xFF0F172A),
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: accentColor,
                        size: 20,
                      ),
                      items:
                          state.members.map((m) {
                            return DropdownMenuItem<String>(
                              value: m.id,
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _buyerId = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                _buildTextFormField(
                  controller: _notesController,
                  label: 'ໝາຍເຫດ (ທາງເລືອກ)',
                  hintText: 'ປ້ອນໝາຍເຫດ...',
                  prefixIcon: Icons.description_outlined,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 24),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors:
                          isKratom
                              ? [
                                const Color(0xFF059669),
                                const Color(0xFF10B981),
                              ]
                              : [
                                const Color(0xFFE11D48),
                                const Color(0xFFF43F5E),
                              ],
                    ),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          _buyerId != null) {
                        final state = ref.read(financeProvider);
                        final usedCount = state.expenses.fold<int>(0, (sum, e) {
                          if (widget.item.type == 'kratom' &&
                              e.kratomStockId == widget.item.id) {
                            return sum + (e.kratomPortions ?? 1);
                          }
                          if (widget.item.type == 'syrup' &&
                              e.syrupStockId == widget.item.id) {
                            return sum + (e.syrupPortions ?? 1);
                          }
                          return sum;
                        });
                        final enteredRemaining = int.parse(
                          _remainingPortionsController.text.trim(),
                        );

                        final updatedItem = widget.item.copyWith(
                          itemName: _nameController.text.trim(),
                          totalCost: double.parse(
                            _costController.text.replaceAll('.', ''),
                          ),
                          buyerId: _buyerId!,
                          notes: _notesController.text.trim(),
                          portions: int.parse(_portionsController.text.trim()),
                          initialRemainingPortions:
                              enteredRemaining + usedCount,
                        );
                        ref
                            .read(financeProvider.notifier)
                            .updatePreStockItem(updatedItem);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ອັບເດດຂໍ້ມູນສາງສຳເລັດ!'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'ບັນທຶກການແກ້ໄຂ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required Color accentColor,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(prefixIcon, color: accentColor, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.24),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
