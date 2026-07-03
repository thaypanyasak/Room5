import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';

class SettleUpScreen extends ConsumerWidget {
  const SettleUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final notifier = ref.read(financeProvider.notifier);
    final transfers = notifier.calculateOptimizedTransfers();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'K', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ສະຫຼຸບໜີ້ສິນ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ຊຳລະແບບປະຢັດການໂອນ',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ລະບົບໄດ້ຄຳນວນ ແລະ ຈັບຄູ່ຜູ້ຕິດໜີ້ ກັບ ຜູ້ທີ່ຈະໄດ້ຮັບເງິນຄືນ ເພື່ອໃຫ້ມີການໂອນເງິນໜ້ອຍຄັ້ງທີ່ສຸດ.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'ລາຍການໂອນເງິນທີ່ຕ້ອງເຮັດ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Transfers list
            Expanded(
              child: transfers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 64, color: const Color(0xFF10B981).withOpacity(0.8)),
                          const SizedBox(height: 16),
                          const Text(
                            'ທຸກຢ່າງເຄຼຍກັນໝົດແລ້ວ!',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: transfers.length,
                      itemBuilder: (context, index) {
                        final transfer = transfers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(transfer.from.avatarUrl),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_upward_rounded, size: 10, color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                            title: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: transfer.from.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                  const TextSpan(
                                    text: ' ໂອນໃຫ້ ',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                  TextSpan(
                                    text: transfer.to.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'ແຕະເພື່ອເບິ່ງ QR Code ໂອນໄວ',
                                style: TextStyle(color: Colors.white30, fontSize: 11),
                              ),
                            ),
                            trailing: Text(
                              currencyFormat.format(transfer.amount),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onTap: () {
                              _showQRDialog(context, transfer, currencyFormat);
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Settle up & reset button
            if (state.expenses.isNotEmpty || state.preStockItems.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: const BorderSide(color: Color(0xFFF87171)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    _showResetConfirmDialog(context, ref);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'ໄລ່ເງິນແລ້ວ & ລ້າງຂໍ້ມູນ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(financeProvider);
    final controller = TextEditingController(text: 'ງວດທີ ${state.periods.length + 1}');
    bool keepRemainingStock = true;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                'ສະຫຼຸບ ແລະ ເລີ່ມງວດໃໝ່',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ລະບົບຈະບັນທຶກລາຍຈ່າຍ ແລະ ສາງທັງໝົດໃນປັດຈຸບັນເຂົ້າໃນປະຫວັດງວດ ແລະ ລ້າງຂໍ້ມູນເພື່ອເລີ່ມຮອບໃໝ່.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'ຊື່ອງວດນີ້',
                      labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ການຈັດການສິນຄ້າຄົງເຫຼືອ:',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => keepRemainingStock = false),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: !keepRemainingStock ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !keepRemainingStock ? const Color(0xFF10B981) : Colors.white10,
                              ),
                            ),
                            child: Text(
                              '1. ລ້າງສາງທັງໝົດ',
                              style: TextStyle(
                                color: !keepRemainingStock ? const Color(0xFF10B981) : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => keepRemainingStock = true),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: keepRemainingStock ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: keepRemainingStock ? const Color(0xFF10B981) : Colors.white10,
                              ),
                            ),
                            child: Text(
                              '2. ເກັບຂອງທີ່ເຫຼືອ',
                              style: TextStyle(
                                color: keepRemainingStock ? const Color(0xFF10B981) : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(financeProvider.notifier).settleAndStartNewPeriod(
                      periodName: name,
                      keepRemainingStock: keepRemainingStock,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ເລີ່ມງວດໃໝ່ "$name" ແລ້ວ!')),
                    );
                  },
                  child: const Text('ຕົກລົງ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQRDialog(BuildContext context, Transfer transfer, NumberFormat format) {
    // VietQR mock code generator schema: https://img.vietqr.io/image/<BANK_ID>-<ACCOUNT_NO>-<TEMPLATE>.png?amount=<AMOUNT>&addInfo=<DESCRIPTION>&accountName=<ACCOUNT_NAME>
    final String amountStr = transfer.amount.toStringAsFixed(0);
    final String description = Uri.encodeComponent('${transfer.from.name} on ngoen Room 5');
    final String receiverName = Uri.encodeComponent(transfer.to.name.toUpperCase());
    
    // We mock MBBank (id: MB) with account number 0909090909
    final String mockQrUrl = 'https://img.vietqr.io/image/MB-0909090909-compact2.png?amount=$amountStr&addInfo=$description&accountName=$receiverName';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ສະແກນ QR Code ເພື່ອໂອນເງິນ',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'QR Code ໂອນໄວ (VietQR/MOCK)',
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                ),
                const SizedBox(height: 20),
                
                // QR Display Frame
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: transfer.to.qrPath != null && transfer.to.qrPath!.isNotEmpty
                        ? Image.file(
                            File(transfer.to.qrPath!),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: const Color(0xFF0F172A),
                                child: const Icon(Icons.broken_image_rounded, size: 60, color: Colors.black26),
                              );
                            },
                          )
                        : Image.network(
                            mockQrUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: const Color(0xFF0F172A),
                                child: const Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.white24),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Money Transfer Details
                _qrDetailRow('ຜູ້ຮັບ:', transfer.to.name),
                _qrDetailRow(
                  'ປະເພດ QR:',
                  transfer.to.qrPath != null && transfer.to.qrPath!.isNotEmpty
                      ? 'QR ສ່ວນຕົວຂອງ ${transfer.to.name}'
                      : 'BCEL Bank - 0909090909 (MOCK)',
                ),
                _qrDetailRow('ຈຳນວນເງິນໂອນ:', format.format(transfer.amount), valueColor: const Color(0xFF10B981)),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('ປິດ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qrDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
