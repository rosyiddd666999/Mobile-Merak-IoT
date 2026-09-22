import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../core/theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/egg.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/design_kit.dart';
import '../../shared/root_app_bar.dart';
import 'widgets/egg_card.dart';

/// Hub Telur (tab index 2): Data Telur + Anakan.
/// Monitoring inkubator & CCTV tinggal di tab Inkubator.
class EggsListScreen extends ConsumerWidget {
  const EggsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggsAsync = ref.watch(eggsListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final breedersAsync = ref.watch(breedersListProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user != null;

    final anakCount = chicksAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => null,
    );
    final names = <String, String>{
      for (final b in breedersAsync.valueOrNull ?? const [])
        b.id: (b.nama?.isNotEmpty == true ? b.nama! : b.id),
    };

    return Scaffold(
      appBar: const RootAppBar(title: 'Telur'),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: null,
              onPressed: () => context.push(AppRoutes.eggNew),
              backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chicksListProvider);
          ref.invalidate(breedersListProvider);
          await ref.read(eggsListProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            eggsAsync.maybeWhen(
              data: (eggs) {
                final latest = List<Egg>.of(eggs)
                  ..sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));
                if (latest.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _LatestActivityCard(
                    eggs: latest.take(3).toList(),
                    names: names,
                    onOpen: (id) => context.push(AppRoutes.eggDetail(id)),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SectionHeader(title: 'Data Telur'),
            const SizedBox(height: 12),
            AsyncStateView(
              async: eggsAsync,
          actionLabel: 'memuat data telur',
              loadingMessage: 'Memuat data telur...',
              emptyIcon: Icons.egg_outlined,
              emptyMessage: 'Belum ada data telur',
              onRetry: () => ref.refresh(eggsListProvider),
              isEmpty: (eggs) => eggs.isEmpty,
              dataBuilder: (eggs) => Column(
                children: [
                  for (final egg in eggs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EggCard(
                        egg: egg,
                        onTap: () =>
                            context.push(AppRoutes.eggDetail(egg.id)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Anakan'),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.flutter_dash,
                  color: AppColors.primaryTeal,
                ),
                title: const Text(
                  'Data Anakan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  anakCount != null
                      ? '$anakCount anakan terdata'
                      : 'Lihat hasil penetasan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.chicks),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aktivitas terkini: 3 telur terbaru + nama pasangan induk.
class _LatestActivityCard extends StatelessWidget {
  final List<Egg> eggs;
  final Map<String, String> names;
  final ValueChanged<String> onOpen;

  const _LatestActivityCard({
    required this.eggs,
    required this.names,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas Terkini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < eggs.length; i++) ...[
              _eggRow(eggs[i]),
              if (i < eggs.length - 1)
                const Divider(height: 1, indent: 0, endIndent: 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eggRow(Egg egg) {
    final ayah = names[egg.indukJantanId] ?? egg.indukJantanId;
    final ibu = names[egg.indukBetinaId] ?? egg.indukBetinaId;
    final pair = (egg.indukJantanId.isEmpty && egg.indukBetinaId.isEmpty)
        ? '-'
        : '$ayah × $ibu';
    final fertil = egg.fertilitas;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.egg_outlined,
          size: 19,
          color: AppColors.primaryTeal,
        ),
      ),
      title: Text(
        egg.id,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$pair · ${egg.tanggalMasuk.isNotEmpty ? formatDate(egg.tanggalMasuk) : '-'}',
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StatusChip(
        label: fertil.isEmpty ? '-' : fertil,
        status: fertil == 'Fertil'
            ? AppStatus.active
            : fertil == 'Infertil'
            ? AppStatus.alert
            : AppStatus.pending,
      ),
      onTap: () => onOpen(egg.id),
    );
  }
}
