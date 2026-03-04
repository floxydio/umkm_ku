import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/top_product_entity.dart';
import '../../domain/entities/weekly_report_entity.dart';
import '../bloc/report_bloc.dart';
import '../widgets/report_card_widget.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final now = DateTime.now();
        return getIt<ReportBloc>()..add(LoadDailyReport(now));
      },
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatefulWidget {
  const _ReportView();

  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final bloc = context.read<ReportBloc>();
    final now = DateTime.now();

    switch (_tabController.index) {
      case 0:
        bloc.add(LoadDailyReport(now));
      case 1:
        final monday =
            now.subtract(Duration(days: now.weekday - 1));
        bloc.add(LoadWeeklyReport(
            DateTime(monday.year, monday.month, monday.day)));
      case 2:
        bloc.add(LoadMonthlyReport(month: now.month, year: now.year));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hari Ini'),
            Tab(text: 'Minggu Ini'),
            Tab(text: 'Bulan Ini'),
          ],
        ),
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          if (state is ReportLoading || state is ReportInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReportError) {
            return _ErrorView(message: state.message);
          }
          if (state is ReportFeatureLocked) {
            return _PremiumGateView(featureKey: state.featureKey);
          }
          if (state is DailyReportLoaded) {
            return _DailyView(
              report: state.report,
              topProducts: state.topProducts,
              secondary: secondary,
            );
          }
          if (state is WeeklyReportLoaded) {
            return _WeeklyView(
              report: state.report,
              topProducts: state.topProducts,
              secondary: secondary,
            );
          }
          if (state is MonthlyReportLoaded) {
            return _MonthlyView(
              report: state.report,
              topProducts: state.topProducts,
              secondary: secondary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Daily View ────────────────────────────────────────────────────────────────

class _DailyView extends StatelessWidget {
  final DailyReportEntity report;
  final List<TopProductEntity> topProducts;
  final Color secondary;

  const _DailyView({
    required this.report,
    required this.topProducts,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(report.date);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _SummaryRow(
            revenue: report.totalRevenue,
            transactions: report.totalTransactions,
            profit: report.totalProfit,
            secondary: secondary,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Grafik Penjualan Per Jam'),
          const SizedBox(height: 8),
          _HourlyBarChart(hourlyData: report.hourlyRevenue),
          const SizedBox(height: 20),
          _TopProductsSection(topProducts: topProducts),
        ],
      ),
    );
  }
}

// ── Weekly View ───────────────────────────────────────────────────────────────

class _WeeklyView extends StatelessWidget {
  final WeeklyReportEntity report;
  final List<TopProductEntity> topProducts;
  final Color secondary;

  const _WeeklyView({
    required this.report,
    required this.topProducts,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekLabel =
        '${DateFormat('d MMM', 'id_ID').format(report.startDate)} – '
        '${DateFormat('d MMM yyyy', 'id_ID').format(report.startDate.add(const Duration(days: 6)))}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(weekLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _SummaryRow(
            revenue: report.totalRevenue,
            transactions: report.totalTransactions,
            profit: report.totalProfit,
            secondary: secondary,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Grafik Omzet Per Hari'),
          const SizedBox(height: 8),
          _WeeklyBarChart(days: report.days),
          const SizedBox(height: 20),
          _TopProductsSection(topProducts: topProducts),
        ],
      ),
    );
  }
}

// ── Monthly View ──────────────────────────────────────────────────────────────

class _MonthlyView extends StatelessWidget {
  final MonthlyReportEntity report;
  final List<TopProductEntity> topProducts;
  final Color secondary;

