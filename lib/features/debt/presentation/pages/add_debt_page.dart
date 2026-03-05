import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../bloc/debt_bloc.dart';

class AddDebtPage extends StatefulWidget {
  final CustomerEntity customer;

  const AddDebtPage({super.key, required this.customer});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Pilih Tanggal Jatuh Tempo',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = CurrencyFormatter.parseRupiah(_amountCtrl.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah hutang harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    context.read<DebtBloc>().add(
          AddDebt(AddDebtParams(
            customerId: widget.customer.id,
            amount: amount,
            dueDate: _dueDate,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          )),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is DebtActionSuccess) {
          setState(() => _isSaving = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hutang berhasil dicatat')),
          );
        } else if (state is DebtError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catat Hutang Baru'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _submit,
                child: const Text('Simpan'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Pelanggan (readonly) ──────────────────────────────────
              _InfoCard(customer: widget.customer),
              const SizedBox(height: 20),

              // ── Jumlah Hutang ─────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Hutang',
                  hintText: '0',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_RupiahInputFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Jumlah hutang tidak boleh kosong';
                  }
                  if (CurrencyFormatter.parseRupiah(v) <= 0) {
                    return 'Jumlah hutang harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Tanggal Jatuh Tempo ───────────────────────────────────
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Jatuh Tempo (Opsional)',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _dueDate = null),
                          ),
                        const Icon(Icons.calendar_today_rounded),
                      ],
                    ),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormatter.formatDate(_dueDate!)
                        : 'Tidak ada jatuh tempo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _dueDate != null
                              ? null
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Keterangan ────────────────────────────────────────────
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Opsional)',
                  hintText: 'Contoh: Hutang pembelian barang',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ── Save Button ───────────────────────────────────────────
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: const Text('Simpan Hutang'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final CustomerEntity customer;
  const _InfoCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                customer.name.isNotEmpty
                    ? customer.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  customer.phone,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rupiah Input Formatter ────────────────────────────────────────────────────

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final value = int.tryParse(digits) ?? 0;
    final formatted = _format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(int value) {
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
