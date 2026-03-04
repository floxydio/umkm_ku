import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/cart_entity.dart';

class TransactionSuccessPage extends StatefulWidget {
  final String transactionId;
  final CartEntity savedCart;

  const TransactionSuccessPage({
    super.key,
    required this.transactionId,
    required this.savedCart,
  });

  @override
  State<TransactionSuccessPage> createState() =>
      _TransactionSuccessPageState();
}

class _TransactionSuccessPageState extends State<TransactionSuccessPage>
    with SingleTickerProviderStateMixin {
  Timer? _autoReturnTimer;
  int _countdown = 3;
  bool _userInteracted = false;
  late AnimationController _checkAnimController;
  late Animation<double> _checkScaleAnim;

  @override
  void initState() {
    super.initState();

    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkScaleAnim = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );
    _checkAnimController.forward();

    _startCountdown();
  }

  void _startCountdown() {
    _autoReturnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_userInteracted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _navigateBack();
      }
    });
  }

  void _navigateBack() {
    if (mounted) Navigator.of(context).pop();
  }

  void _onNewTransaction() {
    _userInteracted = true;
    _autoReturnTimer?.cancel();
    Navigator.of(context).pop();
  }

  void _onShareReceipt() {
    _userInteracted = true;
    _autoReturnTimer?.cancel();
    final receipt = _buildReceiptText();
    Clipboard.setData(ClipboardData(text: receipt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Struk disalin ke clipboard. Tempel di WhatsApp!'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _buildReceiptText() {
    final cart = widget.savedCart;
    final shortId = widget.transactionId.substring(0, 8).toUpperCase();
    final now = DateTime.now();
    final dateStr = DateFormatter.formatDate(now);
    final timeStr = DateFormatter.formatTime(now);

    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('         STRUK PEMBELIAN        ');
    buffer.writeln('================================');
    buffer.writeln('No. Transaksi : #$shortId');
    buffer.writeln('Tanggal       : $dateStr $timeStr');
    buffer.writeln('--------------------------------');

    for (final item in cart.items) {
      buffer.writeln(item.product.name);
      buffer.writeln(
          '  ${item.quantity} x ${CurrencyFormatter.formatRupiah(item.product.price)} = ${CurrencyFormatter.formatRupiah(item.subtotal)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln(
        'Subtotal  : ${CurrencyFormatter.formatRupiah(cart.subtotal)}');
    if (cart.discount > 0) {
      buffer.writeln(
          'Diskon    : -${CurrencyFormatter.formatRupiah(cart.discount)}');
    }
    buffer.writeln('TOTAL     : ${CurrencyFormatter.formatRupiah(cart.total)}');
    buffer.writeln(
        'Bayar     : ${CurrencyFormatter.formatRupiah(cart.paid)}');
    buffer.writeln(
        'Kembalian : ${CurrencyFormatter.formatRupiah(cart.change)}');
    buffer.writeln('================================');
    buffer.writeln('       Terima kasih!            ');
    buffer.writeln('================================');

    return buffer.toString();
  }

  @override
  void dispose() {
    _autoReturnTimer?.cancel();
    _checkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cart = widget.savedCart;
    final shortId =
        widget.transactionId.substring(0, 8).toUpperCase();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _userInteracted = true;
          _autoReturnTimer?.cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi Berhasil'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Success icon
                ScaleTransition(
                  scale: _checkScaleAnim,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        size: 72, color: Colors.green[600]),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Pembayaran Berhasil!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No. Transaksi: #$shortId',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Transaksi',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Divider(height: 16),

                        // Items
                        ...cart.items.map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.product.name} ×${item.quantity}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatRupiah(
                                        item.subtotal),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )),

                        const Divider(height: 16),

                        if (cart.discount > 0) ...[
                          _SummaryRow(
                            label: 'Subtotal',
                            value: CurrencyFormatter.formatRupiah(
                                cart.subtotal),
                          ),
                          _SummaryRow(
                            label: 'Diskon',
                            value:
                                '-${CurrencyFormatter.formatRupiah(cart.discount)}',
                            valueColor: cs.error,
                          ),
                          const SizedBox(height: 4),
                        ],

                        _SummaryRow(
                          label: 'TOTAL',
                          value:
                              CurrencyFormatter.formatRupiah(cart.total),
                          labelStyle: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          valueStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _SummaryRow(
                          label: 'Bayar',
                          value:
                              CurrencyFormatter.formatRupiah(cart.paid),
                        ),

                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Kembalian: ${CurrencyFormatter.formatRupiah(cart.change)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Transaksi Baru'),
                    onPressed: _onNewTransaction,
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Salin Struk (WhatsApp)'),
                    onPressed: _onShareReceipt,
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-return countdown
                if (!_userInteracted)
                  Text(
                    'Kembali otomatis dalam $_countdown detik...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? defaultStyle),
        Text(
          value,
          style: (valueStyle ?? defaultStyle)?.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
