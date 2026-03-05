import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../debt/presentation/bloc/debt_bloc.dart';
import '../../../debt/presentation/pages/customer_list_page.dart';
import '../../../pos/presentation/pages/pos_page.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/pages/product_list_page.dart';
import '../../../report/presentation/pages/report_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final userName = state is AuthAuthenticated ? state.user.storeName : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(userName.isNotEmpty ? userName : 'UMKM Ku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.point_of_sale_rounded),
                label: const Text('Kasir / POS'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PosPage()),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Produk'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => getIt<ProductBloc>(),
                      child: const ProductListPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Hutang Pelanggan'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => getIt<DebtBloc>(),
                      child: const CustomerListPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Laporan'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
