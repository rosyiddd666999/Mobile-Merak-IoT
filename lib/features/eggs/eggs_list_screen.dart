import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../core/theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/chick.dart';
import '../../data/models/egg.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/design_kit.dart';
import '../../shared/root_app_bar.dart';
import '../chicks/widgets/chick_card.dart';
import 'widgets/egg_card.dart';

/// Hub Telur (tab index 2): Aktivitas Terkini + Data Telur + Anakan inline.
/// Kedua list utama punya opsi 10 terbaru / semua, tanpa navigasi terpisah.
class EggsListScreen extends ConsumerStatefulWidget {
  const EggsListScreen({super.key});

  @override
  ConsumerState<EggsListScreen> createState() => _EggsListScreenState();
}

class _EggsListScreenState extends ConsumerState<EggsListScreen> {
  /// null = tampil semua, 10 = 10 terbaru.
  int? _limitEggs = 10;
  int? _limitChicks = 10;

  @override
  Widget build(BuildContext context) {
    final eggsAsync = ref.watch(eggsListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final breedersAsync = ref.watch(breedersListProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user != null;

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
            Row(
              children: [
                const Expanded(child: SectionHeader(title: 'Data Telur')),
                _LimitSwitch(
                  value: _limitEggs,
                  onChanged: (v) => setState(() => _limitEggs = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AsyncStateView(
              async: eggsAsync,
              actionLabel: 'memuat data telur',
              loadingMessage: 'Memuat data telur...',
              emptyIcon: Icons.egg_outlined,
              emptyMessage: 'Belum ada data telur',
              onRetry: () => ref.refresh(eggsListProvider),
              isEmpty: (eggs) => eggs.isEmpty,
              dataBuilder: (eggs) {
                final sorted = List<Egg>.of(eggs)
                  ..sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));
                final visible = _limitEggs == null
                    ? sorted
                    : sorted.take(_limitEggs!).toList();
                return Column(
                  children: [
                    for (final egg in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: EggCard(
                          egg: egg,
                          onTap: () =>
                              context.push(AppRoutes.eggDetail(egg.id)),
                        ),
                      ),
                    Text(
                      'Menampilkan ${visible.length} dari ${sorted.length} telur',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: SectionHeader(title: 'Anakan')),
                _LimitSwitch(
                  value: _limitChicks,
                  onChanged: (v) => setState(() => _limitChicks = v),
                ),
                if (canCreate)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primaryTeal,
                    ),
                    tooltip: 'Tambah anakan',
                    onPressed: () => context.push(AppRoutes.chickNew),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AsyncStateView(
              async: chicksAsync,
              actionLabel: 'memuat data anakan',
              loadingMessage: 'Memuat data anakan...',
              emptyIcon: Icons.flutter_dash,
              emptyMessage: 'Belum ada data anakan',
              onRetry: () => ref.refresh(chicksListProvider),
              isEmpty: (chicks) => chicks.isEmpty,
              dataBuilder: (chicks) {
                final sorted = List<Chick>.of(chicks)
                  ..sort(
                    (a, b) => b.tanggalMenetas.compareTo(a.tanggalMenetas),
                  );
                final visible = _limitChicks == null
                    ? sorted
                    : sorted.take(_limitChicks!).toList();
                return Column(
                  children: [
                    for (final chick in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ChickCard(
                          chick: chick,
                          onTap: () => context.push(
                            AppRoutes.chickDetail(chick.id),
                          ),
                        ),
                      ),
                    Text(
                      'Menampilkan ${visible.length} dari ${sorted.length} anakan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan batas list: 10 terbaru atau semua.
class _LimitSwitch extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _LimitSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int?>(
      segments: const [
        ButtonSegment<int?>(value: 10, label: Text('10')),
        ButtonSegment<int?>(value: null, label: Text('Semua')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      showSelectedIcon: false,
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
