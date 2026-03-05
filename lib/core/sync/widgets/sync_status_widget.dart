import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../sync_cubit.dart';

/// Compact sync-status indicator for app bars or bottom bars.
///
/// • SyncIdle       → small grey dot
/// • SyncInProgress → tiny spinning indicator
/// • SyncSuccess    → green dot + "Tersinkron X mnt lalu"
/// • SyncError      → orange dot + "Gagal sinkron, coba lagi" (tappable)
class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        if (state is SyncInProgress) return const _Spinner();
        if (state is SyncSuccess) return _SuccessRow(at: state.lastSyncedAt);
        if (state is SyncError) {
          return _ErrorRow(onTap: () => context.read<SyncCubit>().sync());
        }
        return const _Dot(color: Colors.grey);
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
}

class _SuccessRow extends StatelessWidget {
  final DateTime at;
  const _SuccessRow({required this.at});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Dot(color: Colors.green),
        const SizedBox(width: 4),
        Text(
          'Tersinkron ${_timeAgo(at)}',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.green),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

class _ErrorRow extends StatelessWidget {
  final VoidCallback onTap;
  const _ErrorRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Dot(color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'Gagal sinkron, coba lagi',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
