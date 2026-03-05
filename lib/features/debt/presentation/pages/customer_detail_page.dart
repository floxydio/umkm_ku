import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/debt_entity.dart';
import '../bloc/debt_bloc.dart';
import 'add_debt_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerEntity customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<DebtBloc>()
        .add(LoadDebtsByCustomer(widget.customer));
  }

  void _shareWhatsApp(BuildContext context, CustomerEntity customer) {
    final authState = context.read<AuthBloc>().state;
    final storeName = authState is AuthAuthenticated
        ? authState.user.storeName
        : 'Toko Kami';

    final text =
        'Halo ${customer.name}, tagihan hutang Anda di $storeName:\n'
        'Total hutang: ${CurrencyFormatter.formatRupiah(customer.totalDebt)}\n'
        'Terima kasih 🙏';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks tagihan disalin. Paste di WhatsApp pelanggan.'),
      ),
    );
  }

  void _navigateToAddDebt(BuildContext context, CustomerEntity customer) {
    final bloc = context.read<DebtBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AddDebtPage(customer: customer),
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, DebtEntity debt) {
    final bloc = context.read<DebtBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _PaymentSheet(debt: debt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          BlocBuilder<DebtBloc, DebtState>(
            builder: (context, state) {
              final customer = state is DebtsLoaded
                  ? state.customer
                  : widget.customer;
              return IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Bagikan Tagihan',
                onPressed: () => _shareWhatsApp(context, customer),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is DebtActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Berhasil disimpan')),
            );
          }
        },
        builder: (context, state) {
          if (state is DebtLoading || state is DebtInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DebtError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text(state.message),
                  TextButton(
                    onPressed: () => context
                        .read<DebtBloc>()
                        .add(LoadDebtsByCustomer(widget.customer)),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          if (state is DebtsLoaded) {
            return _DetailBody(
              customer: state.customer,
              debts: state.debts,
              onAddDebt: () => _navigateToAddDebt(context, state.customer),
              onPay: (debt) => _showPaymentSheet(context, debt),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Detail Body ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final CustomerEntity customer;
  final List<DebtEntity> debts;
  final VoidCallback onAddDebt;
  final ValueChanged<DebtEntity> onPay;

  const _DetailBody({
    required this.customer,
    required this.debts,
    required this.onAddDebt,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CustomerHeader(customer: customer),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddDebt,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat Hutang Baru'),
            ),
          ),
        ),
        if (debts.isEmpty)
          const Expanded(child: _EmptyDebts())
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: debts.length,
              itemBuilder: (context, i) => _DebtCard(
                debt: debts[i],
                onPay: debts[i].isPaid ? null : () => onPay(debts[i]),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Customer Header ───────────────────────────────────────────────────────────

class _CustomerHeader extends StatelessWidget {
  final CustomerEntity customer;
  const _CustomerHeader({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                customer.name.isNotEmpty
                    ? customer.name[0].toUpperCase()
                    : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    customer.phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Hutang',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatRupiah(customer.totalDebt),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: customer.totalDebt > 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Debt Card ─────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback? onPay;

  const _DebtCard({required this.debt, this.onPay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = debt.isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatRupiah(debt.amount),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                _StatusChip(isPaid: isPaid),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormatter.formatDate(debt.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (debt.dueDate != null) ...[
              const SizedBox(height: 2),
              Text(
                'Jatuh tempo: ${DateFormatter.formatDate(debt.dueDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _isDueDatePassed(debt.dueDate!) && !isPaid
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (debt.note != null && debt.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                debt.note!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dibayar: ${CurrencyFormatter.formatRupiah(debt.paidAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Sisa: ${CurrencyFormatter.formatRupiah(debt.remainingAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                if (!isPaid && onPay != null)
                  FilledButton.tonal(
                    onPressed: onPay,
                    child: const Text('Bayar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isDueDatePassed(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }
}

class _StatusChip extends StatelessWidget {
  final bool isPaid;
  const _StatusChip({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Lunas' : 'Belum Lunas',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isPaid
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Empty Debts ───────────────────────────────────────────────────────────────

class _EmptyDebts extends StatelessWidget {
  const _EmptyDebts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          const Text('Belum ada catatan hutang'),
        ],
      ),
    );
  }
}

// ── Payment Sheet ─────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final DebtEntity debt;
  const _PaymentSheet({required this.debt});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = CurrencyFormatter.parseRupiah(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bayar harus lebih dari 0')),
      );
      return;
    }
    if (amount > widget.debt.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bayar melebihi sisa hutang')),
      );
      return;
    }

    setState(() => _isSaving = true);
    context.read<DebtBloc>().add(AddPayment(
          debtId: widget.debt.id,
          amount: amount,
          paidAt: DateTime.now(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is DebtActionSuccess) {
          Navigator.pop(context);
        } else if (state is DebtError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bayar Hutang',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa hutang: ${CurrencyFormatter.formatRupiah(widget.debt.remainingAmount)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar',
                hintText: '0',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_PaymentInputFormatter()],
              autofocus: true,
            ),
            const SizedBox(height: 16),
            // Quick-fill button
            TextButton(
              onPressed: () {
                final remaining = widget.debt.remainingAmount;
                final formatted = _formatRupiahRaw(remaining);
                _amountCtrl.text = formatted;
                _amountCtrl.selection = TextSelection.collapsed(
                    offset: formatted.length);
              },
              child: Text(
                'Bayar lunas (${CurrencyFormatter.formatRupiah(widget.debt.remainingAmount)})',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bayar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiahRaw(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    final rem = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - rem) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _PaymentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final value = int.tryParse(digits) ?? 0;
    final s = value.toString();
    final buf = StringBuffer();
    final rem = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - rem) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
