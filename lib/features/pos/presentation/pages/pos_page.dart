import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../bloc/cart_cubit.dart';
import '../bloc/pos_bloc.dart';
import 'transaction_success_page.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PosBloc>(
          create: (_) => getIt<PosBloc>()..add(const LoadProducts()),
        ),
        BlocProvider<CartCubit>(
          create: (_) => CartCubit(),
        ),
      ],
      child: const _PosView(),
    );
  }
}

class _PosView extends StatefulWidget {
  const _PosView();

  @override
  State<_PosView> createState() => _PosViewState();
}

class _PosViewState extends State<_PosView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _onPayPressed(BuildContext context) {
    final cartState = context.read<CartCubit>().state;
    final authState = context.read<AuthBloc>().state;

    if (!cartState.canPay) return;

    String cashierId = 'default-owner';
    String cashierName = 'Pemilik';

    if (authState is AuthAuthenticated) {
      cashierId = authState.user.id;
      cashierName = authState.user.storeName.isNotEmpty
          ? authState.user.storeName
          : authState.user.fullName;
    }

    context.read<PosBloc>().add(
          ProcessTransaction(
            cart: cartState.toCartEntity(),
            cashierId: cashierId,
            cashierName: cashierName,
          ),
        );
  }

  List<ProductEntity> _filterProducts(
      List<ProductEntity> products, String query) {
    if (query.isEmpty) return products;
    final lq = query.toLowerCase();
    return products
        .where((p) =>
            p.name.toLowerCase().contains(lq) ||
            p.categoryName.toLowerCase().contains(lq))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) {
              if (cart.totalItems == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Badge(
                  label: Text('${cart.totalItems}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<PosBloc, PosState>(
        listener: (context, state) {
          if (state is PosSuccess) {
            // Capture blocs before async gap to avoid BuildContext issues
            final cartCubit = context.read<CartCubit>();
            final posBloc = context.read<PosBloc>();
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (_) => TransactionSuccessPage(
                  transactionId: state.transactionId,
                  savedCart: state.savedCart,
                ),
              ),
            )
                .then((_) {
              cartCubit.clearCart();
              _discountController.clear();
              _paidController.clear();
              posBloc.resetToReady();
            });
          } else if (state is PosError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            context.read<PosBloc>().resetToReady();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide
                ? _buildWideLayout(context)
                : _buildNarrowLayout(context);
          },
        ),
      ),
    );
  }

  // ── Wide (tablet/landscape) layout ─────────────────────────────────────────

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: _buildProductPanel(context),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _buildCartPanel(context),
        ),
      ],
    );
  }

  // ── Narrow (phone/portrait) layout ─────────────────────────────────────────

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 55,
          child: _buildProductPanel(context),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 45,
          child: _buildCartPanel(context),
        ),
      ],
    );
  }

  // ── Product panel ───────────────────────────────────────────────────────────

  Widget _buildProductPanel(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(child: _buildProductGrid(context)),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state is PosLoading || state is PosInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PosError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      context.read<PosBloc>().add(const LoadProducts()),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }

        final products = state is PosReady ? state.products : <ProductEntity>[];
        final filtered = _filterProducts(products, _searchQuery);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 56,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Produk tidak ditemukan'
                      : 'Belum ada produk',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.15,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _ProductCard(product: filtered[i]),
        );
      },
    );
  }

  // ── Cart panel ─────────────────────────────────────────────────────────────

  Widget _buildCartPanel(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        return Column(
          children: [
            Expanded(
              child: cart.isEmpty
                  ? _buildEmptyCart(context)
                  : _buildCartItemList(context, cart),
            ),
            const Divider(height: 1),
            _buildPaymentSection(context, cart),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Keranjang kosong',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemList(BuildContext context, CartState cart) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
    );
  }

  Widget _buildPaymentSection(BuildContext context, CartState cart) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: theme.cardTheme.color ?? cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            label: 'Subtotal',
            value: CurrencyFormatter.formatRupiah(cart.subtotal),
          ),
          const SizedBox(height: 6),

          // Discount row
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Diskon', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                  onChanged: (v) {
                    final amount = int.tryParse(v) ?? 0;
                    context.read<CartCubit>().applyDiscount(amount);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Total row
          _SummaryRow(
            label: 'TOTAL',
            value: CurrencyFormatter.formatRupiah(cart.total),
            labelStyle: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            valueStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),

          // Paid amount row
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Uang Diterima', style: TextStyle(fontSize: 14)),
              ),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                  onChanged: (v) {
                    final amount = int.tryParse(v) ?? 0;
                    context.read<CartCubit>().updatePaid(amount);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Change display
          if (cart.paid > 0)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: cart.paid >= cart.total
                    ? Colors.green.withValues(alpha: 0.1)
                    : cs.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                cart.paid < cart.total
                    ? 'Kurang: ${CurrencyFormatter.formatRupiah(cart.total - cart.paid)}'
                    : 'Kembalian: ${CurrencyFormatter.formatRupiah(cart.change)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cart.paid >= cart.total
                      ? Colors.green[700]
                      : cs.error,
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Pay button
          BlocBuilder<PosBloc, PosState>(
            builder: (context, posState) {
              final isProcessing = posState is PosLoading;
              return SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: (!isProcessing && cart.canPay)
                      ? () => _onPayPressed(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('BAYAR'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── ProductCard ────────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final ProductEntity product;

  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onTap(BuildContext context) async {
    if (widget.product.stock <= 0) return;
    await _animController.forward();
    await _animController.reverse();
    if (!context.mounted) return;
    context.read<CartCubit>().addToCart(widget.product);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ditambahkan'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final product = widget.product;
    final isOutOfStock = product.stock <= 0;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isOutOfStock ? null : () => _onTap(context),
          child: Opacity(
            opacity: isOutOfStock ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category chip
                  if (product.categoryName.isNotEmpty &&
                      product.categoryName != 'Tanpa Kategori')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categoryName,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Product name
                  Flexible(
                    child: Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    CurrencyFormatter.formatRupiah(product.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Stock
                  Text(
                    isOutOfStock ? 'Stok habis' : 'Stok: ${product.stock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOutOfStock
                          ? cs.error
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CartItemTile ───────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItemEntity item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cubit = context.read<CartCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyFormatter.formatRupiah(item.product.price),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Qty stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepperButton(
                icon: Icons.remove,
                onPressed: () =>
                    cubit.updateQuantity(item.product.id, item.quantity - 1),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _StepperButton(
                icon: Icons.add,
                onPressed: () =>
                    cubit.updateQuantity(item.product.id, item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              CurrencyFormatter.formatRupiah(item.subtotal),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => cubit.removeFromCart(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// ── SummaryRow ─────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? defaultStyle),
        Text(value, style: valueStyle ?? defaultStyle),
      ],
    );
  }
}