  const _MonthlyView({
    required this.report,
    required this.topProducts,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel =
        DateFormat('MMMM yyyy', 'id_ID').format(DateTime(report.year, report.month));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(monthLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _SummaryRow(
            revenue: report.totalRevenue,
            transactions: report.totalTransactions,
            profit: report.totalProfit,
            secondary: secondary,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Grafik Omzet Harian'),
          const SizedBox(height: 8),
          _MonthlyBarChart(allDays: report.allDays),
          const SizedBox(height: 20),
          _TopProductsSection(topProducts: topProducts),
          const SizedBox(height: 16),
          _ExportButton(),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int revenue;
  final int transactions;
  final int profit;
  final Color secondary;

  const _SummaryRow({
    required this.revenue,
    required this.transactions,
    required this.profit,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        ReportCard(
          label: 'Omzet',
          value: CurrencyFormatter.formatRupiah(revenue),
          valueColor: secondary,
        ),
        const SizedBox(width: 8),
        ReportCard(
          label: 'Transaksi',
          value: '$transactions',
          valueColor: primary,
        ),
        const SizedBox(width: 8),
        ReportCard(
          label: 'Keuntungan',
          value: CurrencyFormatter.formatRupiah(profit),
          valueColor: const Color(0xFF27AE60),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

// ── Bar Charts ────────────────────────────────────────────────────────────────

String _compactRupiah(int amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}jt';
  }
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
  return '$amount';
}

class _HourlyBarChart extends StatelessWidget {
  final List<HourlyRevenuePoint> hourlyData;

  const _HourlyBarChart({required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maxY = hourlyData.isEmpty
        ? 1.0
        : (hourlyData.map((h) => h.revenue).reduce((a, b) => a > b ? a : b) *
                1.2)
            .toDouble();

    final barGroups = hourlyData
        .map((h) => BarChartGroupData(
              x: h.hour,
              barRods: [
                BarChartRodData(
                  toY: h.revenue.toDouble(),
                  color: h.revenue > 0
                      ? primary
                      : primary.withValues(alpha: 0.15),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            ))
        .toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY,
          barGroups: barGroups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, _) => Text(
                  _compactRupiah(val.toInt()),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6,
                getTitlesWidget: (val, _) => Text(
                  '${val.toInt()}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyReportEntity> days;

  const _WeeklyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final maxY = days.isEmpty
        ? 1.0
        : (days.map((d) => d.totalRevenue).reduce((a, b) => a > b ? a : b) *
                1.2)
            .toDouble();

    final barGroups = days.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: d.totalRevenue.toDouble(),
            color: d.totalRevenue > 0
                ? primary
                : primary.withValues(alpha: 0.15),
            width: 22,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY,
          barGroups: barGroups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, _) => Text(
                  _compactRupiah(val.toInt()),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= dayLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(dayLabels[idx],
                      style: const TextStyle(fontSize: 11));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<DailyReportEntity> allDays;

  const _MonthlyBarChart({required this.allDays});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final maxY = allDays.isEmpty
        ? 1.0
        : (allDays
                    .map((d) => d.totalRevenue)
                    .reduce((a, b) => a > b ? a : b) *
                1.2)
            .toDouble();

    final barGroups = allDays.asMap().entries.map((entry) {
      final d = entry.value;
      return BarChartGroupData(
        x: d.date.day,
        barRods: [
          BarChartRodData(
            toY: d.totalRevenue.toDouble(),
            color: d.totalRevenue > 0
                ? primary
                : primary.withValues(alpha: 0.15),
            width: 6,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY,
          barGroups: barGroups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (val, _) => Text(
                  _compactRupiah(val.toInt()),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (val, _) => Text(
                  '${val.toInt()}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top Products ──────────────────────────────────────────────────────────────

class _TopProductsSection extends StatelessWidget {
  final List<TopProductEntity> topProducts;

  const _TopProductsSection({required this.topProducts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Top 5 Produk Terlaris'),
        const SizedBox(height: 8),
        if (topProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Belum ada transaksi',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...topProducts.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final p = entry.value;
            return _TopProductTile(rank: rank, product: p);
          }),
      ],
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final TopProductEntity product;

  const _TopProductTile({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColors = [
      const Color(0xFFFFD700), // gold
      const Color(0xFFC0C0C0), // silver
      const Color(0xFFCD7F32), // bronze
    ];
    final badgeColor =
        rank <= 3 ? rankColors[rank - 1] : theme.colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: rank <= 3 ? Colors.black87 : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        title: Text(product.productName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${product.quantitySold} terjual'),
        trailing: Text(
          CurrencyFormatter.formatRupiah(product.totalRevenue),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Premium Gate ──────────────────────────────────────────────────────────────

class _PremiumGateView extends StatelessWidget {
  final String featureKey;

  const _PremiumGateView({required this.featureKey});

  String get _label => featureKey == 'weekly_report'
      ? 'Laporan Mingguan'
      : 'Laporan Bulanan';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded,
                size: 64,
                color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'Fitur Premium',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$_label tersedia untuk pengguna premium. '
              'Upgrade sekarang untuk melihat tren omzet yang lebih lengkap.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Upgrade ke Premium'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir!')),
    );
  }
}

// ── Export Button ─────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      icon: const Icon(Icons.picture_as_pdf_rounded),
      label: const Text('Export PDF (Premium)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.secondary,
        side: BorderSide(color: theme.colorScheme.secondary),
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur export PDF tersedia di Premium.')),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
