import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../product/presentation/widgets/upsell_bottom_sheet.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../bloc/debt_bloc.dart';
import 'customer_detail_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  @override
  void initState() {
    super.initState();
    context.read<DebtBloc>().add(const LoadCustomers());
  }

  Future<void> _onFabTap(BuildContext context, int customerCount) async {
    if (customerCount >= AppConstants.maxFreeCustomers) {
      UpsellBottomSheet.show(
        context,
        description:
            'Anda telah mencapai batas ${AppConstants.maxFreeCustomers} pelanggan '
            'pada paket gratis. Tingkatkan ke Premium untuk pelanggan tidak terbatas.',
        price: 49000,
        onBuy: () {},
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<DebtBloc>(),
        child: const _AddCustomerDialog(),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, CustomerEntity customer) {
    final bloc = context.read<DebtBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CustomerDetailPage(customer: customer),
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        bloc.add(const LoadCustomers());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hutang Pelanggan')),
      body: BlocConsumer<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is DebtLoading || state is DebtInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DebtError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<DebtBloc>().add(const LoadCustomers()),
            );
          }
          if (state is CustomersLoaded) {
            return _CustomerListBody(
              state: state,
              onCustomerTap: (c) => _navigateToDetail(context, c),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          final count =
              state is CustomersLoaded ? state.customers.length : 0;
          return FloatingActionButton.extended(
            onPressed: () => _onFabTap(context, count),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Tambah Pelanggan'),
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _CustomerListBody extends StatelessWidget {
  final CustomersLoaded state;
  final ValueChanged<CustomerEntity> onCustomerTap;

  const _CustomerListBody({
    required this.state,
    required this.onCustomerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryBanner(summary: state.summary),
        if (state.customers.isEmpty)
          const Expanded(child: _EmptyState())
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.customers.length,
              separatorBuilder: (context, i) => const Divider(height: 1),
              itemBuilder: (context, i) => _CustomerTile(
                customer: state.customers[i],
                onTap: () => onCustomerTap(state.customers[i]),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Summary Banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final dynamic summary;

  const _SummaryBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Piutang',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatRupiah(summary.totalRemaining as int),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.totalCustomers} Pelanggan',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customer Tile ─────────────────────────────────────────────────────────────

class _CustomerTile extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback onTap;

  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDebt = customer.totalDebt > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        customer.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        customer.phone,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.formatRupiah(customer.totalDebt),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasDebt
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasDebt)
            Text(
              'Belum lunas',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          const Text('Belum ada pelanggan'),
          const SizedBox(height: 4),
          Text(
            'Tambah pelanggan untuk mulai mencatat hutang',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 8),
          Text(message),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// ── Add Customer Dialog ────────────────────────────────────────────────────────

class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog();

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    context.read<DebtBloc>().add(
          AddCustomer(AddCustomerParams(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          )),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is DebtActionSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelanggan berhasil ditambahkan')),
          );
        } else if (state is DebtError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan',
                  hintText: 'Contoh: Budi Santoso',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                  hintText: '08xxxxxxxxxx',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nomor HP tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
